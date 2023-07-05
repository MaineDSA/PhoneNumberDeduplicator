local people = {}

local function write()
	local file = assert(io.open("output.csv", "w"))
	file:write('email,')
	file:write('can2_phone,')
	file:write('other_phones,')
	file:write('\n')
	for email, phones in pairs(people) do
		if phones[1] ~= '' then
			file:write('"' .. email .. '",')
			file:write('"' .. (phones[1] or '') .. '",')
			file:write('"' .. (phones[2] or '') .. '",')
			file:write('\n')
		end
	end
	file:close()
end

local function printPhones(phones, email)
	print(email)
	for _, phone in ipairs(phones) do
		if phone ~= '' then
			print(phone)
		end
	end
end

local function removeNumber(phones, search_phone, skip_i)
	for i, phone in ipairs(phones) do
		if i ~= skip_i and tostring(phone) == tostring(search_phone) then
			phones[i] = ''
		end
	end
end

local function consolidateOtherPhones(phones)
	local otherphones = {}
	for i, phone in ipairs(phones) do
		if i > 1 and phone ~= '' then table.insert(otherphones, phone) end
	end
	phones[2] = table.concat(otherphones, ';')
end

local function deduplicatePhones(phones)
	for i, phone in ipairs(phones) do
		if phone ~= '' then
			removeNumber(phones, phone, i)
		end
	end
end

local function fillPrimaryPhone(phones)
	if phones[1] ~= '' then return end
	for _, phone in ipairs(phones) do
		if phone ~= '' then phones[1] = phone end
	end
end

local function formatNumber(str)
	local country_code, area_code, trip, quad = string.match(str, '%+*(%d*)%s*%(*(%d%d%d)%)*%s*%-*(%d%d%d)%-*(%d%d%d%d)')
	local str_num = (country_code or '') .. (area_code or '') .. (trip or '') .. (quad or '')

	if not str_num then
		return ''
	elseif #str_num == 7 then
		return tonumber('1207' .. str_num)
	elseif #str_num == 10 then
		return tonumber('1' .. str_num)
	end

	return str_num
end

local function formatPhones(phones)
	for i, phone in ipairs(phones) do
		if phone ~= '' then
			phones[i] = formatNumber(phone)
		end
	end
end

local function splitPhones(phones)
	for i, phone in ipairs(phones) do
		if phone ~= '' and string.find(phone, ';') then
			local splitphonelist = {}
			for str in string.gmatch(phone, "([^;]+)") do
				print('splitting out phone number ' .. str)
				table.insert(splitphonelist, str)
			end
			phones[i] = ''
			table.move(splitphonelist, 1, #splitphonelist, #phones + 1, phones)
		end
	end
end

local function populateList()
	local i = 0
	for line in io.lines("download.csv") do
		if i > 0 then
			local email,
				can2_phone,
				homephone,
				home_phone,
				mobile_phone,
				phone,
				phonenumber
				= line:match('%s*"*(.-)"*,%s*"*(.-)"*,%s*"*(.-)"*,%s*"*(.-)"*,%s*"*(.-)"*,%s*"*(.-)"*,%s*"*(.-)"*')

			if email and email ~= '' then -- ignore those without emails
				people[email] = { can2_phone, mobile_phone, phonenumber, phone, homephone, home_phone }
			end
		end
		i = i + 1
	end
end

populateList()
for email, phones in pairs(people) do
	print(email)
	splitPhones(phones)
	formatPhones(phones)
	fillPrimaryPhone(phones)
	deduplicatePhones(phones)
	consolidateOtherPhones(phones)
	--printPhones(phones, email)
end
write()

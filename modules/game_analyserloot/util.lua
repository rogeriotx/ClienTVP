function formatNumber(amount)
	local formatted = amount

	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")

		if k == 0 then
			break
		end
	end

	return formatted
end

function formatName(name, maxLength)
	local length = string.len(name)

	if maxLength < length then
		name = string.sub(name, 0, maxLength) .. ".."
	end

	return name
end

function copyTable(_table)
	local newTable = {}

	for _key, value in pairs(_table) do
		newTable[_key] = value
	end

	return newTable
end

function getNumberValue(msg)
	if not msg then
		return 0
	end

	local b, e = string.find(msg, "%d+")
	local count = 0
	count = (b == nil or e == nil) and 0 or tonumber(string.sub(msg, b, e))

	return count
end
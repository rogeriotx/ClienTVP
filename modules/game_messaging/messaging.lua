local specialWindow, MESSAGING_SERVERSIDE = nil, 253

local function sendMessageBox(title, message, specialCallback)
	if specialWindow then
		specialWindow:destroy()
	end

	specialWindow = displayInfoBox(title, message)
	specialWindow:show()
	specialWindow:raise()
	specialWindow:focus()
end

function specialMessageBox(title, message, specialCallback)
	return sendMessageBox(title, message, specialCallback)
end

function init()
	ProtocolGame.registerExtendedJSONOpcode(MESSAGING_SERVERSIDE, onExtendedJSONOpcode)
end

function terminate()
	ProtocolGame.unregisterExtendedJSONOpcode(MESSAGING_SERVERSIDE, onExtendedJSONOpcode)
	
	scheduleEvent(function()
		if specialWindow then
			specialWindow:destroy()
		end
	end, 50)
end

function onExtendedJSONOpcode(protocol, code, json_data)
	local action = json_data['action']
	local data = json_data['data']
	if not action or not data then
		return false
	end
	
	if action == "sendMessage" then
		sendMessageBox(data.title, data.message)
	end
end
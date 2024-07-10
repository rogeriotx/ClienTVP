-- private variables
local infoWindow = nil
local websiteLink = "http://"..Services.website..""

local infoTexts = {
	[1] = ""..APP_NAME.." Client",
	[2] = "Version " .. g_app.getVersion(),
	[3] = "Copyright (C) 2020",
	[4] = "Ravenor",
	[5] = "All rights reserved.",
	[6] = "Official Website",
	[7] = "ravenor.online",
}

-- public functions
function init()
	infoWindow = g_ui.displayUI('client_info')
	infoWindow:hide()
	
	connect(g_game, { onGameStart = hide })
	-- connect(g_game, { onGameEnd = show })
  
	setClientInfo()
end

function show()
	if not infoWindow then return true end
	
	infoWindow:show()
	infoWindow:raise()
	infoWindow:focus()
end

function terminate()
	disconnect(g_game, { onGameStart = hide })

	infoWindow:destroy()
	infoWindow = nil
end

function toggle()
    if infoWindow:isVisible() then
        hide()
        return
    end
	
    show()
end

function hide()
    infoWindow:hide()
end

function hide()
	infoWindow:hide()
end

function openWebsite()
	g_platform.openUrl(websiteLink)
end

function setClientInfo()
	for label, text in pairs(infoTexts) do 
		local label = infoWindow:getChildById('infoLabel' .. label)
		label:setText(text)
	end
end

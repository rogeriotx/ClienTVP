function load()
    connect(g_game, { onLogout = onLogout, onGameEnd = onGameEnd, onExit = onExit,
                    onLogin = onLogin})
                end
         
function terminate()
    disconnect(g_game, { onLogout = onLogout, onGameEnd = onGameEnd, onExit = onExit,
                    onLogin = onLogin})

end

function sanitize_filename(filename)
	--[[
    -- Substituir caracteres não permitidos por "_"
    filename = filename:gsub("[\\/:%*%?\"<>|]", "_")
    
    -- Limitar o comprimento máximo do nome do arquivo (260 caracteres é o limite no Windows)
    local max_length = 260
    if #filename > max_length then
        filename = filename:sub(1, max_length)
    end
    
    return filename
	--]]
end

local function getCharacterConfigName(name)
	--[[
    local player = g_game.getCharacterName()
    -- return "/config-"..base64.encode(name and name or player)..".otml"
    return "/config-"..sanitize_filename((name and name or player))..".otml"
	--]]
end

function onExit()
	--[[
    onLogout()
	--]]
end

function onLogout()
    --[[
    modules.game_console.save_channels_history()

    save_file()
    modules.game_minimap.saveMap()

    local viplist = modules.game_viplist.getVipListInfo()
    local viplist_settings = g_settings.getNode('VipList')
    local minimap_settings = g_settings.getNode('Minimap')
    g_configs.unload(getCharacterConfigName())
    g_configs.loadSettings("/config.otml")

    viplist_settings['VipInfo'] = viplist
    g_settings.mergeNode('VipList', viplist_settings)
    
    g_settings.setNode('Minimap', minimap_settings)
	--]]
end

function onGameEnd()
	--[[
    addEvent(modules.client_options.setup)
    for _, panel in pairs(modules.game_interface.getAllPanelList()) do
        addEvent(function()
            panel:closeAll()
        end)
    end
	--]]
end

function save_file(name)
	--[[
    g_settings.save()
	--]
end

function onLogin()
	--[[
    local viplist = modules.game_viplist.getVipListInfo()
    local settings = g_settings.getNode('Minimap')
    g_configs.loadSettings(getCharacterConfigName())
    modules.game_viplist.setVipListInfo(viplist)
    modules.game_viplist.saveVipInfo()
    g_settings.setNode('Minimap', settings)
    g_settings.save()
	--]]
end
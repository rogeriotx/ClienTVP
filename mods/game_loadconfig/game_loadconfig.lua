local lastLoad = nil

function init()
	connect(g_game, {onLoadConfig = onLoadConfig})
	connect(g_game, {onGameEnd = onGameEnd})
end

function terminate()
	disconnect(g_game, {onLoadConfig = onLoadConfig})
	connect(g_game, {onGameEnd = onGameEnd})
end

function onLoadConfig(characterName)
	if characterName then
		if lastLoad and lastLoad ~= characterName then
			if g_settings.exists("Minimap") then
				g_settings.remove("Minimap")
			end
		end

		g_configs.loadSettings("/"..characterName..".otml")
		lastLoad = characterName
	end
end

function onGameEnd()
	if lastLoad then
		g_settings.save()
		g_configs.unload("/"..lastLoad..".otml")
	end
end
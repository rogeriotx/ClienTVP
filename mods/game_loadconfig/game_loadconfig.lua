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
	if lastLoad and lastLoad ~= characterName then
		if g_settings.exists("Minimap") then
			g_settings.remove("Minimap")
		end
	end

	g_configs.loadSettings("/"..characterName..".otml")
	lastLoad = characterName
end

function onGameEnd()
	g_settings.save()
	g_configs.unload("/"..characterName..".otml")
end
function init()
	--btnDummy = modules.client_topmenu.addLeftGameToggleButton('dummyButton', tr('Dummy Management'), '/images/topbuttons/guild', toggle)

	load()

	connect(g_game, {onGameStart = onGameStart})
	connect(g_game, {onGameEnd = onGameEnd})

	ProtocolGame.registerExtendedJSONOpcode(95, function(protocol, opcode, buffer) onReceiveInfo(buffer) end)
end

function terminate()
	disconnect(g_game, {onGameStart = onGameStart})
	disconnect(g_game, {onGameEnd = onGameEnd})

	PProtocolGame.unregisterExtendedJSONOpcode(95)

	gameDummy:destroy()
end

function onGameStart()
	g_game.getProtocolGame():sendExtendedOpcode(95, 'refresh')
end

function onGameEnd()
	gameDummy:destroy()
	load()
end

function load()
	gameDummy = g_ui.displayUI('game_dummy')
	gameDummy:hide()
	--gameDummy.topButton = modules.game_sidemenu.getDummyButton()
end

function toggle()
	if gameDummy:isVisible() then
		gameDummy:hide()
	else
		gameDummy:show()
	end
end

local rowColor = "#414141"
function onReceiveInfo(buffer)
	for i = 1, #buffer.data do
		if buffer.data[i].haveSkin then
			if not gameDummy.skinsWindow:getChildById(buffer.data[i].name) then
				local newSkin = g_ui.createWidget('newSkin', gameDummy.skinsWindow)

				newSkin:setId(buffer.data[i].name)

				newSkin.skinID:setOutfit({type = buffer.data[i].outfit.type, auxType = buffer.data[i].outfit.auxType, head = buffer.data[i].outfit.head, body = buffer.data[i].outfit.body, legs = buffer.data[i].outfit.legs, feet = buffer.data[i].outfit.feet, addons = 0, wings = 0, aura = 0, shader = ""})
				newSkin.skinID:setAnimate(false)

				newSkin.skinName:setText(buffer.data[i].name)

				newSkin.originalcolor = (rowColor)
				newSkin:setBackgroundColor(newSkin.originalcolor)
				newSkin:setBorderColor(newSkin.originalcolor)
				rowColor = (rowColor == "#414141" and "#484848" or "#414141")
			end
		end
	end
end

function onSendInfo(skinName)
	g_game.getProtocolGame():sendExtendedOpcode(95, skinName)
end
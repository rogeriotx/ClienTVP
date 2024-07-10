Modal = {}

Messages = {
	[1] = {"Read with attention!\n\n", "#fe7e7e",
		"Dear player,\nYou are about to receive special and unique content from our Ravenor Online's Inauguration Founder Packs.\nSome contents such as: Outfits and Dummy Skin, will only be attributed to this character who is opening the trophy and the process is IRREVERSIBLE, not being up to Ravenor Team, the reimbursement in case your character suffers in the future any punishment of exclusion, or regret for choosing the wrong character to be assigned with Ravenor Online's Inauguration Founder Packs content.\n\nEnjoy it!\n\nKind regards,\nRavenor Online", "white"
	}
}

Modal.Init = function()
	Modal.Define()
	connect(g_game, {onGameEnd = Modal.OnEnd })

	ProtocolGame.registerExtendedJSONOpcode(90, Modal.Reciver)
end

Modal.Terminate = function()
	disconnect(g_game, {onGameEnd = Modal.OnEnd })

	ProtocolGame.unregisterExtendedJSONOpcode(90)
end

Modal.OnEnd = function()
	if Modal.UI then
		Modal.Destroy()
	end
end

Modal.Define = function()
	Modal.Destroy = function()
		Modal.UI:destroy()
		Modal.UI = nil
	end

	Modal.Reciver = function(protocol, code, json_data)
		local action = json_data['action']
		local data = json_data['data']
		if not action or not data then
			return false
		end

		if not Messages[tonumber(data.type)] then
			return false
		end

		Modal.Value = data.value;
		Modal.Open(data.title, data.type)
	end

	Modal.Accept = function()
		if not g_game.getFeature(GameExtendedOpcode) then return end
		local protocolGame = g_game.getProtocolGame()
		if protocolGame then
			protocolGame:sendExtendedJSONOpcode(90, {action = "Confirm_Special_Box", data = {accept = true, value = Modal.Value}})
		end 

		if Modal.UI then
			Modal.Destroy()
		end
	end

	Modal.Cancel = function()
		if not g_game.getFeature(GameExtendedOpcode) then return end
		local protocolGame = g_game.getProtocolGame()
		if protocolGame then
			protocolGame:sendExtendedJSONOpcode(90, {action = "Confirm_Special_Box", data = {accept = false}})
		end 

		if Modal.UI then
			Modal.Destroy()
		end
	end

	Modal.Open = function(title, type)
		if Modal.UI then
			Modal.Destroy()
			return false
		end

		Modal.UI = g_ui.displayUI("modal")
		Modal.UI.text:setColoredText(Messages[type])
		Modal.UI:setText(title)
		Modal.UI.text:setHeight(Modal.UI.text:getTextSize().height + 50)
		Modal.UI:setHeight(Modal.UI.text:getHeight() + 35)
	end
end
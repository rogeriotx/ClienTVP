COMMAND_BUYITEM = '!shop'
WEBSITE_GETCOINS = 'https://ravenor.online/account/store'
COINS_OPCODE = 52

local window, listCategory, listProduct, coinBalance, acceptWindow, transferPointsWindow, withdrawWindow, changeNamePrice
local CS_SHOP_CLIENTSIDE, CS_SHOP_SERVERSIDE = 202, 203
local WEBSITE_GETCOINS = "https://ravenor.online/account/store"
local PLAYER_GENDER = 0

-- Reddington special check
local function formatNumbers(number)
	local ret = number
	while true do  
		ret, k = string.gsub(ret, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then
			break
		end
	end
return ret
end


function init()	
	g_ui.importStyle('assets/ui')
	g_ui.importStyle('assets/acceptwindow')
	
	connect(g_game, { 
		onGameEnd = onCloseStore
	})
    
	window = g_ui.displayUI('assets/store')
	-- shopButton = modules.game_sidemenu.getStoreButton() --addSideButton('storeButton', tr('Store (Ctrl+Shift+S)'), '/images/topbuttons/shop', toggle, false, 8, "STORE")
	-- shopButton:setImageColor("#75bfff")
	-- shopButton:setOn(false)
	modules.game_sidemenu.getStoreButton():setOn(false)
	g_keyboard.bindKeyDown('Ctrl+Shift+S', toggle)

	listCategory = window:recursiveGetChildById('listCategory')
	listProduct  = window:recursiveGetChildById('listProduct')
	coinBalance  = window:recursiveGetChildById('lblCoins')
	transferHistory  = window:recursiveGetChildById('transferHistory')
	
	transferPointsWindow = g_ui.displayUI('assets/transferpoints')
	transferPointsWindow:setVisible(false)
	
	withdrawWindow = g_ui.displayUI('assets/withdrawpoints')
	withdrawWindow:setVisible(false)
	
	transferHistory:setVisible(false)			
	ProtocolGame.registerExtendedJSONOpcode(CS_SHOP_SERVERSIDE, onExtendedJSONOpcode)
	
	local addons = {}

	listProduct.onChildFocusChange = function(self, focusedChild)
		if (not focusedChild) then return end
		local product = focusedChild.product

		local player = g_game.getLocalPlayer()
		local panel = window:getChildById('panelItem')
		local btnBuy = panel:getChildById('btnBuy')
		local lblName = panel:getChildById('lblName')
		local offerBox = panel:getChildById('boxOffer')

		local outfit = offerBox:getChildById('outfit')
		local image = offerBox:getChildById('image')
		local item = offerBox:getChildById('item')
		
		if product.type == 1 or product.type == 2 then
			panel:getChildById('lblName'):setText("x"..product.count.." "..product.name)
		else
			panel:getChildById('lblName'):setText(product.name)
		end
		
		local description = panel:getChildById('lblDescription')

		-- Remover addons existentes
		if #addons > 0 then
			local index = 7
			for i = 1, #addons do
				local addon = panel:getChildById('addon_'..i)
				if addon then
					panel:removeChild(addon)
					addon:destroy()
				end
			end

			panel:moveChildToIndex(description, index)
			description:removeAnchor(AnchorTop)
			description:addAnchor(AnchorTop, 'boxOffer', AnchorBottom)

			addons = {} 
		end

		--Outfit Offer:
		if product.type == 3 then

			local looktype = product.sexId.male
			if PLAYER_GENDER == 0 then
				looktype = product.sexId.female
			end

			offerBox:setSize({width = 86, height = 75 })
			btnBuy:setMarginTop(15)
			lblName:setMarginLeft(175)

			local index = panel:getChildIndex(description)
			--Creating Addons UI:
			for id, addon in pairs(product.addons) do
				local tmpAddon = panel:getChildById('addon_'..id)

				if addon.enabled then
					if not tmpAddon then

						local prevAnchor = 'boxOffer'
						if addons[1] ~= nil then
							index = index + 1
							prevAnchor = 'addon_1'
						end

						tmpAddon = g_ui.createWidget('Teste', panel)
						tmpAddon:setId('addon_'..id)
						tmpAddon:addAnchor(AnchorTop, prevAnchor, AnchorBottom)
						tmpAddon:addAnchor(AnchorLeft, prevAnchor, AnchorLeft)
		
						panel:moveChildToIndex(tmpAddon, index)
	
						description:removeAnchor(AnchorTop)
						description:addAnchor(AnchorTop, 'addon_'..id, AnchorBottom)
						panel:moveChildToIndex(description, index)

						table.insert(addons, id)
					end

					-- Addon:
					tmpAddon:getChildById('lblName'):setText("Addon "..id)
					local boxOffer = tmpAddon:getChildById('boxOffer')
					boxOffer:getChildById('outfit'):setAnimate(true)
					boxOffer:getChildById('outfit'):setOutfit({
						type = looktype,
						auxType = 0,
						addons = id,
						head = player:getOutfit().head,
						body = player:getOutfit().body,
						legs = player:getOutfit().legs,
						feet = player:getOutfit().feet
					})

					tmpAddon:getChildById('lblPrice'):setText(formatNumbers(product.addons[id].price))
					if (getCoinsBalance() < product.addons[id].price) then
						tmpAddon:getChildById('lblPrice'):setColor("#d33c3c")
						tmpAddon:getChildById('btnBuy'):disable()
					else
						tmpAddon:getChildById('lblPrice'):setColor("white")
						tmpAddon:getChildById('btnBuy'):enable()
					end

					if product.addons[id].have then
						tmpAddon:getChildById('btnBuy'):disable()
						tmpAddon:getChildById('btnBuy'):setText("Already own this")
					end
					
					--Addon Button Buy:
					tmpAddon:getChildById('btnBuy').onClick = function(widget)
						if acceptWindow then
							return true
						end

						local name = tmpAddon:getChildById('lblName'):getText()

						local addonId = string.split(tmpAddon:getChildById('lblName'):getText(), " ")

						local acceptFunc = function()
							local unformatted = coinBalance:getText():gsub(',', '')
							local balanceInfo = tonumber(unformatted)
							if balanceInfo >= product.addons[id].price then
								print(product.addons[id].price)
								sendAction("buyItem", { name = product.name, addon = addonId[2]})
	
								if acceptWindow then
									resetAllWidgetOpacity(acceptWindow)
									acceptWindow:destroy()
									acceptWindow = nil
								end
							else
								displayErrorBox(window:getText(), tr("You don't have enough coins"))
								resetAllWidgetOpacity(acceptWindow)
								acceptWindow:destroy()
								acceptWindow = nil
							end
						end
					
						local cancelFunc = function() resetAllWidgetOpacity(acceptWindow) acceptWindow:destroy() acceptWindow = nil end
						acceptWindow = displayGeneralBox(tr('Confirmation of Purchase'), 'Do you want to buy the product "'..name..'"?', { 
							{text=tr('Cancel'), callback=cancelFunc},
							{text=tr('Buy'), callback=acceptFunc},
							anchor=AnchorHorizontalCenter 
						}, acceptFunc, cancelFunc)

						acceptWindow:lock()
					end
				end
			end
		
			--Full Outfit
			panel:getChildById('lblName'):setText('Outfit')
			outfit:setVisible(true)
			outfit:setAnimate(true)
			outfit:setOutfit({
				type = looktype,
				auxType = 0,
				addons = 0,
				head = player:getOutfit().head,
				body = player:getOutfit().body,
				legs = player:getOutfit().legs,
				feet = player:getOutfit().feet
			})

			image:setVisible(false)
			item:setVisible(false)

		elseif product.type == 1 then
			item:setVisible(true)

			item:setItemId(product.clientId)

			outfit:setVisible(false)
			image:setVisible(false)
			--Not Outfit Offer:
		else
			local productImage = product.image[1]
			if productImage then
		
				offerBox:setSize({width = 96, height = 96 })
				btnBuy:setMarginTop(0)
				lblName:setMarginLeft(140)

				--Remove Outfit UI:
				if #addons > 0 then
					for i = 1, #addons do
						local addon = panel:getChildById('addon_'..i)
						if addon then
							local index = panel:getChildIndex(addon)
							
							panel:moveChildToIndex(description, index)
							description:removeAnchor(AnchorTop)
							description:addAnchor(AnchorTop, 'boxOffer', AnchorBottom)
		
							addon:destroy()
						end
	
					end

					addons = {}
				end

				image:setVisible(true)
				image:setImageSource("images/"..productImage)

				outfit:setVisible(false)
				item:setVisible(false)
			end
		end
		
		panel:getChildById('btnBuy'):setText("Buy")
		panel:getChildById('lblPrice'):setText(formatNumbers(product.price))
		panel:getChildById('lblDescription'):setText(product.description)

		if (getCoinsBalance() < product.price) then
			panel:getChildById('lblPrice'):setColor("#d33c3c")
			panel:getChildById('btnBuy'):disable()
		else
			panel:getChildById('lblPrice'):setColor("white")
			panel:getChildById('btnBuy'):enable()
		end

		if product.type == 3 then
			if product.have then
				panel:getChildById('btnBuy'):disable()
				panel:getChildById('btnBuy'):setText("Already own this")
			end
		end
		
		panel:getChildById('btnBuy').onClick = function(widget)
			if acceptWindow then
				return true
			end

			local acceptFunc = function()
				local unformatted = coinBalance:getText():gsub(',', '')
				local balanceInfo = tonumber(unformatted)
				if balanceInfo >= product.price then
					if (product.type == 3) then
						sendAction("buyItem", {name = product.name})
					else
						sendAction("buyItem", {name = product.name})
					end
					
					if acceptWindow then
						resetAllWidgetOpacity(acceptWindow)
						acceptWindow:destroy()
						acceptWindow = nil
					end
				else
					displayErrorBox(window:getText(), tr("You don't have enough coins"))
					resetAllWidgetOpacity(acceptWindow)
					acceptWindow:destroy()
					acceptWindow = nil
				end

			end
		
			local cancelFunc = function() resetAllWidgetOpacity(acceptWindow) acceptWindow:destroy() acceptWindow = nil end
			acceptWindow = displayGeneralBox(
			tr('Confirmation of Purchase'), 'Do you want to buy the product "'..product.name..'"?', { 
				{text=tr('Cancel'), callback=cancelFunc},
				{text=tr('Buy'), callback=acceptFunc},
				anchor=AnchorHorizontalCenter 
			}, acceptFunc, cancelFunc)

			acceptWindow:lock()
		end
	end  
end

function terminate()
	disconnect(g_game, { 
		onGameEnd = onCloseStore
	})
	g_keyboard.unbindKeyDown('Ctrl+Shift+S')
	ProtocolGame.unregisterExtendedJSONOpcode(CS_SHOP_SERVERSIDE, onExtendedJSONOpcode)
	window:destroy()
	if transferPointsWindow then transferPointsWindow:destroy() end
	if withdrawWindow then withdrawWindow:destroy() end
end

function getCoinsWebsite()
	if WEBSITE_GETCOINS ~= "" then
		g_platform.openUrl(WEBSITE_GETCOINS)
	else
		sendStoreMessageBox("Error", "No data for store URL.")
	end
end

function getCoinsBalance()
	local unformatted = coinBalance:getText():gsub(',', '')
	local balanceInfo = tonumber(unformatted)
return balanceInfo
end

function createHistoryEntries(buffer)
	-- Clearing the history
	while transferHistory:getChildCount() > 0 do
		local child = transferHistory:getLastChild()
		transferHistory:destroyChildren(child)
	end
	
	local data = buffer[1]
	-- Filling it
	for i = 1, #data do
		local row = g_ui.createWidget('HistoryEntry', transferHistory)	  
		row.index = i
		row:getChildById('historyDate'):setText(data[i].date)
		row:getChildById('historyDescription'):setText(data[i].description)
		row:getChildById('historyBalance'):setText(data[i].balance)
		
		if tonumber(row:getChildById('historyBalance'):getText()) < 0 then
			row:getChildById('historyBalance'):setColor("#d33c3c")
		else
			row:getChildById('historyBalance'):setMarginLeft(151)
			row:getChildById('historyBalance'):setColor("#00ff00")
		end
		
		
		if (i > 1) then
			row:setMarginTop(24 + ((i-1) * 15))
		end
		
		if (i % 2 == 0) then
			row:setBackgroundColor("#414141")
		end
	end
end

function sendAction(action, data)
	if not g_game.getFeature(GameExtendedOpcode) then return end
	local protocolGame = g_game.getProtocolGame()
	if data == nil then
		data = {}
	end

	if protocolGame then
		protocolGame:sendExtendedJSONOpcode(CS_SHOP_CLIENTSIDE, {action = action, data = data})
	end  
end

function toggleTransferHistory()
	if transferHistory:isVisible() then
		transferHistory:setVisible(false)
		window.btnHistory:setOn(false)
	else
		window.btnHistory:setOn(true)
		transferHistory:setVisible(true)
		listCategory:getFocusedChild():focus(false)
		sendAction("getHistoryData", nil)
	end
end

function onExtendedJSONOpcode(protocol, code, json_data)
	local action = json_data['action']
	local data = json_data['data']
	if not action or not data then
		return false
	end
  
	if action == 'sendCoins' then
		coinBalance:setText(formatNumbers(data))
	elseif action == "sendStoreData" then
		getStoreCategories(data)
	elseif action == "sendHistory" then
		createHistoryEntries(data)
	elseif action == "sendStoreURL" then
		changeStoreUrl(data.url)
	elseif action == "sendImagesURL" then
		changeImagesUrl(data.url)
	elseif action == "sendHideStore" then
		window:hide()
		modules.game_sidemenu.getStoreButton():setOn(false)
	elseif action == "sendPlayerSex" then
		updatePlayerSex(data)
	end
end

function updatePlayerSex(data)
	PLAYER_GENDER = data.sex
end

function changeStoreUrl(url)
	WEBSITE_GETCOINS = url
end

function changeImagesUrl(url)
	IMAGES_URL = url
end

function getStoreCategories(buffer)
	clearCategories()

	local player = g_game.getLocalPlayer()
	local storeIndex = buffer[1]
	for i, store in ipairs(storeIndex) do
		local category = g_ui.createWidget('MenuCategoryStore', listCategory)
			category.index  = i
			
			category:setIcon("images/"..store.icon)

			category:setText(tr(storeIndex[i].name))
	
		category.onClick = function(self)	
			listProduct:destroyChildren()

			local storeProducts = store.offers
			if storeProducts then
				for i, product in ipairs(storeProducts) do
					if tostring(self.index) == product.category_id then
						local row = g_ui.createWidget('RowStore', listProduct)

						local offerBox = row:getChildById('boxOffer')

						local outfit = offerBox:getChildById('outfit')
						local image = offerBox:getChildById('image')
						local item = offerBox:getChildById('item')

						row.store = store
						row.product = product		  
						row.type = product.type		
						
						if product.type == 1 or product.type == 2 then
							row:getChildById('lblName'):setText("x"..product.count.." "..product.name)
						else
							row:getChildById('lblName'):setText(product.name)
						end
					
						local price = product.price

						row:getChildById('lblName'):setTextAlign(AlignCenter)
						row:getChildById('lblName'):setMarginRight(10)
						
						if product.addons then
							for _, addon in pairs(product.addons) do
								price = price + addon.price
							end
						end

						row:getChildById('lblPrice'):setText(formatNumbers(price))
						
						if getCoinsBalance() < product.price then
							row:getChildById('lblPrice'):setColor("#d33c3c")
						end
						
						if product.type == 3 then
							local looktype = product.sexId.male
							if PLAYER_GENDER == 0 then
								looktype = product.sexId.female
							end
				
							outfit:setVisible(true)
							outfit:setAnimate(true)
							outfit:setOutfit({
								type = looktype,
								auxType = 0,
								addons = 3,
								head = player:getOutfit().head,
								body = player:getOutfit().body,
								legs = player:getOutfit().legs,
								feet = player:getOutfit().feet
							})
				
							image:setVisible(false)
							item:setVisible(false)
						elseif product.type == 1 then
							item:setVisible(true)
				
							item:setItemId(product.clientId)
				
							outfit:setVisible(false)
							image:setVisible(false)
						else
							local productImage = product.image[1]
							if productImage then
								image:setVisible(true)
								image:setImageSource("images/"..productImage)
				
								outfit:setVisible(false)
								item:setVisible(false)
							end
						end

					end
				end
			end
			
			if transferHistory:isVisible() then
				transferHistory:setVisible(false)
				window.btnHistory:setOn(false)
			end
			
			listProduct:focusChild(listProduct:getFirstChild())  
		end
	end
	
	listCategory:focusChild(listCategory:getFirstChild())  
	listCategory:getFirstChild().onClick(listCategory:getFirstChild())
	storeDataSent = true
end


function clearOffers()
	while listProduct:getChildCount() > 0 do
		local child = listProduct:getLastChild()
		listProduct:destroyChildren(child)
	end
end

function clearCategories()
	clearOffers()
	while listCategory:getChildCount() > 0 do
		local child = listCategory:getLastChild()
		listCategory:destroyChildren(child)
	end
end

function onCloseStore()
	window:hide()
	modules.game_sidemenu.getStoreButton():setOn(false)
	transferPointsWindow:setVisible(false)
	
	if acceptWindow then
		acceptWindow:destroy()
		acceptWindow = nil
	end
end

function openStoreWindow()
	window:setVisible(true)
	modules.game_sidemenu.getStoreButton():setOn(true)
end

function transferPoints()
	window:hide()
	modules.game_sidemenu.getStoreButton():setOn(false)
	
	if getCoinsBalance() <= 0 then
		return sendStoreMessageBox("Gifting not possible", "You don't have enough coins to gift.", true)
	end
	
	local value = transferPointsWindow:getChildById('transferPointsValue')
	value:setText(tr('0'))
	
	local balanceInfo = window:getChildById('lblCoins'):getText()
	local balance = transferPointsWindow:getChildById('coinBalance2')
	balance:setText(formatNumbers(balanceInfo))
	transferPointsWindow:setVisible(true)
	transferPointsWindow:focus()
	transferPointsWindow:raise()
	
	
	if acceptWindow then
		acceptWindow:destroy()
		acceptWindow = nil
	end
end

function toggleWithdraw()
	window:hide()
	modules.game_sidemenu.getStoreButton():setOn(false)
	
	if getCoinsBalance() <= 0 then
		return sendStoreMessageBox("Withdraw not possible", "You don't have enough coins to withdraw.", true)
	end
	
	local value = withdrawWindow:getChildById('withdrawValue')
	value:setText(tr('0'))
	
	local balanceInfo = window:getChildById('lblCoins'):getText()
	local balance = withdrawWindow:getChildById('coinBalance2')

	balance:setText(formatNumbers(balanceInfo))
	withdrawWindow:setVisible(true)
	withdrawWindow:focus()
	withdrawWindow:raise()
	
	
	if acceptWindow then
		acceptWindow:destroy()
		acceptWindow = nil
	end
end

function transferAccept()
	local nickname = transferPointsWindow:getChildById('transferPointsText')
	local value = transferPointsWindow:getChildById('transferPointsValue')
	if not value then return true end
	
	transferPointsWindow:getChildById('buttonOk').onClick = function(widget)
		
		local balanceInfo = getCoinsBalance()

		local transferableAmountSet = tonumber(value:getText())
		if transferableAmountSet > balanceInfo then
			displayErrorBox(window:getText(),
				tr("You don't have enough coins 1 " .. transferableAmountSet .. " vs " .. balanceInfo))
			return true
		end
		
		if tonumber(transferableAmountSet) <= 0 then
			return true
		end
		
		if acceptWindow then
			return true
		end
		
		local cancelFunc = function() acceptWindow:destroy() acceptWindow = nil end
		local acceptFunc = function()
			if balanceInfo >= transferableAmountSet then
				-- Send the action to transfer the coins.
				sendAction("transferCoins", {name = nickname:getText(), amount = transferableAmountSet})
				
				-- Destroy accept window
				resetAllWidgetOpacity(acceptWindow)
				acceptWindow:destroy()
				acceptWindow = nil
				
				-- Cleaning
				nickname:setText("")
				value:setText("0")
				
				-- Removing the window
				transferPointsWindow:setVisible(false)
				window:setVisible(true)
				modules.game_sidemenu.getStoreButton():setOn(true)
				
				-- Getting coins balance
				sendAction("getCoins", nil)
			else
				displayErrorBox(window:getText(), tr("You don't have enough coins 2 " .. transferableAmountSet .. " vs " .. balanceInfo))
				resetAllWidgetOpacity(acceptWindow)
				acceptWindow:destroy()
				acceptWindow = nil
			end
		end
		
		acceptWindow = displayGeneralBox(tr('Gift Tibia Coins'), tr("Do you want to transfer "..transferableAmountSet.." to "..nickname:getText().."?"),
		{ 
		{ text=tr('Cancel'), callback=cancelFunc },
		{ text=tr('Yes'), callback=acceptFunc },
		anchor=AnchorHorizontalCenter }, acceptFunc, cancelFunc)
		acceptWindow:lock()
			
	end
end

function transferCancel()
	local nickname = transferPointsWindow:getChildById('transferPointsText')
	local value = transferPointsWindow:getChildById('transferPointsValue')
	nickname:setText("")
	value:setText("0")
				
	transferPointsWindow:setVisible(false)
	transferHistory:setVisible(false)
	window.btnHistory:setOn(false)
	window:setVisible(true)
	modules.game_sidemenu.getStoreButton():setOn(true)

end

function withdrawAccept()
	local unformatted = coinBalance:getText():gsub(',', '')
	local balanceInfo = tonumber(unformatted)
	local value = withdrawWindow:getChildById('withdrawValue')
	if not value then return true end
	
	-- withdrawWindow:getChildById('buttonOk').onClick = function(widget)
		local withdrawAmountSet = tonumber(value:getText())
		if withdrawAmountSet > balanceInfo then
			displayErrorBox(window:getText(), tr("You don't have that amount of coins to withdraw."))
			return true
		end
		
		if tonumber(withdrawAmountSet) <= 0 then
			return true
		end
		
		if acceptWindow then
			return true
		end
		
		local cancelFunc = function() resetAllWidgetOpacity(acceptWindow) acceptWindow:destroy() acceptWindow = nil end
		local acceptFunc = function()
			if balanceInfo >= withdrawAmountSet then
				-- Send the action to transfer the coins.
				sendAction("withdrawCoins", {amount = withdrawAmountSet})
				
				-- Destroy accept window
				resetAllWidgetOpacity(acceptWindow)
				acceptWindow:destroy()
				acceptWindow = nil
				
				-- Cleaning
				value:setText("0")
				
				-- Removing the window
				withdrawWindow:setVisible(false)
				window:setVisible(true)
				modules.game_sidemenu.getStoreButton():setOn(true)

				
				-- Getting coins balance
				sendAction("getCoins", nil)
			else
				displayErrorBox(window:getText(), tr("You don't have enough coins"))
				resetAllWidgetOpacity(acceptWindow)
				acceptWindow:destroy()
				acceptWindow = nil
			end
		end
		
		acceptWindow = displayGeneralBox(tr('Withdraw Coins'), tr("Do you want to withdraw "..withdrawAmountSet.." coins?"),
		{ 
			{ text=tr('Cancel'), callback=cancelFunc },
		{ text=tr('Yes'), callback=acceptFunc },
		anchor=AnchorHorizontalCenter }, acceptFunc, cancelFunc)
		acceptWindow:lock()
	-- end
end

function withdrawCancel()
	local value = withdrawWindow:getChildById('withdrawValue')
	value:setText("0")
				
	withdrawWindow:setVisible(false)
	transferHistory:setVisible(false)
	window.btnHistory:setOn(false)
	window:setVisible(true)
	modules.game_sidemenu.getStoreButton():setOn(true)
end

function sendStoreMessageBox(title, message, specialCallback)
	modules.game_messaging.specialMessageBox(title, message, function() openStoreWindow() end)
end

function toggle()
	if window:isVisible() then
		window:hide()
		modules.game_sidemenu.getStoreButton():setOn(false)
	else
		-- Opcodes
		sendAction("getCoins", nil)
		sendAction("getStoreData", nil)
		sendAction("getStoreUrl", nil)
		sendAction("getImagesUrl", nil)
		sendAction("getGender", nil)
		
		-- The rest
		window:show()
		window:raise()
		window:focus()
		modules.game_sidemenu.getStoreButton():setOn(true)
	end
end
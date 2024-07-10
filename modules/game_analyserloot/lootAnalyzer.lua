local moneyIndex = {
	[2160.0] = 3,
	[2152.0] = 2,
	[2148.0] = 1
}

lootAnalyzer = nil
suppliesUsedWidget = nil
lootedItemsWidget = nil
local acceptLootChanges = true
function init()
	connect(LocalPlayer, {})
	connect(g_game, {
		onGameStart = onPlayerLogin,
		onGameEnd = closeCustomItem 
	})
	
	local function OpenPopMenu()
		local menu = g_ui.createWidget('PopupMenu')
		menu:addOption("Loot Analyser", function() modules.game_analyserloot.toggle() end)
		menu:addSeparator()
		menu:addOption("Experience Analyser", function() modules.game_analyserexp.toggle() end)
		menu:display()
	end

	-- buttonLoot = modules.client_topmenu.addRightGameToggleButton('analyserButton', tr('Loot Analyzer (Ctrl+U)'), '/images/topbuttons/analyzers', toggle, true, 1, tr('Loot Analyzer'))
	-- buttonLoot:setWidth(80 - 13)

	lootAnalyzer = g_ui.loadUI("lootAnalyzer", modules.game_interface.getRightPanel())
	balanceWidget.widget = lootAnalyzer
	-- lootAnalyzer.topButton = buttonLoot

	g_keyboard.bindKeyDown("Ctrl+U", toggle)

	customItemWindow = g_ui.displayUI("customItem")
	customItemWindow:hide()

	lootAnalyzer:setup()
	resetLoot()
	
	local lootWindow = lootAnalyzer:getChildById("contentsPanel")

	suppliesUsedWidget = g_ui.createWidget("ItemWidget")
	lootWindow:insertChild(nil, suppliesUsedWidget)

	local labelWidget = g_ui.createWidget("LootedItems")
	lootWindow:insertChild(nil, labelWidget)

	local seperatorWidget = g_ui.createWidget("HorizontalSeparator")
	lootWindow:insertChild(nil, seperatorWidget)

	lootedItemsWidget = g_ui.createWidget("ItemWidget")
	lootWindow:insertChild(nil, lootedItemsWidget)

	ProtocolGame.registerExtendedOpcode(GameServerOpcodes.GameServerLootStatistics, parseLootStatistics)
end

function terminate()
	closeCustomItem()

	disconnect(LocalPlayer, {})
	disconnect(g_game, {
		onGameStart = refresh,
		onGameEnd = closeCustomItem
	})

	g_keyboard.unbindKeyDown("Ctrl+U")

	lootAnalyzer:destroy()
	suppliesUsedWidget:destroy()
	lootedItemsWidget:destroy()
	resetLoot()
	ProtocolGame.unregisterExtendedOpcode(GameServerOpcodes.GameServerLootStatistics)
end

function parseLootStatistics(protocol, opcode, buffer)
	local status, result = pcall(function() return json.decode(buffer) end)

	if not status then
		return
	end

	local category = result["category"]
	local amount = tonumber(result["amount"])
	local itemId = tonumber(result["itemId"])
	local itemSubType = tonumber(result["itemSubType"])

	if category ~= "supply" and category ~= "loot" then
		return
	end

	if not itemDatabase:hasData(itemId, itemSubType) then
		return
	end

	local price = itemDatabase:getPrice(category, itemId, itemSubType)

	if price > 0 and acceptLootChanges == true then
		addItem(category, amount, itemId, itemSubType)
	end

end

function onPlayerLogin()

	local customItemSettings = g_settings.getNode("playerCustomItemDatabase")

	playerItemDatabase:clean()

	if customItemSettings then
		for _key, item in pairs(customItemSettings) do
			local itemId = tonumber(_key)

			local itemName = item.name
			local priceBuy = tonumber(item.priceBuy)
			local priceSell = tonumber(item.priceSell)
			local clientId = tonumber(item.clientId)

			local subTypes = {}
			if item.subTypes ~= nil then

				for subTypeId, subTypeData in pairs(item.subTypes) do
					subTypes[subTypeId] = {
						name = subTypeData.name,
						priceBuy = tonumber(subTypeData.priceBuy),
						priceSell = tonumber(subTypeData.priceSell),
						clientId = tonumber(subTypeData.clientId)
					}
				end
			end

			playerItemDatabase:set(itemId, {
				name = itemName,
				priceBuy = priceBuy,
				priceSell = priceSell,
				clientId = clientId,
				subTypes = subTypes
			})
		end
	end

	acceptLootChanges = false

	scheduleEvent(function ()
		acceptLootChanges = true
	end, 500)
	refresh()
end

function addItem(category, amount, itemId, itemSubType)
	local parentWidget = nil
	local price = itemDatabase:getPrice(category, itemId, itemSubType)

	if category == "supply" then
		parentWidget = suppliesUsedWidget
	elseif category == "loot" then
		parentWidget = lootedItemsWidget
	end

	if not itemWidget:hasData(category, itemId, itemSubType) then
		local box = itemWidget:new(parentWidget, category, amount, itemId, itemSubType)
		local itemIndex = moneyIndex[itemId]

		if itemIndex then
			moveMoneyBox(itemIndex, category, parentWidget, box)
		end
	end

	itemWidget:increment(category, itemId, itemSubType, amount)
	balanceWidget:update(category, price * amount)
end

function moveMoneyBox(index, category, panel, box)
	if index > 1 and not itemWidget:hasData(category, 2148, 0) then
		index = index - 1
	end

	if index > 2 and not itemWidget:hasData(category, 2152, 0) then
		index = index - 1
	end

	panel:moveChildToIndex(box, index)
end

function refresh()
	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	lootAnalyzer:setup()

	resetLoot()

	local contentsPanel = lootAnalyzer:getChildById("contentsPanel")

	lootAnalyzer:setContentMinimumHeight(44)

	--if lootAnalyzer:isVisible() and not modules.game_playerbars.lootAnalyzer:isChecked() then
	--	modules.game_playerbars.lootAnalyzer:setChecked(true)
	--end
end

function resetLoot()
	balanceWidget:clear()
	itemWidget:clear()

	if suppliesUsedWidget then
		for _i, child in pairs(suppliesUsedWidget:getChildren()) do
			child:destroy()
		end
		suppliesUsedWidget:setHeight(0)
	end

	if lootedItemsWidget then
		for _i, child in pairs(lootedItemsWidget:getChildren()) do
			child:destroy()
		end

		lootedItemsWidget:setHeight(0)
	end
end

function toggle()
	if lootAnalyzer:isVisible() then
		--if not modules.game_playerbars.lootAnalyzer:isChecked() then
			lootAnalyzer:close()
		--end
	else--if modules.game_playerbars.lootAnalyzer:isChecked() then
		lootAnalyzer:open()
	end
end

function onMiniWindowClose()
	--modules.game_playerbars.lootAnalyzer:setChecked(false)
end

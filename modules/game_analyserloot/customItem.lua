local customItemList = {
	list = {}
}

function customItemList:clear()
	self.list = {}	
end

function customItemList:add(itemId, itemData)
	local customBuy = -1
	local customSell = -1
	local customSettings = playerItemDatabase:get(itemId)
	local subTypes = itemData.subTypes

	if customSettings then
		customBuy = customSettings.priceBuy
		customSell = customSettings.priceSell
		subTypes = customSettings.subTypes or itemData.subTypes
	end

	self.list[#self.list + 1] = {
		itemId = itemId,
		name = itemData.name,
		priceBuy = itemData.priceBuy,
		priceSell = itemData.priceSell,
		clientId = itemData.clientId,
		customBuy = customBuy,
		customSell = customSell,
		subTypes = subTypes
	}

end

function customItemList:sort()
	table.sort(self.list, function (a, b)
		return string.lower(a.name) < string.lower(b.name)
	end)
end

function customItemList:get()
	return self.list
end

customItemWindow = nil

local lastSearch = 0
local minimumNameToSeach = 3

function closeCustomItem()
	customItemWindow:hide()
	customItemWindow:getChildById("searchBar"):setText("")
	customItemList:clear()
	clearCustomItem()
end

function toggleCustomItem()
	if customItemWindow:isVisible() then
		closeCustomItem()
	else
		buildCustomItemSearchList()
		customItemWindow:show()
		customItemWindow:raise()
		customItemWindow:focus()
	end
end

function clearCustomItem()
	local itemList = customItemWindow:getChildById("itemList")
	local children = itemList:getChildren()

	for k = 1, #children do
		children[k]:destroy()
	end
end

function buildCustomItemSearchList()
	lastSearch = g_clock.millis()

	clearCustomItem()
	customItemList:sort()

	local itemCount = 0
	for _, itemData in pairs(customItemList:get()) do
		itemCount = itemCount + 1

		customItemRow:addItem(itemData)

		if itemData.subTypes ~= nil then

			for subTypeId, subTypeData in pairs(itemData.subTypes) do
				local itemSubTypeData = {
					name = subTypeData.name,
					clientId = subTypeData.clientId,
					subTypeId = subTypeId,
					customBuy = subTypeData.customBuy or -1,
					customSell = subTypeData.customSell or -1,
					priceSell = subTypeData.priceSell,
					priceBuy = subTypeData.priceBuy,
					itemId = itemData.itemId
				}
				customItemRow:addItem(itemSubTypeData)
			end
		end

	end

	if itemCount <= 0 then
		customItemRow:addEmptyItem()
	end
end

function onChangeSearchBar(text)
	customItemList:clear()

	if string.len(text) >= minimumNameToSeach then
    local itemDataList = itemDatabase:getItemsByName(text)

		for itemId, itemData in pairs(itemDataList) do
			customItemList:add(itemId, itemData)
		end
	end

	buildCustomItemSearchList()
end

function showTextEdit(self, category)
	local _title = "Edit Value"
	local desc = "Unknown"

	if category == "loot" then
		desc = "Loot Value"
	elseif category == "supply" then
		desc = "Supply Value"
	end

	local itemName = self:getParent():getChildById("itemName"):getText()

	modules.client_textedit.show(self, {
		title = _title,
		description = desc .. " for " .. itemName .. [[
.
Edited items are highlighted.

Leave empty to use default values.]]
	})
end

function postTextEdited(self)
	local saveSettings = false
	local time_ms = g_clock.millis()

	if time_ms < lastSearch + 500 then
		return
	end

	customItemRow:set(self:getParent())
	local itemName = customItemRow:getItemName()
	local itemId = customItemRow:getItemId()

	local itemInfo = itemDatabase:get(itemId)

	local buyCost = itemInfo.priceBuy
	local sellCost = itemInfo.priceSell
	
	local itemInfoSubTypeId = -1

	if itemInfo.subTypes ~= nil then
		for subTypeId, subTypeData in pairs(itemInfo.subTypes) do
			if subTypeData.name == itemName then
				buyCost = subTypeData.priceBuy
				sellCost = subTypeData.priceSell

				itemInfoSubTypeId = subTypeId
				break
			end
		end
	end
	
	local customBuyCost = customItemRow:updatePriceBuy(buyCost)
	local customSellCost = customItemRow:updatePriceSell(sellCost)

	if itemInfo.subTypes ~= nil and itemInfoSubTypeId ~= -1 then
		itemInfo.subTypes[itemInfoSubTypeId].priceBuy = customBuyCost
		itemInfo.subTypes[itemInfoSubTypeId].priceSell = customSellCost
	else
		itemInfo.priceBuy = customBuyCost
		itemInfo.priceSell = customSellCost
	end

	if buyCost ~= customBuyCost or sellCost ~= customSellCost then
		playerItemDatabase:set(itemId, itemInfo)
		saveSettings = true

	elseif playerItemDatabase:get(itemId, itemInfoSubTypeId) then
		playerItemDatabase:set(itemId, nil)
		saveSettings = true
	end

	if saveSettings then
		customItemRow:addBackground(itemId, itemInfoSubTypeId, itemName)
		scheduleEvent(saveCustomItemSettings())
	end
end

function saveCustomItemSettings()
	g_settings.setNode("playerCustomItemDatabase", playerItemDatabase.data)
end

function showEditedItems()
	customItemList:clear()

	for itemId, itemData in pairs(playerItemDatabase.data) do
		customItemList:add(itemId, itemData)
	end

	buildCustomItemSearchList()
end



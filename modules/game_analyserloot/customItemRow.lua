customItemRow = {
  lootSearchLabel = nil
}

local colorNoItemFound = "#f6ff00"
local colorDefault = "#00000022"
local colorCustom = "#ffea0011"

function customItemRow:create()
  local itemList = customItemWindow:getChildById("itemList")
	self.lootSearchLabel = g_ui.createWidget("CustomItemButton", itemList)
	return self
end

function customItemRow:set(lootSearchLabel)
	self.lootSearchLabel = lootSearchLabel
end

function customItemRow:getItemName()
	return self.lootSearchLabel:getChildById("itemName"):getText()
end

function customItemRow:getItemId()
	return getNumberValue(self.lootSearchLabel:getChildById("itemId"):getText())
end

function customItemRow:addName(itemName, color)
	local itemNameWidget = self.lootSearchLabel:getChildById("itemName")
	itemNameWidget:setText(itemName)
	if color ~= nil then
		itemNameWidget:setColor(color)
	end
end

function customItemRow:addPriceBuy(price)
	local priceBuyWidget = self.lootSearchLabel:getChildById("priceBuyBar")
	priceBuyWidget:setText(price)
end

function customItemRow:updatePriceBuy(price)
	local priceBuyWidget = self.lootSearchLabel:getChildById("priceBuyBar")
	local customBuyCost = getNumberValue(priceBuyWidget:getText())
	priceBuyWidget:setText(price and customBuyCost)
	return price and customBuyCost
end

function customItemRow:hidePriceBuy()
	local priceBuyWidget = self.lootSearchLabel:getChildById("priceBuyBar")
	local priceBuyWidgetInfo = self.lootSearchLabel:getChildById("priceBuyBarInfo")
	priceBuyWidget:hide()
	priceBuyWidgetInfo:hide()
end

function customItemRow:addPriceSell(price)
	local priceSellWidget = self.lootSearchLabel:getChildById("priceSellBar")
	priceSellWidget:setText(price)
end

function customItemRow:updatePriceSell(price)
	local priceSellWidget = self.lootSearchLabel:getChildById("priceSellBar")
	local customSellCost = getNumberValue(priceSellWidget:getText())
	priceSellWidget:setText(price and customSellCost)
	return price and customSellCost
end

function	customItemRow:hidePriceSell()
	local priceSellWidget = self.lootSearchLabel:getChildById("priceSellBar")
	local priceSellWidgetInfo = self.lootSearchLabel:getChildById("priceSellBarInfo")
	priceSellWidget:hide()
	priceSellWidgetInfo:hide()
end

function customItemRow:addItemIdText(itemId)
  local itemIdWidget = self.lootSearchLabel:getChildById("itemId")
	itemIdWidget:setText(itemId)
end

function customItemRow:addImage(itemName, clientId, subTypeId)
  local itemImageWidget = self.lootSearchLabel:getChildById("itemImage")
  itemImageWidget:setTooltip(itemName)
	itemImageWidget:setItemId(clientId)
	itemImageWidget:setShowCount(false)

	if subTypeId ~= nil then
		itemImageWidget:setItemSubType(subTypeId)
	else
		itemImageWidget:setItemSubType(0)
	end
end

function customItemRow:hideImage()
	local itemImageWidget = self.lootSearchLabel:getChildById("itemImage")
	itemImageWidget:hide()
end

function customItemRow:addItem(itemData)
  local row = customItemRow:create()

	if itemData.customBuy <= 0 then
		itemData.customBuy = itemData.priceBuy
	end

	if itemData.customSell <= 0 then
		itemData.customSell = itemData.priceSell
	end

  row:addImage(itemData.name, itemData.clientId, itemData.subTypeId)
  row:addName(itemData.name)
  row:addPriceBuy(itemData.customBuy)
  row:addPriceSell(itemData.customSell)
  row:addItemIdText(itemData.itemId)
	row:addBackground(itemData.itemId, itemData.subTypeId, itemData.name)
end

function customItemRow:addBackground(itemId, subTypeId, itemName)
	local hasCustomValues = false
	local itemData = playerItemDatabase:get(itemId, subTypeId)
	
	if itemData ~= nil then
		if itemData.name == itemName then
			hasCustomValues = true
		end

		if itemData.subTypes ~= nil then
			for subTypeId, subTypeData in pairs(itemData.subTypes) do
				if subTypeData.name == itemName then
						hasCustomValues = true	
					break
				end
			end
		end
	end

  self.lootSearchLabel:setBackgroundColor(hasCustomValues and colorCustom or colorDefault)
end

function customItemRow:addEmptyItem()
	local row = customItemRow:create()
	
	row:addName("No items found", colorNoItemFound)

	row:hideImage()
	row:hidePriceSell()
	row:hidePriceBuy()
end
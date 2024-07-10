itemWidget = {
  data = {
	  supply = {},
	  loot = {}
  }
}

function itemWidget:new(parentWidget, category, amount, itemId, itemSubType)
  local info = itemDatabase:get(itemId, itemSubType)

  local name = info.name
  local price = itemDatabase:getPrice(category, itemId, itemSubType)

  local itemWidget = g_ui.createWidget("ItemEntry")
	self:reset(itemWidget, category, itemId, itemSubType)

	parentWidget:setHeight(parentWidget:getHeight() + 42)
	parentWidget:insertChild(nil, itemWidget)

	self:addImage(itemWidget, name, itemId, itemSubType, amount)
	self:addAmount(itemWidget, 999999)
  self:addCost(itemWidget, 999999999999)
  self:addName(itemWidget, name)
	self:addPrice(itemWidget, price)

	return itemWidget
end

function itemWidget:clear()
	self.data.supply = {}
	self.data.loot = {}
end


function itemWidget:addPrice(itemWidget, price)
	local itemPrice = itemWidget:getChildById("itemPrice")
	itemPrice:setText(formatNumber(price) .. " gp")
end

function itemWidget:addImage(itemWidget, name, itemId, itemSubType, amount)
	local itemImage = itemWidget:getChildById("itemImage")

  if amount > 100 then 
    amount = 100
  end

  local clientId = itemDatabase:getClientId(itemId, itemSubType)

  itemImage:setTooltip(name)
  itemImage:setItemId(clientId)
  
  if itemSubType == -1 then
    itemImage:setItemCount(amount)
  else
    itemImage:setItemSubType(self:subTypeToColor(itemSubType))
  end
  
  itemImage:setShowCount(false)
end

function itemWidget:subTypeToColor(itemSubType)
  if itemSubType == 10 then -- manafluid
    return 7 -- purple
  elseif itemSubType == 11 then -- lifefluid
    return 2 -- red
  elseif itemSubType == 12 then -- lemonade
    return 5 -- yellow
  elseif itemSubType == 1 then -- water
    return 1 -- blue
  elseif itemSubType == 2 then -- wine
    return 7 -- purple
  elseif itemSubType == 3 then -- beer
    return 3 -- brown
  elseif itemSubType == 4 then -- mud
    return 3 -- brown
  elseif itemSubType == 5 then -- blood
    return 2 -- red
  elseif itemSubType == 6 then -- slime
    return 4 -- green
  elseif itemSubType == 7 then -- oil
    return 3 -- brown
  elseif itemSubType == 8 then -- urine
    return 5 -- yellow
  elseif itemSubType == 9 then -- milk
    return 6 -- white
  end
  return 0
end

function itemWidget:addCost(itemWidget, cost)
  local itemCost = itemWidget:getChildById("itemCost")
	itemCost:setText(formatNumber(cost) .. " gp")
end

function itemWidget:addName(itemWidget, name)
  local itemName = itemWidget:getChildById("itemName")
	itemName:setText(formatName(name, 13))
end

function itemWidget:addAmount(itemWidget, amount)
  local itemAmount = itemWidget:getChildById("itemAmount")
	itemAmount:setText(formatNumber(amount) .. "x")
end

function itemWidget:hasData(category, itemId, itemSubType)
  if self.data[category][itemId] ~= nil then
    return self.data[category][itemId][itemSubType] ~= nil
  end
  return false
end

function itemWidget:get(category, itemId, itemSubType)
  return self.data[category][itemId][itemSubType]
end

function itemWidget:set(category, amount, itemId, itemSubType, cost, itemWidget)
  local info = itemDatabase:get(itemId, itemSubType)

  local name = info.name

  itemWidget:setTooltip(name)

  self:addImage(itemWidget, name, itemId, itemSubType, amount)
  self:addAmount(itemWidget, amount)
  self:addCost(itemWidget, cost)

  self.data[category][itemId][itemSubType] = {
    cost = cost,
    amount = amount,
    widget = itemWidget
  }
end

function itemWidget:reset(itemWidget, category, itemId, itemSubType)
  self.data[category][itemId] = {}
  self.data[category][itemId][itemSubType] = {
    cost = 0,
    amount = 0,
    widget = itemWidget
  }

end

function itemWidget:increment(category, itemId, itemSubType, amount)
  local price = itemDatabase:getPrice(category, itemId, itemSubType)

	local lootData = itemWidget:get(category, itemId, itemSubType)
	local _amount = lootData.amount + amount
	local _cost = lootData.cost + price * amount
	local itemWidget = lootData.widget

  self:set(category, _amount, itemId, itemSubType, _cost, itemWidget)
end
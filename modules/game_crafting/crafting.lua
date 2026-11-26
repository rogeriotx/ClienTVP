local CODE = 91

local window = nil
local categories = nil
local craftPanel = nil
local itemsList = nil

local selectedCategory = nil
local selectedCraftId = nil
local Crafts = {herbalist = {}, woodcutting = {}, mining = {}, generalcrafting = {}, forcearcher = {}, weaponsmith = {}, jewelsmith = {}}
local money = 0
local skipRefresh = false


function init()
  connect(g_game, {onGameStart = create, onGameEnd = destroy})
  ProtocolGame.registerExtendedOpcode(CODE, onExtendedOpcode)
  if g_game.isOnline() then create() end
end

function terminate()
  disconnect(g_game, {onGameStart = create, onGameEnd = destroy})
  ProtocolGame.unregisterExtendedOpcode(CODE, onExtendedOpcode)
  destroy()
end

function create()
  if window then return end
  window = g_ui.displayUI("crafting")
  window:hide()
  categories = window:getChildById("categories")
  craftPanel = window:getChildById("craftPanel")
  itemsList = window:getChildById("itemsList")
  local pg = g_game.getProtocolGame()
  if pg then pg:sendExtendedOpcode(CODE, json.encode({action = "fetch"})) end
end

function destroy()
  if not window then return end
  local pg = g_game.getProtocolGame()
  if pg then pg:sendExtendedOpcode(CODE, json.encode({action = "hide"})) end
  categories = nil; craftPanel = nil; itemsList = nil
  selectedCategory = nil; selectedCraftId = nil
  Crafts = {herbalist = {}, woodcutting = {}, mining = {}, generalcrafting = {}, forcearcher = {}, weaponsmith = {}, jewelsmith = {}}
  window:destroy(); window = nil
end

function onExtendedOpcode(protocol, code, buffer)
  local status, json_data = pcall(function() return json.decode(buffer) end)
  if not status then g_logger.error("[Crafting] JSON error") return false end
  local action = json_data.action
  local data = json_data.data
  if action == "fetch" then
    if not Crafts[data.category] then Crafts[data.category] = {} end
    for i = 1, #data.crafts do table.insert(Crafts[data.category], data.crafts[i]) end
    if data.category == "herbalist" then selectCategory("herbalist"); selectItem(1) end
  elseif action == "materials" then
    for i = 1, #data.materials do
      local material = data.materials[i]
      for x = 1, #material do
        local craftEntry = Crafts[data.category] and Crafts[data.category][data.from + i - 1]
        if craftEntry and craftEntry.materials then
            local mats = craftEntry.materials[x]
            if mats then
                mats.player = material[x]
            end
        end
      end
    end
    if data.from == 1 and window:isVisible() and selectedCategory == data.category then
      skipRefresh = true
      selectItem(selectedCraftId)
      skipRefresh = false
    end
  elseif action == "money" then
    money = data
    window:recursiveGetChildById("playerMoney"):setText(comma_value(money))
  elseif action == "show" then
    selectItem(selectedCraftId); show()
  elseif action == "crafted" then
    onItemCrafted()
  end
end

function onItemCrafted()
  if not (selectedCategory and selectedCraftId) then return end
  if not Crafts[selectedCategory] then return end
  local craft = Crafts[selectedCategory][selectedCraftId]
  if not craft then return end
  for i = 1, #craft.materials do
    local w = craftPanel:getChildById("craftLine" .. i)
    w:setImageSource("/images/crafting/craft_line" .. i .. "on")
    scheduleEvent(function() w:setImageSource("/images/crafting/craft_line" .. (i == 2 and 5 or i)) end, 850)
  end
  local btn = window:recursiveGetChildById("craftButton")
  btn:disable()
  scheduleEvent(function() btn:enable() end, 860)
  local pg = g_game.getProtocolGame()
  if pg then pg:sendExtendedOpcode(CODE, json.encode({action = "refreshMaterials"})) end
end

function onSearch()
  scheduleEvent(function()
    local text = window:recursiveGetChildById("searchInput"):getText():lower()
    for i = itemsList:getChildCount(), 1, -1 do
      local child = itemsList:getChildByIndex(i)
      local name = child:getChildById("name"):getText():lower()
      if text:len() >= 1 then
        if name:find(text) then child:show(); child:focus(); selectItem(i) else child:hide() end
      else child:show(); child:focus(); selectItem(i) end
    end
  end, 25)
end

local function refreshCraftItemVisuals(widget, data)
  if not widget then return end
  local rarity = tonumber(data and (data.rarity or data.rarityId or data.rarityLevel) or 0) or 0
  local tier = tonumber(data and (data.tier or data.tierLevel) or 0) or 0
  g_game.updateRarityFrames(widget, rarity)
  g_game.updateTierIcon(widget, tier)
end

local function getMaterialCountText(material)
  local c = material.player or 0
  local NL = "\n"
  local t = c .. NL .. material.count
  return t
end

local function getMaterialCountColor(material)
  local c = material.player or 0
  if c >= material.count then
    return "#FFFFFF"
  end
  return "#FF0000"
end

function selectCategory(category)
  if selectedCategory then
    local old = categories:getChildById(selectedCategory .. "Cat")
    if old then old:setOn(false) end
  end
  local new = categories:getChildById(category .. "Cat")
  if not new then return end
  new:setOn(true)
  selectedCategory = category
  itemsList:destroyChildren()
  selectedCraftId = nil
  for i = 1, 6 do
    craftPanel:getChildById("material" .. i):setItem(nil)
    craftPanel:getChildById("count" .. i):setText("")
  end
  craftPanel:getChildById("craftOutcome"):setItem(nil)
  window:recursiveGetChildById("totalCost"):setText("")
  if Crafts[selectedCategory] then
  for i = 1, #Crafts[selectedCategory] do
    local craft = Crafts[selectedCategory][i]
    local w = g_ui.createWidget("ItemListItem")
    w:setId(i)
    local iw = w:getChildById("item")
    iw:setItemId(craft.clientId)
    refreshCraftItemVisuals(iw, craft)
    w:getChildById("name"):setText(craft.name)
    w:getChildById("level"):setText("Required Level " .. craft.level)
    itemsList:addChild(w)
    if i == 1 then w:focus(); selectItem(1) end
  end
  end
end

function selectItem(id)
  local craftId = tonumber(id)
  selectedCraftId = craftId
  if not Crafts[selectedCategory] then return end
  local craft = Crafts[selectedCategory][craftId]
  if not craft then return end
  if not skipRefresh then
    local pg = g_game.getProtocolGame()
    if pg then pg:sendExtendedOpcode(CODE, json.encode({action = "refreshMaterials"})) end
  end
  for i = 1, 6 do
    craftPanel:getChildById("material" .. i):setItem(nil)
    craftPanel:getChildById("count" .. i):setText("")
   g_game.updateRarityFrames(craftPanel:getChildById("material" .. i), 0)
  end
  for i = 1, #craft.materials do
    local material = craft.materials[i]
    local mw = craftPanel:getChildById("material" .. i)
    mw:setItemId(material.id)
    refreshCraftItemVisuals(mw, material)
    g_game.updateRarityFrames(mw, material.requiredRarity or 0)
    local ct = craftPanel:getChildById("count" .. i)
    ct:setText(getMaterialCountText(material))
    ct:setColor(getMaterialCountColor(material))
  end
  local oc = craftPanel:getChildById("craftOutcome")
  oc:setItemId(craft.clientId)
  oc:setItemCount(craft.count)
  refreshCraftItemVisuals(oc, craft)
  window:recursiveGetChildById("totalCost"):setText(comma_value(craft.cost))
end

function craftItem()
  if not (selectedCategory and selectedCraftId) then return end
  local pg = g_game.getProtocolGame()
  if pg then
    pg:sendExtendedOpcode(CODE, json.encode({action = "craft", data = {category = selectedCategory, craftId = selectedCraftId}}))
  end
end

function toggle()
  if not window then create() end
  if not window then return end
  if window:isVisible() then hide() else show() end
end

function show()
  if not window then return end
  window:show(); window:raise(); window:focus()
  local pg = g_game.getProtocolGame()
  if pg then pg:sendExtendedOpcode(CODE, json.encode({action = "refreshMaterials"})) end
end

function hide()
  if not window then return end
  local pg = g_game.getProtocolGame()
  if pg then pg:sendExtendedOpcode(CODE, json.encode({action = "hide"})) end
  window:hide()
end

function comma_value(amount)
  local formatted = amount
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1.%2")
    if k == 0 then break end
  end
  return formatted
end

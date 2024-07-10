local itemRarities = {
  ITEM_COMMON = 1,
	ITEM_UNCOMMON = 2,
	ITEM_RARE = 3,
	ITEM_EPIC = 4,
	ITEM_LEGENDARY = 5,
}

local itemRarityImages = {
  MINIMAL = {
    common =    "/images/rarity/item_common",
    uncommon =  "/images/rarity/minimal/item_uncommon",
    rare =      "/images/rarity/minimal/item_rare",
    epic =      "/images/rarity/minimal/item_epic",
    legendary = "/images/rarity/minimal/item_legendary",
  },
  NORMAL = {
    common =    "/images/rarity/item_common",
    uncommon =  "/images/rarity/normal/item_uncommon",
    rare =      "/images/rarity/normal/item_rare",
    epic =      "/images/rarity/normal/item_epic",
    legendary = "/images/rarity/normal/item_legendary",
  },
  FULL = {
    common =    "/images/rarity/item_common",
    uncommon =  "/images/rarity/full/item_uncommon",
    rare =      "/images/rarity/full/item_rare",
    epic =      "/images/rarity/full/item_epic",
    legendary = "/images/rarity/full/item_legendary",
  },
}

local ItemRarityCustomAttribute = 29305
local ItemDeafultImage = "/images/rarity/item_common"

local uiitems_to_to_rarity = {}

function reload_item_rarity()
  for id, uiitem in pairs(uiitems_to_to_rarity) do
    local item = uiitem:getItem()
    if item then
      uiitem:updateItemRarity()
    end
  end
end

local function getRarityImagesFromConfig()
  local option = modules.client_options.getOption("raritySelect")
  if option == 1 then
    return itemRarityImages.MINIMAL
  elseif option == 2 then
    return itemRarityImages.NORMAL
  elseif option == 3 then
    return itemRarityImages.FULL
  end
  return itemRarityImages.FULL
end

local function getRarityImage(rarityId)
  local image = nil
  local rarityImagesConfig = getRarityImagesFromConfig()

  if rarityId == itemRarities.ITEM_COMMON then
    image = rarityImagesConfig.common
  elseif rarityId == itemRarities.ITEM_UNCOMMON then
    image = rarityImagesConfig.uncommon
  elseif rarityId == itemRarities.ITEM_RARE then
    image = rarityImagesConfig.rare
  elseif rarityId == itemRarities.ITEM_EPIC then
    image = rarityImagesConfig.epic
  elseif rarityId == itemRarities.ITEM_LEGENDARY then
    image = rarityImagesConfig.legendary
  end

  return image
end

function getItemRarityImage(item)
  if item then
    local rarity = item:getCustomAttribute(ItemRarityCustomAttribute)
    if rarity ~= nil and rarity ~= 0 then
      local rarityImage = getRarityImage(rarity)
      if rarityImage ~= nil then
        return rarityImage
      else
        return ItemDeafultImage
      end
    end
  end

  return ItemDeafultImage
end

local contador = 0

function UIItem:updateItemRarity()
  local imageSource = getItemRarityImage(self:getItem())
  self:setImageSource(imageSource)
  if not self.contador then
    contador = contador + 1
    self.contador = contador
    uiitems_to_to_rarity[contador] = self
  end
end

function UIItem:onDragEnter(mousePos)
  if self:isVirtual() then return false end

  local item = self:getItem()
  if not item then return false end

  self:setBorderWidth(1)
  self.currentDragThing = item
  g_mouse.pushCursor('target')
  return true
end

function UIItem:isItem()
  return false
end

function UIItem:onDragLeave(droppedWidget, mousePos)
  if self:isVirtual() then return false end
  self.currentDragThing = nil
  g_mouse.popCursor('target')
  self:setBorderWidth(0)
  self.hoveredWho = nil
  return true
end

function UIItem:onDrop(widget, mousePos, forced)
  if not self:canAcceptDrop(widget, mousePos) and not forced then return false end

  local item = widget.currentDragThing
  if not item or not item:isItem() then return false end
  
  if self.selectable then
    if item:isPickupable() then
      self:setItem(Item.create(item:getId(), item:getCountOrSubType()))
      return true
    end
    return false
  end

  local toPos = self.position

  local itemPos = item:getPosition()
  if itemPos.x == toPos.x and itemPos.y == toPos.y and itemPos.z == toPos.z then return false end

  if item:getCount() > 1 then
    modules.game_interface.moveStackableItem(item, toPos)
  else
    g_game.move(item, toPos, 1)
  end

  self:setBorderWidth(0)
  return true
end

function UIItem:onDestroy()
  if self == g_ui.getDraggingWidget() and self.hoveredWho then
    self.hoveredWho:setBorderWidth(0)
  end

  if self.hoveredWho then
    self.hoveredWho = nil
  end
end

function UIItem:onHoverChange(hovered)
  UIWidget.onHoverChange(self, hovered)
    
  if self:isVirtual() or not self:isDraggable() then return end

  local draggingWidget = g_ui.getDraggingWidget()
  if draggingWidget and self ~= draggingWidget then
    local gotMap = draggingWidget:getClassName() == 'UIGameMap'
    local gotItem = draggingWidget:getClassName() == 'UIItem' and not draggingWidget:isVirtual()
    if hovered and (gotItem or gotMap) then
      self:setBorderWidth(1)
      draggingWidget.hoveredWho = self
    else
      self:setBorderWidth(0)
      draggingWidget.hoveredWho = nil
    end
  end
end

function UIItem:onMouseRelease(mousePosition, mouseButton)
  if self.cancelNextRelease then
    self.cancelNextRelease = false
    return true
  end

  if self:isVirtual() then return false end

  local item = self:getItem()
  if not item or not self:containsPoint(mousePosition) then return false end

  if modules.client_options.getOption('classicControl') and not g_app.isMobile() and
     ((g_mouse.isPressed(MouseLeftButton) and mouseButton == MouseRightButton) or
      (g_mouse.isPressed(MouseRightButton) and mouseButton == MouseLeftButton)) then
    g_game.look(item)
    self.cancelNextRelease = true
    return true
  elseif modules.game_interface.processMouseAction(mousePosition, mouseButton, nil, item, item, nil, nil, nil, self) then
    return true
  end
  return false
end

function UIItem:canAcceptDrop(widget, mousePos)
  if not self.selectable and (self:isVirtual() or not self:isDraggable()) then return false end
  if not widget or not widget.currentDragThing then return false end

  local children = rootWidget:recursiveGetChildrenByPos(mousePos)
  for i=1,#children do
    local child = children[i]
    if child == self then
      return true
    elseif not child:isPhantom() then
      return false
    end
  end

  error('Widget ' .. self:getId() .. ' not in drop list.')
  return false
end

function UIItem:onClick(mousePos)
  if not self:isVirtual() then
    local keyboardModifiers = g_keyboard.getModifiers()
    if keyboardModifiers == KeyboardCtrlAltModifier then
      modules.game_itemtooltip.requestLinked(self)
    end
  end
  
  if not self.selectable or not self.editable then
    return
  end

  if modules.game_itemselector then
    modules.game_itemselector.show(self)
  end
end

function UIItem:onItemChange()
  local tooltip = nil
  local item = self:getItem()

  if item then
    if item:getTooltip():len() > 0 then
      tooltip = self:getItem():getTooltip()
    end
    self:updateItemRarity()
  end
  self:setTooltip(tooltip)
end

function UIItem:setItemRarity(rarity)
  local item = self:getItem()
  if item ~= nil then
    item:setCustomAttribute(ItemRarityCustomAttribute, rarity)
  end
end
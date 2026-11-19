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

-- pbOT server (ItemRarity_t): 1 common, 2 rare, 3 epic, 4 legendary, 5 brutal -> imagens do TVP
local serverRarityToTvp = {
  [1] = itemRarities.ITEM_COMMON,
  [2] = itemRarities.ITEM_RARE,
  [3] = itemRarities.ITEM_EPIC,
  [4] = itemRarities.ITEM_LEGENDARY,
  [5] = itemRarities.ITEM_LEGENDARY, -- brutal: sem moldura propria no TVP
}

function getItemRarityImage(item)
  if item then
    if item.getRarityId and item:getRarityId() > 0 then
      return ItemDeafultImage -- pbOT: moldura desenhada pelo overlay 'rarityId' (rarity_frames do old, com brutal)
    end
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

-- ===== pbOT: tier (t1..t10) e loot category sobre o item =====
local lootCategoryIcons = { [1] = 15, [2] = 16, [3] = 5, [4] = 27, [5] = 11, [6] = 7, [7] = 23, [8] = 59, [9] = 35 }

local function getLootIconId(flags)
  local iconId = 0
  for bit, icon in pairs(lootCategoryIcons) do
    if flags % (2 ^ (bit + 1)) >= 2 ^ bit then
      if iconId ~= 0 then return 52 end -- varias categorias
      iconId = icon
    end
  end
  return iconId
end

local function getOverlay(self, id, setup)
  local w = self:getChildById(id)
  if not w then
    w = g_ui.createWidget('UIWidget', self)
    w:setId(id)
    w:setPhantom(true)
    w:setFocusable(false)
    setup(w)
  end
  return w
end

function UIItem:updateItemOverlays()
  local item = self:getItem()

  -- pbOT: molduras do old_pbOT_Client (1 common, 2 rare, 3 epic, 4 legendary, 5 brutal)
  local rarity = item and item.getRarityId and item:getRarityId() or 0
  local rarityWidget = self:getChildById('rarityId')
  if rarity > 0 and rarity <= 5 then
    rarityWidget = getOverlay(self, 'rarityId', function(w)
      w:fill('parent')
      w:setImageSource('/images/ui/rarity_frames')
    end)
    rarityWidget:setImageClip(((rarity - 1) * 38) .. ' 0 32 32')
    rarityWidget:show()
  elseif rarityWidget then
    rarityWidget:hide()
  end
  local tier = item and item.getTier and item:getTier() or 0
  local tierIcon = self:getChildById('tierIcon')
  if tier > 0 and tier <= 10 then
    tierIcon = getOverlay(self, 'tierIcon', function(w)
      w:setSize({width = 12, height = 12})
      w:addAnchor(AnchorTop, 'parent', AnchorTop)
      w:addAnchor(AnchorRight, 'parent', AnchorRight)
      w:setMarginTop(1)
      w:setMarginRight(1)
    end)
    tierIcon:setImageSource('/images/ui/tier/t' .. tier)
    tierIcon:show()
  elseif tierIcon then
    tierIcon:hide()
  end

  local lootFlags = item and item.getLootCategory and item:getLootCategory() or 0
  local iconId = lootFlags > 0 and getLootIconId(lootFlags) or 0
  local lootIcon = self:getChildById('lootCategoryId')
  if iconId > 0 then
    lootIcon = getOverlay(self, 'lootCategoryId', function(w)
      w:setSize({width = 19, height = 19})
      w:addAnchor(AnchorBottom, 'parent', AnchorBottom)
      w:addAnchor(AnchorLeft, 'parent', AnchorLeft)
      w:setImageSource('/images/game/lootcategory_icons')
    end)
    lootIcon:setImageClip(((iconId - 1) % 8) * 19 .. ' ' .. (math.ceil(iconId / 8) - 1) * 19 .. ' 19 19')
    lootIcon:show()
  elseif lootIcon then
    lootIcon:hide()
  end
end

function UIItem:updateItemRarity()
  local imageSource = getItemRarityImage(self:getItem())
  self:setImageSource(imageSource)
  self:updateItemOverlays()
  if not self.contador then
    contador = contador + 1
    self.contador = contador
    uiitems_to_to_rarity[contador] = self
  end
end

local function tooltipFn()
  return modules.game_tooltip and modules.game_tooltip.m_TooltipFunction
end

function UIItem:onDragEnter(mousePos)
  if self:isVirtual() then return false end

  local item = self:getItem()
  if not item then return false end

  if tooltipFn() then tooltipFn().destroyByItem(item:getId()) end -- pbOT tooltip
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
      -- pbOT: janelas do mods/game_marketplace
      local parentWindow = self:getParent()
      local mp = modules.game_marketplace
      if mp and parentWindow and parentWindow:getId() == "FulfillBuyOfferWindow" then
        local itemPos = item:getPosition()
        if itemPos then
          mp.selectFulfillItem(item:getServerId(), item:getId(), item:getName(), item:isStackable(), itemPos)
          return true
        end
      elseif mp and parentWindow and parentWindow:getId() == "createBuyOfferWindow" then
        mp.selectBuyOfferItem(item:getServerId(), item:getId(), item:getName(), item:isStackable())
        return true
      end
      self:setItem(Item.create(item:getId(), item:getCountOrSubType()))
      return true
    end
    return false
  end

  local toPos = self.position

  local itemPos = item:getPosition()
  if itemPos.x == toPos.x and itemPos.y == toPos.y and itemPos.z == toPos.z then return false end

  if item:getCount() > 1 then
    if tooltipFn() then tooltipFn().destroyByItem(item:getId()) end
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
  -- pbOT: tooltip do servidor (game_tooltip, pacotes 0x9F/0x9E)
  local tt = tooltipFn()
  if tt and not hovered then tt.destroy() end

  UIWidget.onHoverChange(self, hovered)

  local item = self:getItem()
  if tt and item and hovered then
    tt.create(self:getPosition(), item, self:isVirtual() or not self:isDraggable())
  end
    
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
    if keyboardModifiers == KeyboardCtrlAltModifier and modules.game_itemtooltip then
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
  else
    self:updateItemOverlays() -- esconde tier/loot quando o slot esvazia
  end
  self:setTooltip(tooltip)
end

function UIItem:setItemRarity(rarity)
  local item = self:getItem()
  if item ~= nil then
    item:setCustomAttribute(ItemRarityCustomAttribute, rarity)
  end
end
-- @docclass
UIItemTooltip = extends(UIItem, "UIItemTooltip")

function UIItemTooltip.create()
  local tooltip = UIItemTooltip.internalCreate()
  tooltip:setVirtual(false)
  tooltip:setFocusable(false)

  tooltip.iLvl = 0
  tooltip.uLvl = 0
  tooltip.rarityId = 0
  tooltip.requiredLevelAttr = 0
  tooltip.maxAttr = 0
  tooltip.attr = nil
  tooltip.imp = nil
  tooltip.count = 1
  tooltip.weight = 0
  tooltip.itemName = nil
  tooltip.desc = nil
  tooltip.type = nil
  tooltip.first = nil
  tooltip.second = nil
  tooltip.third = nil
  tooltip.fourth = nil
  tooltip.mirrored = false
  tooltip.unidentified = false
  tooltip.hpgain = false
  tooltip.hpticks = false
  tooltip.manaGain = false
  tooltip.manaTicks = false

  return tooltip
end

function UIItemTooltip:resetTooltip()
  self.iLvl = 0
  self.uLvl = 0
  self.rarityId = 0
  self.requiredLevelAttr = 0
  self.maxAttr = 0
  self.attr = nil
  self.imp = nil
  self.count = 1
  self.weight = 0
  self.itemName = nil
  self.desc = nil
  self.type = nil
  self.first = nil
  self.second = nil
  self.third = nil
  self.fourth = nil
  self.mirrored = false
  self.unidentified = false
  self.hpgain = false
  self.hpticks = false
  self.manaGain = false
  self.manaTicks = false
end

function UIItemTooltip:getItemTooltip()
  return {
    id = self:getItemId(),
    iLvl = self.iLvl,
    uLvl = self.uLvl,
    rarity = self.rarityId,
    tierRarity = self.requiredLevelAttr,
    maxAttributes = self.maxAttr,
    attributes = self.attr,
    imp = self.imp,
    count = self.count,
    name = self.name or self.itemName,
    desc = self.desc,
    type = self.type or self.itemType,
    first = self.first or self.armor or self.attack or 0,
    second = self.second or self.defense or 0,
    third = self.third or self.shootRange or self.extraDefense or 0,
    fourth = self.fourth or self.armor or 0,
    weight = self.weight,
    mirrored = self.mirrored,
    unidentified = self.unidentified,
    reqLvl = self.reqLvl,
    hpgain = self.hpgain,
    hpticks = self.hpticks,
    manaGain = self.manaGain,
    manaTicks = self.manaTicks
  }
end

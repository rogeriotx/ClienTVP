-- @docclass
UILinkedItem = extends(UIWidget, "UILinkedItem")

function UILinkedItem.create()
  local link = UILinkedItem.internalCreate()
  link:setPhantom(true)
  link:setFocusable(false)
  link:setTextAlign(AlignLeft)

  link.cached = false
  link.itemId = 0
  link.iLvl = 0
  link.uLvl = 0
  link.reqLvl = 0
  link.rarity = 0
  link.maxAttributes = 0
  link.attributes = nil
  link.imp = nil
  link.count = 1
  link.weight = 0
  link.name = nil
  link.itemName = nil
  link.desc = nil
  link.type = nil
  link.first = nil
  link.second = nil
  link.third = nil
  link.subType = 1
  link.attackSpeed = 0
  link.charges = 1
  link.duration = 0
  link.stackable = false
  link.mirrored = nil
  link.unidentified = nil

  return link
end

function UILinkedItem:isItem()
  return false
end

function UILinkedItem:getLinkedTooltip()
  return {
    id = self.itemId,
    iLvl = self.iLvl,
    uLvl = self.uLvl,
    reqLvl = self.reqLvl,
    rarity = self.rarity or self.rarityId,
    tierRarity = self.tierRarity or self.requiredLevelAttr,
    maxAttributes = self.maxAttributes,
    attributes = self.attributes,
    imp = self.imp,
    count = self.count,
    name = self.name,
    desc = self.desc,
    type = self.type or self.itemType,
    first = self.first or self.armor or self.attack or 0,
    second = self.second or self.hitChance or self.defense or 0,
    third = self.third or self.shootRange or self.extraDefense or 0,
    weight = self.weight,
    stackable = self.stackable,
    mirrored = self.mirrored,
    unidentified = self.unidentified,
    subType = self.subType,
    attackSpeed = self.attackSpeed,
    charges = self.charges,
    duration = self.duration
  }
end


-- @docclass
UICreatureButton = extends(UIWidget, "UICreatureButton")

local CreatureButtonColors = {
  onIdle = {notHovered = '#AFAFAF', hovered = '#F7F7F7' },
  onTargeted = {notHovered = '#E04040', hovered = '#F8A4A4' },
  onFollowed = {notHovered = '#40E040', hovered = '#B4F8B4' }
}

local LifeBarColors = {} -- Must be sorted by percentAbove
table.insert(LifeBarColors, {percentAbove = 94, color = '#00b700' } )
table.insert(LifeBarColors, {percentAbove = 59, color = '#60c060' } )
table.insert(LifeBarColors, {percentAbove = 29, color = '#c0c000' } )
table.insert(LifeBarColors, {percentAbove = 9, color = '#c03030' } )
table.insert(LifeBarColors, {percentAbove = 3, color = '#b30000' } )
table.insert(LifeBarColors, {percentAbove = -1, color = '#590000' } )

function UICreatureButton.create()
  local button = UICreatureButton.internalCreate()
  button:setFocusable(false)
  button.creature = nil
  button.isHovered = false
  button.isBattle = false
  return button
end

function UICreatureButton:setCreature(creature)
    self.creature = creature
end

function UICreatureButton:getCreature()
  return self.creature
end

function UICreatureButton:getCreatureId()
    return self.creature:getId()
end

function UICreatureButton:setup(id)
  self.lifeBarWidget = self:getChildById('lifeBar')
  self.creatureWidget = self:getChildById('creature')
  self.labelWidget = self:getChildById('label')
  self.skullWidget = self:getChildById('skull')
  self.starWidget = self:getChildById('stars')
  self.shieldWidget = self:getChildById('shield')
  self.emblemWidget = self:getChildById('emblem')
end

function UICreatureButton:update()
  local color = CreatureButtonColors.onIdle
  local show = false
  if self.creature == g_game.getAttackingCreature() then
    color = CreatureButtonColors.onTargeted
  elseif self.creature == g_game.getFollowingCreature() then
    color = CreatureButtonColors.onFollowed
  end
  color = self.isHovered and color.hovered or color.notHovered

  if self.color == color then
    return
  end
  self.color = color

  if color ~= CreatureButtonColors.onIdle.notHovered then
    self.creatureWidget:setBorderWidth(1)
    self.creatureWidget:setBorderColor(color)
    self.labelWidget:setColor(color)
  else
    self.creatureWidget:setBorderWidth(0)
    self.labelWidget:setColor(color)
  end
end

function UICreatureButton:creatureSetup(creature)
	if self.creature ~= creature then
		self.creature = creature
		self.creatureWidget:setCreature(creature)	
    if self.creatureName ~= creature:getName() then
      self.creatureName = creature:getName()
      self.labelWidget:setText(creature:getName())
    end
	end

	self:updateLifeBarPercent()
	self:updateSkull()
	self:updateShield()
	self:updateStars()
	self:updateEmblem()
  self:update()
end

function UICreatureButton:updateSkull()
  if not self.creature then
    return
  end
  local skullId = self.creature:getSkull()

  self.skullWidget:setVisible(self.creature:isShowingSkullTexture())

  if skullId == self.skullId then
    return
  end
  self.skullId = skullId

  if skullId ~= SkullNone then
    self.skullWidget:setWidth(self.skullWidget:getHeight())
    local imagePath = getSkullImagePath(skullId)

    if self.isBattle then
      imagePath = getSkullImagePathWithoutBorder(skullId)
    end

    self.skullWidget:setImageSource(imagePath)
    self.skullWidget:setMarginLeft(5)
    self.skullActive = true
  else
    self.skullWidget:setWidth(0)
    self.skullWidget:setMarginLeft(0)
    self.skullActive = false
  end
  self:checkNameWidget()
end

local function getStarImagePath(starId)
  local path
  if starId == StarOne then
    path = '/images/game/states/star_one'
  elseif starId == StarTwo then
    path = '/images/game/states/star_two'
  elseif starId == StarThree then
    path = '/images/game/states/star_three'
  end
  return path
end

function UICreatureButton:updateStars()
  if not self.creature then
    return
  end
  local starId = self.creature:getStar()
  if starId > 3 then starId = starId - 3 end

  if starId == self.starId then
    return
  end
  self.starId = starId

  if starId == 1 then
    local imagePath = getStarImagePath(starId)
    self.starWidget:setImageSource(imagePath)
    self.starWidget:setMarginLeft(2)
    self.starWidget:setWidth(11)
    self.starWidget:setImageClip("0 0 11 10")
  elseif starId == 2 then
    local imagePath = getStarImagePath(starId)
    self.starWidget:setImageSource(imagePath)
    self.starWidget:setMarginLeft(2)
    self.starWidget:setWidth(21)
    self.starWidget:setImageClip("0 0 21 10")
  elseif starId == 3 then
    local imagePath = getStarImagePath(starId)
    self.starWidget:setImageSource(imagePath)
    self.starWidget:setMarginLeft(2)
    self.starWidget:setWidth(31)
    self.starWidget:setImageClip("0 0 31 10")
  else
    self.starWidget:setWidth(0)
    self.starWidget:setMarginLeft(0)
  end
  self:checkNameWidget()
end

function UICreatureButton:checkNameWidget()
  self.labelWidget:setMarginLeft(5)
end

function UICreatureButton:updateShield()
  if not self.creature then
    return
  end
  local shieldId = self.creature:getShield()

  self.shieldWidget:setVisible(self.creature:isShowingShieldTexture())
  if shieldId == self.shieldId then
    return
  end
  self.shieldId = shieldId

  
  if shieldId ~= ShieldNone and self.isBattle then
    self.shieldWidget:setWidth(self.shieldWidget:getHeight())
    local imagePath = getShieldImagePathAndBlink(shieldId)
    
    local shieldImagesPath = {
      [ShieldWhiteBlue] = "/images/game/states/invited_party_member",
      [ShieldYellow] = "/images/game/states/party_leader",
      [ShieldWhiteYellow] = "/images/game/states/party_request",
      [ShieldBlue] = "/images/game/states/party_member",
      [ShieldBlueSharedExp] = '/images/game/states/shield_blue_shared',
      [ShieldBlueNoSharedExpBlink] = '/images/game/states/shield_blue_not_shared',
      [ShieldYellowNoSharedExpBlink] = '/images/game/states/shield_yellow_not_shared',
      [ShieldYellowSharedExp] = '/images/game/states/shield_yellow_shared',
      [ShieldBlueNoSharedExp] = '/images/game/states/shield_blue_not_shared',
      [ShieldYellowNoSharedExp] = '/images/game/states/shield_yellow_not_shared'
    }

    if shieldImagesPath[shieldId] then
      imagePath = shieldImagesPath[shieldId]
    end

    self.shieldWidget:setImageSource(imagePath)
    self.shieldWidget:setMarginLeft(3)
    self.shieldActive = true
  else
    self.shieldWidget:setWidth(0)
    self.shieldWidget:setMarginLeft(0)
    self.shieldActive = false
  end
  self:checkNameWidget()
end

function UICreatureButton:updateEmblem()
  if not self.creature then
    return
  end
  local emblemId = self.creature:getEmblem()
  if self.emblemId == emblemId then
    return
  end
  self.emblemId = emblemId

  if emblemId ~= EmblemNone then
    self.emblemWidget:setWidth(self.emblemWidget:getHeight())
    local imagePath = getEmblemImagePath(emblemId)
    self.emblemWidget:setImageSource(imagePath)
    self.emblemWidget:setMarginLeft(5)
    self.emblemActive = true
  else
    self.emblemActive = false
    self.emblemWidget:setWidth(0)
    self.emblemWidget:setMarginLeft(0)
  end
  self:checkNameWidget()
end

function UICreatureButton:updateLifeBarPercent()
  if not self.creature then
    return
  end
  local percent = self.creature:getHealthPercent()
  if self.percent == percent then
    return
  end

  self.percent = percent
  self.lifeBarWidget:setPercent(percent)

  local color
  for i, v in pairs(LifeBarColors) do
    if percent > v.percentAbove then
      color = v.color
      break
    end
  end

  self.lifeBarWidget:setBackgroundColor(color)
end
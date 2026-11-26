skillsWindow = nil

function init()
  connect(LocalPlayer, {
    onExperienceChange = onExperienceChange,
    onLevelChange = onLevelChange,
    onHealthChange = onHealthChange,
    onManaChange = onManaChange,
    onSoulChange = onSoulChange,
    onStaminaChange = onStaminaChange,
    onFreeCapacityChange = onFreeCapacityChange,
    onTotalCapacityChange = onTotalCapacityChange,
    -- onOfflineTrainingChange = onOfflineTrainingChange,
    onRegenerationChange = onRegenerationChange,
    onSpeedChange = onSpeedChange,
    onBaseSpeedChange = onBaseSpeedChange,
    onMagicLevelChange = onMagicLevelChange,
    onBaseMagicLevelChange = onBaseMagicLevelChange,
    onSkillChange = onSkillChange,
    onBaseSkillChange = onBaseSkillChange
  })
  connect(g_game, {
    onGameStart = refresh,
    onGameEnd = offline
  })

  -- skillsButton = modules.client_topmenu.addRightGameToggleButton('skillsButton', tr('Skills (Ctrl+S)'), '/images/topbuttons/skills', toggle, false, 1, tr('Skills'))
  skillsWindow = g_ui.loadUI('skills', modules.game_interface.getRightPanel())
  skillsWindow.topButton = modules.game_sidemenu.getSkillsButton()

  g_keyboard.bindKeyDown('Ctrl+S', toggleByHotkey)
  skillsWindow.onMouseRelease = function(self, menuPosition, mouseButton)
    local keyboardModifiers = g_keyboard.getModifiers()
    local player = g_game.getLocalPlayer()
    if not modules.client_options.getOption('classicControl') then
      if keyboardModifiers == KeyboardCtrlModifier and mouseButton == MouseRightButton then
        createSkillPercentMenu(menuPosition)
        return true
      end
    else
      if keyboardModifiers == KeyboardNoModifier and mouseButton == MouseRightButton then
        createSkillPercentMenu(menuPosition)
        return true
      end
    end
  end

  refresh()
end

function terminate()
  g_keyboard.unbindKeyDown('Ctrl+S')
  disconnect(LocalPlayer, {
    onExperienceChange = onExperienceChange,
    onLevelChange = onLevelChange,
    onHealthChange = onHealthChange,
    onManaChange = onManaChange,
    onSoulChange = onSoulChange,
    onStaminaChange = onStaminaChange,
    onFreeCapacityChange = onFreeCapacityChange,
    onTotalCapacityChange = onTotalCapacityChange,
    -- onOfflineTrainingChange = onOfflineTrainingChange,
    onRegenerationChange = onRegenerationChange,
    onSpeedChange = onSpeedChange,
    onBaseSpeedChange = onBaseSpeedChange,
    onMagicLevelChange = onMagicLevelChange,
    onBaseMagicLevelChange = onBaseMagicLevelChange,
    onSkillChange = onSkillChange,
    onBaseSkillChange = onBaseSkillChange
  })
  disconnect(g_game, {
    onGameStart = refresh,
    onGameEnd = offline
  })

  skillsWindow:destroy()
end

function expForLevel(level)
  return math.floor((50*level*level*level)/3 - 100*level*level + (850*level)/3 - 200)
end

function expToAdvance(currentLevel, currentExp)
  return expForLevel(currentLevel+1) - currentExp
end

function resetSkillColor(id)
  local skill = skillsWindow:recursiveGetChildById(id)
  local widget = skill:getChildById('value')
  widget:setColor('#bbbbbb')
end

function toggleSkill(id, state)
  local skill = skillsWindow:recursiveGetChildById(id)
  skill:setVisible(state)
end

function setSkillBase(id, value, baseValue)
  if baseValue <= 0 or value < 0 then
    return
  end
  local skill = skillsWindow:recursiveGetChildById(id)
  local widget = skill:getChildById('value')

  if value > baseValue then
    widget:setColor('#00C000') -- green
    skill:setTooltip(baseValue .. ' +' .. (value - baseValue))
  elseif value < baseValue then
    widget:setColor('#C00000') -- red
    skill:setTooltip(baseValue .. ' ' .. (value - baseValue))
  else
    widget:setColor('#bbbbbb') -- default
    skill:removeTooltip()
  end
end

function setSkillValue(id, value)
  local skill = skillsWindow:recursiveGetChildById(id)
  local widget = skill:getChildById('value')
  widget:setText(value)
end

function setSkillColor(id, value)
  local skill = skillsWindow:recursiveGetChildById(id)
  local widget = skill:getChildById('value')
  widget:setColor(value)
end

function setSkillTooltip(id, value)
  local skill = skillsWindow:recursiveGetChildById(id)
  local widget = skill:getChildById('value')
  widget:setTooltip(value)
end

function setSkillPercent(id, percent, tooltip, color)
  local skill = skillsWindow:recursiveGetChildById(id)
  local widget = skill:getChildById('percent')
  if widget then
    widget:setPercent(math.floor(percent))

    if tooltip then
      widget:setTooltip(tooltip)
    end

    if color then
    	widget:setBackgroundColor(color)
    end
  end
end

function checkAlert(id, value, maxValue, threshold, greaterThan)
  if greaterThan == nil then greaterThan = false end
  local alert = false

  -- maxValue can be set to false to check value and threshold
  -- used for regeneration checking
  if type(maxValue) == 'boolean' then
    if maxValue then
      return
    end

    if greaterThan then
      if value > threshold then
        alert = true
      end
    else
      if value < threshold then
        alert = true
      end
    end
  elseif type(maxValue) == 'number' then
    if maxValue < 0 then
      return
    end

    local percent = math.floor((value / maxValue) * 100)
    if greaterThan then
      if percent > threshold then
        alert = true
      end
    else
      if percent < threshold then
        alert = true
      end
    end
  end

  if alert then
    setSkillColor(id, '#C00000') -- red
  else
    resetSkillColor(id)
  end
end

function update()
  -- local offlineTraining = skillsWindow:recursiveGetChildById('offlineTraining')
  -- if not g_game.getFeature(GameOfflineTrainingTime) then
  --   offlineTraining:hide()
  -- else
  --   offlineTraining:show()
  -- end

  local regenerationTime = skillsWindow:recursiveGetChildById('regenerationTime')
  if not g_game.getFeature(GamePlayerRegenerationTime) then
    regenerationTime:hide()
  else
    regenerationTime:show()
  end
end

local function load_skills_content()
  local progressbarWidgets = {}

  for id, widget in pairs(skillsWindow.contentsPanel:getChildren()) do
    if widget.percent and widget.skillNameWidget then
      local widgetName = widget.skillNameWidget:getText()
      local setting = g_settings.getBoolean('SkillProgress-'..widgetName, true)

      widget.enableProgressBar = function()
        widget:setHeight(24)
        g_settings.set('SkillProgress-'..widgetName, true)
        widget.percent:setVisible(true)
      end
      widget.disableProgressBar = function()
        widget:setHeight(14)
        widget.percent:setVisible(false)
        g_settings.set('SkillProgress-'..widgetName, false)
      end
      if setting then
        widget.enableProgressBar()
      else
        widget.disableProgressBar()
      end

      progressbarWidgets[#progressbarWidgets + 1] = {widgetName, widget}
    end
  end
  return progressbarWidgets
end

function createSkillPercentMenu(menuPosition)
  if not g_game.isOnline() then return end

  local progressbarWidgets = load_skills_content()

  local menu = g_ui.createWidget('PopupMenu')
  menu:setId('skillPercentMenu')
  menu:setGameMenu(true)

  for _, data in pairs(progressbarWidgets) do
    local widgetName = data[1]
    local settingName = 'SkillProgress-'..widgetName
    local visible = g_settings.getBoolean(settingName, true)
    if visible then
      menu:addOption(tr('Hide') .. ' ' .. widgetName, function() data[2].disableProgressBar() end)
    else
      menu:addOption(tr('Show') .. ' ' .. widgetName, function() data[2].enableProgressBar() end)
    end
  end

  local sep = menu:addSeparator("#b0b0b0")

  menu:addOption(tr('Hide all Skill Bars'), function()
    for _, data in pairs(progressbarWidgets) do
      data[2].disableProgressBar()
    end
  end)

  menu:addOption(tr('Show all SkillBars'), function()
    for _, data in pairs(progressbarWidgets) do
      data[2].enableProgressBar()
    end
  end)
  menu:display(menuPosition)  
  return menu
end

function refresh()
  skillsWindow:setup()
  local player = g_game.getLocalPlayer()
  if not player then return end

  if expSpeedEvent then expSpeedEvent:cancel() end
  expSpeedEvent = cycleEvent(checkExpSpeed, 30*1000)

  onExperienceChange(player, player:getExperience())
  onLevelChange(player, player:getLevel(), player:getLevelPercent())
  onHealthChange(player, player:getHealth(), player:getMaxHealth())
  onManaChange(player, player:getMana(), player:getMaxMana())
  onSoulChange(player, player:getSoul())
  onFreeCapacityChange(player, player:getFreeCapacity())
  onStaminaChange(player, player:getStamina())
  onMagicLevelChange(player, player:getMagicLevel(), player:getMagicLevelPercent())
  -- onOfflineTrainingChange(player, player:getOfflineTrainingTime())
  onRegenerationChange(player, player:getRegenerationTime())
  onSpeedChange(player, player:getSpeed())

  local hasAdditionalSkills = g_game.getFeature(GameAdditionalSkills)
  for i = Skill.Fist, Skill.ManaLeechAmount do
    onSkillChange(player, i, player:getSkillLevel(i), player:getSkillLevelPercent(i))
    onBaseSkillChange(player, i, player:getSkillBaseLevel(i))

    if i > Skill.Fishing then
      toggleSkill('skillId'..i, hasAdditionalSkills)
    end
  end

  update()

  local contentsPanel = skillsWindow:getChildById('contentsPanel')
  skillsWindow:setContentMinimumHeight(44)
  if hasAdditionalSkills then
    skillsWindow:setContentMaximumHeight(520)
  else
    skillsWindow:setContentMaximumHeight(350)
  end
  skillsWindow:setup()
  load_skills_content()
end

function offline()
  if expSpeedEvent then expSpeedEvent:cancel() expSpeedEvent = nil end
end

function toggleByHotkey()
  if modules.game_console.isChatEnabled() then
    toggle()
  end
end

function toggle()
  load_skills_content()
  if modules.game_sidemenu.getSkillsButton():isOn() then
    skillsWindow:close()
  else
    skillsWindow:open()
  end
end

function checkExpSpeed()
  local player = g_game.getLocalPlayer()
  if not player then return end

  local currentExp = player:getExperience()
  local currentTime = g_clock.seconds()
  if player.lastExps ~= nil then
    player.expSpeed = (currentExp - player.lastExps[1][1])/(currentTime - player.lastExps[1][2])
    onLevelChange(player, player:getLevel(), player:getLevelPercent())
  else
    player.lastExps = {}
  end
  table.insert(player.lastExps, {currentExp, currentTime})
  if #player.lastExps > 30 then
    table.remove(player.lastExps, 1)
  end
end

function onMiniWindowClose()
  modules.game_sidemenu.getSkillsButton():setOn(false)
end

function onSkillButtonClick(button)
end

function onExperienceChange(localPlayer, value)
  local postFix = ""
  if value > 1e15 then
	postFix = "B"
	value = math.floor(value / 1e9)
  elseif value > 1e12 then
	postFix = "M"
	value = math.floor(value / 1e6)
  elseif value > 1e9 then
	postFix = "K"
	value = math.floor(value / 1e3)
  end
  setSkillValue('experience', comma_value(value) .. postFix)
end

function onLevelChange(localPlayer, value, percent)
  setSkillValue('level', value)
  local text = tr('You have %s percent to go', 100 - percent) .. '\n' ..
               comma_value(expToAdvance(localPlayer:getLevel(), localPlayer:getExperience())) .. tr(' of experience left')

  if localPlayer.expSpeed ~= nil then
     local expPerHour = math.floor(localPlayer.expSpeed * 3600)
     if expPerHour > 0 then
        local nextLevelExp = expForLevel(localPlayer:getLevel()+1)
        local hoursLeft = (nextLevelExp - localPlayer:getExperience()) / expPerHour
        local minutesLeft = math.floor((hoursLeft - math.floor(hoursLeft))*60)
        hoursLeft = math.floor(hoursLeft)
        text = text .. '\n' .. comma_value(expPerHour) .. ' of experience per hour'
        text = text .. '\n' .. tr('Next level in %d hours and %d minutes', hoursLeft, minutesLeft)
     end
  end

  setSkillPercent('level', percent, text)
end

function onHealthChange(localPlayer, health, maxHealth)
  setSkillValue('health', health)
  checkAlert('health', health, maxHealth, 30)
end

function onManaChange(localPlayer, mana, maxMana)
  setSkillValue('mana', mana)
  checkAlert('mana', mana, maxMana, 30)
end

function onSoulChange(localPlayer, soul)
  setSkillValue('soul', soul)
end

function onStaminaChange(localPlayer, stamina)
  local stamina_row = skillsWindow:recursiveGetChildById('stamina')
  if not g_game.getFeature(GamePlayerStamina) then
    stamina_row:hide()
    return
  end
  stamina_row:show()

  local hours = math.floor(stamina / 60)
  local minutes = stamina % 60
  if minutes < 10 then
    minutes = '0' .. minutes
  end
  local percent = math.floor(100 * stamina / (42 * 60)) -- max 42 horas

  setSkillValue('stamina', hours .. ':' .. minutes)

  local left = tr('You have %s hours and %s minutes left', hours, minutes)
  if stamina > 2400 then
    setSkillPercent('stamina', percent, left .. '\n' .. tr('If you are premium player, you will gain 50%% more experience'), '#00C000')
  elseif stamina > 840 then
    setSkillPercent('stamina', percent, left, 'orange')
  elseif stamina > 0 then
    setSkillPercent('stamina', percent, left .. '\n' .. tr('You gain only 50%% experience and you may not gain loot from monsters'), '#C00000')
  else
    setSkillPercent('stamina', percent, left .. '\n' .. tr('You may not receive experience and loot from monsters'), 'black')
  end
end

function onFreeCapacityChange(localPlayer, freeCapacity)
  setSkillValue('capacity', freeCapacity * 100)
  checkAlert('capacity', freeCapacity * 100, localPlayer:getTotalCapacity() * 100, 20)
end

function onTotalCapacityChange(localPlayer, totalCapacity)
  checkAlert('capacity', localPlayer:getFreeCapacity(), totalCapacity, 20)
end

-- function onOfflineTrainingChange(localPlayer, offlineTrainingTime)
--   if not g_game.getFeature(GameOfflineTrainingTime) then
--     return
--   end
--   local hours = math.floor(offlineTrainingTime / 60)
--   local minutes = offlineTrainingTime % 60
--   if minutes < 10 then
--     minutes = '0' .. minutes
--   end
--   local percent = 100 * offlineTrainingTime / (12 * 60) -- max is 12 hours

--   setSkillValue('offlineTraining', hours .. ":" .. minutes)
--   setSkillPercent('offlineTraining', percent, tr('You have %s percent', percent))
-- end

function onRegenerationChange(localPlayer, regenerationTime)
  if not g_game.getFeature(GamePlayerRegenerationTime) or regenerationTime < 0 then
    return
  end
  local minutes = math.floor(regenerationTime / 60)
  local seconds = regenerationTime % 60
  if seconds < 10 then
    seconds = '0' .. seconds
  end

  setSkillValue('regenerationTime', minutes .. ":" .. seconds)
  checkAlert('regenerationTime', regenerationTime, false, 300)
end

function onSpeedChange(localPlayer, speed)
  setSkillValue('speed', speed)

  onBaseSpeedChange(localPlayer, localPlayer:getBaseSpeed())
end

function onBaseSpeedChange(localPlayer, baseSpeed)
  setSkillBase('speed', localPlayer:getSpeed(), baseSpeed)
end

function onMagicLevelChange(localPlayer, magiclevel, percent)
  setSkillValue('magiclevel', magiclevel)
  setSkillPercent('magiclevel', percent, tr('You have %s percent to go', 100 - percent))

  onBaseMagicLevelChange(localPlayer, localPlayer:getBaseMagicLevel())
end

function onBaseMagicLevelChange(localPlayer, baseMagicLevel)
  setSkillBase('magiclevel', localPlayer:getMagicLevel(), baseMagicLevel)
end

function onSkillChange(localPlayer, id, level, percent)
  setSkillValue('skillId' .. id, level)
  setSkillPercent('skillId' .. id, percent, tr('You have %s percent to go', 100 - percent))

  onBaseSkillChange(localPlayer, id, localPlayer:getSkillBaseLevel(id))
end

function onBaseSkillChange(localPlayer, id, baseLevel)
  setSkillBase('skillId'..id, localPlayer:getSkillLevel(id), baseLevel)
end

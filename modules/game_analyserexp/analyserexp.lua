local windowExp
local ExpPanel
local lblSession
local lblExpH
local lblExpGained
local lblExpToLvl
local lblTimeToLevel

-- local opcode = 22

local expSpeedEvent, expSessionEvent
local EXPSESSION = 0
local EXPGAINED = 0


function init()	
  connect(g_game, {
    onGameStart = refresh,
    onGameEnd = offline,
  })

  connect(LocalPlayer, {
    onExperienceChange = onExperienceChange,
    onLevelChange = onLevelChange,
  })
  
  -- ProtocolGame.registerExtendedOpcode(opcode, getAnalyser)
  
  windowExp = g_ui.loadUI('analyserexp', modules.game_interface.getRightPanel()) 
  windowExp:disableResize()

  -- buttonExp = modules.client_topmenu.addRightGameToggleButton('expAnalyserButton', tr('Experience Analyzer (Ctrl+X)'), '/images/topbuttons/analyzers', toggle, true, 2, tr('Experience Analyzer'))
  -- buttonExp:setWidth(96)
  -- windowExp.topButton = buttonExp


  ExpPanel        = windowExp:recursiveGetChildById('expPanel')
  lblSession      = ExpPanel:getChildById('lblSession')
  lblExpH         = ExpPanel:getChildById('lblExpH')
  lblExpGained    = ExpPanel:getChildById('lblExpGained')
  lblExpToLvl     = ExpPanel:getChildById('lblExpToLvl')
  lblTimeToLevel  = ExpPanel:getChildById('lblTimeToLevel')

  refresh()
  g_keyboard.bindKeyPress('Ctrl+X', toggle)
  
end

function terminate()

  disconnect(g_game, {
    onGameStart = refresh,
    onGameEnd = offline,
  })
  
  disconnect(LocalPlayer, {
    onExperienceChange = onExperienceChange,
    onLevelChange = onLevelChange,
  })
  
  -- ProtocolGame.unregisterExtendedOpcode(opcode)
  
  offline()
  windowExp:destroy()
  g_keyboard.unbindKeyPress('Ctrl+X')
end

function toggle()
    if windowExp:isVisible() then
        windowExp:close()
    else
        windowExp:open()
    end
end


function refresh()
  windowExp:setup()
  local player = g_game.getLocalPlayer()
  if not player then return end 
  if expSpeedEvent then expSpeedEvent:cancel() end
  expSpeedEvent = cycleEvent(checkExpSpeed, 30*1000)
  
  if expSessionEvent then expSessionEvent:cancel() end
  expSessionEvent = cycleEvent(refreshSession, 1000)

  resetExpPanel()
  onExperienceChange(player, player:getExperience())
end

function offline()
  resetExpPanel()
end

function resetExpPanel(restart)
  if expSpeedEvent then expSpeedEvent:cancel() expSpeedEvent = nil end
  if expSessionEvent then expSessionEvent:cancel() expSessionEvent = nil end
  lblSession:getChildById('value'):setText("00:00:00")
  lblExpGained:getChildById('value'):setText(0)
  lblExpToLvl:getChildById('value'):setText(0)
  lblExpH:getChildById('value'):setText(0)
  lblTimeToLevel:getChildById('value'):setText("00:00:00")
  EXPSESSION = 0
  EXPGAINED = 0
  local player = g_game.getLocalPlayer()
  if player then
    player.analyserLastExps = nil
    player.analyserExpSpeed = nil
  end
end

function refreshSession()
  local player = g_game.getLocalPlayer()
  if not player then return offline() end
  EXPSESSION = EXPSESSION + 1
  local sT = convertSeconds(EXPSESSION)
  lblSession:getChildById('value'):setText((sT.hours < 10 and "0"..sT.hours or sT.hours)..":"..(sT.minutes < 10 and "0"..sT.minutes or sT.minutes)..":"..(sT.seconds < 10 and "0"..sT.seconds or sT.seconds))
end


function checkExpSpeed()
  local player = g_game.getLocalPlayer()
  if not player then return end

  local currentExp = player:getExperience()
  local currentTime = g_clock.seconds()
  if player.analyserLastExps ~= nil then
    player.analyserExpSpeed = (currentExp - player.analyserLastExps[1][1])/(currentTime - player.analyserLastExps[1][2])
    onLevelChange(player, player:getLevel(), player:getLevelPercent())
  else
    player.analyserLastExps = {}
  end
  table.insert(player.analyserLastExps, {currentExp, currentTime})
  if #player.analyserLastExps > 30 then
    table.remove(player.analyserLastExps, 1)
  end
end

function onExperienceChange(localPlayer, value, oldValue)
  if not expSpeedEvent then expSpeedEvent = cycleEvent(checkExpSpeed, 30*1000) end
  if not expSessionEvent then expSessionEvent = cycleEvent(refreshSession, 1000) end
  if (oldValue and oldValue > 0) then
    EXPGAINED = EXPGAINED + (value - oldValue)
  end
  lblExpGained:getChildById('value'):setText(formatNumbers(EXPGAINED))
end

function onLevelChange(localPlayer, value, percent)
  lblExpToLvl:getChildById('value'):setText(formatNumbers(expToAdvance(localPlayer:getLevel(), localPlayer:getExperience())))

  if localPlayer.analyserExpSpeed ~= nil then
    local expPerHour = math.floor(localPlayer.analyserExpSpeed * 3600)
    if expPerHour > 0 then
      local nextLevelExp = expForLevel(localPlayer:getLevel()+1)
      local hoursLeft = (nextLevelExp - localPlayer:getExperience()) / expPerHour
      local minutesLeft = math.floor((hoursLeft - math.floor(hoursLeft))*60)
      hoursLeft = math.floor(hoursLeft)
      lblExpH:getChildById('value'):setText(formatNumbers(expPerHour))
      lblTimeToLevel:getChildById('value'):setText((hoursLeft < 10 and "0"..hoursLeft or hoursLeft)..":"..(minutesLeft < 10 and "0"..minutesLeft or minutesLeft))
    end
  end
end

function expForLevel(level)
  return math.floor((50*level*level*level)/3 - 100*level*level + (850*level)/3 - 200)
end

function expToAdvance(currentLevel, currentExp)
  return expForLevel(currentLevel+1) - currentExp
end

function formatNumbers(number)
  local ret = number
  while true do  
    ret, k = string.gsub(ret, "^(-?%d+)(%d%d%d)", '%1,%2')
    if k == 0 then
      break
    end
  end
  return ret
end

function convertSeconds(seconds)
  local hours = 0
  local minutes = 0
  repeat
    if seconds >= 60 then
	  minutes = minutes + 1; seconds = seconds - 60
	elseif minutes >= 60 then
	  hours = hours + 1; minutes = minutes - 60
	end
  until seconds < 60 and minutes < 60
  return {hours = hours, seconds = seconds, minutes = minutes}
end

-- function getAnalyser(protocol, opcode, buffer)
  -- if not g_game.getLocalPlayer() then return end
  -- print('teste')
  -- modules.game_analyserloot.getAnalyser(protocol, opcode, buffer)
-- end
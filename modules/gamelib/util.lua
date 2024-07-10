function postostring(pos)
  return pos.x .. " " .. pos.y .. " " .. pos.z
end

function dirtostring(dir)
  for k,v in pairs(Directions) do
    if v == dir then
      return k
    end
  end
end

function getDistanceBetween(p1, p2)
    return math.max(math.abs(p1.x - p2.x), math.abs(p1.y - p2.y))
end

function invertDirection(dir) 
  if dir == 0 then
    return 2
  elseif dir == 2 then
    return 0
  elseif dir == 1 then
    return 3
  elseif dir == 3 then
    return 1 
  elseif dir == 4 then
    return 6
  elseif dir == 7 then
    return 5
  elseif dir == 5 then
    return 7
  elseif dir == 6 then
    return 4
  end
  return nil
end

function resetAllWidgetOpacity(widget)
  local topMenu = g_ui.getRootWidget():getChildById('topMenu')

  modules.game_battle.battleWindow:setup()

  if topMenu then
    for i = 1, topMenu.leftButtonsPanel:getChildCount() do
      local widget = topMenu.leftButtonsPanel:getChildByIndex(i)
      widget:setOpacity(1)
    end

    for i = 1, topMenu.leftGameButtonsPanel:getChildCount() do
      local widget = topMenu.leftGameButtonsPanel:getChildByIndex(i)
      widget:setOpacity(1)
    end

    for i = 1, topMenu.rightButtonsPanel:getChildCount() do
      local widget = topMenu.rightButtonsPanel:getChildByIndex(i)
      widget:setOpacity(1)
    end

    for i = 1, topMenu.rightGameButtonsPanel:getChildCount() do
      local widget = topMenu.rightGameButtonsPanel:getChildByIndex(i)
      widget:setOpacity(1)
    end
  end

  widget:unlock()
end
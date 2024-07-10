-- @docclass
UIMiniWindowContainer = extends(UIWidget, "UIMiniWindowContainer")

function UIMiniWindowContainer.create()
  local container = UIMiniWindowContainer.internalCreate()
  container.scheduledWidgets = {}
  container:setFocusable(false)
  container:setPhantom(true)
  return container
end

function UIMiniWindowContainer:closeAll()
    local children = self:getChildren()
    for i=1,#children do
      if not children[i].headlessborder then
        children[i]:close(true, true)
        children[i]:setup()
        children[i].miniLoaded = false
      end
    end
end
-- TODO: connect to window onResize event
-- TODO: try to resize another widget?
-- TODO: try to find another panel?
function UIMiniWindowContainer:fitAll(noRemoveChild)
  if not self:isVisible() then
    return
  end
  if self:getHeight() > 0 then
    g_settings.set(self:getId() .. 'Height', self:getHeight())
  end

  local function getChildrenHeight(panel)
    local sumHeight = 0
    local children = panel:getChildren()
    for i = 1, #children do
      if children[i]:isVisible() then
        sumHeight = sumHeight + children[i]:getHeight()
      end
    end
    return sumHeight
  end

  local function check_headless_windows(panel)
    local sumHeight = 0
    local children = panel:getChildren()

    for _, child in pairs(children) do
      if child.headlessborder then
        child:destroy()
      end
    end
    

    local first_headless, last_headless
    local already_added = 0

    children = panel:getChildren()
    for i = 1, #children do
      if children[i]:isVisible() then
        
        if children[i].headlesswindow then
          if not first_headless then
            first_headless = i
          end
          
          last_headless = i
        elseif first_headless and last_headless then
          -- build borders

          self:insertChild(first_headless + 2 * already_added, g_ui.createWidget('HeadlessMiniWindowTopBorder'))
          self:insertChild(last_headless + 2 + 2 * already_added, g_ui.createWidget('HeadlessMiniWindowBottomBorder'))

          already_added = already_added + 1

          first_headless = nil
          last_headless = nil
        end

      end
    end

    if first_headless and last_headless then
      -- build borders

      self:insertChild(first_headless + 2 * already_added, g_ui.createWidget('HeadlessMiniWindowTopBorder'))
      self:insertChild(last_headless + 2 + 2 * already_added, g_ui.createWidget('HeadlessMiniWindowBottomBorder'))

      already_added = already_added + 1

      first_headless = nil
      last_headless = nil
    end

    return sumHeight
  end

  local function updateContainer(height)
    local rect = self:getRect()

    self:setImageRect({x = 0, y = height, width = rect.width, height = rect.height - height})
    if height > 0 then
      self:setBackgroundRect({x = 0, y = 0, width = rect.width, height = height})
      self:setBackgroundColor("black")
    else
      self:setBackgroundColor("alpha")
    end
    self:setImageSmooth(true)
    self:setImageRepeated(true)
    self:setClipping(true)
    self:setImageFixedRatio(true)
    local parent = self:getParent()
    if parent then
      local id = self:getParent():getId()
      if id == "gameLeftPanels" then
        local maxChildrenHeight = 0
        

        for _, child in pairs(modules.game_interface.getLeftPanels():getChildren()) do
            maxChildrenHeight = math.max(maxChildrenHeight, (child.childrenHeight and child.childrenHeight or 0))
        end

        local resizer = modules.game_interface.getTopLeftPanel():getParent().bottomResizeBorder
        resizer:setMaximum(modules.game_interface.getRootPanel():getHeight() - maxChildrenHeight)
      elseif id == "gameRightPanels" then
        local maxChildrenHeight = 0
        

        for _, child in pairs(modules.game_interface.getRightPanels():getChildren()) do
            maxChildrenHeight = math.max(maxChildrenHeight, (child.childrenHeight and child.childrenHeight or 0))
        end

        local resizer = modules.game_interface.getTopRightPanel():getParent().bottomResizeBorder
        resizer:setMaximum(modules.game_interface.getRootPanel():getHeight() - maxChildrenHeight)
      end
    end
  end

  if not noRemoveChild then
    local children = self:getChildren()
    if #children > 0 then
      noRemoveChild = children[#children]
    else
      updateContainer(0)
      return
    end
  end

  check_headless_windows(self)
  local sumHeight = getChildrenHeight(self)
  local children = self:getChildren()

  local selfHeight = self:getHeight() - (self:getPaddingTop() + self:getPaddingBottom())

  updateContainer(sumHeight)
  self.childrenHeight = sumHeight+10
  if sumHeight <= selfHeight then
    return
  end
  local removeChildren = {}

  -- try to resize noRemoveChild
  local maximumHeight = selfHeight - (sumHeight - noRemoveChild:getHeight())
  if noRemoveChild:isResizeable() and noRemoveChild:getMinimumHeight() <= maximumHeight then
    sumHeight = sumHeight - noRemoveChild:getHeight() + maximumHeight
    addEvent(function() noRemoveChild:setHeight(maximumHeight) end)
  end
  
  local diff = sumHeight - selfHeight
  for i = #children - 1, #children do
    if sumHeight <= selfHeight then
      break
    end

    
    local child = children[i]
    if child:isResizeable() then
      local new_height = math.max(child:getMinimumHeight(), child:getHeight() - diff)
      
      if new_height < child:getHeight() then
        sumHeight = sumHeight - child:getHeight() + new_height
        addEvent(function() child:setHeight(new_height) end)
      end
    end
    -- break
  end

  -- try to remove no-save widget
  for i=#children,1,-1 do
    if not children[i].headlessborder then
      if sumHeight <= selfHeight then
        break
      end

      local child = children[i]
      if child ~= noRemoveChild and not child.save then
        local childHeight = child:getHeight()
        sumHeight = sumHeight - childHeight
        table.insert(removeChildren, child)
      end
    end
  end

  -- try to remove save widget, not forceOpen
  for i=#children,1,-1 do
    if sumHeight <= selfHeight then
      break
    end

    local child = children[i]
    if child ~= noRemoveChild and child:isVisible() and not child.forceOpen then
      local childHeight = child:getHeight()
      sumHeight = sumHeight - childHeight
      table.insert(removeChildren, child)
    end
  end

  -- try to remove save widget
  for i=#children,1,-1 do
    if sumHeight <= selfHeight then
      break
    end

    local child = children[i]
    if child ~= noRemoveChild and child:isVisible() then
      local childHeight = child:getHeight() - 50
      sumHeight = sumHeight - childHeight
      table.insert(removeChildren, child)
    end
  end

  self.childrenHeight = sumHeight+10
  updateContainer(sumHeight)

  -- close widgets
  for i=1,#removeChildren do
    if removeChildren[i].forceOpen then
      removeChildren[i]:minimize(true)
    else
      removeChildren[i]:close()
    end
  end
end

function UIMiniWindowContainer:onDrop(widget, mousePos)
  if widget.UIMiniWindowContainer then
    local oldParent = widget:getParent()
    if oldParent == self then
      return true
    end
    local isMinimap = widget:getId() == "minimapWindow"
    if isMinimap then
      modules.game_minimap.build_minimap_style(self.topPanel and "otcv8" or "retro")
    end

    if oldParent then
      oldParent:removeChild(widget)
    end
    
    if widget.movedWidget then
      local index = self:getChildIndex(widget.movedWidget)
      self:insertChild(index + widget.movedIndex, widget)
    else
      self:addChild(widget)
    end
    
    self:fitAll(widget)
    return true
  end
end

function UIMiniWindowContainer:moveTo(newPanel)
  if not newPanel or newPanel == self then
    return
  end
  local child = self:getChildByIndex(1)
  while child do
    local isMinimap = child:getId() == "minimapWindow"
    newPanel:addChild(child)
    if isMinimap then
      modules.game_minimap.build_minimap_style(newPanel.topPanel and "otcv8" or "retro")
    end
    if not child.headlessborder then
      child:saveParent()
    end
    child = self:getChildByIndex(1)
  end
  newPanel:fitAll()
end

function UIMiniWindowContainer:swapInsert(widget, index)
  local oldParent = widget:getParent()
  local oldIndex = self:getChildIndex(widget)

  if oldParent == self and oldIndex ~= index then
    local oldWidget = self:getChildByIndex(index)
    if oldWidget then
      self:removeChild(oldWidget)
      self:insertChild(oldIndex, oldWidget)
    end
    self:removeChild(widget)
    self:insertChild(index, widget)
  end
  self:fitAll()
end

function UIMiniWindowContainer:scheduleInsert(widget, index)
  if index - 1 > self:getChildCount() then
    if self.scheduledWidgets[index] then
      pdebug('replacing scheduled widget id ' .. widget:getId())
    end
    self.scheduledWidgets[index] = widget
  else
    local oldParent = widget:getParent()
    if oldParent ~= self then
      if oldParent then
        oldParent:removeChild(widget)
      end
      self:insertChild(index, widget)

      while true do
        local placed = false
        for nIndex,nWidget in pairs(self.scheduledWidgets) do
          if nIndex - 1 <= self:getChildCount() then
            local oldParent = nWidget:getParent()
            if oldParent ~= self then
              if oldParent then
                oldParent:removeChild(nWidget)
              end
              self:insertChild(nIndex, nWidget)
            else
              self:moveChildToIndex(nWidget, nIndex)
            end
            self.scheduledWidgets[nIndex] = nil
            placed = true
            break
          end
        end
        if not placed then break end
      end
    end
  end
end

function UIMiniWindowContainer:order()
  local children = self:getChildren()
  for i=1,#children do
    if not children[i].headlessborder then
      if not children[i].miniLoaded then return end
    end
  end

  table.sort(children, function(a, b)
    local indexA = a.miniIndex or a.autoOpen or 999
    local indexB = b.miniIndex or b.autoOpen or 999
    return indexA < indexB
  end)

  self:reorderChildren(children)
  self:saveChildren()
  local ignoreIndex = 0
  for i=1,#children do
    if children[i].save then
      children[i].miniIndex = i - ignoreIndex
    else
      ignoreIndex = ignoreIndex + 1
    end      
  end
end

function UIMiniWindowContainer:saveChildren()
  local children = self:getChildren()
  local ignoreIndex = 0
  for i=1,#children do
    if not children[i].headlessborder then
      if children[i].save then
        children[i]:saveParentIndex(self:getId(), i - ignoreIndex)
      else
        ignoreIndex = ignoreIndex + 1
      end
    end
  end
end

function UIMiniWindowContainer:onGeometryChange()
  self:fitAll()
end
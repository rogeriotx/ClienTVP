-- @docclass
UIMiniWindow = extends(UIWindow, "UIMiniWindow")

function getUIMiniWindowSettingsName()
    local sufix = ""
    local player = g_game.getLocalPlayer()
    if player then sufix = player:getName() end

    return 'MiniWindows' .. sufix
end

function UIMiniWindow.create()
    local miniwindow = UIMiniWindow.internalCreate()
    miniwindow.UIMiniWindowContainer = true
    return miniwindow
end

function UIMiniWindow:open(dontSave)
    self:setVisible(true)

    if not dontSave then self:setSettings({closed = false, open = true}) end

	if self.topButton then self.topButton:setOn(true) end

    self.justOpened = true

    signalcall(self.onOpen, self)

    for _, panel in pairs(modules.game_interface.getAllPanelList()) do
        addEvent(function()
            panel:fitAll()
        end)
    end

end

function UIMiniWindow:close(dontSave, ignoreFitAll)
    if not self:isExplicitlyVisible() then return end
    if self.forceOpen then return end
	local lockButton = self:getChildById('lockButton')
    if lockButton and lockButton:isOn() then return end

    self:setVisible(false)

    if not dontSave then self:setSettings({closed = true, open = false}) end

	if self.topButton then self.topButton:setOn(false) end

    signalcall(self.onClose, self)
    if not ignoreFitAll then
        for _, panel in pairs(modules.game_interface.getAllPanelList()) do
            addEvent(function()
                panel:fitAll()
            end)
        end
    end

end

function UIMiniWindow:minimize(dontSave)
    self:setOn(true)
    self:getChildById('contentsPanel'):hide()
    self:getChildById('miniwindowScrollBar'):hide()
    self:getChildById('bottomResizeBorder'):hide()
    if self.miniBroder then self.miniBroder:hide() end
    if self.minimizeButton then self.minimizeButton:setOn(true) end
    self.maximizedHeight = self:getHeight()
    self:setHeight(self.minimizedHeight)

    if not dontSave then self:setSettings({minimized = true}) end

    signalcall(self.onMinimize, self)
end

function UIMiniWindow:maximize(dontSave)
    self:setOn(false)
    self:getChildById('contentsPanel'):show()
    self:getChildById('miniwindowScrollBar'):show()
    self:getChildById('bottomResizeBorder'):show()
    if self.miniBroder then self.miniBroder:show() end
    if self.minimizeButton then self.minimizeButton:setOn(false) end
    self:setHeight(self:getSettings('height') or self.maximizedHeight)

    if not dontSave then self:setSettings({minimized = false}) end

    local parent = self:getParent()
    if parent and parent:getClassName() == 'UIMiniWindowContainer' then
        parent:fitAll(self)
    end

    signalcall(self.onMaximize, self)
end

function UIMiniWindow:lock(dontSave)
    local lockButton = self:getChildById('lockButton')
    if lockButton then lockButton:setOn(true) end
    self:setDraggable(false)
    self.locked = true
    if not dontSave then self:setSettings({ locked = true }) end

    signalcall(self.onLockChange, self)
end

function UIMiniWindow:unlock(dontSave)
    local lockButton = self:getChildById('lockButton')
    if lockButton then lockButton:setOn(false) end
    self:setDraggable(true)
    self.locked = false
    if not dontSave then self:setSettings({ locked = false }) end
    signalcall(self.onLockChange, self)
end

function UIMiniWindow:setup()

    if not self.originalHeight then
        self.originalHeight = self:getHeight()
    end

    self:getChildById('closeButton').onClick = function() self:close() end
    if self.forceOpen then
        if self.closeButton then self.closeButton:hide() end
    end

    if (self.minimizeButton) then
        self.minimizeButton.onClick = function()
            if self:isOn() then
                self:maximize()
            else
                self:minimize()
            end
        end
    end
    if self.lockButton then
        self.lockButton.onClick = function()
            if not self.locked then
                self:lock()
            else
                self:unlock()
            end
        end
    end

    local oldParent = self:getParent()
    local settings = g_settings.getNode(getUIMiniWindowSettingsName())

    if settings and settings[self:getId()] then
        settings = settings[self:getId()]
    end

    if settings then
        if settings.parentId then
            local parent = rootWidget:recursiveGetChildById(settings.parentId)
            if parent then
                if parent:getClassName() == 'UIMiniWindowContainer' and settings.index and parent:isOn() then
                    self.miniIndex = settings.index
                    parent:scheduleInsert(self, settings.index)
                elseif settings.position then
                    self:setParent(parent)
                    self:setPosition(topoint(settings.position))
                end
            end
        end

        if settings.minimized then
            self:minimize(true)
        else
            if settings.height and self:isResizeable() then
                self:setHeight(settings.height)
            elseif settings.height and not self:isResizeable() then
                self:eraseSettings({height = true})
            else
                self:setHeight(self.originalHeight)
            end
        end

        if settings.open or self.forceOpen then
            self:open(true)
        elseif settings.closed then
            self:close(true)
        else
            -- não existe nem closed e nem open declarados
            if self.autoOpen or self.forceOpen then
                self:open()
            else
                self:close()
            end
        end

        if settings.locked then 
            self:lock(true) 
        end
    else
        if self.autoOpen or self.forceOpen then
            self:open(true)
        else
            self:close(true)
        end
        self:setHeight(self.originalHeight)
    end

    local newParent = self:getParent()

    self.miniLoaded = true

    if self.save then
        if oldParent and oldParent:getClassName() == 'UIMiniWindowContainer' then
            addEvent(function() oldParent:order() end)
        end
        if newParent and newParent:getClassName() == 'UIMiniWindowContainer' and
            newParent ~= oldParent then
            addEvent(function() newParent:order() end)
        end
    end

    self:fitOnParent()
end

function UIMiniWindow:onVisibilityChange(visible) self:fitOnParent() end

function UIMiniWindow:onDragEnter(mousePos)
    local parent = self:getParent()
    if not parent then return false end
    self.parentWidget = nil
    if parent:getClassName() == 'UIMiniWindowContainer' then
        self.parentWidget = parent
        local containerParent = parent:getParent():getParent()
        parent:removeChild(self)
        containerParent:addChild(self)
        parent:saveChildren()
    end

    local oldPos = self:getPosition()
    self.movingReference = {
        x = mousePos.x - oldPos.x,
        y = mousePos.y - oldPos.y
    }
    self.oldPos = oldPos
    self:setPosition(oldPos)
    self.free = true
    return true
end

local function isInArray(table, value)
    for v = 1, #table do if table[v] == value then return true end end
    return false
end

function UIMiniWindow:onDragLeave(droppedWidget, mousePos)

    local children = rootWidget:recursiveGetChildrenByMarginPos(mousePos)
    local panels = {}

    for _, child in pairs(children) do
        local availablePanelList = {
            "rightPanel1", "rightPanel2", "rightPanel3",
            "rightPanel4", "leftPanel1", "leftPanel2", "leftPanel3",
            "leftPanel4"
        }

        if self.openOnTopPanel then
            table.insert(availablePanelList, "gameTopLeftPanel")
            table.insert(availablePanelList, "gameTopRightPanel")
        end

        if isInArray(availablePanelList, child:getId()) then 
            table.insert(panels, child)
        end
    end

    if #panels == 0 then
        local tmp = self
        addEvent(function()
            if not tmp or tmp:isDestroyed() then
                return true
            end
            local closest = modules.game_interface.getPanelList()[1]
            for _, panel in pairs(modules.game_interface.getPanelList()) do
                
                local panelDist = math.abs(panel:getX() + panel:getWidth() / 2 - mousePos.x)
                local closestDist = math.abs(closest:getX() + closest:getWidth() / 2 - mousePos.x)
                
                if panelDist <= closestDist then
                    closest = panel
                end
            end

            local isMinimap = tmp:getId() == "minimapWindow"
            if isMinimap then
                modules.game_minimap.build_minimap_style(self.topPanel and "otcv8" or "retro")
            end

            tmp:setParent(closest)
        end)
    end

    for _, panel in pairs(modules.game_interface.getAllPanelList()) do
        addEvent(function()
            panel:fitAll()
        end)
    end

    if self.movedWidget then
        self.setMovedChildMargin(self.movedOldMargin or 0)
        self.movedWidget = nil
        self.setMovedChildMargin = nil
        self.movedOldMargin = nil
        self.movedIndex = nil
    end

    
    UIWindow:onDragLeave(self, droppedWidget, mousePos)
    self:saveParent(self:getParent())
end

function UIMiniWindow:onDragMove(mousePos, mouseMoved)
    local oldMousePosY = mousePos.y - mouseMoved.y
    local children = rootWidget:recursiveGetChildrenByMarginPos(mousePos)
    local overAnyWidget = false
    local movingPosition = mousePos
    for i = 1, #children do
        local child = children[i]
        if child:getParent():getClassName() == 'UIMiniWindowContainer' then
            overAnyWidget = true

            local childCenterY = child:getY() + child:getHeight() / 2
            if child == self.movedWidget and mousePos.y < childCenterY and
                oldMousePosY < childCenterY then break end

            if self.movedWidget then
                self.setMovedChildMargin(self.movedOldMargin or 0)
                self.setMovedChildMargin = nil
            end

            if mousePos.y < childCenterY then
                self.movedOldMargin = child:getMarginTop()
                self.setMovedChildMargin = function(v)
                    child:setMarginTop(v)
                end
                self.movedIndex = 0
            else
                self.movedOldMargin = child:getMarginBottom()
                self.setMovedChildMargin = function(v)
                    child:setMarginBottom(v)
                end
                self.movedIndex = 1
            end

            self.movedWidget = child
            self.setMovedChildMargin(self:getHeight())
            break
        end
    end

    if not overAnyWidget and self.movedWidget then
        self.setMovedChildMargin(self.movedOldMargin or 0)
        self.movedWidget = nil
    end

    local rightPanels = modules.game_interface.getRightPanels():getChildCount()
    local leftPanels = modules.game_interface.getLeftPanels():getChildCount()

    if leftPanels == 0 then
        
        local last_right_panel = modules.game_interface.getRightPanels()["rightPanel"..rightPanels]
        -- print(movingPosition.x, last_right_panel:getX(), self:getX())
        if mouseMoved.x > 0 then -- Movendo para direita
            if mousePos.x < last_right_panel:getX() then
                movingPosition.x = last_right_panel:getX()
                self.movingReference = { x = 0, y = 0 }
            end
        else -- Movendo para esquerda
            if self:getX() <= last_right_panel:getX() then
                movingPosition.x = last_right_panel:getX()
                self.movingReference = { x = 0, y = 0 }
            end
        end
    end

    return UIWindow.onDragMove(self, movingPosition, mouseMoved)
end

function UIMiniWindow:onMousePress()
    local parent = self:getParent()
    if not parent then return false end
    if parent:getClassName() ~= 'UIMiniWindowContainer' then
        self:raise()
        return true
    end
end

function UIMiniWindow:onFocusChange(focused)
    if not focused then return end
    local parent = self:getParent()
    if parent and parent:getClassName() ~= 'UIMiniWindowContainer' then
        self:raise()
    end
end

function UIMiniWindow:onHeightChange(height)
    if not self:isOn() then self:setSettings({height = height}) end
    self:fitOnParent()
end

function UIMiniWindow:getSettings(name)
    if not self.save then return nil end
    local settings = g_settings.getNode(getUIMiniWindowSettingsName())
    if settings then
        local selfSettings = settings[self:getId()]
        if selfSettings then return selfSettings[name] end
    end
    return nil
end

function UIMiniWindow:setSettings(data)
    if not self.save then return end

    local settings = g_settings.getNode(getUIMiniWindowSettingsName())
    if not settings then settings = {} end

    local id = self:getId()
    if not settings[id] then settings[id] = {} end

    for key, value in pairs(data) do settings[id][key] = value end

    g_settings.setNode(getUIMiniWindowSettingsName(), settings)
end

function UIMiniWindow:eraseSettings(data)
    if not self.save then return end

    local settings = g_settings.getNode(getUIMiniWindowSettingsName())
    if not settings then settings = {} end

    local id = self:getId()
    if not settings[id] then settings[id] = {} end

    for key, value in pairs(data) do settings[id][key] = nil end

    g_settings.setNode(getUIMiniWindowSettingsName(), settings)
end

function UIMiniWindow:clearSettings()
    if not self.save then return end

    local settings = g_settings.getNode(getUIMiniWindowSettingsName())
    if not settings then settings = {} end

    local id = self:getId()
    settings[id] = {}

    g_settings.setNode(getUIMiniWindowSettingsName(), settings)
end

function UIMiniWindow:saveParent()
    local parent = self:getParent()
    if parent then
        if parent:getClassName() == 'UIMiniWindowContainer' then
            parent:saveChildren()
        else
            self:saveParentPosition(parent:getId(), self:getPosition())
        end
    end
end

function UIMiniWindow:saveParentPosition(parentId, position)
    local selfSettings = {}
    selfSettings.parentId = parentId
    selfSettings.position = pointtostring(position)
    self:setSettings(selfSettings)
end

function UIMiniWindow:saveParentIndex(parentId, index)
    local selfSettings = {}
    selfSettings.parentId = parentId
    selfSettings.index = index
    self:setSettings(selfSettings)
    self.miniIndex = index
end

function UIMiniWindow:disableResize()
    self:getChildById('bottomResizeBorder'):disable()
end

function UIMiniWindow:enableResize()
    self:getChildById('bottomResizeBorder'):enable()
end

function UIMiniWindow:fitOnParent()
    local parent = self:getParent()
    if self:isVisible() and parent and parent:getClassName() ==
        'UIMiniWindowContainer' then parent:fitAll(self) end
end

function UIMiniWindow:setParent(parent)
    UIWidget.setParent(self, parent)
    self:fitOnParent()
    parent:saveChildren()
end

function UIMiniWindow:setHeight(height)
    UIWidget.setHeight(self, height)
    signalcall(self.onHeightChange, self, height)
end

function UIMiniWindow:setContentHeight(height)
    local contentsPanel = self:getChildById('contentsPanel')
    local minHeight = contentsPanel:getMarginTop() +
                          contentsPanel:getMarginBottom() +
                          contentsPanel:getPaddingTop() +
                          contentsPanel:getPaddingBottom()

    local resizeBorder = self:getChildById('bottomResizeBorder')
    resizeBorder:setParentSize(minHeight + height)
end

function UIMiniWindow:setContentMinimumHeight(height)
    local contentsPanel = self:getChildById('contentsPanel')
    local minHeight = contentsPanel:getMarginTop() +
                          contentsPanel:getMarginBottom() +
                          contentsPanel:getPaddingTop() +
                          contentsPanel:getPaddingBottom()

    local resizeBorder = self:getChildById('bottomResizeBorder')
    resizeBorder:setMinimum(minHeight + height)
end

function UIMiniWindow:setContentMaximumHeight(height)
    local contentsPanel = self:getChildById('contentsPanel')
    local minHeight = contentsPanel:getMarginTop() +
                          contentsPanel:getMarginBottom() +
                          contentsPanel:getPaddingTop() +
                          contentsPanel:getPaddingBottom()

    local resizeBorder = self:getChildById('bottomResizeBorder')
    resizeBorder:setMaximum(minHeight + height)
end

function UIMiniWindow:getMinimumHeight()
    local resizeBorder = self:getChildById('bottomResizeBorder')
    return resizeBorder:getMinimum()
end

function UIMiniWindow:getMaximumHeight()
    local resizeBorder = self:getChildById('bottomResizeBorder')
    return resizeBorder:getMaximum()
end

function UIMiniWindow:isResizeable()
    local resizeBorder = self:getChildById('bottomResizeBorder')
    return resizeBorder:isExplicitlyVisible() and resizeBorder:isEnabled()
end

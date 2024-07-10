---@diagnostic disable: lowercase-global
local gameStart = 0

function init()
	connect(Container, {
		onOpen = onContainerOpen,
		onClose = onContainerClose,
		onSizeChange = onContainerChangeSize,
		onUpdateItem = onContainerUpdateItem
	})
	connect(g_game, {
		onGameStart = markStart,
		onGameEnd = clean
	})

	reloadContainers()
end

function terminate()
	disconnect(Container, {
		onOpen = onContainerOpen,
		onClose = onContainerClose,
		onSizeChange = onContainerChangeSize,
		onUpdateItem = onContainerUpdateItem
	})
	disconnect(g_game, {
		onGameStart = markStart,
		onGameEnd = clean
	})
end

function reloadContainers()
	clean()
	for _, container in pairs(g_game.getContainers()) do
		onContainerOpen(container)
	end
end

function clean()
	for containerid, container in pairs(g_game.getContainers()) do
		destroy(container)
	end
end

function markStart()
	gameStart = g_clock.millis()
end

function destroy(container)
	modules.game_interface.updatePanels()

	if container.window then
		container.window:destroy()
		container.window = nil
		container.itemsPanel = nil
	end
end

function refreshContainerItems(container)
	for slot = 0, container:getCapacity() - 1 do
		local itemWidget = container.itemsPanel:getChildById('item' .. slot)
		itemWidget:setItem(container:getItem(slot))
		itemWidget:updateItemRarity()
	end

	if container:hasPages() then
		refreshContainerPages(container)
	end
end

function toggleContainerPages(containerWindow, hasPages)
	if hasPages == containerWindow.pagePanel:isOn() then
		return
	end
	containerWindow.pagePanel:setOn(hasPages)
	if hasPages then
		containerWindow.miniwindowScrollBar:setMarginTop(containerWindow.miniwindowScrollBar:getMarginTop() +
			containerWindow.pagePanel:getHeight())
		containerWindow.contentsPanel:setMarginTop(containerWindow.contentsPanel:getMarginTop() +
			containerWindow.pagePanel:getHeight())
	else
		containerWindow.miniwindowScrollBar:setMarginTop(containerWindow.miniwindowScrollBar:getMarginTop() -
			containerWindow.pagePanel:getHeight())
		containerWindow.contentsPanel:setMarginTop(containerWindow.contentsPanel:getMarginTop() -
			containerWindow.pagePanel:getHeight())
	end
end

function refreshContainerPages(container)
	local currentPage = 1 + math.floor(container:getFirstIndex() / container:getCapacity())
	local pages = 1 + math.floor(math.max(0, (container:getSize() - 1)) / container:getCapacity())
	container.window:recursiveGetChildById('pageLabel'):setText(string.format('Page %i of %i', currentPage, pages))

	local prevPageButton = container.window:recursiveGetChildById('prevPageButton')
	if currentPage == 1 then
		prevPageButton:setEnabled(false)
	else
		prevPageButton:setEnabled(true)
		prevPageButton.onClick = function()
			g_game.seekInContainer(container:getId(),
				container:getFirstIndex() - container:getCapacity())
		end
	end

	local nextPageButton = container.window:recursiveGetChildById('nextPageButton')
	if currentPage >= pages then
		nextPageButton:setEnabled(false)
	else
		nextPageButton:setEnabled(true)
		nextPageButton.onClick = function()
			g_game.seekInContainer(container:getId(),
				container:getFirstIndex() + container:getCapacity())
		end
	end

	local pagePanel = container.window:recursiveGetChildById('pagePanel')
	if pagePanel then
		pagePanel.onMouseWheel = function(widget, mousePos, mouseWheel)
			if pages == 1 then return end
			if mouseWheel == MouseWheelUp then
				return prevPageButton.onClick()
			else
				return nextPageButton.onClick()
			end
		end
	end
end

local openWideNextContainer = false

function setOpenWideNextContainer(value)
	openWideNextContainer = value
end

local openNewContainer

function setPreviousContainerWhenOpenNewContainer(container)
	openNewContainer = container
end

function onContainerOpen(container, previousContainer)
	local containerWindow
	local prevContentHeight = 0

	if previousContainer then
		containerWindow = previousContainer.window
		previousContainer.window = nil
		previousContainer.itemsPanel = nil

		local contentsPanel = containerWindow:getChildById('contentsPanel')
		local minHeight = contentsPanel:getMarginTop()     +
						  contentsPanel:getMarginBottom()  +
						  contentsPanel:getPaddingTop()    +
						  contentsPanel:getPaddingBottom()

		prevContentHeight = containerWindow:getHeight() - minHeight
	else
		containerWindow = g_ui.createWidget('ContainerWindow', modules.game_interface.getContainerPanel())

		-- white border flash effect
		containerWindow:setBorderWidth(2)
		containerWindow:setBorderColor("#FFFFFF")

		scheduleEvent(function()
			if containerWindow then
				containerWindow:setBorderWidth(0)
			end
		end, 300)

		if openNewContainer then
			previousContainer = openNewContainer.window

			local contentsPanel = previousContainer:getChildById('contentsPanel')
			local minHeight = contentsPanel:getMarginTop() +
								contentsPanel:getMarginBottom() +
								contentsPanel:getPaddingTop() +
								contentsPanel:getPaddingBottom()
			prevContentHeight = previousContainer:getHeight() - minHeight
		end
	end

	containerWindow:setId('container' .. container:getId())
	if gameStart + 1000 < g_clock.millis() then
		containerWindow:clearSettings()
	end

	local containerPanel = containerWindow:getChildById('contentsPanel')
	local containerItemWidget = containerWindow:getChildById('containerItemWidget')

	containerWindow.onClose = function()
		g_game.close(container)
		containerWindow:hide()
	end

	containerWindow.onDrop = function(container, widget, mousePos)
		if containerPanel:getChildByPos(mousePos) then
		  return false
		end
		local child = findClosestUIItem(containerWindow, mousePos)
		if child then
		  child:onDrop(widget, mousePos, true)        
		end
	end

	containerWindow.onMousePress = function(widget, mousePos, mouseButton)

		if containerWindow.locked then
			containerWindow:setDraggable(false)
			return false
		end

		local oldMousePos = mousePos
		xToleranceLeft = containerWindow:getX() + 5
		xToleranceRight = containerWindow:getX() + containerWindow:getWidth() - 5
		yToleranceTop = containerWindow:getY() + 2
		yToleranceBottom = containerWindow:getY() + containerWindow:getHeight() - 2

		containerWindow:setDraggable(true)

		if mousePos.x < xToleranceLeft or mousePos.x > xToleranceRight or mousePos.y > yToleranceBottom or mousePos.y < yToleranceTop then
			containerWindow:setDraggable(false)
			return false
		end

		local child = containerWindow:getChildByPos(mousePos)
		if child == containerPanel then
			containerWindow:setDraggable(false)
		end
	end



	containerWindow.onMouseRelease = function(widget, mousePos, mouseButton)
		-- search for closest uiitem element between container gap
		print("onMouseRelease")
		if mouseButton == MouseButton4 then
			if container:hasParent() then
				return g_game.openParent(container)
			end
		elseif mouseButton == MouseButton5 then
			for i, item in ipairs(container:getItems()) do
				if item:isContainer() then
					return g_game.open(item, container)
				end
			end
		elseif mouseButton == MouseLeftButton or mouseButton == MouseRightButton then
			local clickedItem = containerWindow:recursiveGetChildByPos(mousePos)
			if clickedItem and clickedItem:getClassName() == 'UIItem' then
				return false
			end


			local closestItem = findClosestUIItem(containerWindow, mousePos)
			if closestItem then
				local item = closestItem:getItem()
				if not item then return false end
				if modules.client_options.getOption('classicControl') and not g_app.isMobile() and
					((g_mouse.isPressed(MouseLeftButton) and mouseButton == MouseRightButton) or
						(g_mouse.isPressed(MouseRightButton) and mouseButton == MouseLeftButton)) then
					g_game.look(item)
					closestItem.cancelNextRelease = true
					return true
				elseif modules.game_interface.processMouseAction(mousePos, mouseButton, nil, item, item, nil, nil) then
					return true
				end
			end
		end
	end

	-- this disables scrollbar auto hiding
	local scrollbar = containerWindow:getChildById('miniwindowScrollBar')
	scrollbar:mergeStyle({ ['$!on'] = {} })

	local upButton = containerWindow:getChildById('upButton')
	upButton.onClick = function()
		g_game.openParent(container)
	end
	upButton:setVisible(container:hasParent())

	local name = container:getName()
	name = name:sub(1, 1):upper() .. name:sub(2)
	containerWindow:setText(name)

	containerItemWidget:setItem(container:getContainerItem())

	containerPanel:destroyChildren()

	local function get_grid_position(index, num_columns) 
		local row = math.floor(index / num_columns)
		local column = index % num_columns
		return row, column
	end

	for slot = 0, container:getCapacity() - 1 do
		local itemWidget = g_ui.createWidget('Item', containerPanel)
		itemWidget:setId('item' .. slot)
		local item = container:getItem(slot)
		itemWidget:setItem(item)
		itemWidget:addAnchor(AnchorTop, 'parent', AnchorTop)
		itemWidget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
		
		itemWidget:setMargin(0)
		local row, column = get_grid_position(slot, 4)
		local marginy = 4 + row * (34 + 3)
		local marginx = column * (34 + 3)
		itemWidget:setMarginTop(marginy)
		itemWidget:setMarginLeft(marginx)

		itemWidget.position = container:getSlotPosition(slot)

		if not container:isUnlocked() then
			itemWidget:setBorderColor('red')
		end
	end

	container.window = containerWindow
	container.itemsPanel = containerPanel

	toggleContainerPages(containerWindow, container:hasPages())
	refreshContainerPages(container)

	local cellSize = {height = 34, width = 34}--layout:getCellSize()
	containerWindow:setContentMinimumHeight(cellSize.height+4+3) -- set min height
	
	local row, column = get_grid_position(container:getCapacity() - 1, 4)

	row = row+1

	local maxHeight = 4 + row * (cellSize.height + 3)
	containerWindow:setContentMaximumHeight(maxHeight) -- set max height

	if container:hasPages() then
		local height = containerWindow.miniwindowScrollBar:getMarginTop() + containerWindow.pagePanel:getHeight() + 17
		if containerWindow:getHeight() < height then
			containerWindow:setHeight(height)
		end
	end

	local itemsCount = container:getItemsCount()
	local hasHeightInSettings = containerWindow:getSettings("height")
	local filledLines = math.max(math.ceil(itemsCount / 4), 1)
	local containerHeight

	containerWindow.autoOpen = 999

	local defaultContentHeight
	if openWideNextContainer then
		defaultContentHeight = maxHeight
	else

		if row == filledLines then
			defaultContentHeight = maxHeight
		else
			defaultContentHeight = (cellSize.height + 3) * filledLines + 4
			if itemsCount > 0 then
				defaultContentHeight = defaultContentHeight + 3
			end
		end
	end

	if previousContainer then -- Possui container anterior
		containerHeight = prevContentHeight
	else -- Não possui container anterior
		if hasHeightInSettings then -- Possui height configurado
			-- Abre com height configurado
			local contentsPanel = containerWindow:getChildById('contentsPanel')
			local minHeight = contentsPanel:getMarginTop()     +
			contentsPanel:getMarginBottom()  +
			contentsPanel:getPaddingTop()    +
			contentsPanel:getPaddingBottom()
			containerHeight = hasHeightInSettings - minHeight
		else
			-- Segue Comportamento padrão de abertura
			containerHeight = defaultContentHeight
		end
	end
	
	containerWindow:setContentHeight(containerHeight)
	
	containerWindow:setup()

	containerWindow.miniwindowScrollBar:setMinimum(0)
	containerWindow.miniwindowScrollBar:setValue(0)

	setOpenWideNextContainer(false)
	setPreviousContainerWhenOpenNewContainer(nil)
end

function findClosestUIItem(containerWindow, mousePos)
    local closestItem = nil
    local closestDistance = 2

    local directions = {
        {x = -2, y = 0},
        {x = 2, y = 0},
        {x = 0, y = -2},
        {x = 0, y = 2},
        {x = -2, y = -2},
        {x = 2, y = -2},
        {x = -2, y = 2},
        {x = 2, y = 2},
    }
    for _, dir in pairs(directions) do
        local posToCheck = {x = mousePos.x + dir.x, y = mousePos.y + dir.y}
        local item = containerWindow:recursiveGetChildByPos(posToCheck)
        if item and item:getClassName() == 'UIItem' then
            local distance = math.sqrt((posToCheck.x - mousePos.x)^2 + (posToCheck.y - mousePos.y)^2)
            distance = math.floor(distance)
            if distance <= closestDistance then
                closestItem = item
                closestDistance = distance
            end
        end
    end
    return closestItem
end

function onContainerClose(container)
	destroy(container)
end

function onContainerChangeSize(container, size)
	if not container.window then return end
	refreshContainerItems(container)
end

function onContainerUpdateItem(container, slot, item, oldItem)
	if not container.window then return end
	local itemWidget = container.itemsPanel:getChildById('item' .. slot)
	itemWidget:setItem(item)
end

minimapWidget = nil
minimapWindow = nil
fullmapView = false
loaded = false
oldZoom = nil
oldPos = nil

function build_minimap_style(mode)  

  if mode == minimapWindow.mode then
    return true
  end

  if mode == "refresh" then
    mode = minimapWindow.mode
  end

  minimapWindow.closeButton:setVisible(false)
  minimapWindow.miniwindowScrollBar:setVisible(false)
  if mode == "retro" then
    -- minimapWindow = g_ui.createWidget('OriginalMinimapMiniwindow')
    -- minimapWindow:disableResize()
    
    minimapWindow:setImageSource("/images/ui/special_miniwindow")
    minimapWindow:setImageBorder(4)
    
    minimapWindow:setPadding(0)
    
    minimapWindow.minimizeButton:setVisible(false)
    minimapWindow.lockButton:setVisible(false)
    
    minimapWindow.contentsPanel:fill('parent')
    minimapWindow.contentsPanel:setMargin(0)
    minimapWindow.contentsPanel:setPadding(0)
    minimapWindow.contentsPanel:setPaddingRight(7)

    minimapWindow.contentsPanel.minimapBackground:setVisible(true)
    minimapWindow.contentsPanel.navigator:setVisible(true)
    
    minimapWindow.contentsPanel.minimapBackground:setMarginTop(4)
    minimapWindow.contentsPanel.minimapBackground:setMarginBottom(0)
    minimapWindow.contentsPanel.minimapBackground:setMarginLeft(10)
    minimapWindow.contentsPanel.minimapBackground:setMarginRight(0)
    
    
    minimapWindow.contentsPanel.minimap:removeAnchor(AnchorTop)
    minimapWindow.contentsPanel.minimap:removeAnchor(AnchorBottom)
    minimapWindow.contentsPanel.minimap:removeAnchor(AnchorLeft)
    minimapWindow.contentsPanel.minimap:removeAnchor(AnchorRight)
    minimapWindow.contentsPanel.minimap:addAnchor(AnchorTop, 'minimapBackground', AnchorTop)
    minimapWindow.contentsPanel.minimap:addAnchor(AnchorLeft, 'minimapBackground', AnchorLeft)
    minimapWindow.contentsPanel.minimap:addAnchor(AnchorBottom, 'minimapBackground', AnchorBottom)
    minimapWindow.contentsPanel.minimap:addAnchor(AnchorRight, 'minimapBackground', AnchorRight)


    minimapWindow.contentsPanel.minimap:setHeight(106)
    minimapWindow.contentsPanel.minimap:setWidth(106)
    
    minimapWindow.contentsPanel.minimap:setMargin(1)

    minimapWindow.contentsPanel.minimap.toggleFullmap:setVisible(true)
    minimapWindow.contentsPanel.floorUpButton:setVisible(true)
    minimapWindow.contentsPanel.floorDownButton:setVisible(true)
    minimapWindow.contentsPanel.zoomOutButton:setVisible(true)
    minimapWindow.contentsPanel.zoomInButton:setVisible(true)
    minimapWindow.contentsPanel.centreButton:setVisible(true)
    
    for _, child in pairs(minimapWindow.contentsPanel.minimap:getChildren()) do
      child:setVisible(false)
    end

    minimapWindow.contentsPanel.minimap:setVisible(true)


    minimapWindow.headlesswindow = true
    minimapWidget.headlesswindow = true
    
    minimapWindow:maximize()
    minimapWindow:unlock()

    minimapWindow:setHeight(119)
  else
    
    minimapWindow.headlesswindow = false
    minimapWidget.headlesswindow = false
    
    minimapWindow:setImageSource("/images/ui/window")
    minimapWindow:setImageBorder(4)
    minimapWindow:setImageBorderTop(17)
    
    minimapWindow:setContentMinimumHeight(64)
    
    minimapWindow:setPadding(0)
    
    minimapWindow.minimizeButton:setVisible(true)
    minimapWindow.lockButton:setVisible(true)
    minimapWindow.closeButton:setWidth(0)

    
    minimapWindow.contentsPanel:setMarginLeft(3)
    minimapWindow.contentsPanel:setMarginBottom(3)
    minimapWindow.contentsPanel:setMarginTop(17)
    minimapWindow.contentsPanel:setMarginRight(1)

    minimapWindow.contentsPanel:setPaddingTop(0)
    minimapWindow.contentsPanel:setPaddingRight(3)
    minimapWindow.contentsPanel:setPaddingBottom(0)
    minimapWindow.contentsPanel:setPaddingLeft(1)
    
    minimapWindow.contentsPanel.minimap:fill('parent')
    minimapWindow.contentsPanel.minimap:setMargin(0)
    
    for _, child in pairs(minimapWindow.contentsPanel.minimap:getChildren()) do
      child:setVisible(true)
    end

    
    minimapWindow.contentsPanel.floorUpButton:setVisible(false)
    minimapWindow.contentsPanel.floorDownButton:setVisible(false)
    minimapWindow.contentsPanel.zoomOutButton:setVisible(false)
    minimapWindow.contentsPanel.zoomInButton:setVisible(false)
    minimapWindow.contentsPanel.centreButton:setVisible(false)
    
    minimapWindow.contentsPanel.minimapBackground:setVisible(false)
    minimapWindow.contentsPanel.navigator:setVisible(false)
    minimapWindow:enableResize()
    
  end
  
  minimapWindow.miniwindowScrollBar.disableScroll = true
  minimapWindow.miniwindowScrollBar:setWidth(0)
  
  minimapWindow:setIconColor('alpha')
  minimapWidget = minimapWindow:recursiveGetChildById('minimap')
  minimapWindow.mode = mode
  
  minimapWidget:setMixZoom(-1)
  minimapWidget:setMaxZoom(2)
  minimapWidget:fixCross()
  minimapWindow:fitOnParent()

  if g_game.isOnline() then
    updateCameraPosition()
  end
  
  return minimapWindow
end

function init()
  
  minimapWindow = g_ui.loadUI('minimap', modules.game_interface.getRightPanel())  
  minimapWidget = minimapWindow:recursiveGetChildById('minimap')

  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.bindKeyPress('Alt+Left', function() minimapWidget:move(3 * (3 - minimapWidget:getZoom()), 0) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Right', function() minimapWidget:move(-3 * (3 - minimapWidget:getZoom()), 0) end,
    gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Up', function() minimapWidget:move(0, 3 * (3 - minimapWidget:getZoom())) end,
    gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Down', function() minimapWidget:move(0, -3 * (3 - minimapWidget:getZoom())) end,
    gameRootPanel)
  g_keyboard.bindKeyDown('Ctrl+M', toggle)
  g_keyboard.bindKeyDown('Ctrl+Shift+M', toggleFullMap)

  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
  })

  connect(LocalPlayer, {
    onPositionChange = updateCameraPosition
  })

  if g_game.isOnline() then
    online()
  end
end

function terminate()
  if g_game.isOnline() then
    saveMap()
  end

  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
  })

  disconnect(LocalPlayer, {
    onPositionChange = updateCameraPosition
  })

  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.unbindKeyPress('Alt+Left', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Right', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Up', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Down', gameRootPanel)
  g_keyboard.unbindKeyDown('Ctrl+M')
  g_keyboard.unbindKeyDown('Ctrl+Shift+M')

  minimapWindow:destroy()
end

function toggle()
  minimapWindow:open()
end

function online()
	addEvent(function()
		minimapWindow:setup()
		for _, widget in pairs(minimapWidget:getChildren()) do
			if string.find(widget:getId(), 'flag') then
				widget:destroy()
			end
		end
		loadMap()
		updateCameraPosition()
		minimapWindow:open()
		build_minimap_style(minimapWindow:getParent().topPanel and "otcv8" or "retro")
		minimapWidget:fixCross()
	end)
end

function offline()
  saveMap()
end

function loadMap()
  local clientVersion = g_game.getClientVersion()

  g_minimap.clean()
  loaded = false

  local minimapFile = '/minimap.otmm'
  local dataMinimapFile = '/data' .. minimapFile
  local versionedMinimapFile = '/minimap' .. clientVersion .. '.otmm'
  if g_resources.fileExists(dataMinimapFile) then
    loaded = g_minimap.loadOtmm(dataMinimapFile)
  end
  if not loaded and g_resources.fileExists(versionedMinimapFile) then
    loaded = g_minimap.loadOtmm(versionedMinimapFile)
  end
  if not loaded and g_resources.fileExists(minimapFile) then
    loaded = g_minimap.loadOtmm(minimapFile)
  end
  if not loaded then
    print("Minimap couldn't be loaded, file missing?")
  end
  minimapWidget:load()
end

function load_full_map()
  loaded = g_minimap.loadOtmm("/data/minimap772.otmm")
  if not loaded then
    print("Minimap couldn't be loaded, file missing?")
  end
  minimapWidget:load()
  saveMap()
end

function saveMap()
  local clientVersion = g_game.getClientVersion()
  local minimapFile = '/minimap' .. clientVersion .. '.otmm' 
  g_minimap.saveOtmm(minimapFile)
  minimapWidget:save()
end

function updateCameraPosition()
  local player = g_game.getLocalPlayer()
  if not player then return end
  local pos = player:getPosition()
  if not pos then return end
  if not minimapWidget:isDragging() then
    if not fullmapView then
      minimapWidget:setCameraPosition(player:getPosition())
    end
    minimapWidget:setCrossPosition(player:getPosition())
  end
end

function toggleFullMap()
  if not fullmapView then
    fullmapView = true
    minimapWindow:hide()
    minimapWidget:setParent(modules.game_interface.getRootPanel())
    minimapWidget:fill('parent')
    minimapWidget:setAlternativeWidgetsVisible(true)
    local player = g_game.getLocalPlayer()
    if player then
      minimapWidget:setCameraPosition(player:getPosition())
    end

    for _, child in pairs(minimapWidget:getChildren()) do
      child:setVisible(true)
    end
  else
    fullmapView = false
    minimapWidget:setParent(minimapWindow:getChildById('contentsPanel'))
    minimapWidget:fill('parent')
    minimapWindow:show()
    minimapWidget:setAlternativeWidgetsVisible(false)
    local player = g_game.getLocalPlayer()
    if player then
      minimapWidget:setCameraPosition(player:getPosition())
    end

    build_minimap_style("refresh")
  end

  local zoom = oldZoom or 0
  local pos = oldPos or minimapWidget:getCameraPosition()
  oldZoom = minimapWidget:getZoom()
  oldPos = minimapWidget:getCameraPosition()
  minimapWidget:setZoom(zoom)
  minimapWidget:setCameraPosition(pos)
end

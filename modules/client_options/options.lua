local defaultOptions = {
  layout = DEFAULT_LAYOUT, -- set in init.lua
  vsync = true,
  showFps = false,
  showPing = false,
  advancedTooltip = true,
  fullscreen = false,
  classicView = not g_app.isMobile(),
  cacheMap = g_app.isMobile(),
  classicControl = false,
  smartWalk = false,
  dash = false,
  raritySelect = 3,
  autoChaseOverride = true,
  showStatusMessagesInConsole = false,
  swapCtrlBehavior = false,
  showEventMessagesInConsole = true,
  showInfoMessagesInConsole = false,
  showTimestampsInConsole = false,
  showLevelsInConsole = false,
  automaticallyOpenPMs = false,
  showPrivateMessagesOnScreen = true,
  rightPanels = 1,
  leftPanels = 0,
  containerPanel = 5,
  backgroundFrameRate = 60,
  enableAudio = true,
  enableMusicSound = false,
  musicSoundVolume = 100,
  botSoundVolume = 100,
  enableLights = true,
  floorFading = true,
  crosshair = 0,
  ambientLight = 0,
  optimizationLevel = 1,
  displayNames = true,
  displayHealth = true,
  displayMana = false,
  displayHealthOnTop = false,
  showHealthManaCircle = false,
  hidePlayerBars = true,
  highlightThingsUnderCursor = false,
  topHealtManaBar = false,
  displayText = true,
  dontStretchShrink = false,
  turnDelay = 30,
  hotkeyDelay = 30,
    
  wsadWalking = false,
  walkFirstStepDelay = 200,
  walkTurnDelay = 100,
  walkStairsDelay = 50,
  walkTeleportDelay = 200,
  walkCtrlTurnDelay = 150,

  topBar = false,

  actionbar1 = false,
  actionbar2 = false,
  actionbar3 = false,
  actionbar4 = false,
  actionbar5 = false,
  actionbar6 = false,
  actionbar7 = false,
  actionbar8 = false,
  actionbar9 = false,

  actionbarLock = false,

  profile = 1,
  antialiasing = true,
  shiftRighClickFollowCreature = false,
  openContainerInNewWindow = false,
  showTopLeftPanel = false,
  showTopRightPanel = false,
  hdmodeBox = true,
}
local optionsWindow
local options = {}
local extraOptions = {}
local generalPanel
local interfacePanel
local consolePanel
local graphicsPanel
local audioPanel
local customPanel
local extrasPanel
local audioButton

local fpsEvent

local optionsChangeHistory = {}

function init()
  for k,v in pairs(defaultOptions) do
    g_settings.setDefault(k, v)
    options[k] = v
  end
  for _, v in ipairs(g_extras.getAll()) do
	  extraOptions[v] = g_extras.get(v)
    g_settings.setDefault("extras_" .. v, extraOptions[v])
  end

  optionsWindow = g_ui.displayUI('options')
  optionsWindow:hide()

  g_keyboard.bindKeyDown('Ctrl+Shift+F', function() toggleOption('fullscreen') end)
  g_keyboard.bindKeyDown('Ctrl+N', toggleDisplays)
  
  generalPanel = g_ui.displayUI('game')
  generalPanel:hide()
  
  optionsWindow.General.onClick = function(self)
    hide()
    generalPanel:setVisible(true)
  end
  
  interfacePanel = g_ui.displayUI('interface')
  interfacePanel:hide()
  
  optionsWindow.Interface.onClick = function(self)
    hide()
    interfacePanel:setVisible(true)
  end
  
  consolePanel = g_ui.displayUI('console')
  consolePanel:hide()
  
  optionsWindow.Console.onClick = function(self)
    hide()
    consolePanel:setVisible(true)
  end
  
  graphicsPanel = g_ui.displayUI('graphics')
  graphicsPanel:hide()
  
  optionsWindow.Graphics.onClick = function(self)
    hide()
    graphicsPanel:setVisible(true)
  end
  
  local function updateFps()
    graphicsPanel:recursiveGetChildById("currentFrameRateLabel"):setText(string.format("Current Framerate: %d", g_app.getFps()))
  end
  
  fpsEvent = cycleEvent(updateFps, 500)
  
  audioPanel = g_ui.displayUI('audio')
  audioPanel:hide()

  g_keyboard.bindKeyDown('Ctrl+Enter', toggle)

  audioButton = modules.client_topmenu.addLeftButton('audioButton', tr('Audio'), '/images/topbuttons/audio', function() toggleOption('enableAudio') end, nil, nil, "Audio")
  audioButton:hide()
  addEvent(function() 
      setup()
      if g_game.isOnline() then
        online()
      end 
  end)
  
  connect(g_game, { onGameStart = online,
                     onGameEnd = offline })    
  optionsChangeHistory = {}                
end

function terminate()
  disconnect(g_game, { onGameStart = online,
                     onGameEnd = offline })  
  g_keyboard.unbindKeyDown('Ctrl+Enter')
  g_keyboard.unbindKeyDown('Ctrl+Shift+F')
  g_keyboard.unbindKeyDown('Ctrl+N')
  optionsWindow:destroy()
  generalPanel:destroy()
  graphicsPanel:destroy()
  consolePanel:destroy()
  interfacePanel:destroy()
  audioButton:destroy()
  removeEvent(fpsEvent)
end

function setup()
  -- load options
  for k,v in pairs(defaultOptions) do
    if type(v) == 'boolean' then
      setOption(k, g_settings.getBoolean(k), true)
    elseif type(v) == 'number' then
      setOption(k, g_settings.getNumber(k), true)
    elseif type(v) == 'string' then
      setOption(k, g_settings.getString(k), true)
    end
  end
  optionsChangeHistory = {} 
end

function toggle()
  if optionsWindow:isVisible() then
    hide()
  else
    show()
  end
end

function show()
  optionsWindow:show()
  optionsWindow:raise()
  optionsWindow:focus()
  modules.game_sidemenu.getOptionsButton():setOn(true)
end

function hide()
  optionsWindow:hide()
  modules.game_sidemenu.getOptionsButton():setOn(false)
end

function toggleDisplays()
  if options['displayNames'] and options['displayHealth'] and options['displayMana'] then
    setOption('displayNames', false)
  elseif options['displayHealth'] then
    setOption('displayHealth', false)
    setOption('displayMana', false)
  else
    if not options['displayNames'] and not options['displayHealth'] then
      setOption('displayNames', true)
    else
      setOption('displayHealth', true)
      setOption('displayMana', true)
    end
  end
end

function toggleOption(key) 
  setOption(key, not getOption(key))
end

function setOption(key, value, force, canRevert)
  if extraOptions[key] ~= nil then
    g_extras.set(key, value)
    g_settings.set("extras_" .. key, value)
    if key == "debugProxy" and modules.game_proxy then
      if value then
        modules.game_proxy.show()
      else
        modules.game_proxy.hide()      
      end
    end
    return
  end
  
  if modules.game_interface == nil then
    return
  end

  if not force and options[key] == value then return end
  local gameMapPanel = modules.game_interface.getMapPanel()

  if key == 'vsync' then
    g_window.setVerticalSync(value)
  elseif key == 'showFps' then
    modules.client_topmenu.setFpsVisible(value)
    if modules.game_stats and modules.game_stats.ui.fps then
      modules.game_stats.ui.fps:setVisible(value)
    end
  elseif key == 'showPing' then
    modules.client_topmenu.setPingVisible(value)
    if modules.game_stats and modules.game_stats.ui.ping then
      modules.game_stats.ui.ping:setVisible(value)
    end
  elseif key == 'fullscreen' then
    g_window.setFullscreen(value)
  elseif key == 'enableAudio' then
    if g_sounds ~= nil then
      g_sounds.setAudioEnabled(value)
    end
    if value then
      audioButton:setIcon('/images/topbuttons/audio')
    else
      audioButton:setIcon('/images/topbuttons/audio_mute')
    end
  elseif key == 'enableMusicSound' then
    if g_sounds ~= nil then
      g_sounds.getChannel(SoundChannels.Music):setEnabled(value)
    end
  elseif key == 'musicSoundVolume' then
    if g_sounds ~= nil then
      g_sounds.getChannel(SoundChannels.Music):setGain(value/100)
    end
    audioPanel:recursiveGetChildById('musicSoundVolumeLabel'):setText(tr('Music volume: %d', value))
  elseif key == 'hdmodeBox' then
    g_sprites.setHDMode(value)
  elseif key == 'botSoundVolume' then
    if g_sounds ~= nil then
      g_sounds.getChannel(SoundChannels.Bot):setGain(value/100)
    end
    audioPanel:recursiveGetChildById('botSoundVolumeLabel'):setText(tr('Bot sound volume: %d', value))    
  elseif key == 'showHealthManaCircle' then
    modules.game_healthinfo.enableCircles(value)
  elseif key == 'backgroundFrameRate' then
    local text, v = value, value
    if value <= 0 or value >= 201 then text = 'max' v = 0 end
    graphicsPanel:recursiveGetChildById('backgroundFrameRateLabel'):setText(tr('Ajust Framerate Limit: %s', text))
    g_app.setMaxFps(v)
  elseif key == 'enableLights' then
    gameMapPanel:setDrawLights(value and options['ambientLight'] < 100)
  elseif key == 'floorFading' then
    gameMapPanel:setFloorFading(value and 500 or 0)
    -- interfacePanel:recursiveGetChildById('floorFadingLabel'):setText(tr('Floor fading: %s ms', value))
  elseif key == 'crosshair' then
    if value == 1 then
      gameMapPanel:setCrosshair("")    
    elseif value == 2 then
      gameMapPanel:setCrosshair("/images/crosshair/default.png")        
    elseif value == 3 then
      gameMapPanel:setCrosshair("/images/crosshair/full.png")    
    end
  elseif key == 'ambientLight' then
    gameMapPanel:setMinimumAmbientLight(value/100)
    gameMapPanel:setDrawLights(options['enableLights'] and value < 100)
  elseif key == 'optimizationLevel' then
    g_adaptiveRenderer.setLevel(value - 2)
  elseif key == 'displayNames' then
    gameMapPanel:setDrawNames(value)
  elseif key == 'displayHealth' then
    gameMapPanel:setDrawHealthBars(value)
  elseif key == 'displayMana' then
    gameMapPanel:setDrawManaBar(value)
  elseif key == 'displayHealthOnTop' then
    gameMapPanel:setDrawHealthBarsOnTop(false) --value
  elseif key == 'hidePlayerBars' then
    gameMapPanel:setDrawPlayerBars(true)
  elseif key == 'topHealtManaBar' then
    -- modules.game_healthinfo.topHealthBar:setVisible(value)
    -- modules.game_healthinfo.topManaBar:setVisible(value)
  elseif key == 'displayText' then
    gameMapPanel:setDrawTexts(value)
  elseif key == 'dontStretchShrink' then
    addEvent(function()
      modules.game_interface.updateStretchShrink()
    end)
  elseif key == 'dash' then
    if value then
      g_game.setMaxPreWalkingSteps(2)
    else 
      g_game.setMaxPreWalkingSteps(1)    
    end
  elseif key == 'wsadWalking' then
    if modules.game_console and modules.game_console.consoleToggleChat:isChecked() ~= value then
      modules.game_console.consoleToggleChat:setChecked(value)
    end
  elseif key == 'hotkeyDelay' then
    generalPanel:recursiveGetChildById('hotkeyDelayLabel'):setText(tr('Hotkey delay: %s ms', value))  
  elseif key == 'walkFirstStepDelay' then
    generalPanel:recursiveGetChildById('walkFirstStepDelayLabel'):setText(tr('Walk delay after first step: %s ms', value))  
  elseif key == 'walkTurnDelay' then
    generalPanel:recursiveGetChildById('walkTurnDelayLabel'):setText(tr('Walk delay after turn: %s ms', value))  
  elseif key == 'walkStairsDelay' then
    generalPanel:recursiveGetChildById('walkStairsDelayLabel'):setText(tr('Walk delay after floor change: %s ms', value))  
  elseif key == 'walkTeleportDelay' then
    generalPanel:recursiveGetChildById('walkTeleportDelayLabel'):setText(tr('Walk delay after teleport: %s ms', value))  
  elseif key == 'walkCtrlTurnDelay' then
    generalPanel:recursiveGetChildById('walkCtrlTurnDelayLabel'):setText(tr('Walk delay after ctrl turn: %s ms', value))  
  elseif key == "rightPanels" then
    value = math.max(1, value)
    value = math.min(4, value)
    interfacePanel:recursiveGetChildById('rightCount'):setText(value)
    interfacePanel:recursiveGetChildById('showTopRightPanel'):setEnabled(value >= 2)
    interfacePanel:recursiveGetChildById('backRight'):setEnabled(value > 1)
    interfacePanel:recursiveGetChildById('frontRight'):setEnabled(value < 4)
  elseif key == "leftPanels" then
    value = math.max(0, value)
    value = math.min(4, value)
    interfacePanel:recursiveGetChildById('leftCount'):setText(value)  
    interfacePanel:recursiveGetChildById('showTopLeftPanel'):setEnabled(value >= 2)
    interfacePanel:recursiveGetChildById('backLeft'):setEnabled(value > 0)
    interfacePanel:recursiveGetChildById('frontLeft'):setEnabled(value < 4)
  elseif key == "antialiasing" then
    g_app.setSmooth(value)
  elseif key == "showTopLeftPanel" then
      local panelCount = #modules.game_interface.getLeftPanelList()

      if panelCount < 2 then
        value = false
        interfacePanel:recursiveGetChildById('showTopLeftPanel'):setEnabled(false)
      else
        interfacePanel:recursiveGetChildById('showTopLeftPanel'):setEnabled(true)
      end
  elseif key == "showTopRightPanel" then
      local panelCount = #modules.game_interface.getRightPanelList()

      if panelCount < 2 then
        value = false
        interfacePanel:recursiveGetChildById('showTopRightPanel'):setEnabled(false)
      else
        interfacePanel:recursiveGetChildById('showTopRightPanel'):setEnabled(true)
      end
  end

  -- change value for keybind updates
  for _,panel in pairs({interfacePanel, consolePanel, graphicsPanel, generalPanel}) do
    local widget = panel:recursiveGetChildById(key)
    if widget then
      if widget:getStyle().__class == 'UICheckBox' then
        widget:setChecked(value)
      elseif widget:getStyle().__class == 'UIScrollBar' then
        widget:setValue(value)
      elseif widget:getStyle().__class == 'UIComboBox' then
        if type(value) == "string" then
          widget:setCurrentOption(value, true)
          break
        end
        if value == nil or value < 1 then 
          value = 1
        end
        if widget.currentIndex ~= value then
          widget:setCurrentIndex(value, true)
        end
      end      
      break
    end
  end

  if canRevert and not optionsChangeHistory[key] then
     optionsChangeHistory[key] = {options[key], value}
  end
  
  g_settings.set(key, value)
  options[key] = value

  if key == "showTimestampsInConsole" then
    modules.game_console.reload_timestamp()
  end

  if key == "profile" then
    modules.client_profiles.onProfileChange()
  end

  if key == "raritySelect" then
    reload_item_rarity()
  end
  
  if key == 'classicView' or key == "showTopRightPanel" or key == "showTopLeftPanel" or key == 'rightPanels' or key == 'leftPanels' or key == 'cacheMap' then
    modules.game_interface.refreshViewMode()    
  end
end

function doRevertChangeOptions()
    for key, option in pairs(optionsChangeHistory) do
      setOption(key, option[1])
    end
    optionsChangeHistory = {}
end

function cancelEdits(widget)
    widget:setVisible(false)
    doRevertChangeOptions()
    show()
end

function okEdits(self)
    show()
    optionsChangeHistory = {}
    self:setVisible(false)
end

function getOption(key)
  return options[key]
end

function addTab(name, panel, icon)
  -- optionsTabBar:addTab(name, panel, icon)
end

function addButton(name, func, icon)
  -- optionsTabBar:addButton(name, func, icon)
end

-- hide/show

function online()
    setup()
    optionsChangeHistory = {}
  -- g_app.setSmooth(g_settings.getBoolean("antialiasing"))
end

function offline()
    optionsChangeHistory = {}
end

-- classic view

-- graphics

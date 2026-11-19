---@diagnostic disable: lowercase-global

local showOptionsButton, sidemenuWindow, inventoryWindow

function getStoreButton()
    return sidemenuWindow.storeButton 
end

function getToggleOptionsButton()
    return sidemenuWindow.optionsButton
end

function getLeftButtonsPanel()
    return sidemenuWindow:recursiveGetChildById("leftSideButtonsPanel")
end

function getRightButtonsPanel()
    return sidemenuWindow:recursiveGetChildById("rightSideButtonsPanel")
end

function getExitButton()
    return modules.game_inventory.getInventoryWindow():recursiveGetChildById("logoutButton")
end

function addSideButton(id, description, icon, panel)

    local button = g_ui.createWidget("SideButton", panel)

    button:setId(id)
    button:setTooltip(description)
    button:setOn(false)

    button:setImageSource(icon)
    button.onMouseRelease = function(widget, mousePos, mouseButton)
        if widget:containsPoint(mousePos) and mouseButton ~= MouseMidButton and mouseButton ~= MouseTouch then
            widget.callback()
            return true
        end
    end
    button.onTouchRelease = button.onMouseRelease
    return button
end

local buttons = {}

function getSideButtons()
    return buttons
end

function getOptionsButton()
    return modules.game_inventory.getInventoryWindow():recursiveGetChildById("optionsButton")
end

function getHotkeysButton()
    return buttons.hotkeys
end

function getSkillsButton()
    return buttons.skills
end

function getBattleButton()
    return buttons.battle
end

function getInventoryButton()
    return buttons.inventory
end

function getUnjustifiedButton()
    return buttons.unjustified
end

function getVipListButton()
    return buttons.viplist
end

function getBestiaryButton()
    return buttons.bestiary
end

--function getDummyButton()
  --  return buttons.dummy
--end

function getBattlepassButton()
    return buttons.battlepass
end

-- pbOT
function getTasksButton()
    return buttons.tasks
end

function getTasksTrackerButton()
    return buttons.taskstracker
end

function getForgeButton()
    return buttons.forge
end

function getCraftingButton()
    return buttons.crafting
end

-- pbOT: mods (characterstats, guild, marketplace...) adicionam botao aqui,
-- ja que o topmenu fica oculto durante o jogo no layout do TVP
function addModuleButton(id, description, icon, callback)
    if not sidemenuWindow then return nil end
    local panel = getLeftButtonsPanel()
    local old = panel:getChildById(id)
    if old then old:destroy() end
    local button = addSideButton(id, description, icon, panel)
    button.callback = function() if callback then callback() end end
    button.onDestroy = function() scheduleEvent(updateSize, 1) end
    scheduleEvent(updateSize, 1)
    return button
end

function init()

    -- g_ui.importStyle('sidemenu')

    sidemenuWindow = g_ui.loadUI('sidemenu', modules.game_interface.getRightPanel())
    sidemenuWindow.bottomResizeBorder:disable()
    
    showOptionsButton = getToggleOptionsButton()
    showOptionsButton.onClick = toggle
    
    g_keyboard.bindKeyDown('Ctrl+Shift+Enter', toggle)
    
    --TODO: questlog    
    buttons.skills = addSideButton("skillsButton", tr('Skills (Ctrl+S)'), "/images/topbuttons/sidepanel/skills", getLeftButtonsPanel())
    buttons.battle = addSideButton("battleButton", tr('Battle') .. ' (Ctrl+B)', "/images/topbuttons/sidepanel/battle", getLeftButtonsPanel())	
    buttons.viplist = addSideButton("viplistButton", tr('VIP List') .. ' (Ctrl+P)', "/images/topbuttons/sidepanel/viplist", getLeftButtonsPanel())
    buttons.unjustified = addSideButton("unjustifiedButton", tr('Unjustified Points (Ctrl+I)'), "/images/topbuttons/sidepanel/unjustifiedpoints", getLeftButtonsPanel())
    buttons.analyzer = addSideButton("analyzerButton", "Analytics", "/images/topbuttons/sidepanel/analyzers", getLeftButtonsPanel())
    buttons.bestiary = addSideButton("bestiaryButton", "Bestiary (Ctrl+)", "/images/topbuttons/sidepanel/bestiary", getLeftButtonsPanel())
	--buttons.dummy = addSideButton("dummyButton", tr('Dummy') .. ' (Ctrl+)', "/images/topbuttons/sidepanel/dummy", getLeftButtonsPanel())
    buttons.battlepass = addSideButton("battlepass", "BattlePass (Ctrl+)", "/images/topbuttons/sidepanel/battlepass", getLeftButtonsPanel())

    -- pbOT: Battlepass/Bestiary dependem do servidor TVP -> ocultos; Tasks/Forge do servidor pbOT
    buttons.battlepass:hide()
    buttons.bestiary:hide()
    buttons.tasks = addSideButton("tasksButton", tr('Tasks'), "/images/topbuttons/sidepanel/tasks", getLeftButtonsPanel())
    buttons.taskstracker = addSideButton("tasksTrackerButton", tr('Tasks Tracker'), "/images/topbuttons/sidepanel/taskstracker", getLeftButtonsPanel())
    buttons.forge = addSideButton("forgeButton", tr('Exaltation Forge'), "/images/topbuttons/sidepanel/forge", getLeftButtonsPanel())
    buttons.crafting = addSideButton("craftingButton", tr('Crafting'), "/images/topbuttons/sidepanel/crafting", getLeftButtonsPanel())
    buttons.crafting.callback = function()
        if modules.game_crafting and modules.game_crafting.toggle then modules.game_crafting.toggle() end
    end
    buttons.tasks.callback = function()
        if modules.game_tasks and modules.game_tasks.toggleTasksPanel then modules.game_tasks.toggleTasksPanel() end
    end
    buttons.taskstracker.callback = function()
        if modules.game_tasks and modules.game_tasks.toggleTracker then modules.game_tasks.toggleTracker() end
    end
    buttons.forge.callback = function()
        if modules.game_forge and modules.game_forge.toggle then modules.game_forge.toggle() end
    end

    buttons.hotkeys = addSideButton("hotkeysButton", tr('Hotkeys') .. ' (Ctrl+K)', "/images/topbuttons/sidepanel/hotkeys", getRightButtonsPanel())

    buttons.bestiary.callback = function()
        modules.game_bestiary.toggleTracker()
    end

    buttons.battlepass.callback = function()
        modules.game_battlepass.m_BattlepassFunctions.open()
    end
    
    buttons.hotkeys.callback = function()
        modules.game_hotkeys.toggle()
    end


    buttons.skills.callback = function()
        modules.game_skills.toggle()
    end

    buttons.battle.callback = function()
        modules.game_battle.toggle()
    end

   -- buttons.dummy.callback = function()
    --    modules.game_dummy.toggle()
    --end

    buttons.unjustified.callback = function()
        modules.game_whiteredskull.toggle()
    end

    buttons.viplist.callback = function()
        modules.game_viplist.toggle()
    end

    getStoreButton().onClick = function()
        modules.game_store.toggle()
    end

    buttons.analyzer.callback = function()
        local menu = g_ui.createWidget('PopupMenu')
        menu:addOption("Loot Analyser (Ctrl+U)", function() modules.game_analyserloot.toggle() end)
        menu:addSeparator()
        menu:addOption("Experience Analyser (Ctrl+X)", function() modules.game_analyserexp.toggle() end)
        menu:display()
    end

    enable()
    connect(g_game, { onGameStart = onGameStart, onGameEnd = onGameEnd })
end

function onGameStart()
    local settings = tonumber(g_settings.get('SideMenuOption'))
    if settings then
        if settings == 1 then
            disable()
        else
            enable()
        end
    else
        enable()
    end
end

function onGameEnd()

end

function terminate()
    g_keyboard.unbindKeyDown('Ctrl+Shift+Enter')
    disconnect(g_game, { onGameStart = onGameStart, onGameEnd = onGameEnd })
    sidemenuWindow:destroy()
end

-- pbOT: altura cresce conforme o numero de botoes visiveis (5 por linha, celula 20 + 2)
local function getButtonRows()
    local visible = 0
    for _, child in ipairs(getLeftButtonsPanel():getChildren()) do
        if child:isExplicitlyVisible() then visible = visible + 1 end
    end
    return math.max(2, math.ceil(visible / 5))
end

function updateSize()
    if not sidemenuWindow or showOptionsButton:isOn() then return end
    local rows = getButtonRows()
    getLeftButtonsPanel():setHeight(rows * 22 + 4)
    sidemenuWindow:setHeight(73 + (rows - 2) * 22)
end

function enable()
    showOptionsButton:setOn(false)
    getLeftButtonsPanel():setVisible(true)
    getRightButtonsPanel():setVisible(true)
    g_settings.set('SideMenuOption', 2)
    sidemenuWindow:setHeight(73)
    updateSize()
end

function disable()
    -- default parameters
    showOptionsButton:setOn(true)
    getLeftButtonsPanel():setVisible(false)
    getRightButtonsPanel():setVisible(false)
    sidemenuWindow:setHeight(26)
    g_settings.set('SideMenuOption', 1)
end

function force_status()
    if showOptionsButton:isOn() then
        --TODO: Fix pressed animation
        enable()
    else
        disable()
    end
end

function toggle()
    if showOptionsButton:isOn() then
        --TODO: Fix pressed animation
        enable()
    else
        disable()
    end
end
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

    buttons.hotkeys = addSideButton("hotkeysButton", tr('Hotkeys') .. ' (Ctrl+K)', "/images/topbuttons/sidepanel/hotkeys", getRightButtonsPanel())

    buttons.bestiary.callback = function()
        modules.game_bestiary.toggleTracker()
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

function enable()
    showOptionsButton:setOn(false)
    getLeftButtonsPanel():setVisible(true)
    getRightButtonsPanel():setVisible(true)
    g_settings.set('SideMenuOption', 2)
    sidemenuWindow:setHeight(73)
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
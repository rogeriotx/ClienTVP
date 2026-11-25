---@diagnostic disable: undefined-field, need-check-nil, undefined-global
local chaseModeRadioGroup

InventorySlotStyles = {
    [InventorySlotHead] = "HeadSlot",
    [InventorySlotNeck] = "NeckSlot",
    [InventorySlotBack] = "BackSlot",
    [InventorySlotBody] = "BodySlot",
    [InventorySlotRight] = "RightSlot",
    [InventorySlotLeft] = "LeftSlot",
    [InventorySlotLeg] = "LegSlot",
    [InventorySlotFeet] = "FeetSlot",
    [InventorySlotFinger] = "FingerSlot",
    [InventorySlotAmmo] = "AmmoSlot"
}

Icons = {
    [65536 * 2 ^ SkullWhite] = {tooltip = tr('You have attacked an unmarked player'), path = '/images/game/states/white_skull', id = 'skull_white'},
    [65536 * 2 ^ SkullGreen] = {tooltip = tr('You are a member of a party'), path = '/images/game/states/skull_party_member', id = 'skull_green'},
    [65536 * 2 ^ SkullRed] = {tooltip = tr('You have killed too many unmarked player'), path = '/images/game/states/red_skull', id = 'skull_red'},
    [PlayerStates.Swords] = {tooltip = tr('You may not logout during a fight'), path = '/images/game/states/logout_block', id = 'condition_logout_block'},
    [PlayerStates.Poison] = {tooltip = tr('You are poisoned'), path = '/images/game/states/poisoned', id = 'condition_poisoned'},
    [PlayerStates.Burn] = {tooltip = tr('You are burning'), path = '/images/game/states/burning', id = 'condition_burning'},
    [PlayerStates.Energy] = {tooltip = tr('You are electrified'), path = '/images/game/states/electrified', id = 'condition_electrified'},
    [PlayerStates.Drunk] = {tooltip = tr('You are drunk'), path = '/images/game/states/drunk', id = 'condition_drunk'},
    [PlayerStates.ManaShield] = {tooltip = tr('You are protected by a magic shield'), path = '/images/game/states/magic_shield', id = 'condition_magic_shield'},
    [PlayerStates.Paralyze] = {tooltip = tr('You are paralysed'), path = '/images/game/states/slowed', id = 'condition_slowed'},
    [PlayerStates.Haste] = {tooltip = tr('You are hasted'), path = '/images/game/states/haste', id = 'condition_haste'},
    [PlayerStates.Drowning] = {tooltip = tr('You are drowning'), path = '/images/game/states/drowning', id = 'condition_drowning'},
    [PlayerStates.Freezing] = {tooltip = tr('You are freezing'), path = '/images/game/states/freezing', id = 'condition_freezing'},
    [PlayerStates.Dazzled] = {tooltip = tr('You are dazzled'), path = '/images/game/states/dazzled', id = 'condition_dazzled'},
    [PlayerStates.Cursed] = {tooltip = tr('You are cursed'), path = '/images/game/states/cursed', id = 'condition_cursed'},
    [PlayerStates.PartyBuff] = {tooltip = tr('You are strengthened'), path = '/images/game/states/strengthened', id = 'condition_strengthened'},
    [PlayerStates.PzBlock] = {tooltip = tr('You may not logout or enter a protection zone'), path = '/images/game/states/protection_zone_block', id = 'condition_protection_zone_block'},
    [PlayerStates.Pz] = {tooltip = tr('You are within a protection zone'), path = '/images/game/states/protection_zone', id = 'condition_protection_zone'},
    [PlayerStates.Bleeding] = {tooltip = tr('You are bleeding'), path = '/images/game/states/bleeding', id = 'condition_bleeding'},
    [PlayerStates.Hungry] = {tooltip = tr('You are hungry'), path = '/images/game/states/hungry', id = 'condition_hungry'},
}

local inventoryWindow = nil
local capLabel = nil
local soulLabel = nil

local fightOffensiveBox = nil
local fightBalancedBox = nil
local fightDefensiveBox = nil
local standModeBox = nil
local chaseModeBox = nil
local safeFightButton = nil

local whiteDoveBox = nil
local whiteHandBox = nil
local yellowHandBox = nil
local redFistBox = nil
local fightModeRadioGroup = nil
local inventoryMinimized = false
local sidebuttonsMinimized = false
local capPanel, conditionPanel, miniwindowScrollBar

local inventoryButton
local purseButton = nil

function toggle()
    if inventoryButton:isOn() then
        inventoryWindow:close()
    else
        inventoryWindow:open()
    end
end

function init()
    inventoryWindow = g_ui.loadUI('inventory', modules.game_interface.getRightPanel())
    inventoryWindow:disableResize()
    inventoryButton = modules.client_topmenu.addRightGameToggleButton('inventoryButton', tr('Inventory') .. ' (Ctrl+Y)',
        '/images/topbuttons/inventory', toggle, false, 4, tr('Inventory'))
    inventoryButton:setVisible(false)
    purseButton = inventoryWindow:recursiveGetChildById('purseButton')
    purseButton.onClick = function()
    local purse = g_game.getLocalPlayer():getInventoryItem(InventorySlotPurse)
        if purse then
          g_game.use(purse)
        end
    end

    -- g_keyboard.bindKeyDown('Ctrl+Y', toggle)

    inventoryWindow.topButton = inventoryButton

    fightOffensiveBox = inventoryWindow:recursiveGetChildById('fightOffensiveBox')
    fightBalancedBox = inventoryWindow:recursiveGetChildById('fightBalancedBox')
    fightDefensiveBox = inventoryWindow:recursiveGetChildById('fightDefensiveBox')
    
    chaseModeBox = inventoryWindow:recursiveGetChildById('chaseModeBox')
    standModeBox = inventoryWindow:recursiveGetChildById('standModeBox')
    safeFightButton = inventoryWindow:recursiveGetChildById('safeFightBox')
    
    whiteDoveBox = inventoryWindow:recursiveGetChildById('whiteDoveBox')
    whiteHandBox = inventoryWindow:recursiveGetChildById('whiteHandBox')
    yellowHandBox = inventoryWindow:recursiveGetChildById('yellowHandBox')
    redFistBox = inventoryWindow:recursiveGetChildById('redFistBox')
    
    fightModeRadioGroup = UIRadioGroup.create()
    fightModeRadioGroup:addWidget(fightOffensiveBox)
    fightModeRadioGroup:addWidget(fightBalancedBox)
    fightModeRadioGroup:addWidget(fightDefensiveBox)
    
    chaseModeRadioGroup = UIRadioGroup.create()
    chaseModeRadioGroup:addWidget(standModeBox)
    chaseModeRadioGroup:addWidget(chaseModeBox)
    
    connect(fightModeRadioGroup, {onSelectionChange = onSetFightMode})
    connect(chaseModeRadioGroup, {onSelectionChange = onSetChaseMode})
    connect(safeFightButton, {onCheckChange = onSetSafeFight})
    
    connect(LocalPlayer, {onInventoryChange = onInventoryChange,
        onFreeCapacityChange = onFreeCapacityChange,
        onSoulChange = onSoulChange,
        onStatesChange = onStatesChange,
        onSkullChange = updateCreatureSkull,
    })
    
    connect(g_game, {onGameStart = refresh,
        onGameEnd = offline,
        onFightModeChange = update,
        onChaseModeChange = update,
        onSafeFightChange = update,
        onPVPModeChange = update,
        onWalk = check,
        onAutoWalk = check
    })

    capLabel = inventoryWindow:recursiveGetChildById('capLabel')
    soulLabel = inventoryWindow:recursiveGetChildById('soulLabel')
    
    inventoryWindow:recursiveGetChildById('minimizeButton').onClick = function()
        local lastCombatControls = g_settings.getNode('LastCombatControls')
        local char = g_game.getCharacterName()
        if lastCombatControls[char] then
            onInventoryMinimize(lastCombatControls[char].inventoryMinimize)
        end
    end
    
    connect(inventoryWindow, {
        onMinimize = function()
            onInventoryMinimize(true)
        end,
        onMaximize = function()
            onInventoryMinimize(false)
        end
    })
    
    for k, v in pairs(Icons) do
        g_textures.preload(v.path)
    end
    
    onInventoryMinimize(false)
    
    if g_game.isOnline() then
        local localPlayer = g_game.getLocalPlayer()
        onFreeCapacityChange(localPlayer, localPlayer:getFreeCapacity())
        onSoulChange(localPlayer, localPlayer:getSoul())
        onStatesChange(localPlayer, localPlayer:getStates(), 0)
        updateCreatureSkull(localPlayer, localPlayer:getSkull())
        local lastCombatControls = g_settings.getNode('LastCombatControls')
		local char = g_game.getCharacterName()

        if lastCombatControls[char] then
            onInventoryMinimize(lastCombatControls[char].inventoryMinimize)
        end
    end
    
    refresh()
end

function terminate()
    if g_game.isOnline() then
        offline()
    end

    -- g_keyboard.unbindKeyDown('Ctrl+Y')
    
    disconnect(LocalPlayer, {onInventoryChange = onInventoryChange,
        onFreeCapacityChange = onFreeCapacityChange,
        onSoulChange = onSoulChange,
        onStatesChange = onStatesChange,
        onSkullChange = updateCreatureSkull
    })
    
    disconnect(g_game, {onGameStart = refresh,
        onGameEnd = offline,
        onFightModeChange = update,
        onChaseModeChange = update,
        onSafeFightChange = update,
        onPVPModeChange = update,
        onWalk = check,
        onAutoWalk = check})
    
    inventoryWindow:destroy()
    
    fightModeRadioGroup:destroy()
end

function update()
    local fightMode = g_game.getFightMode()
    if fightMode == FightOffensive then
        fightModeRadioGroup:selectWidget(fightOffensiveBox)
    elseif fightMode == FightBalanced then
        fightModeRadioGroup:selectWidget(fightBalancedBox)
    else
        fightModeRadioGroup:selectWidget(fightDefensiveBox)
    end
    
    local chaseMode = g_game.getChaseMode()
    if chaseMode == 1 then
        chaseModeRadioGroup:selectWidget(chaseModeBox, true)
    else
        chaseModeRadioGroup:selectWidget(standModeBox, true)
    end
    
    local safeFight = g_game.isSafeFight()
    safeFightButton:setChecked(not safeFight)

end

function check()
    if modules.client_options.getOption('autoChaseOverride') then
        if g_game.isAttacking() and g_game.getChaseMode() == ChaseOpponent then
            local distance = getDistanceBetween(g_game.getLocalPlayer():getPosition(), g_game.getAttackingCreature():getPosition())
            if distance > 1 then
                g_game.setChaseMode(DontChase)
            end
        end
    end
end

function refresh()
    inventoryWindow:setup()
    local player = g_game.getLocalPlayer()
    for i = InventorySlotFirst, InventorySlotLast do
        if g_game.isOnline() then
            onInventoryChange(player, i, player:getInventoryItem(i))
        else
            onInventoryChange(player, i, nil)
        end
    end
    
    if player then
        local char = g_game.getCharacterName()
        
        local lastCombatControls = g_settings.getNode('LastCombatControls')
        if not table.empty(lastCombatControls) then
            if lastCombatControls[char] then
                g_game.setFightMode(lastCombatControls[char].fightMode)
                g_game.setChaseMode(lastCombatControls[char].chaseMode)
                g_game.setSafeFight(lastCombatControls[char].safeFight)
                if lastCombatControls[char].pvpMode then
                    g_game.setPVPMode(lastCombatControls[char].pvpMode)
                end
                onInventoryMinimize(lastCombatControls[char].inventoryMinimize)
            end
        else
            onInventoryMinimize(false)
        end
    end
    update()
end

function toggleIcon(bitChanged)
    if not Icons[bitChanged] then return end -- bit de estado sem icone definido
    local content = inventoryWindow:recursiveGetChildById('conditionPanel')
    if not content then return end
    local icon = content:getChildById(Icons[bitChanged].id)
    if icon then
        icon:destroy()
        updateIconsPositions()
    else
        icon = loadIcon(bitChanged)
        icon:setParent(content)
        updateIconsPositions()
    end
end

function loadIcon(bitChanged)
    local icon = g_ui.createWidget('ConditionWidget')
    icon:setId(Icons[bitChanged].id)
    icon:setImageSource(Icons[bitChanged].path)
    icon:setTooltip(Icons[bitChanged].tooltip)
    return icon
end

-- 8.0: faixa horizontal (layout horizontalBox no otui); apenas ordena os icones
local condition_order = {
    condition_protection_zone = 1, condition_protection_zone_block = 2, condition_logout_block = 3,
    skull_white = 4, skull_green = 4, skull_red = 4,
    condition_poisoned = 5, condition_burning = 6, condition_electrified = 7, condition_drowning = 8,
    condition_freezing = 9, condition_dazzled = 10, condition_cursed = 11, condition_bleeding = 12,
    condition_drunk = 13, condition_magic_shield = 14, condition_slowed = 15, condition_haste = 16,
    condition_strengthened = 17, condition_hungry = 18,
}

function updateIconsPositions()
    local panel = inventoryWindow:recursiveGetChildById('conditionPanel')
    if not panel then return end
    local children = panel:getChildren()
    table.sort(children, function(a, b)
        return (condition_order[a:getId()] or 99) < (condition_order[b:getId()] or 99)
    end)
    for i, widget in ipairs(children) do
        panel:moveChildToIndex(widget, i)
    end
end

function save()
    local lastCombatControls = g_settings.getNode('LastCombatControls')
    if not lastCombatControls then
        lastCombatControls = {}
    end
    
    local player = g_game.getLocalPlayer()
    if player then
        local char = g_game.getCharacterName()
        lastCombatControls[char] = {
            fightMode = g_game.getFightMode(),
            chaseMode = g_game.getChaseMode(),
            safeFight = g_game.isSafeFight(),
            inventoryMinimize = inventoryMinimized
        }

        
        if g_game.getFeature(GamePVPMode) then
            lastCombatControls[char].pvpMode = g_game.getPVPMode()
        end
        -- save last combat control settings
        g_settings.setNode('LastCombatControls', lastCombatControls)
    end
end

function offline()
    inventoryWindow:recursiveGetChildById('conditionPanel'):destroyChildren()
    save()
end

function onStatesChange(localPlayer, now, old)
    if now == old then return end
    
    local bitsChanged = bit32.bxor(now, old)
    for i = 1, 32 do
        local pow = math.pow(2, i - 1)
        if pow > bitsChanged then break end
        local bitChanged = bit32.band(bitsChanged, pow)
        if bitChanged ~= 0 then
            toggleIcon(bitChanged)
        end
    end
    save()
end

-- hooked events
function onInventoryChange(player, slot, item, oldItem)
    local itemWidget = inventoryWindow:getChildById('slot' .. slot)
    if not itemWidget then
        return
    end
    if item then
        itemWidget:setStyle('Item')
        itemWidget:setItem(item)
    else
        itemWidget:setStyle(InventorySlotStyles[slot])
        itemWidget:setItem(nil)
        if itemWidget.updateItemOverlays then itemWidget:updateItemOverlays() end
    end
end

function onSoulChange(player, soul)
    if soulLabel and soul then soulLabel:setText(soul) end
end

function onFreeCapacityChange(player, freeCapacity)
    if not freeCapacity then return end
    
    freeCapacity = freeCapacity * 100

    if freeCapacity > 99999 then
        freeCapacity = math.min(9999, math.floor(freeCapacity / 1000)) .. "k"
    elseif freeCapacity > 999 then
        freeCapacity = math.floor(freeCapacity)
    elseif freeCapacity > 99 then -- so não acontece quando real cap < 1
        -- freeCapacity = math.floor(freeCapacity * 10) / 10
    end
    capLabel:setText(freeCapacity)
end

function onSetFightMode(self, selectedFightButton)
    if selectedFightButton == nil then return end
    local buttonId = selectedFightButton:getId()
    local fightMode
    
    if buttonId == 'fightOffensiveBox' then
        fightMode = FightOffensive
    elseif buttonId == 'fightBalancedBox' then
        fightMode = FightBalanced
    else
        fightMode = FightDefensive
    end
    g_game.setFightMode(fightMode)
    save()
end

function onSetChaseMode(self, selectedChaseButton)
    if selectedChaseButton == nil then return end
    
    local chaseMode
    
    local buttonId = selectedChaseButton:getId()
    
    if buttonId == 'standModeBox' then
        chaseMode = DontChase
    elseif buttonId == 'chaseModeBox' then
        chaseMode = ChaseOpponent
    end
    
    g_game.setChaseMode(chaseMode)
    save()
end


function onSetSafeFight(self, checked)
    g_game.setSafeFight(not checked)
    save()
end

function onSetPVPMode(self, selectedPVPButton)
    save()
    if selectedPVPButton == nil then
        return
    end
    
    local buttonId = selectedPVPButton:getId()
    local pvpMode = PVPWhiteDove
    if buttonId == 'whiteDoveBox' then
        pvpMode = PVPWhiteDove
    elseif buttonId == 'whiteHandBox' then
        pvpMode = PVPWhiteHand
    elseif buttonId == 'yellowHandBox' then
        pvpMode = PVPYellowHand
    elseif buttonId == 'redFistBox' then
        pvpMode = PVPRedFist
    end
    
    g_game.setPVPMode(pvpMode)
end

function getPVPBoxByMode(mode)
    local widget = nil
    if mode == PVPWhiteDove then
        widget = whiteDoveBox
    elseif mode == PVPWhiteHand then
        widget = whiteHandBox
    elseif mode == PVPYellowHand then
        widget = yellowHandBox
    elseif mode == PVPRedFist then
        widget = redFistBox
    end
    return widget
end

function updateCreatureSkull(creature, skullId)
    local player = g_game.getLocalPlayer()
    if creature ~= player then return end
    local skullIcons = {2, 3, 4}
    for k, v in pairs(skullIcons) do
        local content = inventoryWindow:recursiveGetChildById('conditionPanel')
        local icon = content:getChildById(Icons[65536 * 2 ^ v].id)
        if icon then
            icon:destroy()
            updateIconsPositions()
        end
    end
    toggleSkullIcon(skullId)
end

function toggleSkullIcon(skullId)
    if skullId == 0 or not Icons[65536 * 2 ^ skullId] then return end
    local content = inventoryWindow:recursiveGetChildById('conditionPanel')
    local icon = content:getChildById(Icons[65536 * 2 ^ skullId].id)
    if not icon then
        icon = loadIcon(65536 * 2 ^ skullId)
        icon:setParent(content)
        updateIconsPositions()
    end
end

function getInventoryWindow()
    return inventoryWindow
end

function adjustWindowHeight()
    local height = inventoryWindow.defaultHeight

    inventoryWindow:setHeight(height)
end

function onInventoryMinimize(value)
    capPanel = inventoryWindow:recursiveGetChildById('capPanel')
    conditionPanel = inventoryWindow:recursiveGetChildById('conditionPanel')
    miniwindowScrollBar = inventoryWindow:recursiveGetChildById('miniwindowScrollBar')
    miniwindowScrollBar:hide()
    
    inventoryWindow.defaultHeight = value and 64 or 170
    adjustWindowHeight()


    local widget_positions = {
        ["minimized"] = {
            ["minimizeButton"] = {left = 2+8, top = 8-4},
            ["lockButton"] = {left = 2+8, top = 21-4},
            ["capPanel"] = {left = 2+22, top = 3, height = 19},
            ["conditionpluscap"] = {left = 2+22, top = 3, height = 38},

            ["fightOffensiveBox"] = {left = 2+66+4-12, top = 8-4},
            ["fightBalancedBox"] = {left = 2+86+4-12, top = 8-4},
            ["fightDefensiveBox"] = {left = 2+106+4-12, top = 8-4},
            
            ["standModeBox"] = {left = 2+66+4-12, top = 30-4},
            ["chaseModeBox"] = {left = 2+86+4-12, top = 30-4},
            ["safeFightBox"] = {left = 2+106+4-12, top = 30-4},

            ["conditionPanel"] = { left = 2 + 22, top = 49, width = 96 },
            ["soulPanel"] = { left = 2 + 22, top = 22, height = 19 },

            ["slot1"] = {left = 2+0, top = 1-4, invisible = true}, -- head slot
            ["slot2"] = {left = 2+0, top = 1-4, invisible = true}, -- head slot
            ["slot3"] = {left = 2+0, top = 1-4, invisible = true}, -- head slot
            ["slot4"] = {left = 2+0, top = 1-4, invisible = true}, -- head slot
            ["slot5"] = {left = 2+0, top = 1-4, invisible = true}, -- head slot
            ["slot6"] = {left = 2+0, top = 1-4, invisible = true}, -- head slot
            ["slot7"] = {left = 2+0, top = 1-4, invisible = true}, -- head slot
            ["slot8"] = {left = 2+0, top = 1-4, invisible = true}, -- head slot
            ["slot9"] = {left = 2+0, top = 1-4, invisible = true}, -- head slot
            ["purseButton"] = {left = 0, top = -10, invisible = true}, -- head slot
            ["slot10"] = {left = 2+128+4+2, top = 13-4, invisible = true}, -- ammo slot
            ["optionsButton"] = { left = 128, top = 128, invisible = true }, -- ammo slot
            ["stopButton"] = { left = 128, top = 4, invisible = false },    -- ammo slot
            ["logoutButton"] = { left = 128, top = 26, invisible = false }, -- ammo slot
        }, 
        ["open"] = {
            ["minimizeButton"] = {left = 2+8, top = 8-4},
            ["lockButton"] = {left = 2+22, top = 8-4},
            ["conditionpluscap"] = {left = 2+0, top = 1-4, invisible = true},
            ["purseButton"] = {left = 0, top = 0}, -- head slot
            
            ["fightOffensiveBox"] = {left = 2+124, top = 22-4+1},
            ["fightBalancedBox"] = {left = 2+124, top = 42-4+1},
            ["fightDefensiveBox"] = {left = 2+124, top = 62-4+1},
            
            ["standModeBox"] = {left = 2+147, top = 22-4+1},
            ["chaseModeBox"] = {left = 2+147, top = 42-4+1},
            ["safeFightBox"] = {left = 2+147, top = 62-4+1},
            
            ["conditionPanel"] = { left = 2 + 8, top = 151, width = 108 },
            ["soulPanel"] = { left = 2 + 8, top = 128, height = 21 },
            ["capPanel"] = { left = 2 + 82, top = 128, height = 21 },
            
            ["slot1"] = {left = 2+45, top = 8-4}, -- head slot
            ["slot2"] = {left = 2+8, top = 22-4}, -- neck slot
            ["slot3"] = {left = 2+82, top = 22-4}, -- backpack slot
            ["slot4"] = {left = 2+45, top = 45-4}, -- body slot
            ["slot5"] = {left = 2+82, top = 59-4}, -- right slot
            ["slot6"] = {left = 2+8, top = 59-4}, -- left slot
            ["slot7"] = {left = 2+45, top = 82-4}, -- leg slot
            ["slot8"] = {left = 2+45, top = 119-4}, -- feet slot
            ["slot9"] = { left = 2 + 8, top = 96 - 4 },    -- head slot
            ["slot10"] = { left = 2 + 82, top = 96 - 4 },  -- ammo slot
            ["stopButton"] = { left = 126, top = 78+3 },    -- ammo slot
            ["optionsButton"] = { left = 126, top = 93+12 }, -- ammo slot
            ["logoutButton"] = { left = 126, top = 127 },                   -- ammo slot
        }
    }
    
    for widget, margin in pairs(widget_positions[value and "minimized" or "open"]) do
        inventoryWindow:recursiveGetChildById(widget):setMargin(margin.top, 0, 0, margin.left)
        if margin.width then
            inventoryWindow:recursiveGetChildById(widget):setWidth(margin.width)
        end
        if margin.height then
            inventoryWindow:recursiveGetChildById(widget):setHeight(margin.height)
        end
        if margin.invisible and margin.invisible == true then
            inventoryWindow:recursiveGetChildById(widget):setVisible(false)
        else
            inventoryWindow:recursiveGetChildById(widget):setVisible(true)
        end
    end
    
    if value then -- minimized
        inventoryWindow.capPanel:setImageColor("alpha")
        inventoryWindow.soulPanel:setImageColor("alpha")
    else -- open
        inventoryWindow.capPanel:setImageColor("white")
        inventoryWindow.soulPanel:setImageColor("white")
    end
    
    
    inventoryMinimized = value
end

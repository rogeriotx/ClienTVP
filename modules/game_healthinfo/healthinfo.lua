local healthInfoWindow, overlay, healthInfoButton
local healthCircleFront, manaCircleFront, healthCircle, manaCircle, manaBar,
      healthBar, healthLabel, manaLabel

function enableCircles(value)
    healthCircle:setVisible(value)
    healthCircleFront:setVisible(value)
    manaCircle:setVisible(value)
    manaCircleFront:setVisible(value)
end

function toggle()
    if not healthInfoButton then return end
    if healthInfoButton:isOn() then
        healthInfoWindow:close()
    else
        healthInfoWindow:open()
    end
end

function init()

    g_healthBars.addHealthBackground("/images/bars/health1", -2, -2, 0, 2, 4)
    g_healthBars.addManaBackground("/images/bars/mana1", -2, -2, 0, 2, 4)

    healthInfoWindow = g_ui.loadUI('healthinfo',
                                   modules.game_interface.getRightPanel())
    healthInfoWindow:disableResize()
    healthInfoWindow.miniwindowScrollBar:setWidth(0)
    
    healthInfoButton = modules.client_topmenu.addRightGameToggleButton(
        'healthInfoButton', tr('Health Information (Ctrl+H)'),
        '/images/topbuttons/healthinfo', toggle, false, 3, tr('Health Info'))
        
    healthInfoWindow.topButton = healthInfoButton
    healthInfoButton:setVisible(false)

    -- g_keyboard.bindKeyDown('Ctrl+H', toggle)
    overlay = g_ui.createWidget('HealthOverlay', modules.game_interface.getMapPanel())

    healthCircle = overlay.healthCircle
    manaCircle = overlay.manaCircle
    healthCircleFront = overlay.healthCircleFront
    manaCircleFront = overlay.manaCircleFront

    manaBar = healthInfoWindow:recursiveGetChildById('manaBar')
    healthBar = healthInfoWindow:recursiveGetChildById('healthBar')
    healthLabel = healthInfoWindow:recursiveGetChildById('healthLabel')
    manaLabel = healthInfoWindow:recursiveGetChildById('manaLabel')

    healthInfoWindow:setup()

    if g_app.isMobile() then
        healthInfoWindow:close()
    end

    connect(LocalPlayer,
            {onHealthChange = onHealthChange, onManaChange = onManaChange})

    connect(g_game, {onGameEnd = offline})

    if g_game.isOnline() then
        local localPlayer = g_game.getLocalPlayer()
        onHealthChange(localPlayer, localPlayer:getHealth(),
                       localPlayer:getMaxHealth())
        onManaChange(localPlayer, localPlayer:getMana(),
                     localPlayer:getMaxMana())
    end
end

function terminate()
    healthInfoWindow:destroy()
    overlay:destroy()
    -- g_keyboard.unbindKeyDown('Ctrl+H')
    if healthInfoButton then healthInfoButton:destroy() end

    disconnect(LocalPlayer,
               {onHealthChange = onHealthChange, onManaChange = onManaChange})
    disconnect(g_game, {onGameEnd = offline})
end

function round(val, decimal)
    if (decimal) then
        return math.floor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
    else
        return math.floor(val + 0.5)
    end
end

function onHealthChange(localPlayer, health, maxHealth)

    if health > maxHealth then maxHealth = health end

    local healthPercent = ((health * 100) / maxHealth)

    if healthPercent == 0 then
        healthPercent = 0
    end

    local globalWidth = healthBar:getImageTextureWidth() -- 100%
    local sizePercent = ((healthPercent * globalWidth) / 100) -- x%
    local percent = round(sizePercent, decimal)
    healthBar:setWidth(percent)
    healthBar:setImageClip(torect('0 0 ' .. tonumber(percent) .. ' 0'))
    healthBar:setTooltip(tr("Your character health is %d out of %d.", health, maxHealth))

    local Yhppc = math.floor(208 * (1 - (healthPercent / 100)))
    local rect = {x = 0, y = Yhppc, width = 63, height = 208 - Yhppc + 1}
    healthCircleFront:setImageClip(rect)
    healthCircleFront:setImageRect(rect)

    if healthPercent > 94 then
        healthCircleFront:setImageColor("#00b700")
    elseif healthPercent > 59 then
        healthCircleFront:setImageColor("#60c060")
    elseif healthPercent > 29 then
        healthCircleFront:setImageColor("#c0c000")
    elseif healthPercent > 9 then
        healthCircleFront:setImageColor("#c03030")
    elseif healthPercent > 3 then
        healthCircleFront:setImageColor("#b30000")
    else
        healthCircleFront:setImageColor("#590000")
    end

    healthLabel:setText(health)
end

function onManaChange(localPlayer, mana, maxMana)
    if mana > maxMana then maxMana = mana end
    local manaPercent = ((mana * 100) / maxMana)

    if not maxMana or maxMana == 0 then
        manaPercent = 100
    end

    manaPercent = math.min(math.max(manaPercent, 0), 100)

    local Ymppc = math.floor(208 * (1 - (manaPercent / 100)))
    local rect = {x = 0, y = Ymppc, width = 63, height = 208 - Ymppc + 1}
    manaCircleFront:setImageClip(rect)
    manaCircleFront:setImageRect(rect)

    manaBar:setTooltip(tr('Your character mana is %d out of %d.', mana, maxMana))
    manaBar:setValue(mana, 0, maxMana)

    local globalWidth = manaBar:getImageTextureWidth() -- 100%

    local sizePercent = ((manaPercent * globalWidth) / 100) -- x%
    local percent = round(sizePercent, decimal)
    manaBar:setWidth(percent)
    manaBar:setImageClip(torect('0 0 ' .. tonumber(percent) .. ' 0'))

    manaLabel:setText(mana)
end

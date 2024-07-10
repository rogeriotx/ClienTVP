--[[
    {
        "unlockTime":0,
        "player":[],
        "red":{
            "week":5,
            "month":10,
            "day":3
        }
    }

    {
        "unlockTime":1706898839,
        "infightTime":1706898839,
        "player":{
            "3":1704306827,
            "4":1704306839,
            "5":1704306851,
            "2":1704306807
        },
        "red":{
            "week":5,
            "month":10,
            "day":3
        },
        "ban":{
            "week":10,
            "month":20,
            "day":6
        },
    }
]]

local window
local statistics

function onMiniWindowClose()
    modules.game_sidemenu.getUnjustifiedButton():setOn(false)
end

function toggle()
    if modules.game_sidemenu.getUnjustifiedButton():isOn() then
        window:close()
    else
        window:open()
    end
end

local function formatTimeDuration(duration)
    local days = math.floor(duration / (24 * 60 * 60))
    duration = duration % (24 * 60 * 60)
    local hours = math.floor(duration / (60 * 60))
    duration = duration % (60 * 60)
    local minutes = math.floor(duration / 60)
    duration = duration % 60
    local seconds = duration

    local parts = {}
    table.insert(parts, days .. " D")
    table.insert(parts, ", " .. hours .. " H")
    table.insert(parts, ", ".. minutes .. " M")
    table.insert(parts, ", ".. seconds .. " S")

    return table.concat(parts)
end

local function update_white_skull_message()
    
    if not statistics then
        return true
    end

    if not g_game.isOnline() then
        return true
    end

    local now = os.time() 
    local dt = statistics.unlockTime - now
    
    --local whiteSkullTicks = statistics.conditionTicks - os.time()
    
    window.contentsPanel.timeStatus:setVisible(dt > 0) -- or whiteSkullTicks > 0
    
    if dt > 0 then
        window.contentsPanel.timeStatus:setText(formatTimeDuration(dt))
    --elseif whiteSkullTicks > 0 then
    --    window.contentsPanel.timeStatus:setText(formatTimeDuration(whiteSkullTicks))
    end

    local lastDay = 0
    local lastWeek = 0
    local lastMonth = 0
    local eligibleMurders = 0
    local dayTimestamp = now - (24 * 60 * 60)
    local weekTimestamp = now - (7 * 24 * 60 * 60)
    local monthTimestamp = now - (30 * 24 * 60 * 60)

    for _, timestamp in pairs(statistics.player) do
        if timestamp > dayTimestamp then
            lastDay = lastDay + 1
        end

        if timestamp > weekTimestamp then
            lastWeek = lastWeek + 1
        end

        eligibleMurders = lastMonth + 1

        if timestamp <= monthTimestamp then
            eligibleMurders = lastMonth
        end

        lastMonth = eligibleMurders
    end

    --TODO: Se o jogador já estiver com red skull, então todas as infos diária, semanal e mensal fazem contabilização para o estágio de ban
    --TODO: Adicionar um esquema de cores para vermelho quanto mais próximo de atingir
    local missing_last_day = statistics.red.day - lastDay
    local missing_last_week = statistics.red.week - lastWeek
    local missing_last_month = statistics.red.month - lastMonth

    if (missing_last_day <= 0 or missing_last_week <= 0 or missing_last_month <= 0) then
        missing_last_day = statistics.ban.day - lastDay
        missing_last_week = statistics.ban.week - lastWeek
        missing_last_month = statistics.ban.month - lastMonth

        window.contentsPanel.dailyDesc:setText(string.format("[%d of %d]", lastDay, statistics.ban.day))
        window.contentsPanel.weeklyDesc:setText(string.format("[%d of %d]", lastWeek, statistics.ban.week))
        window.contentsPanel.monthlyDesc:setText(string.format("[%d of %d]", lastMonth, statistics.ban.month))

        if missing_last_day > 0 then
            window.contentsPanel.SkullSlot01:setTooltip("UPs gained in 24h. " .. missing_last_day .. " full kills left to ban.")
        else
            window.contentsPanel.SkullSlot01:setTooltip("UPs gained in 24h. You got banned.")
        end


        local percent = 100 * math.min(1.0, lastDay / statistics.ban.day)
        window.contentsPanel.SkullProgressbar01.progress:setPercent(percent)
        window.contentsPanel.SkullProgressbar01.progress:setVisible(percent > 0)

        if missing_last_week > 0 then
            window.contentsPanel.SkullSlot02:setTooltip("UPs gained in 7 days. " ..
                missing_last_week .. " full kills left to ban.")
        else
            window.contentsPanel.SkullSlot02:setTooltip("UPs gained in 7 days. You got banned.")
        end

        local percent = 100 * math.min(1.0, lastWeek / statistics.ban.week)
        window.contentsPanel.SkullProgressbar02.progress:setPercent(percent)
        window.contentsPanel.SkullProgressbar02.progress:setVisible(percent > 0)

        if missing_last_month > 0 then
            window.contentsPanel.SkullSlot03:setTooltip("UPs gained in 30 days. " ..
                missing_last_month .. " full kills left to ban.")
        else
            window.contentsPanel.SkullSlot03:setTooltip("UPs gained in 30 days. You got banned.")
        end

        local percent = 100 * math.min(1.0, lastMonth / statistics.ban.month)
        window.contentsPanel.SkullProgressbar03.progress:setPercent(percent)
        window.contentsPanel.SkullProgressbar03.progress:setVisible(percent > 0)

        window.contentsPanel.SkullSlot01.skull:setImageSource("/images/game/skulls/skull_black")
        window.contentsPanel.SkullSlot02.skull:setImageSource("/images/game/skulls/skull_black")
        window.contentsPanel.SkullSlot03.skull:setImageSource("/images/game/skulls/skull_black")

        local p = window.contentsPanel.SkullProgressbar01.progress
        if missing_last_day <= 1 then -- cor clara
            p:setBackgroundColor("#b30000")
        elseif missing_last_day == 2 then
            p:setBackgroundColor("#c0c000")
        elseif missing_last_day <= 4 then -- 3 e 4
            p:setBackgroundColor("#60c060")
        else -- 5 e 6
            p:setBackgroundColor("#00b700")
        end

        local p = window.contentsPanel.SkullProgressbar02.progress
        if missing_last_week <= 1 then -- cor clara
            p:setBackgroundColor("#b30000")
        elseif missing_last_week == 2 then
            p:setBackgroundColor("#c0c000")
        elseif missing_last_week <= 6 then -- 3, 4, 5
            p:setBackgroundColor("#60c060") -- 3 a 9
        else--if missing_last_week <= 8 then
            p:setBackgroundColor("#00b700")
        end

        local p = window.contentsPanel.SkullProgressbar03.progress
        if missing_last_month <= 1 then -- cor clara
            p:setBackgroundColor("#b30000")
        elseif missing_last_month == 2 then
            p:setBackgroundColor("#c0c000")
        elseif missing_last_month >= 10 then
            p:setBackgroundColor("#00b700")
        else
            p:setBackgroundColor("#60c060") -- 3 a 9
        end
        
    else
        window.contentsPanel.dailyDesc:setText(string.format("[%d of %d]", lastDay, statistics.red.day))
        window.contentsPanel.weeklyDesc:setText(string.format("[%d of %d]", lastWeek, statistics.red.week))
        window.contentsPanel.monthlyDesc:setText(string.format("[%d of %d]", lastMonth, statistics.red.month))

        if missing_last_day > 0 then
            window.contentsPanel.SkullSlot01:setTooltip("UPs gained in 24h. " .. missing_last_day .. " full kills left.")
        else
            window.contentsPanel.SkullSlot01:setTooltip("UPs gained in 24h. You reached at least " ..
            statistics.red.day .. " full kills.")
        end

        local percent = 100 * math.min(1.0, lastDay / statistics.red.day)
        window.contentsPanel.SkullProgressbar01.progress:setPercent(percent)
        window.contentsPanel.SkullProgressbar01.progress:setVisible(percent > 0)
        if missing_last_week > 0 then
            window.contentsPanel.SkullSlot02:setTooltip("UPs gained in 7 days. " ..
            missing_last_week .. " full kills left.")
        else
            window.contentsPanel.SkullSlot02:setTooltip("UPs gained in 7 days. You reached at least " ..
            statistics.red.week .. " full kills.")
        end

        local percent = 100 * math.min(1.0, lastWeek / statistics.red.week)
        window.contentsPanel.SkullProgressbar02.progress:setPercent(percent)
        window.contentsPanel.SkullProgressbar02.progress:setVisible(percent > 0)
        if missing_last_month > 0 then
            window.contentsPanel.SkullSlot03:setTooltip("UPs gained in 30 days. " ..
            missing_last_month .. " full kills left.")
        else
            window.contentsPanel.SkullSlot03:setTooltip("UPs gained in 30 days. You reached at least " ..
            statistics.red.month .. " full kills.")
        end

        local percent = 100 * math.min(1.0, lastMonth / statistics.red.month)
        window.contentsPanel.SkullProgressbar03.progress:setPercent(percent)
        window.contentsPanel.SkullProgressbar03.progress:setVisible(percent > 0)

        window.contentsPanel.SkullSlot01.skull:setImageSource("/images/game/skulls/skull_red")
        window.contentsPanel.SkullSlot02.skull:setImageSource("/images/game/skulls/skull_red")
        window.contentsPanel.SkullSlot03.skull:setImageSource("/images/game/skulls/skull_red")

        local p = window.contentsPanel.SkullProgressbar01.progress
        
        if missing_last_day <= 1 then -- cor clara
            p:setBackgroundColor("#b30000")
        elseif missing_last_day == 2 then
            p:setBackgroundColor("#c0c000")
        else
            p:setBackgroundColor("#00b700")
        end

        local p = window.contentsPanel.SkullProgressbar02.progress
        if missing_last_week <= 1 then -- cor clara
            p:setBackgroundColor("#b30000")
        elseif missing_last_week == 2 then
            p:setBackgroundColor("#c0c000")
        elseif missing_last_week == 3 then -- 3
            p:setBackgroundColor("#60c060")
        else--if missing_last_week == 4 then -- 4
            p:setBackgroundColor("#00b700")
        end

        local p = window.contentsPanel.SkullProgressbar03.progress
        if missing_last_month <= 1 then -- cor clara
            p:setBackgroundColor("#b30000")
        elseif missing_last_month == 2 then
            p:setBackgroundColor("#c0c000")
        elseif missing_last_month <= 5 then -- 3, 4, 5
            p:setBackgroundColor("#60c060")
        else--if missing_last_month <= 10 then -- 6, 7, 8, 9
            p:setBackgroundColor("#00b700")
        end
    end

    --TODO: Colocar blink da storage

    local localPlayer = g_game.getLocalPlayer()
    onSkullChange(localPlayer, localPlayer:getSkull())
end

local whiteSkullCycleEvent


function init()

    connect(LocalPlayer, { onSkullChange = onSkullChange })
    connect(g_game, {
        onGameStart = refresh
    })

    -- button = modules.client_topmenu.addRightGameToggleButton('skullsButton', tr('Unjustified Points (Ctrl+I)'), '/images/topbuttons/unjustifiedpoints', toggle, true, 1, tr('Unjustified Points'))
    
    window = g_ui.loadUI('skulls', modules.game_interface.getRightPanel())
    window.topButton = modules.game_sidemenu.getUnjustifiedButton()
    window:disableResize()
    g_keyboard.bindKeyDown('Ctrl+I', toggle)
    window.miniwindowScrollBar:setWidth(0)
    whiteSkullCycleEvent = cycleEvent(update_white_skull_message, 1000)

    ProtocolGame.registerExtendedOpcode(110, function(protocol, code, buffer)
        statistics = json.decode(buffer)
        
        local offset = os.time() - statistics.now
        
        statistics.unlockTime = statistics.unlockTime + offset
        for key, timestamp in pairs(statistics.player) do
            statistics.player[key] = timestamp + offset
        end

        -- statistics.conditionTicks = statistics.conditionTicks + os.time()
        
        local localPlayer = g_game.getLocalPlayer()
        onSkullChange(localPlayer, localPlayer:getSkull())
    end)

    refresh()
end

function refresh()
    window:setup()

    if g_game.isOnline() then
        onGameStart()
    end
end

function terminate()
    g_keyboard.unbindKeyDown('Ctrl+I')
    removeEvent(whiteSkullCycleEvent)
    ProtocolGame.unregisterExtendedOpcode(110)
    disconnect(LocalPlayer, { onSkullChange = onSkullChange })
    disconnect(g_game, {
        onGameStart = refresh
    })
end

function onSkullChange(localPlayer, skull)
    if skull == SkullRed then
        window.contentsPanel.CentralSkullSlot:setTooltip("You currently have red skull.")
    elseif skull == SkullWhite then
        window.contentsPanel.CentralSkullSlot:setTooltip("You currently have white skull.")
    else
        window.contentsPanel.CentralSkullSlot:setTooltip("You currently have no skull.")
    end
    window.contentsPanel.CentralSkullSlot.skull:setImageSource(getSkullImagePath((skull)))
end

function reset_module()
    window.contentsPanel.timeStatus:setText("")
    window.contentsPanel.SkullSlot01:setTooltip("UPs gained in 24h. 3 full kills left.")
    window.contentsPanel.SkullSlot02:setTooltip("UPs gained in 7 days. 5 full kills left.")
    window.contentsPanel.SkullSlot03:setTooltip("UPs gained in 30 days. 10 full kills left.")
    window.contentsPanel.SkullProgressbar01.progress:setPercent(0)
    window.contentsPanel.SkullProgressbar01.progress:setVisible(false)
    window.contentsPanel.SkullProgressbar02.progress:setPercent(0)
    window.contentsPanel.SkullProgressbar02.progress:setVisible(false)
    window.contentsPanel.SkullProgressbar03.progress:setPercent(0)
    window.contentsPanel.SkullProgressbar03.progress:setVisible(false)
    onSkullChange(0, 0)
end

function onGameStart()
    reset_module()
    local protocolGame = g_game.getProtocolGame()
    if protocolGame then
        protocolGame:sendExtendedOpcode(110, "s")
    end
end
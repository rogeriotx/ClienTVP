G_BESTIARY = {}

local CONFIG = {
    CLIENT_OPCODE = 91,
    SERVER_OPCODE = 92
}

local BACK_TYPE = {
    NONE = 0,
    CATEGORIES = 1,
    CREATURES = 2,
    CREATURE = 3,
    SEARCH = 4
}

local difficultys = {
    [1] = "Harmless",
    [2] = "Trivial",
    [3] = "Easy",
    [4] = "Medium",
    [5] = "Hard"
}

local lootTypes = {
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Semi-Rare",
    [4] = "Very Rare"
}

local occurrences = {
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Very Rare"
}

local categories = {
    [1] = {class = "amphibic", image = "images/creatures/amphibic"},
    [2] = {class = "aquatic", image = "images/creatures/aquatic"},
    [3] = {class = "bird", image = "images/creatures/bird"},
    [4] = {class = "construct", image = "images/creatures/construct"},
    [5] = {class = "dragon", image = "images/creatures/dragon"},
    [6] = {class = "elemental", image = "images/creatures/elemental"},
    [7] = {class = "extra dimensional", image = "images/creatures/extra_dimensional"},
    [8] = {class = "fey", image = "images/creatures/fey"},
    [9] = {class = "giant", image = "images/creatures/giant"},
    [10] = {class = "human", image = "images/creatures/human"},
    [11] = {class = "humanoid", image = "images/creatures/humanoid"},
    [12] = {class = "lycanthrope", image = "images/creatures/lycanthrope"},
    [13] = {class = "magical", image = "images/creatures/magical"},
    [14] = {class = "mammal", image = "images/creatures/mammal"},
    [15] = {class = "plant", image = "images/creatures/plant"},
    [16] = {class = "slime", image = "images/creatures/slime"},
    [17] = {class = "undead", image = "images/creatures/undead"},
    [18] = {class = "vermin", image = "images/creatures/vermin"},
    [19] = {class = "reptile", image = "images/creatures/reptile"},
    [20] = {class = "immortal", image = "images/creatures/immortals"},
    [21] = {class = "demon", image = "images/creatures/immortals"}
}

function formatWidgetName(name)
    local maxLen = 16
    if name:len() > maxLen then
        return name:sub(1, maxLen) .. "..."
    end

    return name
end

function closeBestiaryWindow()
    G_BESTIARY.UI:hide()
    modules.game_interface.getRootPanel():focus()
    G_BESTIARY.Tracker.UI.bestiaryWindowButton:setOn(false)
    resetAllWidgetOpacity(G_BESTIARY.UI)
end

function openBestiaryWindow()
    G_BESTIARY.Tracker.UI.bestiaryWindowButton:setOn(true)
    G_BESTIARY.UI:show()
    G_BESTIARY.UI:lock()

    G_BESTIARY.UI.panel.creature:setVisible(false)
    G_BESTIARY.UI.panel.categories:setVisible(true)
    G_BESTIARY.UI.closeButton.backType = BACK_TYPE.NONE

    if G_BESTIARY.needUpdateData() then
        G_BESTIARY.categories = {}
        G_BESTIARY.send("requestData")
    end
end

function toggle()

    if G_BESTIARY.Tracker.UI.bestiaryWindowButton:isOn() then
        closeBestiaryWindow()
    else
        openBestiaryWindow()
    end
end

local function getKillStage(kills, stages)
    if kills >= stages[3] then
        return 3
    elseif kills >= stages[2] then
        return 2
    elseif kills >= stages[1] then
        return 1
    end
    return 0
end

local function formatFileName(str) 
    if string.find(str, " ") then
        return string.gsub(str, " ", "_")
    else
        return str
    end
end

local function getElementColor(element)
	if element == 66 then
		return "white"
	end
	return "red"
end

local function updateBestiaryKill(name, kills)
    for _, data in pairs(G_BESTIARY.data) do
        for _, creature in ipairs(data) do
            if creature.name == name then
                if creature.kills <= creature.stages[3] then
                    creature.kills = kills
                end
                return true
            end
        end
    end
    return false
end

local function updateBestiaryCreature(data)
    for i, t_data in pairs(G_BESTIARY.data) do
        for y, creature in ipairs(t_data) do
            if creature.name == data.name then
                G_BESTIARY.data[i][y] = data
                return true
            end
        end
    end
    return false
end

local function getCreatureByName(name)
    for _, data in pairs(G_BESTIARY.data) do
        for _, creature in ipairs(data) do
            if creature.name:lower() == name:lower() then
                return creature
            end
        end
    end
    return nil
end

local function getCreatureClass(name)
    local creature = getCreatureByName(name) 
    if creature then
        return creature.class
    end
    return nil
end


local function getCategoryByName(name)
    for _, categorie in ipairs(categories) do
        if categorie.class == name then
            return categorie
        end
    end
    return nil
end

local function getRarity(chance)
    if chance <= 1000 then
        return 4
    elseif chance <= 5000 then
        return 3
    elseif chance <= 20000 then
        return 2
    else
        return 1
    end
end

G_BESTIARY.init = function()
    G_BESTIARY.UI = g_ui.displayUI("bestiary", modules.game_interface.getRightPanel())

    G_BESTIARY.Tracker = {}
    G_BESTIARY.Tracker.UI = g_ui.loadUI("bestiary_tracker", modules.game_interface.getRightPanel())
    G_BESTIARY.Tracker.UI:setContentMinimumHeight(43)

    G_BESTIARY.trackerData = {}
    G_BESTIARY.data = {}
    G_BESTIARY.categories = {}
    G_BESTIARY.playerName = ""

    G_BESTIARY.Tracker.UI.topButton = modules.game_sidemenu.getBestiaryButton()
    G_BESTIARY.Tracker.UI.closeButton = toggleTracker
    
    G_BESTIARY.define()

    G_BESTIARY.UI:hide()
    G_BESTIARY.UI.closeButton.backType = BACK_TYPE.NONE

    ProtocolGame.registerExtendedJSONOpcode(CONFIG.SERVER_OPCODE, G_BESTIARY.reciver)
    connect(g_game, {onGameStart = G_BESTIARY.onStart, onGameEnd = G_BESTIARY.onEnd})
    
    if(g_game.isOnline()) then
        G_BESTIARY.onStart()
    end
end

G_BESTIARY.terminate = function()
    disconnect(g_game, {onGameStart = G_BESTIARY.onStart, onGameEnd = G_BESTIARY.onEnd})
    ProtocolGame.unregisterExtendedJSONOpcode(CONFIG.SERVER_OPCODE)
    G_BESTIARY.UI:destroy()
    G_BESTIARY.UI = nil

    G_BESTIARY.Tracker.UI:destroy()
    G_BESTIARY.Tracker.UI = nil
    G_BESTIARY.playerName = nil
end

G_BESTIARY.onStart = function()
    G_BESTIARY.playerName =  g_game.getLocalPlayer():getName()
    G_BESTIARY.send("requestData")
    G_BESTIARY.load()
    G_BESTIARY.Tracker.UI:setup()
	G_BESTIARY.send("requestCharms")
end

G_BESTIARY.onEnd = function()
    if G_BESTIARY.UI:isVisible() then
        closeBestiaryWindow()
    end
    G_BESTIARY.save()
	for _, charm in pairs(G_BESTIARY.UI:recursiveGetChildById('charmsList'):getChildren()) do
		charm:destroy()
	end
end

G_BESTIARY.define = function()
    G_BESTIARY.resetDifficulty = function()
        for i = 1, 5 do
            G_BESTIARY.UI.panel.creature.difficultyList[i]:setImageSource("images/icons/difficulty-inactive")
        end
    end

    G_BESTIARY.resetOccurrence = function()
        for i = 1, 4 do
            G_BESTIARY.UI.panel.creature.occurrenceList[i]:setImageSource("images/icons/occurrence-inactive")
        end
    end

    G_BESTIARY.selectCreature = function(widget)
        G_BESTIARY.UI.panel.creature.lootPanel.list:destroyChildren()
        G_BESTIARY.UI.panel.categories:setVisible(false)
        G_BESTIARY.UI.panel.creature:setVisible(true)

        G_BESTIARY.resetDifficulty()
        G_BESTIARY.resetOccurrence()

        local creatureWindow = G_BESTIARY.UI.panel.creature
        local creature = widget:getParent().object
        local stage = getKillStage(creature.kills, creature.stages)
        local playerName = g_game.getLocalPlayer():getName()

        G_BESTIARY.selectedCreature = creature

        if not G_BESTIARY.trackerData then
            G_BESTIARY.trackerData = {}
        end

        if not G_BESTIARY.trackerData[creature.name] then
            G_BESTIARY.trackerData[creature.name] = false
        end

        creatureWindow.progressFillLeft.fill:setImageSource("")
        creatureWindow.progressFillMiddle.fill:setImageSource("")
        creatureWindow.progressFillRight.fill:setImageSource("")

        creatureWindow.progressFillLeft.fill:setTooltip("")
        creatureWindow.progressFillMiddle.fill:setTooltip("")
        creatureWindow.progressFillRight.fill:setTooltip("")

        creatureWindow:setText(creature.name)
        creatureWindow.trackKills:setChecked(G_BESTIARY.trackerData[creature.name])

        local formated_loot = {}
        for id, data in pairs(creature.loot) do
            if not formated_loot[getRarity(data.rarity)] then
                formated_loot[getRarity(data.rarity)] = {}
            end
            formated_loot[getRarity(data.rarity)][id] = data.count
        end

        for rarity, items in pairs(formated_loot) do
            local loot = g_ui.createWidget("BestiaryLootObject", creatureWindow.lootPanel.list)
            loot.type:setText(lootTypes[rarity] .. ":")

            local i = 1
            for id, count in pairs(items) do
                if tonumber(id) <= 0 then
                    loot.items[i].item:setImageSource("images/undefined-item")
                    loot.items[i].item:setShowCount(false)
                else
                    loot.items[i].item:setItemId(id)
                    loot.items[i].item:setItemCount(count)
                    loot.items[i].item:setShowCount(true)
                end

                i = i + 1
            end
        end

        for i = 1, 5 do
            if i <= creature.difficulty then
                creatureWindow.difficultyList[i]:setImageSource("images/icons/difficulty-active")
            end
            creatureWindow.difficultyList[i]:setTooltip(
                string.format("Difficulty: %s", difficultys[creature.difficulty])
            )
        end

        for i = 1, 4 do
            if i <= creature.occurrence then
                creatureWindow.occurrenceList[i]:setImageSource("images/icons/occurrence-active")
            end
            creatureWindow.occurrenceList[i]:setTooltip(
                string.format("Occurrence: %s", occurrences[creature.occurrence])
            )
        end

  
        if stage >= 0 then
            local fill = creatureWindow.progressFillLeft.fill
            fill:setImageSource("images/fill")
            local Yhppc = math.floor(fill:getWidth() * (1 - math.min(1, creature.kills / creature.stages[1])))
            local rect = { x = 0, y = 0, width = (creature.kills > 0 and math.max(2, fill:getWidth() - Yhppc) or 0), height =
            fill:getHeight() }
            fill:setImageClip(rect)
            fill:setImageRect(rect)
        end

        if stage >= 1 then
            local fill = creatureWindow.progressFillMiddle.fill
            fill:setImageSource("images/fill")

            local Yhppc = math.floor(fill:getWidth() * (1 - math.min(1, (creature.kills - creature.stages[1]) / (creature.stages[2] - creature.stages[1]))))
            local rect = { x = 0, y = 0, width = (creature.kills > 0 and math.max(2, fill:getWidth() - Yhppc) or 0), height =
            fill:getHeight() }
            fill:setImageClip(rect)
            fill:setImageRect(rect)
        end

        if stage >= 2 then
            local fill = creatureWindow.progressFillRight.fill
            fill:setImageSource("images/fill")
            
            local Yhppc = math.floor(fill:getWidth() * (1 - math.min(1, (creature.kills - creature.stages[2]) / (creature.stages[3] - creature.stages[2]))))
            local rect = { x = 0, y = 0, width = (creature.kills > 0 and math.max(2, fill:getWidth() - Yhppc) or 0), height =
            fill:getHeight() }
            fill:setImageClip(rect)
            fill:setImageRect(rect)
        end

        for i = 1, 3 do
            local tooltip = string.format("%d/%d", creature.kills, creature.stages[i])
            if creature.kills >= creature.stages[3] then
                tooltip = tooltip .. " (fully unlocked)"
            end
            if i == 1 then
                if creature.kills >= creature.stages[3] then
                    creatureWindow.progressFillLeft.fill:setImageSource("images/fill_completed")
                end
                creatureWindow.progressFillLeft:setTooltip(tooltip)
            elseif i == 2 then
                if creature.kills >= creature.stages[3] then
                    creatureWindow.progressFillMiddle.fill:setImageSource("images/fill_completed")
                end
                creatureWindow.progressFillMiddle:setTooltip(tooltip)
            elseif i == 3 then
                if creature.kills >= creature.stages[3] then
                    creatureWindow.progressFillRight.fill:setImageSource("images/fill_completed")
                end
                creatureWindow.progressFillRight:setTooltip(tooltip)
            end
        end

        creatureWindow.progressFillMiddle.value:setText(creature.kills)

        creatureWindow.lookType:setOutfit(creature.outfit)
        creatureWindow.lookType:setAnimate(true)

        G_BESTIARY.UI.closeButton.backType = BACK_TYPE.CREATURE
        G_BESTIARY.UI.closeButton:setText("Back")
    end

    G_BESTIARY.onTracker = function(widget)
        local creature = G_BESTIARY.selectedCreature
        local playerName = g_game.getLocalPlayer():getName()
        local checked = widget:isChecked()
        G_BESTIARY.trackerData[creature.name] = checked
        G_BESTIARY.Tracker.load()
    end

    G_BESTIARY.selectCategory = function(widget)
        local categoryName = widget:getParent():getId()
        G_BESTIARY.UI.panel.categories.list:destroyChildren()

        if not G_BESTIARY.data[categoryName] then
            if G_BESTIARY.data[widget:getId()] then
                categoryName = widget:getId()
            else
                return error(string.format("[Bestiary] - Bestiary category %s not found.", categoryName))
            end
        end

        for _, obj in pairs(G_BESTIARY.data[categoryName]) do
            local creatureExists = G_BESTIARY.UI.panel.categories.list:getChildById(string.lower(obj.name))
            if not creatureExists then
                local creature = g_ui.createWidget("BestiaryCreature", G_BESTIARY.UI.panel.categories.list)
                local button = creature.button
                creature:setId(string.lower(obj.name))
                creature:setText(formatWidgetName(obj.name))

                if obj.kills > 0 then
                    creature.unlocked:setText(string.format("%d / 3", getKillStage(obj.kills, obj.stages)))
                    button.onClick = G_BESTIARY.selectCreature
                    obj.outfit.shader = ""
                else
                    creature.unlocked:setText("?")
                    obj.outfit.shader = "outfit_black"
                end

                creature.object = obj
                button.creature:setOutfit(obj.outfit)
                button.creature:setAnimate(true)

				creature.outfit = obj.outfit
            end
        end

        G_BESTIARY.UI.closeButton.backType = BACK_TYPE.CREATURES
        G_BESTIARY.UI.closeButton:setText("Back")
        G_BESTIARY.selectedCategory = categoryName
    end

    G_BESTIARY.closeBackButton = function(widget)
        if G_BESTIARY.UI.closeButton.backType == BACK_TYPE.CREATURES then
            G_BESTIARY.loadCategories()
            G_BESTIARY.UI.closeButton.backType = BACK_TYPE.CATEGORIES
            return true
        elseif G_BESTIARY.UI.closeButton.backType == BACK_TYPE.CREATURE then
            G_BESTIARY.UI.panel.creature:setVisible(false)
            G_BESTIARY.UI.panel.categories:setVisible(true)
            G_BESTIARY.UI.closeButton.backType = BACK_TYPE.CREATURES
            return true
        elseif G_BESTIARY.UI.closeButton.backType == BACK_TYPE.SEARCH then
            G_BESTIARY.UI.panel.creature:setVisible(false)
            G_BESTIARY.UI.panel.categories:setVisible(true)

            G_BESTIARY.UI.panel.categories.list:destroyChildren()

            local category = g_ui.createWidget("BestiaryCategory", G_BESTIARY.UI.panel.categories.list)
            category:setId(getCreatureClass(G_BESTIARY.UI.panel.creature:getText()))
            G_BESTIARY.selectCategory(category)
            G_BESTIARY.UI.closeButton:setText("Back")
            return true
        end

        closeBestiaryWindow()
        G_BESTIARY.UI.closeButton.backType = BACK_TYPE.NONE
        return false
    end

    G_BESTIARY.search = function(widget)
        local text = widget:getParent():getChildById("search"):getText()
        local creature = getCreatureByName(text)

        G_BESTIARY.UI.panel.categories.list:destroyChildren()

        if creature then
            if G_BESTIARY.UI.panel.creature:isVisible()  then
                G_BESTIARY.UI.panel.creature:setVisible(false)
                G_BESTIARY.UI.panel.categories:setVisible(true)
            end
           
            local c_widget = g_ui.createWidget("BestiaryCreature", G_BESTIARY.UI.panel.categories.list)
            local button = c_widget.button
            c_widget:setId(string.lower(creature.name))
            c_widget:setText(formatWidgetName(creature.name))

            if creature.kills > 0 then
                c_widget.unlocked:setText(string.format("%d / 3", getKillStage(creature.kills, creature.stages)))
                button.onClick = function(widget) 
                    G_BESTIARY.selectCreature(widget)
                    G_BESTIARY.UI.closeButton.backType = BACK_TYPE.SEARCH
                end
            else
                c_widget.unlocked:setText("?")
                creature.outfit.shader = "outfit_black"
            end

            c_widget.object = creature
            button.creature:setOutfit(creature.outfit)
            button.creature:setAnimate(true)
        end

        G_BESTIARY.UI.closeButton.backType = BACK_TYPE.CREATURES
    end

    G_BESTIARY.loadCategories = function()
        G_BESTIARY.UI.panel.categories.list:destroyChildren()

        for name, values in pairs(G_BESTIARY.categories) do
            local obj = getCategoryByName(name)
            if not obj then
                return error("[Bestiary] - creature %s not found.", name)
            end

            local category = g_ui.createWidget("BestiaryCategory", G_BESTIARY.UI.panel.categories.list)
            category:setId(obj.class)
            category:setText(
                obj.class:gsub(
                    "(%w%S*)",
                    function(w)
                        return w:gsub("^%l", string.upper)
                    end
                )
            )
            category.total:setText(string.format("Total: %d", values.count))
            category.known:setText(string.format("Known: %d", values.know))
            category.button:setIcon(obj.image)
            category.button.onClick = G_BESTIARY.selectCategory
        end

        G_BESTIARY.UI.closeButton:setText("Close")
    end


    G_BESTIARY.reciver = function(protocol, code, buffer)
        local playerName = g_game.getLocalPlayer():getName()
        local data = buffer.data
        if buffer.action == "bestiaryData" then
            G_BESTIARY.loadData(data.creature)
            if data.finished then
                G_BESTIARY.loadCategories()
                G_BESTIARY.Tracker.load()
            end
        elseif buffer.action == "prepareBestiaryData" then
            G_BESTIARY.data = nil
            G_BESTIARY.data = {}
        elseif buffer.action == "bestiaryKill" then
            for name, kills in pairs(data) do
                updateBestiaryKill(name, kills)
                
                if G_BESTIARY.trackerData[name] and modules.game_sidemenu.getBestiaryButton():isOn() then
                    G_BESTIARY.Tracker.load()
                end
            end
        elseif buffer.action == "bestiaryBalance" then
            G_BESTIARY.UI.bestiaryPoints:setText(data.value)
		elseif buffer.action == "charms" then
            onReceiveCharms(buffer.data)
		elseif buffer.action == "msg" then
            onReceiveMsg(buffer.data)
		elseif buffer.action == "coins" then
            onReceiveCoins(buffer.data)
        end

		addCreaturesCharmsList()
    end

    G_BESTIARY.loadData = function(creature)

         if not getCategoryByName(creature.class) then
            return error(string.format("[Bestiary] class %s not found.", creature.class))
         end

         if not G_BESTIARY.categories[creature.class] then
            G_BESTIARY.categories[creature.class] = {
                count = 0,
                know = 0
            }
         end
         G_BESTIARY.categories[creature.class].count = G_BESTIARY.categories[creature.class].count + 1
         if creature.kills > 0 then
            G_BESTIARY.categories[creature.class].know = G_BESTIARY.categories[creature.class].know + 1
        end

        if not G_BESTIARY.data[creature.class] then
            G_BESTIARY.data[creature.class] = {}
        end

        table.insert(G_BESTIARY.data[creature.class], creature)
    end

    G_BESTIARY.send = function(action, data)
        if not g_game.getFeature(GameExtendedOpcode) then
            return
        end
        local protocolGame = g_game.getProtocolGame()
        if data == nil then
            data = {}
        end

        if protocolGame then
            protocolGame:sendExtendedJSONOpcode(CONFIG.CLIENT_OPCODE, {action = action, data = data})
        end
    end

    G_BESTIARY.save = function()
        if not g_resources.directoryExists("/bestiary/") then
            g_resources.makeDir("/bestiary/")
        end

        if not table.empty(G_BESTIARY.trackerData) then

            local name = formatFileName(G_BESTIARY.playerName)
            local file = string.format("/bestiary/bestiary_%s.json", name)

            local status, result = pcall(function() return json.encode(G_BESTIARY.trackerData, 2) end)
            if not status then
                return onError(
                           "Error while saving profile settings. Data won't be saved. Details: " ..
                               result)
            end
            if result:len() > 100 * 1024 * 1024 then
                return onError(
                           "Something went wrong, file is above 100MB, won't be saved")
            end
            g_resources.writeFileContents(file, result)
        end
    end

    G_BESTIARY.load = function()
        if not g_resources.directoryExists("/bestiary/") then
            g_resources.makeDir("/bestiary/")
        end

        local name = formatFileName(G_BESTIARY.playerName)
        local file = string.format("/bestiary/bestiary_%s.json", name)

        if g_resources.fileExists(file) then
          local status, result = pcall(function()
              return json.decode(g_resources.readFileContents(file))
          end)
          if not status then
              return onError(
                         "Error while reading bestiary config file. Details: " ..
                          result)
          end
          G_BESTIARY.trackerData = result
        end

        if not table.empty(G_BESTIARY.trackerData) then
            G_BESTIARY.Tracker.load()
        end
    end

    G_BESTIARY.needUpdateData = function()
        return true
    end

    G_BESTIARY.Tracker.load = function()
        G_BESTIARY.Tracker.UI.contentsPanel:destroyChildren()

        for name, actived in pairs(G_BESTIARY.trackerData) do
            if actived then
                local trackCreature = getCreatureByName(name)
                if trackCreature then
                    local stage = getKillStage(trackCreature.kills, trackCreature.stages)

                    local obj = g_ui.createWidget("TrackerCreature", G_BESTIARY.Tracker.UI.contentsPanel)
                    obj.name:setText(
                        formatWidgetName(trackCreature.name:gsub(
                            "(%w%S*)",
                            function(w)
                                return w:gsub("^%l", string.upper)
                            end
                        ))
                    )
                    obj.creature:setOutfit(trackCreature.outfit)
                    obj.creature:setAnimate(true)

                    obj.progressFillMiddle.value:setText(trackCreature.kills)

                    obj.progressFillLeft.fill:setImageSource("")
                    obj.progressFillMiddle.fill:setImageSource("")
                    obj.progressFillRight.fill:setImageSource("")

                    obj.progressFillLeft.fill:setTooltip("")
                    obj.progressFillMiddle.fill:setTooltip("")
                    obj.progressFillRight.fill:setTooltip("")
                    

                    if stage >= 0 then
                        local fill = obj.progressFillLeft.fill

                        fill:setImageSource("images/fill")
                        local Yhppc = math.floor(fill:getWidth() * (1 - math.min(1, trackCreature.kills / trackCreature.stages[1])))
                        local rect = {x = 0, y = 0, width = (trackCreature.kills > 0 and math.max(2, fill:getWidth() - Yhppc - 1) or 0), height = fill:getHeight() - 1}
                        fill:setImageClip(rect)
                        fill:setImageRect(rect)
                    end

                    if stage >= 1 then
                        local fill = obj.progressFillMiddle.fill

                        fill:setImageSource("images/fill")
                        local Yhppc = math.floor(fill:getWidth() * (1 - math.min(1, (trackCreature.kills - trackCreature.stages[1]) / (trackCreature.stages[2] - trackCreature.stages[1]))))
                        local rect = {x = 0, y = 0, width = (trackCreature.kills > 0 and math.max(2, fill:getWidth() - Yhppc - 1) or 0), height = fill:getHeight() - 1}
                        fill:setImageClip(rect)
                        fill:setImageRect(rect)
                    end

                    if stage >= 2 then
                        local fill = obj.progressFillRight.fill

                        fill:setImageSource("images/fill")
                        local Yhppc = math.floor(fill:getWidth() * (1 - math.min(1, (trackCreature.kills - trackCreature.stages[2]) / (trackCreature.stages[3] - trackCreature.stages[2]))))
                        local rect = {x = 0, y = 0, width = (trackCreature.kills > 0 and math.max(2, fill:getWidth() - Yhppc - 1) or 0), height = fill:getHeight() - 1}
                        fill:setImageClip(rect)
                        fill:setImageRect(rect)
                    end

                    for i = 1, 3 do
                        local tooltip = string.format("%d/%d", trackCreature.kills, trackCreature.stages[i])
                        if trackCreature.kills >= trackCreature.stages[3] then
                            tooltip = tooltip .. " (fully unlocked)"
                        end

                        if i == 1 then
                            if trackCreature.kills >= trackCreature.stages[3] then
                                obj.progressFillLeft.fill:setImageSource("images/fill_completed")
                            end
                            obj.progressFillLeft:setTooltip(tooltip)
                        elseif i == 2 then
                            if trackCreature.kills >= trackCreature.stages[3] then
                                obj.progressFillMiddle.fill:setImageSource("images/fill_completed")
                            end
                            obj.progressFillMiddle:setTooltip(tooltip)
                        elseif i == 3 then
                            if trackCreature.kills >= trackCreature.stages[3] then
                                obj.progressFillRight.fill:setImageSource("images/fill_completed")
                            end
                            obj.progressFillRight:setTooltip(tooltip)
                        end
                    end
                end
            end
        end
    end
end

function toggleTracker()
    
    if modules.game_sidemenu.getBestiaryButton():isOn() then
        G_BESTIARY.Tracker.UI:close()
        -- modules.game_sidemenu.getBestiaryButton():setOn(false)
    else
        G_BESTIARY.Tracker.UI:open()
        -- modules.game_sidemenu.getBestiaryButton():setOn(true)
    end
end

function onReceiveCharms(info)
	G_BESTIARY.UI:recursiveGetChildById('UnlockButton'):setEnabled(false)
	G_BESTIARY.UI:recursiveGetChildById('ItemBase'):getChildById('image'):setImageSource()
	G_BESTIARY.UI:recursiveGetChildById('imageID'):setText("nil")
	G_BESTIARY.UI:recursiveGetChildById('showCreature'):setOutfit({type = 0, auxType = 0, head = 0, body = 0, legs = 0, feet = 0, addons = 0, wings = 0, aura = 0, shader = ""})
	G_BESTIARY.UI:recursiveGetChildById('showCreatureID'):setText("nil")
	G_BESTIARY.UI:recursiveGetChildById('CreatureList'):hide()

	for _, charm in pairs(G_BESTIARY.UI:recursiveGetChildById('charmsList'):getChildren()) do
		charm:destroy()
	end

	local allCharms = {}
	for charmName, charm in pairs(info) do
		table.insert(allCharms, charm)
	end

	local function compareWidgets(widgetA, widgetB)
		return widgetA.order < widgetB.order
	end

	table.sort(allCharms, compareWidgets)

	for i = 1, #allCharms do
		addCharm(allCharms[i], allCharms[i].name)
	end
end

function addCharm(charm, charmName)
	local createCharm = g_ui.createWidget("CharmItem", G_BESTIARY.UI:recursiveGetChildById('charmsList'))

	createCharm:setId(charmName)
	createCharm.order = charm.order
	createCharm.charmBase.image:setImageSource("images/charms/"..charmName.."")
	createCharm:setText(charmName)
	createCharm.desc = charm.desc
	createCharm.monster = (charm.monster and charm.monster or "nil")
	createCharm:recursiveGetChildById('outfit'):setOutfit({type = charm.outfit and charm.outfit.lookType or 0,auxType = charm.outfit and charm.outfit.lookTypeEx or 0, head = charm.outfit and charm.outfit.lookHead or 0, body = charm.outfit and charm.outfit.lookBody or 0, legs = charm.outfit and charm.outfit.lookLegs or 0, feet = charm.outfit and charm.outfit.lookFeet or 0, addons = 0, wings = 0, aura = 0, shader = ""})
	createCharm:recursiveGetChildById('outfit'):setAnimate(charm.outfit and true or false)
	createCharm:recursiveGetChildById('outfit'):setEnabled(charm.outfit and true or false)
	if charm.rune then
		createCharm.PriceBase.Gold:setVisible(true)
		createCharm.PriceBase.Charm:setVisible(false)
		createCharm.charmBase.lockedMask:setVisible(false)
		createCharm.PriceBase.Value.ValueFix:setText(charm.goldCoin*g_game:getLocalPlayer():getLevel())
		createCharm.PriceBase.Value:setText(formatMoney(charm.goldCoin*g_game:getLocalPlayer():getLevel()))
	else
		createCharm.PriceBase.Gold:setVisible(false)
		createCharm.PriceBase.Charm:setVisible(true)
		createCharm.charmBase.lockedMask:setVisible(true)
		createCharm.PriceBase.Value:setText(charm.charmCoin)
		createCharm.PriceBase.Value.ValueFix:setText(charm.charmCoin)
	end
end

local randomColor = "#414141"
function addCreaturesCharmsList()
	local allMonsters = {}
	for _A, cat in pairs(G_BESTIARY.UI.panel.categories.list:getChildren()) do
		if G_BESTIARY.data[cat:getId()] then
			for _, obj in pairs(G_BESTIARY.data[cat:getId()]) do
				local creature = {}
				creature.id = string.lower(obj.name)
				creature.name = formatWidgetName(obj.name)
				creature.outfit = obj.outfit
				table.insert(allMonsters, creature)
			end
		end
	end

	local function compareWidgets(widgetA, widgetB)
		return widgetA.id:lower() < widgetB.id:lower()
	end

	table.sort(allMonsters, compareWidgets)

	for i = 1, #allMonsters do
		if allMonsters[i].outfit.shader ~= "outfit_black" then
			if not G_BESTIARY.UI:recursiveGetChildById('CreatureList'):getChildById(allMonsters[i].id) then
				local newCreature = g_ui.createWidget("CharmCreatureName", G_BESTIARY.UI:recursiveGetChildById('CreatureList'))
				newCreature:setId(allMonsters[i].id)
				newCreature:setText(allMonsters[i].name)
				newCreature:setBackgroundColor(randomColor == "#414141" and "#484848" or "#414141")
				randomColor = randomColor == "#414141" and "#484848" or "#414141"
				newCreature.outfit = allMonsters[i].outfit
				newCreature.monster = allMonsters[i].name
			end
		end
	end
end

function onReceiveMsg(info)
	G_BESTIARY.UI:recursiveGetChildById('message'):setVisible(true)
	G_BESTIARY.UI:recursiveGetChildById('msgLabel'):setText(info.msg)
end

function onReceiveCoins(info)
	G_BESTIARY.UI:recursiveGetChildById('goldCoinsValue'):setText(info.gold)
	G_BESTIARY.UI:recursiveGetChildById('goldCoins'):setText(formatMoney(info.gold))
	G_BESTIARY.UI:recursiveGetChildById('charmsPoints'):setText(info.charm)
	G_BESTIARY.UI:recursiveGetChildById('extraCharmsPoints'):setText(info.extracharm)
end

function formatMoney(money)
    if money >= 10^6 then
        return string.format("%.2fkk", money / 10^6)
    elseif money >= 10^3 then
        return string.format("%.2fk", money / 10^3)
    else
        return tostring(money)
    end
end

function searchMonsterCharm(search)
    for _, monster in pairs(G_BESTIARY.UI:recursiveGetChildById('CreatureList'):getChildren()) do
		if string.find(monster:getId():lower(), search:lower()) or not search or search == "" then
			monster:show()
		else
			monster:hide()
		end
	end
end
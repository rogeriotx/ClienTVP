---@diagnostic disable: lowercase-global, undefined-field, need-check-nil, inject-field
local CODE_TOOLTIPS = 105

local tooltipWindow = nil
local itemSprite = nil
local labels = nil
local hoveredItem = nil
local player = nil
local protocolGame = nil
local showingVirtual = nil
local hoveredLinked = nil

local BASE_WIDTH = 46
local BASE_HEIGHT = 0

local tooltipWidth = 0
local tooltipWidthBase = BASE_WIDTH
local tooltipHeight = BASE_HEIGHT
local longestString = 0

local cachedItems = {}

local showEvent, hideEvent

local Colors = {
    Default = "#dfdfdf",
    ItemLevel = "#abface",
    Description = "#8080ff",
    Implicit = "#dfdfdf", -- atributos dos items, como exemplo speed da boh
    Attribute = "#2266ff",
    Mirrored = "#22ffbb",
    RarityAttribute = "#00eb00" -- atributos de raridade
}

local rarityColor = {
    {name = "Common", color = "#dfdfdf"},
    {name = "Uncommon", color = "#c2c2c2"}, {name = "Rare", color = "#00dbfd"},
    {name = "Epic", color = "#BA68C8"}, {name = "Legendary", color = "#FBC02D"}
}

local implicits = {
    ["cap"] = "Vol.",
    ["ca"] = "Critical Damage",
    ["cc"] = "Critical Chance",
    ["la"] = "Life Leech",
    ["lc"] = "Life Leech Chance",
    ["ma"] = "Mana Leech",
    ["mc"] = "Mana Leech Chance",
    ["speed"] = "Movement Speed",
    ["fist"] = "Fist Fighting",
    ["sword"] = "Sword Fighting",
    ["club"] = "Club Fighting",
    ["axe"] = "Axe Fighting",
    ["dist"] = "Distance Fighting",
    ["shield"] = "Shielding",
    ["fish"] = "Fishing",
    ["mag"] = "Magic Level",
    ["a_phys"] = "Physical Protection",
    ["a_ene"] = "Energy Protection",
    ["a_earth"] = "Earth Protection",
    ["a_fire"] = "Fire Protection",
    ["a_ldrain"] = "Lifedrain Protection",
    ["a_mdrain"] = "Manadrain Protection",
    ["a_heal"] = "Healing Protection",
    ["a_drown"] = "Drown Protection",
    ["a_ice"] = "Ice Protection",
    ["a_holy"] = "Holy Protection",
    ["a_death"] = "Death Protection",
    ["a_all"] = "Protection All",

    ["hpticks"] = "HP Ticks",
    ["mpticks"] = "MP Ticks",
    ["mpgain"] = "MP Gain",
    ["hpgain"] = "HP Gain",

    ["attrRarity"] = "Rarity",
    ["attrAttack"] = "Increased Attack",
    ["attrArmor"] = "Increased Armor",
    ["attrDef"] = "Increased Defense",
    ["attrSkill"] = "Increased Skills",
--  ["attrMagic"] = "Increased Magic",
	["attrWeightReduction"] = "Reduced Weight",
    ["attrManaRegen"] = "Increased Mana Regeneration",
    ["attrHpRegen"] = "Increased Health Regeneration",
    ["attrMaxHp"] = "Increased Max Health",
    ["attrMaxMana"] = "Increased Max Mana",
    ["attrResistance"] = "Increased Resistance",
    ["attrPhysical"] = "Increased Physical Resistance",
    ["attrResistFire"] = "Increased Fire Resistance",
    ["attrResistIce"] = "Increased Ice Resistance",
    ["attrResisPoison"] = "Increased Poison Resistance",
    ["attrResistEnergy"] = "Increased Energy Resistance",
    ["attrAtkSpeed"] = "Decrease Attack Interval",
    ["attrCritical"] = "Critical Hit",
    ["attrParry"] = "Parry",
    ["attrPerseverance"] = "Perseverance",
    ["attrBerserk"] = "Berserk",
    ["attrCrushingBlow"] = "Crushing Blow",
    ["attrFastHand"] = "Fast Hand",
    ["attrSharpShooter"] = "Sharpshooter",
    ["attrBleeding"] = "Bleeding",
	["attrEletricfying"] = "Eletricfying",
	["attrBurning"] = "Burning",
	["attrPoisoning"] = "Poisoning",
    ["attrSpeed"] = "Increased Movement Speed"
}

local ignoreImp = {["cap"] = true}

local impPercent = {
    ["cap"] = false,
    ["ca"] = true,
    ["cc"] = true,
    ["la"] = true,
    ["lc"] = true,
    ["ma"] = true,
    ["mc"] = true,
    ["a_phys"] = true,
    ["a_ene"] = true,
    ["a_earth"] = true,
    ["a_fire"] = true,
    ["a_ldrain"] = true,
    ["a_mdrain"] = true,
    ["a_heal"] = true,
    ["a_drown"] = true,
    ["a_ice"] = true,
    ["a_holy"] = true,
    ["a_death"] = true,
    ["a_all"] = true,
    ["attrCritical"] = true,
    ["attrResistance"] = true,
    ["attrPhysical"] = true,
    ["attrResistFire"] = true,
    ["attrResistIce"] = true,
    ["attrResisPoison"] = true,
    ["attrResistEnergy"] = true,
    ["attrPerseverance"] = true,
    ["attrBerserk"] = true,
    ["attrCrushingBlow"] = true,
    ["attrFastHand"] = true,
    ["attrSharpShooter"] = true,
    ["attrBleeding"] = true,
	["attrEletricfying"] = true,
	["attrBurning"] = true,
	["attrPoisoning"] = true,
    ["attrParry"] = true,
	["attrWeightReduction"] = true
}

local impInterval = {["attrAtkSpeed"] = true}

local impDuration = {["hpticks"] = true, ["mpticks"] = true}

local isLinkedView = false

function init()
    connect(UIItem, {onHoverChange = onHoverChange})
    connect(g_game, {onGameEnd = resetData})
    connect(UILinkedItem, {onHoverChange = onHoverChange})

    ProtocolGame.registerExtendedOpcode(CODE_TOOLTIPS, function (protocol, code, buffer)
        local json_status, json_data = pcall(function()
            return json.decode(buffer)
        end)

        if not json_status then
            g_logger.error("Tooltips JSON error: " .. json_data)
            return
        end
        local action = json_data.action
        local data = json_data.data
        if not action or not data or table.empty(data) then return end
        if action == "new" then newTooltip(data) end
    end)

    g_ui.importStyle("item_tooltip")

    tooltipWindow = modules.game_interface.getRootPanel().tooltipItem
    tooltipWindow:hide()
    tooltipWindow.tooltipVisible = false

    labels = tooltipWindow:getChildById("labels")
    itemSprite = tooltipWindow:getChildById("itemSprite")
end

function terminate()
    disconnect(UIItem, {onHoverChange = onHoverChange})
    disconnect(g_game, {onGameEnd = resetData})
    disconnect(UILinkedItem, {onHoverChange = onHoverChange})

    ProtocolGame.unregisterExtendedOpcode(CODE_TOOLTIPS)

    if tooltipWindow then
        cachedItems = {}
        hoveredItem = nil
        player = nil
        protocolGame = nil
        showingVirtual = nil
        hoveredLinked = nil

        itemSprite = nil
        labels = nil

        tooltipWindow:destroy()
        tooltipWindow = nil
    end
end

function resetData()
    cachedItems = {}
    hoveredItem = nil
    player = nil
    protocolGame = nil
    showingVirtual = nil
    hoveredLinked = nil
    removeEvent(showEvent)
    removeEvent(hideEvent)
    tooltipWindow:hide()
    tooltipWindow.tooltipVisible = false
end

function filterImplitics(implitics)
    local attrTable = {}
    local nonAttrTable = {}

    for key, value in pairs(implitics) do
        if not ignoreImp[key] then
            if string.sub(key, 1, 4) == "attr" then
                attrTable[key] = value
            else
                nonAttrTable[key] = value
            end
        end
    end

    return attrTable, nonAttrTable
end

function sortImplitics(implitics)
    local sortedKeys = {}
    for key in pairs(implitics) do table.insert(sortedKeys, key) end
    table.sort(sortedKeys)

    local sortedTable = {}
    for _, key in ipairs(sortedKeys) do sortedTable[key] = implitics[key] end

    return sortedTable
end

function convertValue(key, value)
    if key == "attrManaRegen" or key == "attrHpRegen" then
        return string.format("%.1f", value * 0.2)
    elseif key == "attrWeightReduction" then
        return value * 20
    elseif key == "attrSpeed" then
        return value * 5
    end
    return value
end

function getImpliticsText(key, value)
    local impText = nil
    if not implicits[key] then
        impText = value
    else
		if key == "attrWeightReduction" then
            local formattedValue = convertValue(key, value)
            impText = implicits[key] .. " -" .. formattedValue .. "%"
        elseif impPercent[key] then
            impText = implicits[key] .. " " .. value ..
                          (impPercent[key] and "%" or "")
        elseif impInterval[key] then
            impText = implicits[key] .. " -" .. 
							string.format("%.2f", value * 0.05) .. "s"
        elseif impDuration[key] then
            impText = implicits[key] .. " " .. (value > 0 and ": " or "") ..
                          (value / 1000) .. (impDuration[key] and "s" or "")
        else
            local formattedValue = convertValue(key, value)
			impText = implicits[key] .. " " .. (value > 0 and "+" or "") .. 
				formattedValue .. (impPercent[key] and "%" or "")
        end
    end
    return impText
end

function isWeapon(itemType)
    return (itemType == "Two-Handed Sword" or itemType == "Two-Handed Club" or
               itemType == "Two-Handed Axe" or itemType == "Sword" or itemType ==
               "Club" or itemType == "Axe" or itemType == "Fist" or itemType ==
               "Distance")
end

function isTwoHanded(itemType)
    return string.find(string.lower(itemType), "two-handed", 1, true)
end

function isDistance(itemType)
    return string.find(string.lower(itemType), "distance", 1, true)
end

function addString(text, color, resize, marginleft)
    local label = g_ui.createWidget("TooltipLabel", labels)
    label:setColor(color)
    label:setMarginLeft(marginleft or 5)
    if resize then
        tooltipWindow:setWidth(tooltipWidth)
        label:setTextWrap(true)
        -- label:setTextAutoResize(true)
        label:setText(text)
        tooltipHeight = tooltipHeight + label:getTextSize().height + 4
    else
        label:setText(text)
        local textSize = label:getTextSize()
        local actualWidth = textSize.width + label:getMarginLeft()
        if longestString == 0 then
            longestString = actualWidth
            tooltipWidth = tooltipWidthBase + longestString
            label:addAnchor(AnchorTop, "parent", AnchorTop)
        elseif actualWidth > longestString then
            longestString = actualWidth
            tooltipWidth = tooltipWidthBase + longestString
        end
        tooltipHeight = tooltipHeight + textSize.height
    end
    return label
end

function shrinkSeparators()
    local children = labels:getChildren()
    local m = 0
    for _, child in ipairs(children) do
        if child:getStyleName() == "TooltipSeparator" then
            child:setMarginLeft(m)
            child:setMarginRight(m)
        end
    end
end

function addSeparator()
    local sep = g_ui.createWidget("TooltipSeparator", labels)
    tooltipHeight = tooltipHeight + sep:getHeight() + sep:getMarginTop() +
                        sep:getMarginBottom()
end

function addEmpty(height)
    local empty = g_ui.createWidget("TooltipEmpty", labels)
    empty:setHeight(height)
    tooltipHeight = tooltipHeight + height
    return empty
end

function formatWeight(weight)
    local ss

    if weight < 10 then
        ss = "0.0" .. weight
    elseif weight < 100 then
        ss = "0." .. weight
    else
        local weightString = tostring(weight)
        local len = weightString:len()
        ss = weightString:sub(1, len - 2) .. "." ..
                 weightString:sub(len - 1, len)
    end

    ss = ss .. " oz."
    return ss
end

function formatItemType(itemType)
    if isTwoHanded(itemType) then
        return itemType
    elseif isDistance(itemType) then
        return itemType .. " Weapon"
    end

    return "One-Handed " .. itemType
end

function cacheItemFromData(data)
    local _itemUId = data.uid
    local _itemName = data.itemName
    local _spellRune = data.spell_rune
    local _itemDesc = data.desc
    local _itemId = data.clientId
    local _itemLevel = data.itemLevel or 0
    local _imp = data.imp
    local _unidentified = data.unidentified
    local _mirrored = data.mirrored
    local _upgradeLevel = data.uLevel or 0
    local _uniqueName = data.uniqueName
    local _itemRarity = data.rarityId or 0
    local _itemTierRarity = data.requiredLevelAttr or 0
    local _itemMaxAttributes = data.maxAttr or 0
    local _itemAttributes = data.attr
    local _requiredLevel = data.reqLvl or 0
    local _attackSpeed = data.attackSpeed or 0
    local _hitChance = data.hitChance or 0

    if _itemRarity ~= 0 then
        for i = _itemMaxAttributes, 1, -1 do
            _itemAttributes[i] = _itemAttributes[i]:gsub("%%%%", "%%")
        end
    end

    local _isStackable = data.stackable
    local _itemType = data.itemType
    local _firstStat = data.armor or data.attack or 0
    local _secondStat = data.hitChance or data.defense or 0
    local _thirdStat = data.shootRange or data.extraDefense or 0
    local _weight = data.weight
    local _charges = data.charges or -1
    local _duration = data.duration or -1

    if cachedItems[_itemUId] ~= nil then
        cachedItems[_itemUId].last = os.time()
        cachedItems[_itemUId].name = _itemName
        cachedItems[_itemUId].desc = _itemDesc
        cachedItems[_itemUId].iLvl = _itemLevel
        cachedItems[_itemUId].imp = _imp
        cachedItems[_itemUId].unidentified = _unidentified
        cachedItems[_itemUId].mirrored = _mirrored
        cachedItems[_itemUId].uLvl = _upgradeLevel
        cachedItems[_itemUId].uniqueName = _uniqueName
        cachedItems[_itemUId].rarity = _itemRarity
        cachedItems[_itemUId].tierRarity = _itemTierRarity
        cachedItems[_itemUId].maxAttributes = _itemMaxAttributes
        cachedItems[_itemUId].attributes = _itemAttributes
        cachedItems[_itemUId].stackable = _isStackable
        cachedItems[_itemUId].type = _itemType
        cachedItems[_itemUId].first = _firstStat
        cachedItems[_itemUId].second = _secondStat
        cachedItems[_itemUId].third = _thirdStat
        cachedItems[_itemUId].weight = _weight
        cachedItems[_itemUId].reqLvl = _requiredLevel
        cachedItems[_itemUId].itemId = _itemId
        cachedItems[_itemUId].attackSpeed = _attackSpeed
        cachedItems[_itemUId].hitChance = _hitChance
        cachedItems[_itemUId].charges = _charges
        cachedItems[_itemUId].duration = _duration
        cachedItems[_itemUId].spellrune = _spellRune
    else
        cachedItems[_itemUId] = {
            last = os.time(),
            name = _itemName,
            desc = _itemDesc,
            iLvl = _itemLevel,
            imp = _imp,
            unidentified = _unidentified,
            mirrored = _mirrored,
            uLvl = _upgradeLevel,
            uniqueName = _uniqueName,
            rarity = _itemRarity,
            tierRarity = _itemTierRarity,
            maxAttributes = _itemMaxAttributes,
            attributes = _itemAttributes,
            stackable = _isStackable,
            type = _itemType,
            first = _firstStat,
            second = _secondStat,
            third = _thirdStat,
            weight = _weight,
            reqLvl = _requiredLevel,
            itemId = _itemId,
            attackSpeed = _attackSpeed,
            hitChance = _hitChance,
            charges = _charges,
            duration = _duration,
            spellrune = _spellRune
        }
    end
end

function cacheItemFromItemWidget(_itemUId, itemWidget)
    if itemWidget then
        if cachedItems[_itemUId] ~= nil then
            cachedItems[_itemUId].id = itemWidget:getId()
            cachedItems[_itemUId].count = itemWidget:getCount()
            cachedItems[_itemUId].subType = itemWidget:getSubType()
        else
            cachedItems[_itemUId] = {
                id = itemWidget:getId(),
                count = itemWidget:getCount(),
                subType = itemWidget:getSubType()
            }
        end
    end
    -- print("caching!")
end

-- handle requests queue based

local requestQueue = {}

function addRequestToQueue(widget, is_linked_to_chat)
    table.insert(requestQueue, {widget = widget, is_linked_to_chat = is_linked_to_chat, time = g_clock.millis()})
end

function getFirstRequestFromQueue()
    return table.remove(requestQueue, 1)
end

function newTooltip(data)
    local _itemUId = data.uid
    local _itemName = data.itemName
    local _itemId = data.clientId 
    local _uniqueName = data.uniqueName
    local _upgradeLevel = data.uLevel or 0
    local _itemRarity = data.rarityId or 0
    local _itemTierRarity = data.requiredLevelAttr or 0

    local requested = getFirstRequestFromQueue()
    
    if not hoveredLinked then
        return
    end

    cacheItemFromData(data)

    if requested.is_linked_to_chat then
        -- print("delay of " .. (g_clock.millis() - requested.time) .." ms" .. (requested.is_linked_to_chat and " (is linked)" or ""))
        local item = requested.widget:getItem()
        if item then
            cacheItemFromItemWidget(_itemUId, item)

            item.uid = _itemUId
            item.name = _itemName .. (_upgradeLevel > 0 and " +" .. _upgradeLevel or "")
            item.rarity = _itemRarity
            item.tierRarity = _itemTierRarity
            modules.game_console.append_item_tooltip_text(requested.widget, requested.time)
        end
        return
    end

    if hoveredLinked.linked == false then
        -- print("is not_linked")
        if hoveredItem and _itemId == hoveredItem:getId() then
            hoveredItem.uid = _itemUId
            hoveredItem.name = _itemName .. (_upgradeLevel > 0 and " +" .. _upgradeLevel or "")
            hoveredItem.rarity = _itemRarity
            hoveredItem.tierRarity = _itemTierRarity
            showTooltip(_itemUId, hoveredItem)
        end
    end

    if hoveredLinked and _itemUId == hoveredLinked.uid then
        hoveredLinked.cached = true
        for key, value in pairs(cachedItems[_itemUId]) do
            hoveredLinked[key] = value
        end

        isLinkedView = true

        buildItemTooltip(hoveredLinked:getLinkedTooltip())
        return
    end
end

local function request_widget(widget, is_linked_to_chat)
    -- print("requesting")
    local pos, item

    if widget:getClassName() == "UIItem" then
        item = widget:getItem()
    else
        item = widget
    end

    pos = item:getPosition()
    if pos then
        hoveredItem = item
        -- -- print("requesting")
        if protocolGame then
            protocolGame:sendExtendedOpcode(CODE_TOOLTIPS, json.encode({pos.x, pos.y, pos.z, item:getStackPos()}))
            addRequestToQueue(widget, is_linked_to_chat)
        end
    end
end

local function open(Widget)
    isLinkedView = false

    Widget.linked = false

    hoveredLinked = Widget
    -- -- print(hoveredLinked:getClassName())
    if hoveredLinked:getClassName() == "UIItem" then
        local item = hoveredLinked:getItem()
        if item and hoveredLinked.getItemTooltip then
            -- -- print("item alredy exists")
            scheduleBuildItemTooltip(hoveredLinked:getItemTooltip())
            return
        end
    end

    request_widget(hoveredLinked, false)
end

local function request_linked_widget(Widget)
    isLinkedView = true
    
    hoveredLinked = Widget
    hoveredLinked.linked = true
    if Widget.cached then
        -- print("already cached")
        showingVirtual = Widget:getLinkedTooltip()
        buildItemTooltip(showingVirtual) 
    else
        -- print("requesting by uid")
        if protocolGame then -- request_widget_by_uid
            protocolGame:sendExtendedOpcode(CODE_TOOLTIPS, json.encode({Widget.uid}))
            addRequestToQueue(Widget, false)
        end
    end
end

local function close(Widget, dontFadeout)

    if not isWidgetTooltipVisible(Widget) then
        return true
    end
    
    isLinkedView = false
    hoveredLinked = nil

    if tooltipWindow and not dontFadeout then
        g_effects.fadeOut(tooltipWindow, 350)
        tooltipWindow.tooltipVisible = false
    end
end

function requestLinked(widget)
    if not widget.cached then
        -- print("not cached")
        widget.linked = true
        hoveredLinked = widget
        request_widget(hoveredLinked, true)
	else
        -- print("already cached")
		modules.game_console.append_item_tooltip_text(widget, g_clock.millis())
    end
end

function isWidgetTooltipVisible(widget)
    if hoveredLinked and widget then
        if widget == hoveredLinked then
            return true
        end
    end
    return false
end

function onHoverChange(widget, hovered)
    -- print("\n-------\nonHoverChange")
    if not protocolGame then protocolGame = g_game.getProtocolGame() end

    if widget:getClassName() == "UILinkedItem" then
        isLinkedView = true
    elseif modules.client_options.getOption('advancedTooltip') then
        isLinkedView = false
    else
        return
    end
    -- -- print("\n\n", widget:getClassName(), isLinkedView)
    removeEvent(showEvent)

    if hovered then -- Aparecer
        if isWidgetTooltipVisible(widget) then -- Já estava visível, então precisamos resetar o evento de fechá-lo
            -- -- print("I was already visible")
            removeEvent(hideEvent)
        else
            if isLinkedView then
                -- -- print(widget:getId(), "hovered and linked_view")
                request_linked_widget(widget)
            elseif canRequestTooltipInfo(widget) then
                -- -- print(widget:getId(), "trying hovered and usual view")
                open(widget)
            end
        end
    elseif isWidgetTooltipVisible(widget) then -- Desaparecer
        -- estava visível, então espera 5000ms para esconder
        -- -- print("I'm visible and I'm_linked", isLinkedView)
        if isLinkedView then
            -- -- print("closing_linked view")
            close(widget)
        elseif tooltipWindow.tooltipVisible then
            -- -- print(widget:getId(), "not hovered and closing in 5 seconds")
            close(widget)
            -- hideEvent = scheduleEvent(function() close(widget) end, 5000)
        else
            -- -- print(widget:getId(), "not hovered and closing now")
            close(widget)
        end
    else
        -- -- print("I'm not visible")
    end
end

function canRequestTooltipInfo(widget)
    if widget then
        if widget:getClassName() == "UIItem" then
            local item = widget:getItem()
            if not item or widget:getId() == "containerItemWidget" or widget:isVirtual() then
                return false
            end
        end
        return true
    end

    return false
end

function showTooltip(uid, widget)
    cacheItemFromItemWidget(uid, widget)
    scheduleBuildItemTooltip(cachedItems[uid])
end

function scheduleBuildItemTooltip(item)
    if showEvent then
        -- -- print("Removing show event")
        removeEvent(showEvent)
    end
    
    -- -- print("waiting 1s")
    showEvent = scheduleEvent(function()
        buildItemTooltip(item) 
    end, 1000)
end

function buildItemTooltip(item)
    
    removeEvent(hideEvent)
    removeEvent(showEvent)

    tooltipWidth = 0
    longestString = 0
    tooltipWidthBase = BASE_WIDTH
    tooltipHeight = BASE_HEIGHT
    tooltipWindow:setWidth(tooltipWidth)
    tooltipWindow:setHeight(tooltipHeight)

    labels:destroyChildren()

    local id = item.id
    local name = item.name
    local desc = item.desc
    local iLvl = item.iLvl
    local spellrune = item.spellrune
    local reqLvl = item.reqLvl or 0
    local unidentified = item.unidentified
    local mirrored = item.mirrored
    local rarity = item.rarity
    local maxAttributes = item.maxAttributes
    local attributes = item.attributes
    local count = item.count
    local subType = item.subType
    local itemType = item.type
    local first = item.first
    local second = item.second
    local third = item.third
    local weight = item.weight
    local attackSpeed = item.attackSpeed
    local hitChance = item.hitChance
    local charges = item.charges
    local duration = item.duration
    local requiredLevelAttr = item.tierRarity

    itemSprite:setItemId(id)
    itemSprite:setItemSubType(subType)

    if (count == subType) or (count > 0 and subType == 1) then
        itemSprite:setItemCount(count)
        itemSprite:setShowCount(count > 1)
    else
        itemSprite:setShowCount(subType > 1)
    end
        itemSprite:setItemRarity(rarity)
    itemSprite:updateItemRarity()

    local itemNameColor
    if unidentified then
        itemNameColor = rarityColor[2].color
    elseif item.uniqueName then
        itemNameColor = "#dca01e"
    elseif rarity > 1 then
        itemNameColor = rarityColor[rarity].color
    else
        itemNameColor = "#ffffff"
    end

    name = name:gsub("(%a)(%a+)", function(a, b)
        return string.upper(a) .. string.lower(b)
    end)
    if item.uLvl > 0 then name = name .. " +" .. item.uLvl end
    local namewidget
    if unidentified then
        namewidget = addString("Unidentified" .. " " .. name,
                               rarityColor[2].color, false, 78)
    else
        if item.uniqueName then
            namewidget = addString(item.uniqueName .. " " .. name, "#dca01e",
                                   false, 78)
        elseif item.rarity ~= 0 then
            namewidget = addString(rarityColor[rarity].name .. " " .. name,
                                   rarityColor[rarity].color, false, 78)
        else
            namewidget = addString(name, itemNameColor, false, 78)
        end
    end

    
    addString(formatWeight(weight), "#ffffff", false, 78)

    local function getRequiredAttributesLevel(rarityLevel, tierLevel)
        
        local ITEM_UNCOMMON, ITEM_RARE, ITEM_EPIC, ITEM_LEGENDARY = 2, 3, 4, 5
        local ITEM_TIER_1, ITEM_TIER_2, ITEM_TIER_3, ITEM_TIER_4 = 1, 2, 3, 4

        if (tierLevel == ITEM_TIER_1) then
            if (rarityLevel == ITEM_UNCOMMON) then
                return 10
            elseif (rarityLevel == ITEM_RARE) then
                return 10
            elseif (rarityLevel == ITEM_EPIC) then
                return 10
            elseif (rarityLevel == ITEM_LEGENDARY) then
                return 10
            end
        elseif (tierLevel == ITEM_TIER_2) then
            if (rarityLevel == ITEM_UNCOMMON) then
                return 15
            elseif (rarityLevel == ITEM_RARE) then
                return 20
            elseif (rarityLevel == ITEM_EPIC) then
                return 25
            elseif (rarityLevel == ITEM_LEGENDARY) then
                return 30
            end
        elseif (tierLevel == ITEM_TIER_3) then
            if (rarityLevel == ITEM_UNCOMMON) then
                return 35
            elseif (rarityLevel == ITEM_RARE) then
                return 40
            elseif (rarityLevel == ITEM_EPIC) then
                return 45
            elseif (rarityLevel == ITEM_LEGENDARY) then
                return 50
            end
        elseif (tierLevel == ITEM_TIER_4) then
            if (rarityLevel == ITEM_UNCOMMON) then
                return 55
            elseif (rarityLevel == ITEM_RARE) then
                return 60
            elseif (rarityLevel == ITEM_EPIC) then
                return 65
            elseif (rarityLevel == ITEM_LEGENDARY) then
                return 70
            end
        end
        return 0
    end
    local numberBlankSpaces = true
    if requiredLevelAttr then
        local lvl = getRequiredAttributesLevel(rarity, requiredLevelAttr)
        if lvl > 0 then
            addString("Level " .. getRequiredAttributesLevel(rarity, requiredLevelAttr) .. " to active attributes", Colors.ItemLevel, false, 78)
            numberBlankSpaces = false
        end
    end

    if iLvl > 0 then addString("Item Level " .. iLvl, Colors.ItemLevel) end

    local firstText, secondText, thirdText
    if (itemType == "Armor" or itemType == "Helmet" or itemType == "Legs" or
        itemType == "Ring" or itemType == "Necklace" or itemType == "Boots") and
        first ~= 0 then
        firstText = "Armor: " .. first
    elseif itemType == "Two-Handed Sword" or itemType == "Two-Handed Club" or
        itemType == "Two-Handed Axe" or itemType == "Sword" or itemType ==
        "Club" or itemType == "Axe" or itemType == "Fist" or itemType ==
        "Distance" or itemType == "Ammunition" then
        if first > 0 then firstText = "Attack: " .. first end
    elseif itemType == "Shield" then
        firstText = "Defense: " .. second
    end

    if itemType == "Two-Handed Sword" or itemType == "Two-Handed Club" or
        itemType == "Two-Handed Axe" or itemType == "Sword" or itemType ==
        "Club" or itemType == "Axe" or itemType == "Fist" then
        secondText = "Defense: " .. second
    end

    if itemType == "Two-Handed Sword" or itemType == "Two-Handed Club" or
        itemType == "Two-Handed Axe" or itemType == "Sword" or itemType ==
        "Club" or itemType == "Axe" or itemType == "Fist" then
        thirdText = "Extra-Defense: " .. third
    elseif itemType == "Distance" then
        thirdText = "Shoot Range: " .. third
    end

    local manyText = 0
    if (firstText and
        (itemType == "Shield" or itemType == "Ring" or itemType == "Necklace")) or
        (first ~= 0 and second == 0 and third == 0) then
        if numberBlankSpaces then
            addEmpty(47 - 15 * 1)
        else
            addEmpty(47 - 15 * 2)
        end
        addString(firstText, "white", false, 78)
        manyText = 1
    elseif first ~= 0 and second ~= 0 and third == 0 then
        if numberBlankSpaces then
            addEmpty(47 - 15 * 2)
        else
            addEmpty(47 - 15 * 3)
        end
        addString(firstText, "white", false, 78)
        addString(secondText, "white", false, 78)
        manyText = 2
    elseif first ~= 0 and second ~= 0 and third ~= 0 then
        addEmpty(47 - 15 * 3)
        addString(firstText, "white", false, 78)
        addString(secondText, "white", false, 78)
        addString(thirdText, "white", false, 78)
        manyText = 3
    elseif itemType == "Distance" then
        if first ~= 0 and firstText then
            manyText = manyText + 1
        end
        if second ~= 0 and secondText then
            manyText = manyText + 1
        end
        if third ~= 0 and thirdText then
            manyText = manyText + 1
        end

        if not numberBlankSpaces then
            manyText = manyText + 1
        end
        addEmpty(47 - 15 * manyText)
        if not numberBlankSpaces then
            manyText = manyText - 1
        end

        if first ~= 0 and firstText then
            addString(firstText, "white", false, 78)
        end
        if second ~= 0 and secondText then
            addString(secondText, "white", false, 78)
        end
        if third ~= 0 and thirdText then
            addString(thirdText, "white", false, 78)
        end
    end

    if manyText == 0 then
        addEmpty(50)
    end

    addEmpty(2)

    if reqLvl > 0 then
        addString("Required Level " .. reqLvl, Colors.ItemLevel)
    end

    if spellrune then
        local spell = spellrune:split(" for level ")[1]
        local level = spellrune:split(" for level ")[2]
        addSeparator()
        addEmpty(5)
        if level then
            addString("spell \"" .. spell:lower() .. "\"", Colors.Implicit)
            addString("spell rune for level " .. tostring(level),
                      Colors.Implicit)
        else
            addString("spell rune", Colors.Implicit)
            addEmpty(6)
        end
    end

    if isWeapon(itemType) then
        addSeparator()
        addEmpty(5)

        addString(formatItemType(itemType), Colors.Implicit)
        if attackSpeed ~= nil and attackSpeed > 0 then
            addString("Attack Interval: " .. attackSpeed / 1000 .. "s", Colors.Default)
        end
        if hitChance ~= nil and hitChance > 0 then
            addString("Hit chance: +" .. hitChance .. "%", Colors.Default)
        end
    end

    if duration ~= -1 or charges > 0 then
        addSeparator()
        addEmpty(5)

        if duration ~= -1 then
            local durationReal = 0
            if duration == 0 then
                addString("Duration: brand-new", Colors.Default)
            elseif duration >= 120 then
                durationReal = math.floor(duration / 60)
                addString("Duration: " .. durationReal .. " minutes",
                          Colors.Default)
            elseif duration > 60 then
                durationReal = 1
                addString("Duration: " .. durationReal .. " minute",
                          Colors.Default)
            else
                addString("Duration: less than a minute", Colors.Default)
            end
        end

        if charges > 0 then
            addString("Charges: " .. charges, Colors.Default)
        end
    end

    if item.imp then
        local attrTable, nonAttrTable = filterImplitics(item.imp)

        nonAttrTable = sortImplitics(nonAttrTable)
        if next(nonAttrTable) ~= nil then
            addSeparator()
            addEmpty(5)
            for key, value in pairs(nonAttrTable) do
                local impText = getImpliticsText(key, value)
                addString(impText, Colors.Implicit)
            end
        end

        if next(attrTable) ~= nil then
            addSeparator()
            addEmpty(5)
            for key, value in pairs(attrTable) do
                local impText = getImpliticsText(key, value)
                addString(impText, Colors.RarityAttribute)
            end
        end
        addEmpty(5)

    end

    if item.rarity ~= 0 and maxAttributes ~= 0 then
        addSeparator()
        addEmpty(5)
        for i = 1, maxAttributes do
            addString(attributes[i], Colors.Attribute)
        end
    end

    if mirrored then
        addEmpty(5)
        addString("Mirrored", Colors.Mirrored)
    end

    if desc and desc:len() > 0 then
        addSeparator()
        addEmpty(5)
        desc = desc:trim()
        addString(desc, Colors.Description, true)
    end

    shrinkSeparators()

    if isLinkedView then
        tooltipWindow:removeAnchor(AnchorRight)
        tooltipWindow:addAnchor(AnchorLeft, "gameLeftPanels", AnchorRight)
    else
        tooltipWindow:removeAnchor(AnchorLeft)
        tooltipWindow:addAnchor(AnchorRight, "gameRightPanels", AnchorLeft)
    end

    tooltipHeight = math.max(tooltipHeight, 40 + 36)
    tooltipWindow:setWidth(tooltipWidth)
    tooltipWindow:setHeight(tooltipHeight)

    tooltipWindow:raise()
    tooltipWindow:show()
    g_effects.fadeIn(tooltipWindow, 350)
    tooltipWindow.tooltipVisible = true
end
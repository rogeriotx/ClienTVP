local MainWindow,
    BuyPanel,
    SellPanel,
    HistoricPanel,
    BuyOffersPanel,
    MyBuyOffersPanel,
    sellConfirmWindow,
    createBuyOfferWindow,
    FulfillBuyOfferWindow,
    marketButton = nil
local Current = {}
Market = {}
Market.opcode = 179
Market.currencies = {} -- Will be populated from server
Market.itemsDatabase = {} -- Will be populated from items.xml
Market.itemsDatabaseLoaded = false
local descHolder = ""
local orderId = 1
local TOOLTIP_ATTRIBUTE_ATTACK        = 1
local TOOLTIP_ATTRIBUTE_DEFENSE       = 2
local TOOLTIP_ATTRIBUTE_NAME          = 3
local TOOLTIP_ATTRIBUTE_WEIGHT        = 4
local TOOLTIP_ATTRIBUTE_ARMOR         = 5
local TOOLTIP_ATTRIBUTE_HITCHANCE     = 6
local TOOLTIP_ATTRIBUTE_SHOOTRANGE    = 7
local TOOLTIP_ATTRIBUTE_DURATION      = 8
local TOOLTIP_ATTRIBUTE_CHARGES       = 9
local TOOLTIP_ATTRIBUTE_ATTACK_SPEED  = 11
local TOOLTIP_ATTRIBUTE_RESISTANCES   = 12
local TOOLTIP_ATTRIBUTE_STATS         = 13
local TOOLTIP_ATTRIBUTE_SKILL         = 14
local TOOLTIP_ATTRIBUTE_SPEED         = 23
local TOOLTIP_ATTRIBUTE_RARITY        = 24
local TOOLTIP_ATTRIBUTE_EXTRADEFENSE  = 35
local TOOLTIP_ATTRIBUTE_TIER          = 42
local TOOLTIP_ATTRIBUTE_INCREMENTS    = 38
local TOOLTIP_ATTRIBUTE_EXPERIENCE    = 37
local TOOLTIP_ATTRIBUTE_INCREMENT_COINS = 36

local MARKET_RARITY_COLORS = {
    [1] = "#74C365",  -- Common (verde)
    [2] = "#0096FF",  -- Rare (azul)
    [3] = "#8040BF",  -- Epic (roxo)
    [4] = "#FCC200",  -- Legendary (dourado)
    [5] = "#DE0913"   -- Brutal (vermelho)
}
local MARKET_RARITY_NAMES = {
    [0] = "None",
    [1] = "Common",
    [2] = "Rare",
    [3] = "Epic",
    [4] = "Legendary",
    [5] = "Brutal"
}

-- Helper function to format buy offer filters
local function formatBuyOfferFilters(buy_offer)
    local filters = {}
    
    -- Rarity filter
    if buy_offer.rarity and buy_offer.rarity > 0 then
        local rarityName = MARKET_RARITY_NAMES[buy_offer.rarity] or "?"
        table.insert(filters, rarityName)
    end
    
    -- Tier filter
    if buy_offer.tier and buy_offer.tier > 0 then
        table.insert(filters, "T" .. buy_offer.tier)
    end
    
    if #filters == 0 then
        return "Any"
    else
        return table.concat(filters, " ")
    end
end

local function formatMoney(price)
	local tokens = ""
	if price >= 100000000 then
		tokens = {amount = string.format("%.1f", (math.floor(price / 100000000 * 10) / 10)), name = "GMT"}
	elseif price >= 1000000 then
		tokens = {amount = string.format("%.1f", (math.floor(price / 1000000 * 10) / 10)), name = "MMT"}
	elseif price >= 10000 then
		tokens = {amount = string.format("%.1f", (math.floor(price / 10000 * 10) / 10)), name = "W"}
	elseif price >= 100 then
		tokens = {amount = string.format("%.1f", (math.floor(price / 100 * 10) / 10)), name = "P"}
	else
		tokens = {amount = price, name = "MC"}
	end
	
	local str = ""
		str = tokens.amount .. " " .. tokens.name
	return str
end

local function getMarketVisualData(entry)
    if type(entry) ~= "table" then
        return 0, 0
    end

    local rarity = tonumber(entry.rarity) or 0
    local tier = tonumber(entry.tier) or 0

    if (rarity <= 0 or tier <= 0) and entry.tooltip_data then
        local ok, tooltip = pcall(json.decode, entry.tooltip_data)
        if ok and type(tooltip) == "table" then
            for _, attribute in ipairs(tooltip) do
                if type(attribute) == "table" then
                    if rarity <= 0 and attribute.id == TOOLTIP_ATTRIBUTE_RARITY then
                        rarity = tonumber(attribute.value) or rarity
                    elseif tier <= 0 and attribute.id == TOOLTIP_ATTRIBUTE_TIER then
                        tier = tonumber(attribute.value) or tier
                    end
                end
            end
        end
    end

    return rarity, tier
end

local function applyMarketVisualState(widget, entry, nameChildId)
    if not widget then
        return
    end

    local rarity, tier = getMarketVisualData(entry)
    local itemWidget = widget:getChildById("item")
    local nameWidget = widget:getChildById(nameChildId or "name")
    local rarityWidget = widget:getChildById("rarity")

    -- Colorir o nome com a cor da raridade
    if nameWidget then
        nameWidget:setColor(MARKET_RARITY_COLORS[rarity] or "#ffffff")
    end

    -- Mostrar o nome da raridade na coluna rarity
    if rarityWidget then
        local rarityName = MARKET_RARITY_NAMES[rarity] or "None"
        rarityWidget:setText(rarityName)
        rarityWidget:setColor(MARKET_RARITY_COLORS[rarity] or "#888888")
    end

    -- Aplicar frame de raridade no widget do item
    if itemWidget then
        if g_game.updateRarityFrames then
            g_game.updateRarityFrames(itemWidget, rarity)
        end

        if g_game.updateTierIcon then
            g_game.updateTierIcon(itemWidget, tier)
        end
    end
end

-- Tooltip customizado para market
local marketTooltipWindow = nil

-- Funo helper para definir item ID com segurana
local function safeSetItemId(widget, itemId)
    if not widget or not itemId then
        return false
    end
    
    -- Verificar se o ID est em um range vlido
    if itemId <= 0 or itemId > 30000 then
        return false
    end
    
    -- Tentar definir o item ID com proteo
    local success = pcall(function()
        widget:setItemId(itemId)
    end)
    
    return success
end

local function hideMarketTooltip()
    if marketTooltipWindow then
        marketTooltipWindow:destroy()
        marketTooltipWindow = nil
    end
end

local function showMarketTooltip(market_item)
    hideMarketTooltip()
    
    if not market_item.tooltip_data then
        return
    end
    
    local ok, tooltip = pcall(json.decode, market_item.tooltip_data)
    if not ok or type(tooltip) ~= "table" then
        return
    end
    
    -- Criar tooltip como UIWidget simples
    local parent = rootWidget  -- Usar rootWidget diretamente para mximo z-order
    
    marketTooltipWindow = g_ui.createWidget('UIWidget', parent)
    if not marketTooltipWindow then
        return
    end
    
    marketTooltipWindow:setId('marketTooltip')
    marketTooltipWindow:setFocusable(false)
    marketTooltipWindow:setPhantom(false)
    marketTooltipWindow:setVisible(true)
    marketTooltipWindow:setBackgroundColor('#1a1a1aee')
    marketTooltipWindow:setBorderWidth(2)
    marketTooltipWindow:setBorderColor('#FFD700')
    marketTooltipWindow:setWidth(250)
    
    local yPos = 8  -- Comear com padding
    
    -- Processar dados primeiro
    local itemName = ""
    local rarityValue = 0
    local attributes = {}
    
    for _, attr in ipairs(tooltip) do
        if attr.id == 3 then
            itemName = attr.value
        elseif attr.id == 24 then
            rarityValue = tonumber(attr.value) or 0
        elseif attr.id == 5 then
            table.insert(attributes, "Armor: " .. attr.value)
        elseif attr.id == 9 then
            table.insert(attributes, "Charges: " .. attr.value)
        elseif attr.id == 12 then
            local resistNames = {[0]="Physical", [1]="Energy", [2]="Earth", [3]="Fire", [9]="Ice", [10]="Holy", [11]="Death"}
            if resistNames[attr.type] then
                table.insert(attributes, resistNames[attr.type] .. " Absorb: +" .. attr.value .. "%")
            end
        elseif attr.id == 13 then
            local statNames = {[0]="Maximum Health", [1]="Maximum Mana", [3]="Magic Level"}
            if statNames[attr.type] then
                table.insert(attributes, statNames[attr.type] .. ": +" .. attr.value)
            end
        elseif attr.id == 14 then
            local skillNames = {[0]="Fist", [1]="Club", [2]="Sword", [3]="Axe", [4]="Distance", [5]="Shielding"}
            if skillNames[attr.type] then
                local skillText = skillNames[attr.type]
                -- No adicionar "Fighting" para Shielding
                if attr.type == 5 then
                    table.insert(attributes, skillText .. ": +" .. attr.value)
                else
                    table.insert(attributes, skillText .. " Fighting: +" .. attr.value)
                end
            end
        elseif attr.id == 23 then
            table.insert(attributes, "Speed: +" .. attr.value)
        elseif attr.id == 32 then
            table.insert(attributes, "Extra Gold: +" .. attr.value .. "%")
        end
    end
    
    -- Criar item icon (com verificao de validade)
    local itemIcon = g_ui.createWidget('Item', marketTooltipWindow)
    itemIcon:setVirtual(true)
    
    -- Tentar definir o item ID com segurana
    if not safeSetItemId(itemIcon, market_item.clientId) then
        -- Se falhar, usar um item padro (gold coin = 2148)
        safeSetItemId(itemIcon, 2148)
    end
    
    itemIcon:setMarginTop(yPos)
    itemIcon:addAnchor(AnchorTop, 'parent', AnchorTop)
    itemIcon:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
    yPos = yPos + 40
    
    -- Nome do item
    local rarityNames = {"", "Common", "Rare", "Epic", "Legendary", "Brutal"}
    local fullName = itemName
    if rarityValue > 0 and rarityValue <= 5 then
        fullName = rarityNames[rarityValue] .. " " .. itemName
    end
    
    local nameLabel = g_ui.createWidget('Label', marketTooltipWindow)
    nameLabel:setText(fullName)
    nameLabel:setColor(MARKET_RARITY_COLORS[rarityValue] or "#ffffff")
    nameLabel:setFont('verdana-11px-rounded')
    nameLabel:setTextAlign(AlignCenter)
    nameLabel:setMarginTop(yPos)
    nameLabel:addAnchor(AnchorTop, 'parent', AnchorTop)
    nameLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    nameLabel:addAnchor(AnchorRight, 'parent', AnchorRight)
    yPos = yPos + 18
    
    -- Separador
    local separator = g_ui.createWidget('UIWidget', marketTooltipWindow)
    separator:setHeight(1)
    separator:setBackgroundColor('#FFD700')
    separator:setMarginTop(yPos)
    separator:setMarginLeft(8)
    separator:setMarginRight(8)
    separator:addAnchor(AnchorTop, 'parent', AnchorTop)
    separator:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    separator:addAnchor(AnchorRight, 'parent', AnchorRight)
    yPos = yPos + 4
    
    -- Seo de raridade
    if rarityValue > 0 then
        local rarityHeader = g_ui.createWidget('Label', marketTooltipWindow)
        rarityHeader:setText("Rarity")
        rarityHeader:setColor("#cccccc")
        rarityHeader:setFont('verdana-11px-rounded')
        rarityHeader:setTextAlign(AlignCenter)
        rarityHeader:setMarginTop(yPos)
        rarityHeader:addAnchor(AnchorTop, 'parent', AnchorTop)
        rarityHeader:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        rarityHeader:addAnchor(AnchorRight, 'parent', AnchorRight)
        yPos = yPos + 16
        
        local rarityValueLabel = g_ui.createWidget('Label', marketTooltipWindow)
        rarityValueLabel:setText(rarityNames[rarityValue])
        rarityValueLabel:setColor(MARKET_RARITY_COLORS[rarityValue] or "#ffffff")
        rarityValueLabel:setFont('verdana-11px-rounded')
        rarityValueLabel:setTextAlign(AlignCenter)
        rarityValueLabel:setMarginTop(yPos)
        rarityValueLabel:addAnchor(AnchorTop, 'parent', AnchorTop)
        rarityValueLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        rarityValueLabel:addAnchor(AnchorRight, 'parent', AnchorRight)
        yPos = yPos + 18
    end
    
    -- Seo de atributos
    if #attributes > 0 then
        local attrHeader = g_ui.createWidget('Label', marketTooltipWindow)
        attrHeader:setText("Attributes")
        attrHeader:setColor("#cccccc")
        attrHeader:setFont('verdana-11px-rounded')
        attrHeader:setTextAlign(AlignCenter)
        attrHeader:setMarginTop(yPos)
        attrHeader:addAnchor(AnchorTop, 'parent', AnchorTop)
        attrHeader:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        attrHeader:addAnchor(AnchorRight, 'parent', AnchorRight)
        yPos = yPos + 16
        
        for _, attrText in ipairs(attributes) do
            local attrLabel = g_ui.createWidget('Label', marketTooltipWindow)
            attrLabel:setText(attrText)
            attrLabel:setColor("#ffffff")
            attrLabel:setFont('verdana-11px-rounded')
            attrLabel:setTextAlign(AlignLeft)
            attrLabel:setMarginTop(yPos)
            attrLabel:setMarginLeft(10)
            attrLabel:addAnchor(AnchorTop, 'parent', AnchorTop)
            attrLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
            attrLabel:addAnchor(AnchorRight, 'parent', AnchorRight)
            yPos = yPos + 16
        end
    end
    
    -- Ajustar altura final
    marketTooltipWindow:setHeight(yPos + 8)
    
    -- Posicionar prximo ao mouse
    local mousePos = g_window.getMousePosition()
    local windowSize = g_window.getSize()
    
    local x = mousePos.x + 15
    local y = mousePos.y + 15
    
    -- Ajustar se sair da tela
    if x + 250 > windowSize.width then
        x = mousePos.x - 250 - 5
    end
    if y + (yPos + 8) > windowSize.height then
        y = mousePos.y - (yPos + 8) - 5
    end
    
    marketTooltipWindow:setPosition({x = x, y = y})
    marketTooltipWindow:setVisible(true)
    marketTooltipWindow:show()
    marketTooltipWindow:raise()
end

-- Funo para formatar tooltip_data em texto para g_tooltip nativo
function formatTooltipText(tooltip)
    if not tooltip or type(tooltip) ~= "table" then
        return ""
    end
    
    local lines = {}
    local itemName = ""
    local rarityValue = 0
    local armor = nil
    local resistances = {}
    local stats = {}
    local skills = {}
    local special = {}
    
    -- Processar e categorizar atributos
    for _, attr in ipairs(tooltip) do
        if attr.id == 3 then -- NAME
            itemName = attr.value
        elseif attr.id == 24 then -- RARITY
            rarityValue = tonumber(attr.value) or 0
        elseif attr.id == 5 then -- ARMOR
            armor = attr.value
        elseif attr.id == 9 then -- CHARGES
            table.insert(special, "Charges: " .. attr.value)
        elseif attr.id == 12 then -- RESISTANCES
            local resistNames = {[0]="Physical", [1]="Energy", [2]="Earth", [3]="Fire", [9]="Ice", [10]="Holy", [11]="Death"}
            if resistNames[attr.type] then
                table.insert(resistances, resistNames[attr.type] .. " Absorb: +" .. attr.value .. "%")
            end
        elseif attr.id == 13 then -- STATS
            local statNames = {[0]="Maximum Health", [1]="Maximum Mana", [3]="Magic Level"}
            if statNames[attr.type] then
                table.insert(stats, statNames[attr.type] .. ": +" .. attr.value)
            end
        elseif attr.id == 14 then -- SKILLS
            local skillNames = {[0]="Fist", [1]="Club", [2]="Sword", [3]="Axe", [4]="Distance", [5]="Shielding"}
            if skillNames[attr.type] then
                table.insert(skills, skillNames[attr.type] .. " Fighting: +" .. attr.value)
            end
        elseif attr.id == 23 then -- SPEED
            table.insert(special, "Speed: +" .. attr.value)
        elseif attr.id == 32 then -- EXTRA GOLD
            table.insert(special, "Extra Gold: +" .. attr.value .. "%")
        end
    end
    
    -- Montar texto formatado com sees
    local rarityNames = {"", "Common", "Rare", "Epic", "Legendary", "Brutal"}
    local fullName = itemName
    if rarityValue > 0 and rarityValue <= 5 then
        fullName = rarityNames[rarityValue] .. " " .. itemName
    end
    
    -- Comear com o nome
    local text = fullName
    
    -- Adicionar armor se houver
    if armor then
        text = text .. "\n\nArmor: " .. armor
    end
    
    -- Adicionar seo de raridade
    if rarityValue > 0 then
        text = text .. "\n\nRarity\n" .. rarityNames[rarityValue]
    end
    
    -- Adicionar seo de atributos
    local hasAttributes = #resistances > 0 or #stats > 0 or #skills > 0 or #special > 0
    if hasAttributes then
        text = text .. "\n\nAttributes"
        
        -- Resistances
        for _, res in ipairs(resistances) do
            text = text .. "\n" .. res
        end
        
        -- Stats
        for _, stat in ipairs(stats) do
            text = text .. "\n" .. stat
        end
        
        -- Skills
        for _, skill in ipairs(skills) do
            text = text .. "\n" .. skill
        end
        
        -- Special
        for _, spec in ipairs(special) do
            text = text .. "\n" .. spec
        end
    end
    
    return text
end

-- Funes helper para exibir tooltip usando o mdulo game_tooltip
-- Se o mdulo no estiver disponvel, cria tooltip simples
local tooltipWindow = nil

local function marketTooltipShow(tooltip, itemId, mousePos)
    print("[MARKET TOOLTIP] marketTooltipShow called")
    print("[MARKET TOOLTIP] itemId:", itemId)
    print("[MARKET TOOLTIP] tooltip type:", type(tooltip))
    print("[MARKET TOOLTIP] tooltip:", json.encode(tooltip))
    print("[MARKET TOOLTIP] m_TooltipFunction exists:", m_TooltipFunction ~= nil)
    print("[MARKET TOOLTIP] m_TooltipFunction.open exists:", m_TooltipFunction and m_TooltipFunction.open ~= nil)
    
    -- Tentar usar mdulo game_tooltip primeiro
    if m_TooltipFunction and m_TooltipFunction.open then
        print("[MARKET TOOLTIP] Using game_tooltip module")
        m_TooltipList.itemId = itemId
        m_TooltipList.position = mousePos or {x = g_window.getMousePosition().x, y = g_window.getMousePosition().y}
        
        print("[MARKET TOOLTIP] m_TooltipList.itemId:", m_TooltipList.itemId)
        print("[MARKET TOOLTIP] m_TooltipList.position:", m_TooltipList.position.x, m_TooltipList.position.y)
        
        print("[MARKET TOOLTIP] Calling m_TooltipFunction.open...")
        m_TooltipFunction.open(tooltip)
        print("[MARKET TOOLTIP] Tooltip opened successfully")
        return true
    end
    
    -- Fallback: criar tooltip simples
    print("[MARKET TOOLTIP] game_tooltip not available, creating simple tooltip")
    
    -- Destruir tooltip anterior se existir
    if tooltipWindow then
        tooltipWindow:destroy()
        tooltipWindow = nil
    end
    
    -- Tentar carregar do arquivo .otui primeiro
    local success, widget = pcall(g_ui.loadUI, 'tooltip.otui', modules.game_interface.getRootPanel())
    if success and widget then
        tooltipWindow = widget
        print("[MARKET TOOLTIP] Tooltip loaded from .otui file")
    else
        -- Fallback: criar manualmente
        print("[MARKET TOOLTIP] Creating tooltip manually (otui load failed)")
        tooltipWindow = g_ui.createWidget('UIWidget', modules.game_interface.getRootPanel())
        if not tooltipWindow then
            print("[MARKET TOOLTIP] ERROR: Failed to create tooltip window!")
            return false
        end
        
        tooltipWindow:setId('marketTooltipWindow')
        tooltipWindow:setFocusable(false)
        tooltipWindow:setVisible(true)
        tooltipWindow:setPaddingLeft(10)
        tooltipWindow:setPaddingRight(10)
        tooltipWindow:setPaddingTop(10)
        tooltipWindow:setPaddingBottom(10)
        tooltipWindow:setBackgroundColor('#000000EE')
        tooltipWindow:setBorderWidth(2)
        tooltipWindow:setBorderColor('#FFD700')
    end
    
    print("[MARKET TOOLTIP] Tooltip window created, processing attributes...")
    
    -- Processar atributos
    local lines = {}
    local itemName = ""
    local rarityValue = 0
    
    for _, attr in ipairs(tooltip) do
        if attr.id == 3 then -- NAME
            itemName = attr.value
        elseif attr.id == 24 then -- RARITY
            rarityValue = tonumber(attr.value) or 0
        elseif attr.id == 5 then -- ARMOR
            table.insert(lines, "Armor: " .. attr.value)
        elseif attr.id == 9 then -- CHARGES
            table.insert(lines, "Charges: " .. attr.value)
        elseif attr.id == 12 then -- RESISTANCES
            local resistNames = {[0]="Physical", [1]="Energy", [2]="Earth", [3]="Fire", [9]="Ice", [10]="Holy", [11]="Death"}
            if resistNames[attr.type] then
                table.insert(lines, resistNames[attr.type] .. " Absorb: +" .. attr.value .. "%")
            end
        elseif attr.id == 13 then -- STATS
            local statNames = {[0]="Maximum Health", [1]="Maximum Mana", [3]="Magic Level"}
            if statNames[attr.type] then
                table.insert(lines, statNames[attr.type] .. ": +" .. attr.value)
            end
        elseif attr.id == 14 then -- SKILLS
            local skillNames = {[0]="Fist", [1]="Club", [2]="Sword", [3]="Axe", [4]="Distance", [5]="Shielding"}
            if skillNames[attr.type] then
                table.insert(lines, skillNames[attr.type] .. " Fighting: +" .. attr.value)
            end
        elseif attr.id == 23 then -- SPEED
            table.insert(lines, "Speed: +" .. attr.value)
        elseif attr.id == 32 then -- EXTRA GOLD
            table.insert(lines, "Extra Gold: +" .. attr.value .. "%")
        end
    end
    
    print("[MARKET TOOLTIP] Processed", #lines, "attribute lines, itemName:", itemName, "rarity:", rarityValue)
    
    -- Se carregou do .otui, usar os widgets existentes
    local titleLabel = tooltipWindow:getChildById('titleLabel')
    local contentPanel = tooltipWindow:getChildById('contentPanel')
    
    if titleLabel and contentPanel then
        print("[MARKET TOOLTIP] Using .otui structure")
        -- Configurar ttulo
        local rarityNames = {"", "Common", "Rare", "Epic", "Legendary", "Brutal"}
        local fullName = itemName
        if rarityValue > 0 and rarityValue <= 5 then
            fullName = rarityNames[rarityValue] .. " " .. itemName
        end
        titleLabel:setText(fullName)
        titleLabel:setColor(MARKET_RARITY_COLORS[rarityValue] or "#FFD700")
        
        -- Adicionar atributos ao contentPanel
        for _, line in ipairs(lines) do
            local label = g_ui.createWidget('Label', contentPanel)
            label:setText(line)
            label:setColor('#ffffff')
            label:setFont('verdana-11px-rounded')
        end
        
        tooltipWindow:setWidth(240)
        tooltipWindow:setHeight(60 + (#lines * 16))
    else
        -- Criar manualmente (fallback do fallback)
        print("[MARKET TOOLTIP] Using manual structure")
        local yPos = 0
        
        -- Adicionar nome com raridade
        if itemName ~= "" then
            local rarityNames = {"", "Common", "Rare", "Epic", "Legendary", "Brutal"}
            local fullName = itemName
            if rarityValue > 0 and rarityValue <= 5 then
                fullName = rarityNames[rarityValue] .. " " .. itemName
            end
            
            local nameLabel = g_ui.createWidget('Label', tooltipWindow)
            if nameLabel then
                nameLabel:setText(fullName)
                nameLabel:setTextAlign(AlignCenter)
                nameLabel:setColor(MARKET_RARITY_COLORS[rarityValue] or "#ffffff")
                nameLabel:setFont('verdana-11px-rounded')
                nameLabel:setHeight(18)
                nameLabel:setWidth(220)
                nameLabel:setX(0)
                nameLabel:setY(yPos)
                nameLabel:setVisible(true)
                yPos = yPos + 20
            end
        end
        
        -- Adicionar separador
        if #lines > 0 and itemName ~= "" then
            local separator = g_ui.createWidget('UIWidget', tooltipWindow)
            if separator then
                separator:setHeight(2)
                separator:setWidth(220)
                separator:setX(0)
                separator:setY(yPos)
                separator:setBackgroundColor('#FFD700')
                separator:setVisible(true)
                yPos = yPos + 6
            end
        end
        
        -- Adicionar labels para cada atributo
        for i, line in ipairs(lines) do
            local label = g_ui.createWidget('Label', tooltipWindow)
            if label then
                label:setText(line)
                label:setTextAlign(AlignLeft)
                label:setColor('#ffffff')
                label:setFont('verdana-11px-rounded')
                label:setHeight(16)
                label:setWidth(220)
                label:setX(0)
                label:setY(yPos)
                label:setVisible(true)
                yPos = yPos + 16
            end
        end
        
        tooltipWindow:setWidth(240)
        tooltipWindow:setHeight(yPos + 10)
    end
    
    -- Posicionar tooltip
    local pos = mousePos or {x = g_window.getMousePosition().x, y = g_window.getMousePosition().y}
    tooltipWindow:setPosition({x = pos.x + 15, y = pos.y + 15})
    
    print("[MARKET TOOLTIP] Tooltip positioned at", pos.x + 15, pos.y + 15)
    
    -- Garantir que est visvel e no topo
    tooltipWindow:setVisible(true)
    tooltipWindow:show()
    tooltipWindow:raise()
    tooltipWindow:focus()
    
    print("[MARKET TOOLTIP] Tooltip visible:", tooltipWindow:isVisible())
    print("[MARKET TOOLTIP] Simple tooltip created with", #lines, "attribute lines")
    return true
end

-- Funo para mostrar janela de detalhes do item (popup modal)
function showItemDetailsWindow(market_item)
    print("[ITEM DETAILS] Opening details window for:", market_item.item_name)
    
    if not market_item.tooltip_data then
        print("[ITEM DETAILS] No tooltip_data available")
        return
    end
    
    -- Decodificar tooltip_data
    local ok, tooltip = pcall(json.decode, market_item.tooltip_data)
    if not ok or type(tooltip) ~= "table" then
        print("[ITEM DETAILS] Failed to decode tooltip_data")
        return
    end
    
    -- Criar janela
    local window = g_ui.loadUI('item_details.otui', modules.game_interface.getRootPanel())
    if not window then
        print("[ITEM DETAILS] Failed to load item_details.otui")
        return
    end
    
    -- Processar atributos
    local itemName = ""
    local rarityValue = 0
    local attributes = {}
    
    for _, attr in ipairs(tooltip) do
        if attr.id == 3 then -- NAME
            itemName = attr.value
        elseif attr.id == 24 then -- RARITY
            rarityValue = tonumber(attr.value) or 0
        elseif attr.id == 5 then -- ARMOR
            table.insert(attributes, "Armor: " .. attr.value)
        elseif attr.id == 9 then -- CHARGES
            table.insert(attributes, "Charges: " .. attr.value)
        elseif attr.id == 12 then -- RESISTANCES
            local resistNames = {[0]="Physical", [1]="Energy", [2]="Earth", [3]="Fire", [9]="Ice", [10]="Holy", [11]="Death"}
            if resistNames[attr.type] then
                table.insert(attributes, resistNames[attr.type] .. " Absorb: +" .. attr.value .. "%")
            end
        elseif attr.id == 13 then -- STATS
            local statNames = {[0]="Maximum Health", [1]="Maximum Mana", [3]="Magic Level"}
            if statNames[attr.type] then
                table.insert(attributes, statNames[attr.type] .. ": +" .. attr.value)
            end
        elseif attr.id == 14 then -- SKILLS
            local skillNames = {[0]="Fist", [1]="Club", [2]="Sword", [3]="Axe", [4]="Distance", [5]="Shielding"}
            if skillNames[attr.type] then
                table.insert(attributes, skillNames[attr.type] .. " Fighting: +" .. attr.value)
            end
        elseif attr.id == 23 then -- SPEED
            table.insert(attributes, "Speed: +" .. attr.value)
        elseif attr.id == 32 then -- EXTRA GOLD
            table.insert(attributes, "Extra Gold: +" .. attr.value .. "%")
        end
    end
    
    -- Configurar ttulo
    local rarityNames = {"", "Common", "Rare", "Epic", "Legendary", "Brutal"}
    local fullName = itemName
    if rarityValue > 0 and rarityValue <= 5 then
        fullName = rarityNames[rarityValue] .. " " .. itemName
    end
    
    local nameLabel = window:getChildById('itemName')
    if nameLabel then
        nameLabel:setText(fullName)
        nameLabel:setColor(MARKET_RARITY_COLORS[rarityValue] or "#FFD700")
    end
    
    -- Adicionar atributos  lista
    local attributesList = window:getChildById('attributesList')
    if attributesList then
        for _, attrText in ipairs(attributes) do
            attributesList:addText(attrText)
        end
    end
    
    window:show()
    window:raise()
    window:focus()
    
    print("[ITEM DETAILS] Window opened with", #attributes, "attributes")
end

local function marketTooltipHide()
    print("[MARKET TOOLTIP] marketTooltipHide called")
    
    -- Tentar usar mdulo game_tooltip primeiro
    if m_TooltipFunction and m_TooltipFunction.destroy then
        print("[MARKET TOOLTIP] Destroying tooltip using game_tooltip...")
        m_TooltipFunction.destroy()
        print("[MARKET TOOLTIP] Tooltip destroyed")
        return
    end
    
    -- Fallback: destruir tooltip simples
    if tooltipWindow then
        print("[MARKET TOOLTIP] Destroying simple tooltip...")
        tooltipWindow:destroy()
        tooltipWindow = nil
        print("[MARKET TOOLTIP] Simple tooltip destroyed")
    else
        print("[MARKET TOOLTIP] No tooltip to destroy")
    end
end

-- Load and parse items.xml to build searchable database
function loadItemsDatabase()
    if Market.itemsDatabaseLoaded then
        return
    end

    local itemsXmlCandidates = {
        "/mods/game_marketplace/items.xml",
        "/data/things/800/items.xml",
        "/things/800/items.xml"
    }
    local itemsXmlPath = nil

    for _, candidatePath in ipairs(itemsXmlCandidates) do
        if g_resources.fileExists(candidatePath) then
            itemsXmlPath = candidatePath
            break
        end
    end

    if not itemsXmlPath then
        g_logger.warning("Market: items.xml not found in known resource paths")
        return
    end

    local content = g_resources.readFileContents(itemsXmlPath)

    if not content or content == "" then
        g_logger.warning("Market: Failed to load items.xml from " .. itemsXmlPath)
        return
    end

    Market.itemsDatabase = {}

    -- Parse single items: <item id="2148" article="a" name="gold coin">
    for id, article, name in content:gmatch('<item%s+id="(%d+)"%s*article="([^"]*)"%s*name="([^"]+)"') do
        local itemId = tonumber(id)
        if itemId and name ~= "" then
            Market.itemsDatabase[itemId] = {name = name, article = article}
        end
    end

    -- Parse single items without article: <item id="100" name="void">
    for id, name in content:gmatch('<item%s+id="(%d+)"%s*name="([^"]+)"') do
        local itemId = tonumber(id)
        if itemId and name ~= "" and not Market.itemsDatabase[itemId] then
            Market.itemsDatabase[itemId] = {name = name, article = ""}
        end
    end

    -- Parse item ranges with article: <item fromid="108" toid="109" article="a" name="flowers">
    for fromId, toId, article, name in content:gmatch(
        '<item%s+fromid="(%d+)"%s+toid="(%d+)"%s*article="([^"]*)"%s*name="([^"]+)"'
    ) do
        local startId = tonumber(fromId)
        local endId = tonumber(toId)
        if startId and endId and name ~= "" then
            for itemId = startId, endId do
                if not Market.itemsDatabase[itemId] then
                    Market.itemsDatabase[itemId] = {name = name, article = article}
                end
            end
        end
    end

    -- Parse item ranges without article: <item fromid="108" toid="109" name="flowers">
    for fromId, toId, name in content:gmatch('<item%s+fromid="(%d+)"%s+toid="(%d+)"%s*name="([^"]+)"') do
        local startId = tonumber(fromId)
        local endId = tonumber(toId)
        if startId and endId and name ~= "" then
            for itemId = startId, endId do
                if not Market.itemsDatabase[itemId] then
                    Market.itemsDatabase[itemId] = {name = name, article = ""}
                end
            end
        end
    end

    local count = 0
    for _ in pairs(Market.itemsDatabase) do
        count = count + 1
    end

    Market.itemsDatabaseLoaded = true
    g_logger.info("Market: Loaded " .. count .. " items from items.xml")
end

Market.time = {
    {value = 10, name = "10 seconds"},
    {value = 60 * 60 * 4, name = "4 hours"},
    {value = 60 * 60 * 8, name = "8 hours"},
    {value = 60 * 60 * 12, name = "12 hours"},
    {value = 60 * 60 * 24, name = "1 day"},
    {value = 60 * 60 * 24 * 2, name = "2 days"},
	{value = 60 * 60 * 24 * 7, name = "1 week"}
}

-- Updated categories to match server-side
Market.category = {
    all = 1,
    armor = 2,
    weapons = 3,
    shields = 4,
    distance = 5,
    ammunition = 6,
    wands = 7,
    containers = 8,
    helmets = 9,
    legs = 10,
    boots = 11,
    rings = 12,
    necklaces = 13
}

-- Display names for categories (capitalized and user-friendly)
Market.categoryNames = {
    [1] = "All",
    [2] = "Armor",
    [3] = "Weapons",
    [4] = "Shields",
    [5] = "Distance Weapons",
    [6] = "Ammunition",
    [7] = "Wands & Rods",
    [8] = "Containers",
    [9] = "Helmets",
    [10] = "Legs",
    [11] = "Boots",
    [12] = "Rings",
    [13] = "Necklaces"
}

local Marketorder = {
    timer = 1,
    item = 3,
    name = 3,
    rarity = 13,
    seller = 5,
    amount = 7,
    auction = 15,
    price = 9,
    currency = 11
}

local sortedWidget = 1
local toggleValue = true

function ordering(widget)
    for k, v in pairs(Marketorder) do
        if widget:getId() == k then
            if toggleValue == true then -- ascending
                sortedWidget = v + 1
                toggleValue = false
            else -- descending
                sortedWidget = v
                toggleValue = true
            end
        end
    end
    return sortedWidget
end

function init()
    connect(
        LocalPlayer,
        {
            onPositionChange = onPositionChange
        }
    )
    connect(
        g_game,
        {
            onGameEnd = marketoffline
        }
    )

    -- Load items database from items.xml
    loadItemsDatabase()

    MainWindow = g_ui.displayUI("market")
    if not MainWindow then
        g_logger.error("Failed to load market UI")
        return
    end

    MainWindow:hide()
    BuyPanel = MainWindow:getChildById("buyPanel")
    BuyOffersPanel = MainWindow:getChildById("buyOffersPanel")
    MyBuyOffersPanel = MainWindow:getChildById("myBuyOffersPanel")

    ---------------------------------------------------
    -- Column sorting click handlers
    if BuyPanel then
        BuyPanel:getChildById("item").onClick = function()
            orderId = ordering(BuyPanel:getChildById("item"))
            getBuyItems()
        end
        BuyPanel:getChildById("name").onClick = function()
            orderId = ordering(BuyPanel:getChildById("name"))
            getBuyItems()
        end
        BuyPanel:getChildById("rarity").onClick = function()
            orderId = ordering(BuyPanel:getChildById("rarity"))
            getBuyItems()
        end
        BuyPanel:getChildById("seller").onClick = function()
            orderId = ordering(BuyPanel:getChildById("seller"))
            getBuyItems()
        end
        BuyPanel:getChildById("amount").onClick = function()
            orderId = ordering(BuyPanel:getChildById("amount"))
            getBuyItems()
        end
        BuyPanel:getChildById("auction").onClick = function()
            orderId = ordering(BuyPanel:getChildById("auction"))
            getBuyItems()
        end
        BuyPanel:getChildById("price").onClick = function()
            orderId = ordering(BuyPanel:getChildById("price"))
            getBuyItems()
        end
        BuyPanel:getChildById("timer").onClick = function()
            orderId = ordering(BuyPanel:getChildById("timer"))
            getBuyItems()
        end
    end
    ----------------------------------------------------

    SellPanel = MainWindow:getChildById("sellPanel")
    HistoricPanel = MainWindow:getChildById("historicPanel")

    BuyNowWindow = g_ui.createWidget("BuyNowWindow", modules.game_interface.getRootPanel())
    BidWindow = g_ui.createWidget("BidWindow", modules.game_interface.getRootPanel())
    FulfillBuyOfferWindow = g_ui.createWidget("FulfillBuyOfferWindow", modules.game_interface.getRootPanel())

    -- Populate category dropdown with proper display names
    local catsWidget = MainWindow:getChildById("cats")
    if catsWidget then
        local comboBox = catsWidget:getChildById("comboBox")
        if comboBox then
            for id = 1, 13 do
                if Market.categoryNames[id] then
                    comboBox:addOption(Market.categoryNames[id], id)
                end
            end
        end

        local searchEdit = catsWidget:getChildById("searchEdit")
        if searchEdit then
            searchEdit.onTextChange = function()
                Current.search_string = searchEdit:getText()
                Current.page = 1
                getBuyItems()
            end
        end

        local comboBox2 = catsWidget:getChildById("comboBox")
        if comboBox2 then
            comboBox2.onOptionChange = function()
                Current.page = 1
                getBuyItems()
            end
        end
    end

    marketButton = (modules.game_sidemenu and modules.game_sidemenu.addModuleButton and modules.game_sidemenu.addModuleButton("MarketButton", tr("Market"), "/images/topbuttons/sidepanel/marketplace", marketWindowtoggle)) or 
        modules.client_topmenu.addRightGameToggleButton(
        "MarketButton",
        tr("Market"),
        "/images/topbuttons/inventory",
        marketWindowtoggle,
        false,
        9999
    )
    if marketButton then
        marketButton:setOn(false)
    end

    ProtocolGame.registerExtendedOpcode(Market.opcode, parseMarket)
end

function marketWindowtoggle()
    if MainWindow:isVisible() then
        MainWindow:hide()
        marketButton:setOn(false)
        if msgWindow then
            msgWindow:destroy()
            msgWindow = nil
        end
    else
        if marketButton then
            marketButton:setOn(true)
        end
        local catsWidget = MainWindow and MainWindow:getChildById("cats")
        if catsWidget then
            local searchEdit = catsWidget:getChildById("searchEdit")
            if searchEdit then
                searchEdit:setText("")
            end
            local comboBox = catsWidget:getChildById("comboBox")
            if comboBox then
                comboBox:setCurrentOption("All")
            end
        end
        showBuyPanel()
    end
end

function terminate()
    disconnect(
        LocalPlayer,
        {
            onPositionChange = onPositionChange
        }
    )
    disconnect(
        g_game,
        {
            onGameEnd = marketoffline
        }
    )
    ProtocolGame.unregisterExtendedOpcode(Market.opcode)

    if BuyPanel.event then
        removeEvent(BuyPanel.event)
        BuyPanel.event = nil
    end
    if SellPanel.event then
        removeEvent(SellPanel.event)
        SellPanel.event = nil
    end
    if BuyNowWindow then
        BuyNowWindow:destroy()
        BuyNowWindow = nil
    end
    if BidWindow then
        BidWindow:destroy()
        BidWindow = nil
    end
    if FulfillBuyOfferWindow then
        FulfillBuyOfferWindow:destroy()
        FulfillBuyOfferWindow = nil
    end
    if createBuyOfferWindow then
        createBuyOfferWindow:destroy()
        createBuyOfferWindow = nil
    end
    if MainWindow then
        MainWindow:destroy()
        MainWindow = nil
    end
    if sellConfirmWindow then
        sellConfirmWindow:destroy()
        sellConfirmWindow = nil
    end
end

function marketoffline()
    if BuyNowWindow then
        BuyNowWindow:hide()
    end
    if BidWindow then
        BidWindow:hide()
    end
    if FulfillBuyOfferWindow then
        FulfillBuyOfferWindow:hide()
    end
    if createBuyOfferWindow then
        createBuyOfferWindow:hide()
    end
    if MainWindow then
        MainWindow:hide()
    end
    if sellConfirmWindow then
        sellConfirmWindow:hide()
    end
end

function togglePage(id)
    if id == "first" then
        Current.page = 1
    elseif id == "prev" then
        Current.page = math.max(1, Current.page - 1)
    elseif id == "next" then
        Current.page = math.min(Current.max_page, Current.page + 1)
    elseif id == "last" then
        Current.page = Current.max_page
    end
    getBuyItems()
end

function getBuyItems()
    if not MainWindow then
        return
    end
    local catsWidget = MainWindow:getChildById("cats")
    if not catsWidget then
        return
    end
    local comboBox = catsWidget:getChildById("comboBox")
    if not comboBox then
        return
    end
    local option = comboBox:getCurrentOption()
    if not option then
        return
    end

    local params = {
        protocol = "buy_items",
        category = option.data,
        page = Current.page or 1,
        order = orderId,
        search_string = Current.search_string
    }
    g_game.getProtocolGame():sendExtendedOpcode(Market.opcode, json.encode(params))
end

function getSellItems()
    local params = {
        protocol = "sell_items"
    }
    g_game.getProtocolGame():sendExtendedOpcode(Market.opcode, json.encode(params))
end

function cancelSellItem(widget)
    local params = {
        protocol = "cancelsell_item",
        item_code = widget.market_item.item_code
    }
    g_game.getProtocolGame():sendExtendedOpcode(Market.opcode, json.encode(params))
end

function buyItem()
    if not Current.buyWidget then
        return
    end
    local rowItem = BuyNowWindow:getChildById("item")
    local market_item = Current.buyWidget.market_item
    rowItem:setItemId(market_item.clientId)

    -- Aplicar frame de raridade
    local rarity = select(1, getMarketVisualData(market_item))
    if g_game.updateRarityFrames then
        g_game.updateRarityFrames(rowItem, rarity)
    end

    -- Use tooltip_data if available
    rowItem.onHoverChange = function(self, hovered)
        if hovered then
            if market_item.tooltip_data then
                local ok, tooltip = pcall(json.decode, market_item.tooltip_data)
                if ok and type(tooltip) == "table" then
                    marketTooltipShow(tooltip, market_item.clientId)
                end
            end
        else
            marketTooltipHide()
        end
    end

    rowItem:setItemCount(Current.buyWidget.market_item.count)
    BuyNowWindow:setText(Current.buyWidget.market_item.item_name)

    local rowScrollbar = BuyNowWindow:getChildById("countScrollBar")
    rowScrollbar:setMinimum(1)
    rowScrollbar:setMaximum(Current.buyWidget.market_item.count)
    rowScrollbar:setText(Current.buyWidget.market_item.count)
    rowScrollbar:setValue(1)

    local rowPrice = BuyNowWindow:getChildById("price")
    rowPrice:setText(
        "Total Price: " .. formatMoney(Current.buyWidget.market_item.price * Current.buyWidget.market_item.count)
    )
    if Current.buyWidget.market_item.currency == 1 then
        rowPrice:setText(
            "Total Price: " .. formatMoney((Current.buyWidget.market_item.price) * Current.buyWidget.market_item.count)
        )
    end

    rowScrollbar.onValueChange = function(self, value)
        rowItem:setItemCount(value)
        rowScrollbar:setText(value)
        rowPrice:setText("Total Price: " .. formatMoney(value * Current.buyWidget.market_item.price))
    end

    local okButton = BuyNowWindow:getChildById("buttonOk")
    local buyFunc = function()
        local params = {
            protocol = "buy_item",
            item_code = Current.buyWidget.market_item.item_code,
            itemid = Current.buyWidget.market_item.itemid,
            buy_count = rowItem:getItemCount()
        }
        g_game.getProtocolGame():sendExtendedOpcode(Market.opcode, json.encode(params))
        show()
    end

    local cancelButton = BuyNowWindow:getChildById("buttonCancel")
    local cancelFunc = function()
        show()
    end

    BuyNowWindow.onEnter = buyFunc
    BuyNowWindow.onEscape = cancelFunc
    okButton.onClick = buyFunc
    cancelButton.onClick = cancelFunc
    MainWindow:hide()
    BuyNowWindow:show()
end

function bidItem()
    if not Current.buyWidget then
        return
    end
    local rowItem = BidWindow:getChildById("item")
    local market_item = Current.buyWidget.market_item
    BidWindow:setText(market_item.item_name)
    rowItem:setItemId(market_item.clientId)

    -- Aplicar frame de raridade
    local rarity = select(1, getMarketVisualData(market_item))
    if g_game.updateRarityFrames then
        g_game.updateRarityFrames(rowItem, rarity)
    end

    -- Use tooltip_data if available
    rowItem.onHoverChange = function(self, hovered)
        if hovered then
            if market_item.tooltip_data then
                local ok, tooltip = pcall(json.decode, market_item.tooltip_data)
                if ok and type(tooltip) == "table" then
                    marketTooltipShow(tooltip, market_item.clientId)
                end
            end
        else
            marketTooltipHide()
        end
    end

    local rowPrice = BidWindow:getChildById("price")
    rowPrice:setText(comma_value(Current.buyWidget.market_item.bid))

    local rowTextEdit = BidWindow:getChildById("edit")
    rowTextEdit:setText(Current.buyWidget.market_item.bid)
    rowTextEdit.onTextChange = function()
        local bid = tonumber(rowTextEdit:getText())
        if bid then
            rowPrice:setText(
                "Your Bid: " ..
                    comma_value(
                        math.min(Current.buyWidget.market_item.price, math.max(Current.buyWidget.market_item.bid, bid))
                    )
            )
            if Current.buyWidget.market_item.currency == 1 then
                rowPrice:setText(
                    "Your Bid: " ..
                        comma_value(
                            math.min(
                                Current.buyWidget.market_item.price,
                                math.max(Current.buyWidget.market_item.bid, bid)
                            )
                        )
                )
            end
        end
    end

    local okButton = BidWindow:getChildById("buttonOk")
    local bidFunc = function()
        local params = {
            protocol = "bid_item",
            item_code = Current.buyWidget.market_item.item_code,
            bid = tonumber(rowTextEdit:getText())
        }
        g_game.getProtocolGame():sendExtendedOpcode(Market.opcode, json.encode(params))
        show()
    end
    rowPrice:setText("")

    local cancelButton = BidWindow:getChildById("buttonCancel")
    local cancelFunc = function()
        show()
    end

    BidWindow.onEnter = bidFunc
    BidWindow.onEscape = cancelFunc

    okButton.onClick = bidFunc
    cancelButton.onClick = cancelFunc
    MainWindow:hide()
    BidWindow:show()
end

function syncMarketSellItems()
    if SellPanel:getChildById("items"):getChildren() == nil then
        return
    end
    for i, child in ipairs(SellPanel:getChildById("items"):getChildren()) do
        local _t = child.market_item.timeleft
        child:getChildById("timer"):setText(
            _t < 0 and "Expired" or
                string.format(
                    "%02d:%02d:%02d",
                    math.floor(_t / (60 * 60)),
                    math.floor((_t / 60) % 60),
                    math.floor(_t % 60)
                )
        )
        child.market_item.timeleft = child.market_item.timeleft - 1
    end
    SellPanel.event = scheduleEvent(syncMarketSellItems, 1000)
end

function syncMarketBuyItems()
    if BuyPanel:getChildById("items"):getChildren() == nil then
        return
    end
    for i, child in ipairs(BuyPanel:getChildById("items"):getChildren()) do
        local _t = child.market_item.timeleft
        child:getChildById("timer"):setText(
            _t < 0 and "Expired" or
                string.format(
                    "%02d:%02d:%02d",
                    math.floor(_t / (60 * 60)),
                    math.floor((_t / 60) % 60),
                    math.floor(_t % 60)
                )
        )
        child.market_item.timeleft = child.market_item.timeleft - 1
    end
    BuyPanel.event = scheduleEvent(syncMarketBuyItems, 1000)
end

function syncMarketBuyOffers()
    if BuyOffersPanel then
        if BuyOffersPanel:getChildById("items"):getChildren() == nil then
            return
        end
        for i, child in ipairs(BuyOffersPanel:getChildById("items"):getChildren()) do
            local _t = child.buy_offer.timeleft
            child:getChildById("timer"):setText(
                _t < 0 and "Expired" or
                    string.format(
                        "%02d:%02d:%02d",
                        math.floor(_t / (60 * 60)),
                        math.floor((_t / 60) % 60),
                        math.floor(_t % 60)
                    )
            )
            child.buy_offer.timeleft = child.buy_offer.timeleft - 1
        end
        BuyOffersPanel.event = scheduleEvent(syncMarketBuyOffers, 1000)
    end
end

function syncMyBuyOffers()
    if MyBuyOffersPanel then
        if MyBuyOffersPanel:getChildById("items"):getChildren() == nil then
            return
        end
        for i, child in ipairs(MyBuyOffersPanel:getChildById("items"):getChildren()) do
            local _t = child.buy_offer.timeleft
            child:getChildById("timer"):setText(
                _t < 0 and "Expired" or
                    string.format(
                        "%02d:%02d:%02d",
                        math.floor(_t / (60 * 60)),
                        math.floor((_t / 60) % 60),
                        math.floor(_t % 60)
                    )
            )
            child.buy_offer.timeleft = child.buy_offer.timeleft - 1
        end
        MyBuyOffersPanel.event = scheduleEvent(syncMyBuyOffers, 1000)
    end
end

function updateBuyOffersPageWidget()
    local pageWidget = BuyOffersPanel:getChildById("pageWidget")
    if pageWidget then
        pageWidget:getChildById("text"):setText(
            tr("Page") .. ": " .. Current.buyOffersPage .. "/" .. Current.buyOffersMaxPage
        )
        pageWidget:getChildById("first"):setEnabled(Current.buyOffersPage > 1 and true or false)
        pageWidget:getChildById("prev"):setEnabled(Current.buyOffersPage > 1 and true or false)
        pageWidget:getChildById("next"):setEnabled(Current.buyOffersPage < Current.buyOffersMaxPage and true or false)
        pageWidget:getChildById("last"):setEnabled(Current.buyOffersPage < Current.buyOffersMaxPage and true or false)
    end
end

function toggleBuyOffersPage(id)
    if id == "first" then
        Current.buyOffersPage = 1
    elseif id == "prev" then
        Current.buyOffersPage = math.max(1, Current.buyOffersPage - 1)
    elseif id == "next" then
        Current.buyOffersPage = math.min(Current.buyOffersMaxPage, Current.buyOffersPage + 1)
    elseif id == "last" then
        Current.buyOffersPage = Current.buyOffersMaxPage
    end
    getBuyOfferItems()
end

function applyCurrencyStyle(widget, currencyId, price)
    local currency = Market.currencies[currencyId]
    if currency then
        if currency.type == "gold" then
            widget:setText(formatMoney(price))
            widget:setColor("yellow")
        else
            widget:setText(comma_value(price))
            widget:setColor("white")
        end

        local iconWidget = widget:getChildById("currencyIcon")
        if iconWidget then
            if currency.clientId and currency.clientId > 0 then
                iconWidget:setItemId(currency.clientId)
            end
        elseif currency.clientId and currency.clientId > 0 then
            widget:setItemId(currency.clientId)
        elseif currency.image then
            widget:setIcon(currency.image)
        end
    else
        widget:setText(comma_value(price))
    end
end

function parseMarket(protocol, opcode, buffer)
    local receive = json.decode(buffer)
    if receive.protocol == "close" then
        ---------------------------------------------------------------------------------
        marketWindowtoggle()
    elseif receive.protocol == "currencies_config" then
        ---------------------------------------------------------------------------------
        -- Store currencies configuration from server
        Market.currencies = receive.currencies or {}
    elseif receive.protocol == "buy_items" then
        ---------------------------------------------------------------------------------------------
        show()
        if not BuyPanel.event then
            syncMarketBuyItems()
        end

        if receive.first then
            Current.page = receive.page
            Current.category = receive.category
            Current.max_page = receive.max_page
            Current.search_string = receive.search_string
            updatePageWidget()
            BuyPanel:getChildById("items"):destroyChildren()
            BuyPanel:getChildById("buyButton"):setEnabled(false)
            BuyPanel:getChildById("bidButton"):setEnabled(false)
            BuyPanel:getChildById("buyButton"):setImageColor("red")
            BuyPanel:getChildById("bidButton"):setImageColor("red")
        end

        local function onFocus(widget, market_item, focused)
            if focused then
                if market_item.bid <= 0 then
                    BuyPanel:getChildById("buyButton"):setEnabled(true)
                    BuyPanel:getChildById("bidButton"):setEnabled(false)
                    BuyPanel:getChildById("buyButton"):setImageColor("green")
                    BuyPanel:getChildById("bidButton"):setImageColor("red")
                else
                    BuyPanel:getChildById("buyButton"):setEnabled(false)
                    BuyPanel:getChildById("bidButton"):setEnabled(true)
                    BuyPanel:getChildById("buyButton"):setImageColor("red")
                    BuyPanel:getChildById("bidButton"):setImageColor("green")
                end
                Current.buyWidget = widget
            end
        end

        if #receive.market_items > 0 then
            for n, market_item in pairs(receive.market_items) do
                local widget = g_ui.createWidget("MarketItem", BuyPanel:getChildById("items"))
                widget.market_item = market_item
                local _t = market_item.timeleft
                widget:getChildById("timer"):setText(
                    _t < 0 and "Expired" or
                        string.format(
                            "%02d:%02d:%02d",
                            math.floor(_t / (60 * 60)),
                            math.floor((_t / 60) % 60),
                            math.floor(_t % 60)
                        )
                )
                widget.market_item.timeleft = widget.market_item.timeleft - 1
                widget:getChildById("item"):setItemId(market_item.clientId)
                widget:getChildById("item"):setItemCount(market_item.count)

                -- Handle tooltip display on row hover (custom tooltip)
                widget.onHoverChange = function(self, hovered)
                    if hovered then
                        if market_item.tooltip_data then
                            local ok, tooltip = pcall(json.decode, market_item.tooltip_data)
                            if ok and type(tooltip) == "table" then
                                showMarketTooltip(market_item)
                            end
                        end
                    else
                        hideMarketTooltip()
                    end
                end

                if market_item.item_name:len() >= 14 then
                    widget:getChildById("name"):setText(market_item.item_name:sub(1, 14) .. "..")
                else
                    widget:getChildById("name"):setText(market_item.item_name)
                end
                applyMarketVisualState(widget, market_item, "name")

                -- Preencher coluna de descrio/atributos
                local descWidget = widget:getChildById("desc")
                if descWidget then
                    -- Usar attributes_text do servidor (j decodificado)
                    if market_item.attributes_text and market_item.attributes_text ~= "" then
                        descWidget:setText(market_item.attributes_text)
                    else
                        descWidget:setText("")
                    end
                end

                if market_item.seller_name:len() >= 13 then
                    widget:getChildById("seller"):setText(market_item.seller_name:sub(1, 13) .. "..")
                else
                    widget:getChildById("seller"):setText(market_item.seller_name)
                end

                widget:getChildById("amount"):setText(market_item.count)
                widget:getChildById("auction"):setText(market_item.bid > 0 and comma_value(market_item.bid) or "-")
                applyCurrencyStyle(widget:getChildById("price"), market_item.currency, market_item.price)

                widget.onFocusChange = function(self, focused)
                    onFocus(widget, market_item, focused)
                end
                widget.onClick = function(self, mousePos, mouseButton)
                    -- Hide tooltip when clicking
                    hideMarketTooltip()
                    
                    -- Right button: show item details window
                    if mouseButton == MouseRightButton and market_item.tooltip_data then
                        showItemDetailsWindow(market_item)
                        return
                    end
                    
                    widget:focus()
                    onFocus(widget, market_item, true)
                end
                if n == #receive.market_items then
                    SellPanel:hide()
                    HistoricPanel:hide()
                    BuyPanel:show()
                    MainWindow:show()
                end
            end
            BuyPanel.items:getChildByIndex(1):focus()
        else
            SellPanel:hide()
            HistoricPanel:hide()
            BuyPanel:show()
            MainWindow:show()
        end
    elseif receive.protocol == "sell_items" then
        -----------------------------------------------------------------------------------------------------
        if not SellPanel.event then
            syncMarketSellItems()
        end

        if receive.first then
            SellPanel:getChildById("items"):destroyChildren()
        end

        for n, market_item in ipairs(receive.market_items) do
            local widget = g_ui.createWidget("MarketSellItem", SellPanel:getChildById("items"))
            widget.market_item = market_item
            local _t = market_item.timeleft
            widget:getChildById("timer"):setText(
                _t < 0 and "Expired" or
                    string.format(
                        "%02d:%02d:%02d",
                        math.floor(_t / (60 * 60)),
                        math.floor((_t / 60) % 60),
                        math.floor(_t % 60)
                    )
            )
            widget.market_item.timeleft = widget.market_item.timeleft - 1
            widget:getChildById("item"):setItemId(market_item.clientId)
            widget:getChildById("item"):setItemCount(market_item.count)

            -- Handle tooltip display for sell items on row hover
            widget.onHoverChange = function(self, hovered)
                if hovered then
                    if market_item.tooltip_data then
                        local ok, tooltip = pcall(json.decode, market_item.tooltip_data)
                        if ok and type(tooltip) == "table" then
                            showMarketTooltip(market_item)
                        end
                    end
                else
                    hideMarketTooltip()
                end
            end

            if market_item.item_name:len() >= 20 then
                widget:getChildById("name"):setText(market_item.item_name:sub(1, 20) .. "..")
            else
                widget:getChildById("name"):setText(market_item.item_name)
            end
            applyMarketVisualState(widget, market_item, "name")

            widget:getChildById("amount"):setText(market_item.count)
            widget:getChildById("auction"):setText(market_item.bid > 0 and comma_value(market_item.bid) or "-")
            applyCurrencyStyle(widget:getChildById("price"), market_item.currency, market_item.price)
        end
    elseif receive.protocol == "buy_offers" then
        -----------------------------------------------------------------------------------------------------
        show()
        if not BuyOffersPanel.event then
            syncMarketBuyOffers()
        end

        if receive.first then
            Current.buyOffersPage = receive.page
            Current.buyOffersMaxPage = receive.max_page
            updateBuyOffersPageWidget()
            BuyOffersPanel:getChildById("items"):destroyChildren()
            BuyOffersPanel:getChildById("fulfillButton"):setEnabled(false)
            BuyOffersPanel:getChildById("fulfillButton"):setImageColor("red")
        end

        local function onFocus(widget, buy_offer, focused)
            if focused then
                BuyOffersPanel:getChildById("fulfillButton"):setEnabled(true)
                BuyOffersPanel:getChildById("fulfillButton"):setImageColor("green")
                Current.buyOfferWidget = widget
            end
        end

        if #receive.buy_offers > 0 then
            for n, buy_offer in pairs(receive.buy_offers) do
                local widget = g_ui.createWidget("MarketBuyOfferListItem", BuyOffersPanel:getChildById("items"))
                widget.buy_offer = buy_offer
                local _t = buy_offer.timeleft
                widget:getChildById("timer"):setText(
                    _t < 0 and "Expired" or
                        string.format(
                            "%02d:%02d:%02d",
                            math.floor(_t / (60 * 60)),
                            math.floor((_t / 60) % 60),
                            math.floor(_t % 60)
                        )
                )
                widget.buy_offer.timeleft = widget.buy_offer.timeleft - 1
                widget:getChildById("item"):setItemId(buy_offer.clientId)
                widget:getChildById("item"):setItemCount(buy_offer.count)

                -- Handle tooltip display on row hover
                widget.onHoverChange = function(self, hovered)
                    if hovered then
                        if buy_offer.tooltip_data then
                            local ok, tooltip = pcall(json.decode, buy_offer.tooltip_data)
                            if ok and type(tooltip) == "table" then
                                -- Create a market_item structure from buy_offer
                                local market_item = {
                                    tooltip_data = buy_offer.tooltip_data,
                                    clientId = buy_offer.clientId,
                                    item_name = buy_offer.item_name
                                }
                                showMarketTooltip(market_item)
                            end
                        end
                    else
                        hideMarketTooltip()
                    end
                end

                if buy_offer.item_name:len() >= 20 then
                    widget:getChildById("name"):setText(buy_offer.item_name:sub(1, 20) .. "..")
                else
                    widget:getChildById("name"):setText(buy_offer.item_name)
                end
                applyMarketVisualState(widget, buy_offer, "name")

                if buy_offer.buyer_name:len() >= 13 then
                    widget:getChildById("buyer"):setText(buy_offer.buyer_name:sub(1, 13) .. "..")
                else
                    widget:getChildById("buyer"):setText(buy_offer.buyer_name)
                end

                -- Display filters (rarity and/or tier)
                local filtersWidget = widget:getChildById("filters")
                if filtersWidget then
                    local filterText = formatBuyOfferFilters(buy_offer)
                    filtersWidget:setText(filterText)
                    
                    -- Color based on rarity if specified
                    if buy_offer.rarity and buy_offer.rarity > 0 then
                        filtersWidget:setColor(MARKET_RARITY_COLORS[buy_offer.rarity] or "#FCC200")
                    elseif buy_offer.tier and buy_offer.tier > 0 then
                        filtersWidget:setColor("#FCC200")  -- Gold for tier
                    else
                        filtersWidget:setColor("#888888")  -- Gray for "Any"
                    end
                end

                widget:getChildById("amount"):setText(buy_offer.count)
                applyCurrencyStyle(widget:getChildById("price"), buy_offer.currency, buy_offer.price)

                widget.onFocusChange = function(self, focused)
                    onFocus(widget, buy_offer, focused)
                end
                widget.onClick = function(self, mousePos, mouseButton)
                    widget:focus()
                    onFocus(widget, buy_offer, true)
                end
                if n == #receive.buy_offers then
                    SellPanel:hide()
                    HistoricPanel:hide()
                    BuyPanel:hide()
                    MyBuyOffersPanel:hide()
                    BuyOffersPanel:show()
                    MainWindow:show()
                end
            end
            if #receive.buy_offers > 0 then
                BuyOffersPanel.items:getChildByIndex(1):focus()
            end
        else
            SellPanel:hide()
            HistoricPanel:hide()
            BuyPanel:hide()
            MyBuyOffersPanel:hide()
            BuyOffersPanel:show()
            MainWindow:show()
        end
    elseif receive.protocol == "my_buy_offers" then
        -----------------------------------------------------------------------------------------------------
        if not MyBuyOffersPanel.event then
            syncMyBuyOffers()
        end

        if receive.first then
            MyBuyOffersPanel:getChildById("items"):destroyChildren()
        end

        for n, buy_offer in ipairs(receive.buy_offers) do
            local widget = g_ui.createWidget("MarketBuyOfferItem", MyBuyOffersPanel:getChildById("items"))
            widget.buy_offer = buy_offer
            local _t = buy_offer.timeleft
            widget:getChildById("timer"):setText(
                _t < 0 and "Expired" or
                    string.format(
                        "%02d:%02d:%02d",
                        math.floor(_t / (60 * 60)),
                        math.floor((_t / 60) % 60),
                        math.floor(_t % 60)
                    )
            )
            widget.buy_offer.timeleft = widget.buy_offer.timeleft - 1
            widget:getChildById("item"):setItemId(buy_offer.clientId)
            widget:getChildById("item"):setItemCount(buy_offer.count)

            -- Handle tooltip display on row hover
            widget.onHoverChange = function(self, hovered)
                if hovered then
                    if buy_offer.tooltip_data then
                        local ok, tooltip = pcall(json.decode, buy_offer.tooltip_data)
                        if ok and type(tooltip) == "table" then
                            -- Create a market_item structure from buy_offer
                            local market_item = {
                                tooltip_data = buy_offer.tooltip_data,
                                clientId = buy_offer.clientId,
                                item_name = buy_offer.item_name
                            }
                            showMarketTooltip(market_item)
                        end
                    end
                else
                    hideMarketTooltip()
                end
            end

            if buy_offer.item_name:len() >= 20 then
                widget:getChildById("name"):setText(buy_offer.item_name:sub(1, 20) .. "..")
            else
                widget:getChildById("name"):setText(buy_offer.item_name)
            end
            applyMarketVisualState(widget, buy_offer, "name")

            -- Display filters (rarity and/or tier)
            local filtersWidget = widget:getChildById("filters")
            if filtersWidget then
                local filterText = formatBuyOfferFilters(buy_offer)
                filtersWidget:setText(filterText)
                
                -- Color based on rarity if specified
                if buy_offer.rarity and buy_offer.rarity > 0 then
                    filtersWidget:setColor(MARKET_RARITY_COLORS[buy_offer.rarity] or "#FCC200")
                elseif buy_offer.tier and buy_offer.tier > 0 then
                    filtersWidget:setColor("#FCC200")  -- Gold for tier
                else
                    filtersWidget:setColor("#888888")  -- Gray for "Any"
                end
            end

            widget:getChildById("amount"):setText(buy_offer.count)
            applyCurrencyStyle(widget:getChildById("price"), buy_offer.currency, buy_offer.price)
        end
    elseif receive.protocol == "item_to_sell" then
        -----------------------------------------------------------------------------------------------------
        createConfirmSellOfferWindow(receive)
    elseif receive.protocol == "historic" then
        if receive.first then
            HistoricPanel:getChildById("list"):destroyChildren()
        end
        for num, h in ipairs(receive.historic) do
            local text = g_ui.createWidget("HistoricLabel", HistoricPanel:getChildById("list"))
            text:setId("historicwidget: " .. num)
            text:setText(" " .. h.negotiation)
        end
    end
end
-----------------------------------------------------------------------------------------------------
function createConfirmSellOfferWindow(receive)
    if not sellConfirmWindow then
        sellConfirmWindow = g_ui.createWidget("createConfirmSellWindow", modules.game_interface.getRootPanel())
        sellConfirmWindow.priceedit:setMaxLength(15)
        for _, _time in ipairs(Market.time) do
            sellConfirmWindow.timebox:addOption(_time.name)
        end
    end

    -- Populate currency dropdown dynamically
    sellConfirmWindow.currency:clearOptions()
    for id, currency in pairs(Market.currencies) do
        sellConfirmWindow.currency:addOption(currency.name, id)
    end

    sellConfirmWindow:show()
    sellConfirmWindow.item.item = receive
    sellConfirmWindow.item:setItemId(receive.clientId)
    sellConfirmWindow.item:setItemCount(1)
    -- Handle tooltip display with tooltip_data from server
    sellConfirmWindow.item.onHoverChange = function(self, hovered)
        if hovered then
            if receive.tooltip_data then
                local ok, tooltip = pcall(json.decode, receive.tooltip_data)
                if ok and type(tooltip) == "table" then
                    showMarketTooltip(receive)
                end
            end
        else
            hideMarketTooltip()
        end
    end

    sellConfirmWindow.bidCheckBox:setChecked(false)
    sellConfirmWindow.bidEdit:setText("")
    sellConfirmWindow.name:setText(receive.item_name)
    sellConfirmWindow.name:setColor(MARKET_RARITY_COLORS[select(1, getMarketVisualData(receive))] or "#c9a633")

    -- Aplicar frame de raridade no item da janela de venda
    local rarity = select(1, getMarketVisualData(receive))
    if g_game.updateRarityFrames then
        g_game.updateRarityFrames(sellConfirmWindow.item, rarity)
    end
    sellConfirmWindow.currency:setCurrentIndex(1)
    sellConfirmWindow.amount:setEnabled(true)
    sellConfirmWindow.amount:setValue(1)
    sellConfirmWindow.amount:setText(1)
    sellConfirmWindow.amount:setMinimum(1)
    sellConfirmWindow.amount:setMaximum(receive.count)
    sellConfirmWindow.amount.onValueChange = function(self)
        local value = math.max(1, sellConfirmWindow.amount:getValue())
        sellConfirmWindow.item:setItemCount(value)
        sellConfirmWindow.amount:setText(value)
        onSellPriceChange()
        -- Update tooltip count when amount changes
        if receive.tooltip_data then
            local tooltip = json.decode(receive.tooltip_data)
            if tooltip then
                tooltip.count = value
            end
        end
    end
    sellConfirmWindow.priceedit:clearText()
end

function onSellPriceChange()
    local value = math.max(1, sellConfirmWindow.amount:getValue())
    local priceNumber = tonumber(sellConfirmWindow.priceedit:getText())
    if priceNumber then
        sellConfirmWindow.fee:setText("Fee: " .. comma_value(getMarketFee(priceNumber * value)))
        sellConfirmWindow.totalCost:setText(
            "Total: " .. comma_value((priceNumber * value) + getMarketFee(priceNumber * value))
        )
    else
        sellConfirmWindow.fee:setText("Fee: 0")
        sellConfirmWindow.totalCost:setText("Total: 0")
    end
end

function onConfirmSellItem()
    local option = sellConfirmWindow.currency:getCurrentOption()
    local currencyID = option and option.data or 1
    local currencyPrice = tonumber(sellConfirmWindow.priceedit:getText()) or 0

    -- Adjust price based on currency type (gold is stored in base units)
    local currency = Market.currencies[currencyID]
    if currency and currency.type == "gold" then
        currencyPrice = currencyPrice
    end

    local buffer = {
        protocol = "sell_item",
        itemid = sellConfirmWindow.item.item.itemid,
        item_code = sellConfirmWindow.item.item.item_code,
        count = math.max(1, sellConfirmWindow.amount:getValue()),
        maxtime = sellConfirmWindow.timebox:getText(),
        price = currencyPrice,
        bid = sellConfirmWindow.bidCheckBox:isChecked() and (tonumber(sellConfirmWindow.bidEdit:getText()) or 0) or 0,
        currency = currencyID,
        description = descHolder
    }

    descHolder = ""
    for id, _time in ipairs(Market.time) do
        if _time.name == sellConfirmWindow.timebox:getText() then
            buffer.maxtime = id
            break
        end
    end
    g_game.getProtocolGame():sendExtendedOpcode(Market.opcode, json.encode(buffer))
    sellConfirmWindow:hide()
end

function onSellBidCheckChange()
    sellConfirmWindow.bidEdit:setEnabled(sellConfirmWindow.bidCheckBox:isChecked())
end

function selectItemToSell(item)
    descHolder = item:getTooltip()
    g_game.getProtocolGame():sendExtendedOpcode(
        Market.opcode,
        json.encode(
            {
                protocol = "selectItemToSell",
                pos = item:getPosition(),
                count = item:getCount(),
                description = item:getTooltip()
            }
        )
    )
end
-----------------------------------------------------------------------------------------------------
function updatePageWidget()
    local pageWidget = BuyPanel:getChildById("pageWidget")
    pageWidget:getChildById("text"):setText(tr("Page") .. ": " .. Current.page .. "/" .. Current.max_page)
    pageWidget:getChildById("first"):setEnabled(Current.page > 1 and true or false)
    pageWidget:getChildById("prev"):setEnabled(Current.page > 1 and true or false)
    pageWidget:getChildById("next"):setEnabled(Current.page < Current.max_page and true or false)
    pageWidget:getChildById("last"):setEnabled(Current.page < Current.max_page and true or false)
end
----------------------------------------------------------------------------------------------------
function hideAllPanels()
    if BuyPanel then
        BuyPanel:hide()
    end
    if SellPanel then
        SellPanel:hide()
    end
    if HistoricPanel then
        HistoricPanel:hide()
    end
    if BuyOffersPanel then
        BuyOffersPanel:hide()
    end
    if MyBuyOffersPanel then
        MyBuyOffersPanel:hide()
    end
end

-- Window size constants (based on new design 870x460)
local WINDOW_WIDTH_DEFAULT = 1040
local WINDOW_HEIGHT_DEFAULT = 460

local function setWindowSize(width, height)
    if MainWindow then
        MainWindow:setSize({width = width, height = height})
    end
end

function showBuyPanel()
    hideAllPanels()
    setWindowSize(WINDOW_WIDTH_DEFAULT, WINDOW_HEIGHT_DEFAULT)
    Current.page = 1
    getBuyItems()
    if BuyPanel then
        BuyPanel:show()
    end
    if MainWindow then
        MainWindow:show()
        MainWindow:focus()
    end
end

function showSellPanel()
    hideAllPanels()
    setWindowSize(WINDOW_WIDTH_DEFAULT - 28, WINDOW_HEIGHT_DEFAULT)
    getSellItems()
    if SellPanel then
        SellPanel:show()
    end
    if MainWindow then
        MainWindow:show()
    end
end

function showHistoricPanel()
    hideAllPanels()
    setWindowSize(WINDOW_WIDTH_DEFAULT - 40, WINDOW_HEIGHT_DEFAULT)
    g_game.getProtocolGame():sendExtendedOpcode(Market.opcode, json.encode({protocol = "historic"}))
    if HistoricPanel then
        HistoricPanel:show()
    end
    if MainWindow then
        MainWindow:show()
    end
end

function showBuyOffersPanel()
    hideAllPanels()
    setWindowSize(WINDOW_WIDTH_DEFAULT , WINDOW_HEIGHT_DEFAULT)
    Current.buyOffersPage = 1
    getBuyOfferItems()
    if BuyOffersPanel then
        BuyOffersPanel:show()
    end
    if MainWindow then
        MainWindow:show()
    end
end

function showMyBuyOffersPanel()
    hideAllPanels()
    setWindowSize(WINDOW_WIDTH_DEFAULT , WINDOW_HEIGHT_DEFAULT)
    getMyBuyOffers()
    if MyBuyOffersPanel then
        MyBuyOffersPanel:show()
    end
    if MainWindow then
        MainWindow:show()
    end
end

function getBuyOfferItems()
    if not MainWindow then
        return
    end
    local catsWidget = MainWindow:getChildById("cats")
    if not catsWidget then
        return
    end
    local comboBox = catsWidget:getChildById("comboBox")
    if not comboBox then
        return
    end
    local option = comboBox:getCurrentOption()
    if not option then
        return
    end

    local params = {
        protocol = "buy_offers",
        category = option.data,
        page = Current.buyOffersPage or 1,
        order = orderId,
        search_string = Current.search_string
    }
    g_game.getProtocolGame():sendExtendedOpcode(Market.opcode, json.encode(params))
end

function getMyBuyOffers()
    local params = {
        protocol = "my_buy_offers"
    }
    g_game.getProtocolGame():sendExtendedOpcode(Market.opcode, json.encode(params))
end

function createBuyOffer()
    MainWindow:hide()

    if not createBuyOfferWindow then
        createBuyOfferWindow = g_ui.createWidget("createConfirmBuyOfferWindow", modules.game_interface.getRootPanel())

        local priceEdit = createBuyOfferWindow:getChildById("priceedit")
        if priceEdit then
            priceEdit:setMaxLength(15)
        end

        local timeCombo = createBuyOfferWindow:getChildById("timebox")
        if timeCombo then
            for _, _time in ipairs(Market.time) do
                timeCombo:addOption(_time.name)
            end
        end

        local searchEdit = createBuyOfferWindow:getChildById("itemSearch")
        if searchEdit then
            searchEdit.onTextChange = function(self, text)
                searchItemsByName(text)
            end
        end
    end

    -- Populate currency dropdown dynamically
    local currencyCombo = createBuyOfferWindow:getChildById("currency")
    if currencyCombo then
        currencyCombo:clearOptions()
        for id, currency in pairs(Market.currencies) do
            currencyCombo:addOption(currency.name, id)
        end
    end

    -- Populate rarity ComboBox
    local rarityComboBox = createBuyOfferWindow:getChildById("rarityComboBox")
    if rarityComboBox then
        rarityComboBox:clearOptions()
        rarityComboBox:addOption("Any", 0)
        rarityComboBox:addOption("Common", 1)
        rarityComboBox:addOption("Rare", 2)
        rarityComboBox:addOption("Epic", 3)
        rarityComboBox:addOption("Legendary", 4)
        rarityComboBox:addOption("Brutal", 5)
        rarityComboBox:setCurrentIndex(0)  -- Default: Any
    end

    -- Populate tier ComboBox
    local tierComboBox = createBuyOfferWindow:getChildById("tierComboBox")
    if tierComboBox then
        tierComboBox:clearOptions()
        tierComboBox:addOption("Any", 0)
        for i = 1, 10 do
            tierComboBox:addOption("Tier " .. i, i)
        end
        tierComboBox:setCurrentIndex(0)  -- Default: Any
    end

    -- Reset window
    local itemWidget = createBuyOfferWindow:getChildById("item")
    if itemWidget then
        itemWidget:setItemId(0)
        itemWidget.serverId = nil
        itemWidget.clientId = nil
    end

    local nameLabel = createBuyOfferWindow:getChildById("name")
    if nameLabel then
        nameLabel:setText("Select an item above")
    end

    if currencyCombo then
        currencyCombo:setCurrentIndex(1)
    end

    local amountScroll = createBuyOfferWindow:getChildById("amount")
    if amountScroll then
        amountScroll:setValue(1)
        amountScroll:setText(1)
        amountScroll:setMinimum(1)
        amountScroll:setMaximum(1000)
    end

    local priceEdit = createBuyOfferWindow:getChildById("priceedit")
    if priceEdit then
        priceEdit:clearText()
    end

    local searchEdit = createBuyOfferWindow:getChildById("itemSearch")
    if searchEdit then
        searchEdit:setText("")
    end

    local searchResults = createBuyOfferWindow:getChildById("searchResults")
    if searchResults then
        searchResults:destroyChildren()
    end

    createBuyOfferWindow:show()
end

function searchItemsByName(searchText)
    if not createBuyOfferWindow then
        return
    end

    local searchResults = createBuyOfferWindow:getChildById("searchResults")
    if not searchResults then
        return
    end

    searchResults:destroyChildren()

    if not searchText or searchText:len() < 2 then
        return
    end

    -- Make sure database is loaded
    if not Market.itemsDatabaseLoaded then
        loadItemsDatabase()
    end

    local searchLower = searchText:lower()
    local count = 0
    local maxResults = 50
    local addedNames = {}
    local results = {}

    -- Search through the items database (server IDs)
    for serverId, itemData in pairs(Market.itemsDatabase) do
        if count >= maxResults then
            break
        end

        local itemName = itemData.name
        if itemName and itemName ~= "" and not addedNames[itemName:lower()] then
            if itemName:lower():find(searchLower, 1, true) then
                -- Convert server ID to client ID using items.otb mapping
                local clientId = nil
                local isStackable = false

                -- Method 1: Use g_things.getItemType to get the ItemType from items.otb
                local itemType = g_things.getItemType(serverId)
                if itemType then
                    clientId = itemType:getClientId()
                    if itemType.isStackable then
                        isStackable = itemType:isStackable()
                    end
                end

                -- Method 2: Try Item.create and getClientId
                if not clientId or clientId == 0 then
                    local success, item =
                        pcall(
                        function()
                            return Item.create(serverId)
                        end
                    )
                    if success and item then
                        if item.getClientId then
                            clientId = item:getClientId()
                        end
                        if item.isStackable then
                            isStackable = item:isStackable()
                        end
                    end
                end

                -- Method 3: Fallback - serverId might equal clientId for some items
                if not clientId or clientId == 0 then
                    local thingType = g_things.getThingType(serverId, ThingCategoryItem)
                    if thingType then
                        clientId = serverId
                        if thingType.isStackable then
                            isStackable = thingType:isStackable()
                        end
                    end
                end

                if clientId and clientId > 0 then
                    -- Verify the clientId is valid by checking if thingType exists
                    local thingType = g_things.getThingType(clientId, ThingCategoryItem)
                    if thingType then
                        addedNames[itemName:lower()] = true

                        table.insert(
                            results,
                            {
                                serverId = serverId,
                                clientId = clientId,
                                name = itemName,
                                isStackable = isStackable
                            }
                        )
                        count = count + 1
                    end
                end
            end
        end
    end

    -- Sort results alphabetically
    table.sort(
        results,
        function(a, b)
            return a.name:lower() < b.name:lower()
        end
    )

    -- Create widgets for results
    for _, result in ipairs(results) do
        local widget = g_ui.createWidget("ItemSearchResultItem", searchResults)
        widget.serverId = result.serverId
        widget.clientId = result.clientId
        widget.itemName = result.name
        widget.isStackable = result.isStackable

        local itemWidget = widget:getChildById("itemWidget")
        if itemWidget then
            itemWidget:setItemId(result.clientId)
            if result.isStackable then
                itemWidget:setItemCount(1)
            end
        end

        local nameLabel = widget:getChildById("itemName")
        if nameLabel then
            nameLabel:setText(result.name)
        end

        widget.onDoubleClick = function()
            selectBuyOfferItem(result.serverId, result.clientId, result.name, result.isStackable)
        end

        widget.onClick = function()
            widget:focus()
        end
    end

    if count == 0 then
        local noResults = g_ui.createWidget("Label", searchResults)
        noResults:setText("No items found")
        noResults:setTextAlign(AlignCenter)
    end
end

function selectBuyOfferItem(serverId, clientId, itemName, isStackable)
    if not createBuyOfferWindow then
        return
    end

    local itemWidget = createBuyOfferWindow:getChildById("item")
    if itemWidget then
        itemWidget:setItemId(clientId)
        itemWidget.serverId = serverId
        itemWidget.clientId = clientId
        itemWidget.isStackable = isStackable
    end

    local nameLabel = createBuyOfferWindow:getChildById("name")
    if nameLabel then
        nameLabel:setText(itemName or "Unknown Item")
        nameLabel:setColor(isStackable and "#aaffaa" or "#ffffff")
    end

    local amountScroll = createBuyOfferWindow:getChildById("amount")
    if amountScroll then
        amountScroll:setValue(1)
        amountScroll:setText(1)
        amountScroll:setMinimum(1)
        amountScroll:setMaximum(10000)
        amountScroll.onValueChange = function(self, value)
            amountScroll:setValue(value)
            amountScroll:setText(value)
            onBuyOfferPriceChange()
        end
    end
end

function onBuyOfferPriceChange()
    if not createBuyOfferWindow then
        return
    end

    local amountScroll = createBuyOfferWindow:getChildById("amount")
    local priceEdit = createBuyOfferWindow:getChildById("priceedit")
    local feeLabel = createBuyOfferWindow:getChildById("fee")
    local totalLabel = createBuyOfferWindow:getChildById("totalCost")

    if not amountScroll or not priceEdit or not feeLabel or not totalLabel then
        return
    end

    local value = math.max(1, amountScroll:getValue())
    local priceNumber = tonumber(priceEdit:getText())
    if priceNumber then
        feeLabel:setText("Fee: " .. comma_value(getMarketFee(priceNumber * value)))
        totalLabel:setText("Total: " .. comma_value((priceNumber * value) + getMarketFee(priceNumber * value)))
    else
        feeLabel:setText("Fee: 0")
        totalLabel:setText("Total: 0")
    end
end

function onConfirmBuyOffer()
    if not createBuyOfferWindow then
        return
    end
    local itemWidget = createBuyOfferWindow:getChildById("item")
    if not itemWidget or not itemWidget.serverId or itemWidget.serverId == 0 then
        modules.game_textmessage.displayGameMessage("Please select an item first.")
        return
    end

    local currencyCombo = createBuyOfferWindow:getChildById("currency")
    local priceEdit = createBuyOfferWindow:getChildById("priceedit")
    local amountScroll = createBuyOfferWindow:getChildById("amount")
    local timeCombo = createBuyOfferWindow:getChildById("timebox")
    local rarityComboBox = createBuyOfferWindow:getChildById("rarityComboBox")
    local tierComboBox = createBuyOfferWindow:getChildById("tierComboBox")

    if not currencyCombo or not priceEdit or not amountScroll or not timeCombo then
        return
    end

    local option = currencyCombo:getCurrentOption()
    local currencyID = option and option.data or 1
    local currencyPrice = tonumber(priceEdit:getText()) or 0

    -- Get rarity and tier selections
    local rarity = 0
    local tier = 0
    
    if rarityComboBox then
        local rarityOption = rarityComboBox:getCurrentOption()
        if rarityOption then
            rarity = rarityOption.data or 0
        end
    end
    
    if tierComboBox then
        local tierOption = tierComboBox:getCurrentOption()
        if tierOption then
            tier = tierOption.data or 0
        end
    end

    -- Adjust price based on currency type (gold is stored in base units)
    local currency = Market.currencies[currencyID]
    if currency and currency.type == "gold" then
        currencyPrice = currencyPrice
    end

    local buffer = {
        protocol = "create_buy_offer",
        itemid = itemWidget.serverId,
        count = amountScroll:getValue(),
        maxtime = timeCombo:getText(),
        price = currencyPrice,
        currency = currencyID,
        rarity = rarity,
        tier = tier
    }

    for id, _time in ipairs(Market.time) do
        if _time.name == timeCombo:getText() then
            buffer.maxtime = id
            break
        end
    end
    g_game.getProtocolGame():sendExtendedOpcode(Market.opcode, json.encode(buffer))
    createBuyOfferWindow:hide()
    getMyBuyOffers()
    getBuyItems()
    showBuyOffersPanel()
    MainWindow:show()
end

function selectFulfillItem(serverId, clientId, itemName, isStackable, itemPos)
    if not FulfillBuyOfferWindow then
        return
    end

    local rowItem = FulfillBuyOfferWindow:getChildById("item")
    if rowItem then
        rowItem:setItemId(clientId)
        rowItem.serverId = serverId
        rowItem.clientId = clientId
        rowItem.isStackable = isStackable
        rowItem.itemPos = itemPos
    end
end

function fulfillBuyOffer()
    if not Current.buyOfferWidget then
        return
    end
    local rowItem = FulfillBuyOfferWindow:getChildById("item")
    local buy_offer = Current.buyOfferWidget.buy_offer

    rowItem.itemPos = nil
    rowItem.serverId = nil
    rowItem.clientId = nil
    rowItem.isStackable = nil

    rowItem:setItemId(buy_offer.clientId)

    -- Aplicar frame de raridade
    local rarity = select(1, getMarketVisualData(buy_offer))
    if g_game.updateRarityFrames then
        g_game.updateRarityFrames(rowItem, rarity)
    end

    -- Use tooltip_data if available
    rowItem.onHoverChange = function(self, hovered)
        if hovered then
            if buy_offer.tooltip_data then
                local ok, tooltip = pcall(json.decode, buy_offer.tooltip_data)
                if ok and type(tooltip) == "table" then
                    marketTooltipShow(tooltip, buy_offer.clientId)
                end
            end
        else
            marketTooltipHide()
        end
    end

    rowItem:setItemCount(buy_offer.count)
    FulfillBuyOfferWindow:setText(buy_offer.item_name)

    local rowScrollbar = FulfillBuyOfferWindow:getChildById("countScrollBar")
    rowScrollbar:setMinimum(1)
    rowScrollbar:setMaximum(buy_offer.count)
    rowScrollbar:setText(buy_offer.count)
    rowScrollbar:setValue(1)

    local rowPrice = FulfillBuyOfferWindow:getChildById("price")
    rowPrice:setText("Total Price: " .. comma_value(buy_offer.price * buy_offer.count))
    if buy_offer.currency == 1 then
        rowPrice:setText("Total Price: " .. comma_value((buy_offer.price) * buy_offer.count))
    end

    rowScrollbar.onValueChange = function(self, value)
        rowItem:setItemCount(value)
        rowScrollbar:setText(value)
        rowPrice:setText("Total Price: " .. comma_value(value * buy_offer.price))
        if buy_offer.currency == 1 then
            rowPrice:setText("Total Price: " .. comma_value((buy_offer.price) * value))
        end
    end

    local okButton = FulfillBuyOfferWindow:getChildById("buttonOk")
    local fulfillFunc = function()
        local params = {
            protocol = "fulfill_buy_offer",
            offer_code = buy_offer.offer_code,
            fulfill_count = rowItem:getItemCount()
        }
        if rowItem.itemPos then
            params.item_pos = {
                x = rowItem.itemPos.x,
                y = rowItem.itemPos.y,
                z = rowItem.itemPos.z
            }
        end
        g_game.getProtocolGame():sendExtendedOpcode(Market.opcode, json.encode(params))
        show()
    end

    local cancelButton = FulfillBuyOfferWindow:getChildById("buttonCancel")
    local cancelFunc = function()
        show()
    end

    FulfillBuyOfferWindow.onEnter = fulfillFunc
    FulfillBuyOfferWindow.onEscape = cancelFunc
    okButton.onClick = fulfillFunc
    cancelButton.onClick = cancelFunc
    MainWindow:hide()
    FulfillBuyOfferWindow:show()
end

function cancelBuyOffer(widget)
    local params = {
        protocol = "cancel_buy_offer",
        offer_code = widget.buy_offer.offer_code
    }
    g_game.getProtocolGame():sendExtendedOpcode(Market.opcode, json.encode(params))
end

function show()
    BuyNowWindow:hide()
    BidWindow:hide()
    FulfillBuyOfferWindow:hide()
    MainWindow:show()
    MainWindow:focus()
end

function hide()
    if BuyPanel.event then
        removeEvent(BuyPanel.event)
        BuyPanel.event = nil
    end
    if SellPanel.event then
        removeEvent(SellPanel.event)
        SellPanel.event = nil
    end
    marketWindowtoggle()
end

function onPositionChange(player, newPos, oldPos)
    if player:isLocalPlayer() then
    end
end

function getMarketFee(price)
    local fee = 0
    if (fee < 20) then
        fee = 0
    elseif (fee > 1000) then
        fee = 0
    end
    return fee
end


-- Funo que replica formatao do tooltip do game_tooltip.lua
function buildItemDescription(tooltip_data)
    if not tooltip_data or tooltip_data == "" then
        return "No attributes"
    end
    
    local ok, list = pcall(json.decode, tooltip_data)
    if not ok or not list then
        return "Invalid data"
    end
    
    local description = ""
    local name = ""
    local color = nil
    
    -- Mapeamento de atributos (mesmo do game_tooltip.lua)
    local descriptionByAttributeId = {
        [1] = {name = "Attack: %s", icon = 1},
        [2] = {name = "Defense: %s", icon = 3},
        [3] = {name = "%s", icon = nil},  -- NAME
        [4] = {name = "%s", icon = 8},   -- WEIGHT
        [5] = {name = "Armor: %s", icon = 2},
        [6] = {name = "Hit Chance: %s", icon = 47},
        [7] = {name = "Range: %s", icon = 9},
        [8] = {name = "%s", icon = 38},   -- DURATION
        [9] = {name = "Charges: %s", icon = 49},
        [11] = {name = "Attack Speed: %s", icon = 50},
        [12] = {name = "Resistances", icon = nil},
        [13] = {name = "Stats", icon = nil},
        [14] = {name = "Skill", icon = nil},
        [16] = {name = "%s", icon = nil},  -- TEXT
        [18] = {name = "Count: %s", icon = 51},
        [22] = {name = "Container Size: %s", icon = 53},
        [23] = {name = "Speed: %s", icon = 54},
        [24] = {  -- RARITY
            [1] = {name = "Common", icon = 52, color = "#74C365"},
            [2] = {name = "Rare", icon = 55, color = "#0096FF"},
            [3] = {name = "Epic", icon = 58, color = "#8040BF"},
            [4] = {name = "Legendary", icon = 61, color = "#FCC200"},
            [5] = {name = "Brutal", icon = 62, color = "#DE0913"}
        },
        [26] = {name = "Critical Hit Chance: %s%%", icon = 63},
        [27] = {name = "Critical Hit Amount: %s%%", icon = 64},
        [28] = {name = "Mana Leech Chance: %s%%", icon = 65},
        [29] = {name = "Mana Leech Amount: %s%%", icon = 66},
        [30] = {name = "Life Leech Chance: %s%%", icon = 67},
        [31] = {name = "Life Leech Amount: %s%%", icon = 68},
        [32] = {name = "Increment Coins: %s", icon = 69},
        [33] = {name = "Experience: %s", icon = 70},
        [35] = {name = "Extra Defense: %s", icon = 71},
        [36] = {name = "Fire Attack: %s", icon = 72},
        [37] = {name = "Energy Attack: %s", icon = 73},
        [38] = {name = "Ice Attack: %s", icon = 74},
        [39] = {name = "Death Attack: %s", icon = 75},
        [40] = {name = "Earth Attack: %s", icon = 76},
        [41] = {name = "Holy Attack: %s", icon = 77},
        [42] = {name = "Tier: %s", icon = 78}
    }
    
    local attributes = {}
    
    -- Processa nome primeiro (como no game_tooltip)
    for _, attributeValues in pairs(list) do
        if attributeValues.id == 3 then  -- NAME
            name = attributeValues.value
        elseif attributeValues.id == 24 then  -- RARITY
            local v = descriptionByAttributeId[24][attributeValues.value]
            if v then
                name = v.name .. " " .. name
                color = v.color
            end
        end
    end
    
    -- Adiciona nome formatado
    if name and name ~= "" then
        table.insert(attributes, name)
    end
    
    -- Processa outros atributos (mesma ordem do game_tooltip)
    local lastAttributeId
    for _, attributeValues in pairs(list) do
        local v = descriptionByAttributeId[attributeValues.id]
        if v then
            -- Pula NAME e RARITY (j processados)
            if attributeValues.id ~= 3 and attributeValues.id ~= 24 then
                if lastAttributeId == 4 or lastAttributeId == 24 then
                    table.insert(attributes, "---")  -- Separador
                end
                
                if attributeValues.id == 12 or attributeValues.id == 13 or attributeValues.id == 14 then
                    -- Headers para sees
                    if attributeValues.id == 24 then
                        table.insert(attributes, "Rarity")
                    else
                        table.insert(attributes, "Attributes")
                    end
                elseif attributeValues.value ~= "" then
                    -- Formata valor
                    local value = attributeValues.value
                    if tonumber(value) and tonumber(value) > 0 then
                        if attributeValues.id == 11 then  -- ATTACK_SPEED
                            value = tostring(tonumber(value) / 1000)
                        end
                    end
                    
                    local description = v.name:format(value)
                    table.insert(attributes, description)
                end
            end
            lastAttributeId = attributeValues.id
        end
    end
    
    -- Junta tudo
    description = table.concat(attributes, "\n")
    
    -- Limita tamanho
    if string.len(description) > 100 then
        description = string.sub(description, 1, 97) .. "..."
    end
    
    return description
end
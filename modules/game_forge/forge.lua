local FORGE_OPCODE = 93

local window      = nil
local forgeButton = nil
local activeTab   = "fusion"
local wFusionSlot1Item       = nil
local wFusionSlot1CountLabel = nil
local wFusionSlot1TierBadge  = nil

local playerMoney   = 0
local playerDust    = 0
local playerDustMax = 100
local playerSlivers = 0
local playerCores   = 0

local slot1Data = nil
local slot2Data = nil

local forgeHistory      = {}
local historyPage       = 1
local historyTotalPages = 1
local HISTORY_PAGE_SIZE = 10

local improveChance       = false
local reduceLoss          = false
local convergenceFusion   = false
local convergenceTransfer = false

function init()
  connect(g_game, { onGameStart = onCreate, onGameEnd = onDestroy })
  ProtocolGame.registerExtendedOpcode(FORGE_OPCODE, onExtendedOpcode)
  if g_game.isOnline() then onCreate() end
end

function terminate()
  disconnect(g_game, { onGameStart = onCreate, onGameEnd = onDestroy })
  ProtocolGame.unregisterExtendedOpcode(FORGE_OPCODE, onExtendedOpcode)
  onDestroy()
end

function onCreate()
  if not window then
    window = g_ui.displayUI("forge")
    window:hide()
    wFusionSlot1Item       = window:recursiveGetChildById("fusionSlot1Item")
    wFusionSlot1CountLabel = window:recursiveGetChildById("fusionSlot1CountLabel")
    wFusionSlot1TierBadge  = window:recursiveGetChildById("slot1TierBadge")
  end
  if not forgeButton then
    local side = modules.game_sidemenu
    forgeButton = side and side.getForgeButton and side.getForgeButton()
      or modules.client_topmenu.addLeftGameToggleButton('forgeButton', tr('Exaltation Forge'), '/images/topbuttons/shop', toggle)
  end
end

function onDestroy()
  if forgeButton then forgeButton:setOn(false) ; forgeButton = nil end -- botao pertence ao sidemenu
  if window then window:destroy() ; window = nil end
  slot1Data = nil ; slot2Data = nil
  forgeHistory = {} ; historyPage = 1
end

local function sendAction(action, data)
  local proto = g_game.getProtocolGame()
  if not proto then return end
  proto:sendExtendedOpcode(FORGE_OPCODE, json.encode({ action = action, data = data or {} }))
end

local lastRefreshTime = 0
local isRefreshing = false
local function requestRefresh()
  if isRefreshing then return end
  local now = g_clock.millis()
  if now - lastRefreshTime > 800 then
    lastRefreshTime = now
    sendAction("open", {})
  end
end

function onExtendedOpcode(protocol, code, buffer)
  local ok, decoded = pcall(json.decode, buffer)
  if not ok then g_logger.error("[Forge] JSON error: " .. tostring(decoded)) return end
  local action = decoded.action
  local data   = decoded.data
  if     action == "open"            then onOpen(data)
  elseif action == "slot_update"     then onSlotUpdate(data)
  elseif action == "fusion_result"   then onFusionResult(data)
  elseif action == "transfer_result" then onTransferResult(data)
  elseif action == "convert_result"  then onConvertResult(data)
  elseif action == "history"         then onHistory(data)
  elseif action == "error"           then showError(data.message or "Unknown error")
  end
end

function onOpen(data)
  if not window then window = g_ui.displayUI("forge") ; window:hide() end
  playerMoney   = data.money   or 0
  playerDust    = data.dust    or 0
  playerDustMax = data.dustMax or 100
  playerSlivers = data.slivers or 0
  playerCores   = data.cores   or 0
  updateResourcesUI()
  if data.fusionItems       then populateItemList("fusionItemList",       data.fusionItems,       "selectFusionItem")      end

  -- Lista de convergence: filtra considerando que 1 unidade sera o resultado
  if data.convergenceItems then
    local filtered = {}
    for _, item in ipairs(data.convergenceItems) do
      if slot1Data and item.id == slot1Data.id and math.floor(item.tier or 0) == math.floor(slot1Data.tier or 0) then
        -- Este e o mesmo tipo do item selecionado como resultado
        -- Precisa de count >= 3 para ter 2 sobrando para consumir (1 resultado + 2 consumidos)
        if (item.count or 0) >= 3 then
          local copy = {}
          for k, v in pairs(item) do copy[k] = v end
          copy.count = item.count - 1  -- mostra quantos estao disponiveis para consumo
          table.insert(filtered, copy)
        end
      else
        -- Item diferente do selecionado: precisa de count >= 2
        if (item.count or 0) >= 2 then
          table.insert(filtered, item)
        end
      end
    end
    populateItemList("convergenceItemList", filtered, "selectConvergenceItem")
  end

  if data.transferDonors    then populateItemList("transferDonorList",    data.transferDonors,    "selectTransferDonor")   end
  if data.transferReceivers then populateItemList("transferReceiverList", data.transferReceivers, "selectTransferReceiver") end
  isRefreshing = true
  if slot1Data then
    if activeTab == "fusion" then
      -- No refresh, nao chama selectFusionItem pois resetaria slot2Data
      -- Apenas reaplica o visual sem resetar o estado
      local displayId = slot1Data.clientId or slot1Data.id
      local sel = window:recursiveGetChildById("fusionSelectedItem")
      if sel then sel:setItemId(displayId) end
      local btn1 = window:recursiveGetChildById("fusionBtnItem1")
      local btn2 = window:recursiveGetChildById("fusionBtnItem2")
      if btn1 then btn1:setItemId(displayId) end
      if btn2 then btn2:setItemId(displayId) end
      local selBadge = window:recursiveGetChildById("fusionSelectedBadge")
      setTierBadge(selBadge, (slot1Data.tier or 0) + 1)
      -- Atualiza slot do fusionBottom
      local s = wFusionSlot1Item or (window:recursiveGetChildById("fusionSlot1Item"))
      if s then s:setItemId(displayId) end
      local b = wFusionSlot1TierBadge or (window:recursiveGetChildById("slot1TierBadge"))
      setTierBadge(b, slot1Data.tier)
      local cnt = slot1Data.count or 0
      local cl = wFusionSlot1CountLabel or (window:recursiveGetChildById("fusionSlot1CountLabel"))
      if cl then cl:setText(cnt .. " / 1") ; cl:setColor(cnt >= 2 and "#c0c0c0" or "#d33c3c") end
    elseif activeTab == "transfer" then
      selectTransferDonor(slot1Data)
    end
  end
  if slot2Data and activeTab == "transfer" then selectTransferReceiver(slot2Data) end
  isRefreshing = false
end

function populateItemList(listId, items, callbackName)
  if not window then return end
  local list = window:recursiveGetChildById(listId)
  if not list then return end
  list:destroyChildren()
  for _, item in ipairs(items) do
    local entry = g_ui.createWidget("ForgeItemEntry", list)
    local w = entry:getChildById("entryItem")
    if w then w:setItemId(item.clientId or item.id) end
    setTierBadge(entry:getChildById("entryTierBadge"), item.tier)
    local countLbl = entry:getChildById("entryCount")
    if countLbl then
      if item.count and item.count > 1 then countLbl:setText(tostring(item.count)) ; countLbl:show()
      else countLbl:hide() end
    end
    entry.onMousePress = function(widget, mousePos, mouseButton)
      if mouseButton == MouseLeftButton then
        -- remove highlight de todos os itens da lista
        local parentList = widget:getParent()
        if parentList then
          for i = 1, parentList:getChildCount() do
            local child = parentList:getChildByIndex(i)
            if child then
              child:setBorderWidth(1)
              child:setBorderColor("#555555")
            end
          end
        end
        -- aplica highlight neste
        widget:setBorderWidth(2)
        widget:setBorderColor("#ffffff")
        modules.game_forge[callbackName](item)
      end
    end
  end
end

function setTierBadge(badge, tier)
  if not badge then return end
  if tier and tier >= 1 and tier <= 10 then
    badge:setImageSource("/images/ui/tier/t" .. tier)
    badge:show()
  else
    badge:hide()
  end
end

-- ============================================================
-- FUSION
-- ============================================================
function selectFusionItem(item)
  -- Reseta slot2Data apenas se o item selecionado mudou
  if not slot1Data or slot1Data.id ~= item.id or slot1Data.tier ~= item.tier then
    slot2Data = nil
  end
  slot1Data = item
  requestRefresh()
  local displayId = item.clientId or item.id
  local tier = math.floor(item.tier or 0)
  local cls  = math.floor(item.classification or 0)

  local sel = window:recursiveGetChildById("fusionSelectedItem")
  if sel then sel:setItemId(displayId) end
  local btn1 = window:recursiveGetChildById("fusionBtnItem1")
  local btn2 = window:recursiveGetChildById("fusionBtnItem2")
  if btn1 then btn1:setItemId(displayId) end
  if btn2 then btn2:setItemId(displayId) ; btn2:setImageColor({r=0,g=0,b=0,a=200}) end
  local selBadge = window:recursiveGetChildById("fusionSelectedBadge")
  setTierBadge(selBadge, tier + 1)

  local costs   = {1000,2000,3000,4000,5000,6000,7000,8000,9000,10000,11000}
  local chances = {80,70,65,60,50,40,35,25,15,7,5}
  local goldCost = costs[tier + 1] or 0
  local chance   = chances[tier + 1] or 50

  local costLbl = window:recursiveGetChildById("costLabel")
  if costLbl then
    costLbl:setText(formatNumber(goldCost))
    costLbl:setColor(playerMoney >= goldCost and "#c0c0c0" or "#d33c3c")
  end
  local dustLbl = window:recursiveGetChildById("dustCostLabel")
  if dustLbl then
    local dustNeeded = convergenceFusion and 130 or 100
    dustLbl:setText(tostring(dustNeeded))
    dustLbl:setColor(playerDust >= dustNeeded and "#c0c0c0" or "#d33c3c")
  end
  local rateLbl = window:recursiveGetChildById("successRateLabel")
  if rateLbl then
    local rate = convergenceFusion and "100%" or (chance .. "%")
    rateLbl:setText(rate)
    rateLbl:setColor((convergenceFusion or chance >= 50) and "#44ad25" or "#d33c3c")
  end

  local fusionBottom = window:recursiveGetChildById("fusionBottom")
  if fusionBottom then
    local s = wFusionSlot1Item or fusionBottom:recursiveGetChildById("fusionSlot1Item")
    if s then s:setItemId(displayId) end
    local b = wFusionSlot1TierBadge or fusionBottom:recursiveGetChildById("slot1TierBadge")
    setTierBadge(b, tier)
    local cnt = item.count or 0
    local cl = wFusionSlot1CountLabel or fusionBottom:recursiveGetChildById("fusionSlot1CountLabel")
    if cl then cl:setText(cnt .. " / 1") ; cl:setColor(cnt >= 2 and "#c0c0c0" or "#d33c3c") end
  end

  -- Atualiza titulo do painel de requisitos
  local bottomTitle = window:recursiveGetChildById("fusionBottomTitle")
  if bottomTitle then
    bottomTitle:setText(convergenceFusion and "Further Items Needed For Convergence Fusion" or "Further Items Needed For Fusion")
  end

  local desc = window:recursiveGetChildById("descriptionLabel")
  if desc then
    if convergenceFusion then
      desc:setText("The goal of a Convergence fusion is to increase the tier of an item.\nA Convergence fusion has a 100% success rate.\nThere are no bonus effects from a Convergence fusion.\nOnly items with classification 4 can be fused using Convergence.")
    else
      desc:setText("Tier " .. tier .. " -> " .. (tier+1) .. ". Cost: " .. formatNumber(goldCost) .. " gp + 100 dust. Success rate: " .. chance .. "%. Requires 2x " .. (item.name or "item") .. " Tier " .. tier .. ".")
    end
  end

  -- Mostra/esconde botao convergence apenas para classe 4
  local btnConv = window:recursiveGetChildById("btnConvergenceFusion")
  if btnConv then btnConv:setVisible(cls == 4) end

  updateForgeButton()
end

-- ============================================================
-- TRANSFER
-- ============================================================
local TRANSFER_COSTS_CLIENT = {
  [2] = { [1]={gold=5000000,cores=1}, [2]={gold=10000000,cores=2} },
  [3] = { [1]={gold=10000000,cores=1}, [2]={gold=20000000,cores=2}, [3]={gold=40000000,cores=5} },
  [4] = {
    [1]={gold=20000000,cores=1},   [2]={gold=40000000,cores=2},
    [3]={gold=65000000,cores=5},   [4]={gold=100000000,cores=10},
    [5]={gold=250000000,cores=15}, [6]={gold=750000000,cores=20},
    [7]={gold=2500000000,cores=25},[8]={gold=8000000000,cores=30},
    [9]={gold=15000000000,cores=35},
  },
}

local function getTransferCost(donorClass, targetTier)
  local cls = math.floor(donorClass or 0)
  local t   = math.floor(targetTier or 0)
  if TRANSFER_COSTS_CLIENT[cls] then return TRANSFER_COSTS_CLIENT[cls][t] end
  return nil
end

function selectTransferDonor(item)
  slot1Data = item
  requestRefresh()
  local displayId  = item.clientId or item.id
  local donorTier  = math.floor(item.tier or 0)
  local donorClass = math.floor(item.classification or 0)
  local targetTier = donorTier - 1

  local slot1w = window:recursiveGetChildById("slot1")
  if slot1w then slot1w:setItemId(displayId) end
  local btn1 = window:recursiveGetChildById("transferBtnItem1")
  if btn1 then btn1:setItemId(displayId) end
  local countLbl = window:recursiveGetChildById("slot1CountLabel")
  if countLbl then countLbl:setText("1 / 1") ; countLbl:setColor("#c0c0c0") end

  local goldCost, coresCost = 0, 0
  local costEntry = getTransferCost(donorClass, targetTier)
  if costEntry then goldCost = costEntry.gold ; coresCost = costEntry.cores end

  local costLbl = window:recursiveGetChildById("transferCostLabel")
  if costLbl then
    costLbl:setText(formatNumber(goldCost))
    costLbl:setColor(playerMoney >= goldCost and "#c0c0c0" or "#d33c3c")
  end
  local coresLbl = window:recursiveGetChildById("transferCoresLabel")
  if coresLbl then
    coresLbl:setText(tostring(coresCost))
    coresLbl:setColor(playerCores >= coresCost and "#c0c0c0" or "#d33c3c")
  end
  local dustLbl = window:recursiveGetChildById("transferDustLabel")
  if dustLbl then
    local dustNeeded = convergenceTransfer and 160 or 100
    dustLbl:setText(tostring(dustNeeded))
    dustLbl:setColor(playerDust >= dustNeeded and "#c0c0c0" or "#d33c3c")
  end

  -- Mostra/esconde botao convergence apenas para classe 4
  local btnConv = window:recursiveGetChildById("btnConvergenceTransfer")
  if btnConv then btnConv:setVisible(donorClass == 4) end

  updateForgeButton()
end

function selectTransferReceiver(item)
  slot2Data = item
  requestRefresh()
  local displayId = item.clientId or item.id
  local btn2 = window:recursiveGetChildById("transferBtnItem2")
  if btn2 then btn2:setItemId(displayId) end
  updateForgeButton()
end

-- ============================================================
-- CONVERGENCE TOGGLES
-- ============================================================
function toggleConvergenceFusion()
  if not window then return end
  if slot1Data and math.floor(slot1Data.classification or 0) ~= 4 then
    displayInfoBox("Exaltation Forge", "Convergence Fusion is only available for Class 4 items.")
    convergenceFusion = false
    local btn = window:recursiveGetChildById("btnConvergenceFusion")
    local chk = window:recursiveGetChildById("convergenceCheck")
    if btn then btn:setOn(false) end
    if chk then chk:setVisible(false) end
    return
  end
  convergenceFusion = not convergenceFusion
  if convergenceFusion then
    improveChance = false ; reduceLoss = false
    local bi = window:recursiveGetChildById("btnImproveChance")
    local br = window:recursiveGetChildById("btnReduceLoss")
    if bi then bi:setOn(false) end
    if br then br:setOn(false) end
  end
  local btn = window:recursiveGetChildById("btnConvergenceFusion")
  local chk = window:recursiveGetChildById("convergenceCheck")
  if btn then btn:setOn(convergenceFusion) end
  if chk then chk:setVisible(convergenceFusion) end

  local selSlot  = window:recursiveGetChildById("fusionSelectedSlot")
  local convList = window:recursiveGetChildById("convergenceItemList")
  local convSbar = window:recursiveGetChildById("convergenceListScrollbar")
  if selSlot  then selSlot:setVisible(not convergenceFusion) end
  if convList then convList:setVisible(convergenceFusion) end
  if convSbar then convSbar:setVisible(convergenceFusion) end
  if slot1Data then selectFusionItem(slot1Data) end
end

function selectConvergenceItem(item)
  slot2Data = item
  updateForgeButton()
end

function toggleConvergenceTransfer()
  if not window then return end
  if slot1Data and math.floor(slot1Data.classification or 0) ~= 4 then
    displayInfoBox("Exaltation Forge", "Convergence Transfer is only available for Class 4 items.")
    convergenceTransfer = false
    local btn = window:recursiveGetChildById("btnConvergenceTransfer")
    local chk = window:recursiveGetChildById("convergenceTransferCheck")
    if btn then btn:setOn(false) end
    if chk then chk:setVisible(false) end
    return
  end
  convergenceTransfer = not convergenceTransfer
  local btn = window:recursiveGetChildById("btnConvergenceTransfer")
  local chk = window:recursiveGetChildById("convergenceTransferCheck")
  if btn then btn:setOn(convergenceTransfer) end
  if chk then chk:setVisible(convergenceTransfer) end
  if slot1Data then selectTransferDonor(slot1Data) end
end

-- ============================================================
-- IMPROVE / REDUCE TOGGLES
-- ============================================================
function toggleImproveChance()
  if not window then return end
  if playerCores < 1 then
    displayInfoBox("Exaltation Forge", "You need at least 1 Exalted Core.")
    return
  end
  if convergenceFusion then
    displayInfoBox("Exaltation Forge", "Cannot use Exalted Cores with Convergence Fusion.")
    return
  end
  improveChance = not improveChance
  local btn = window:recursiveGetChildById("btnImproveChance")
  local lbl = window:recursiveGetChildById("successRateLabel")
  if btn then btn:setOn(improveChance) end
  if lbl then
    lbl:setText(improveChance and "65%" or "50%")
    lbl:setColor(improveChance and "#44ad25" or "#d33c3c")
  end
end

function toggleReduceLoss()
  if not window then return end
  if playerCores < 1 then
    displayInfoBox("Exaltation Forge", "You need at least 1 Exalted Core.")
    return
  end
  if convergenceFusion then
    displayInfoBox("Exaltation Forge", "Cannot use Exalted Cores with Convergence Fusion.")
    return
  end
  reduceLoss = not reduceLoss
  local btn = window:recursiveGetChildById("btnReduceLoss")
  local lbl = window:recursiveGetChildById("tierLossLabel")
  if btn then btn:setOn(reduceLoss) end
  if lbl then
    lbl:setText(reduceLoss and "50%" or "100%")
    lbl:setColor(reduceLoss and "#44ad25" or "#d33c3c")
  end
end

-- ============================================================
-- SLOT UPDATE / RESULTS
-- ============================================================
function onSlotUpdate(data)
  if data.slot == 1 then slot1Data = data.item else slot2Data = data.item end
  updateForgeButton()
end

function onFusionResult(data)
  playerMoney   = data.money   or playerMoney
  playerSlivers = data.slivers or playerSlivers
  playerCores   = data.cores   or playerCores
  updateResourcesUI()
  local msg = data.message or (data.success and "Fusion successful!" or "Fusion failed.")
  if data.success then
    local lbl = window:recursiveGetChildById("resultLabel")
    if lbl then
      local isPreserved = msg:find("preserved", 1, true)
      lbl:setText(msg)
      lbl:setColor(isPreserved and "#f0c040" or "#44ad25")
    end
    showResultPanel(true)
  else
    showError(msg)
    displayInfoBox("Exaltation Forge", msg)
  end
  scheduleEvent(function()
    slot1Data = nil ; slot2Data = nil
    improveChance = false ; reduceLoss = false ; convergenceFusion = false
    local bi = window and window:recursiveGetChildById("btnImproveChance")
    local br = window and window:recursiveGetChildById("btnReduceLoss")
    local bc = window and window:recursiveGetChildById("btnConvergenceFusion")
    local selSlot  = window and window:recursiveGetChildById("fusionSelectedSlot")
    local convList = window and window:recursiveGetChildById("convergenceItemList")
    local convSbar = window and window:recursiveGetChildById("convergenceListScrollbar")
    if bi then bi:setOn(false) end
    if br then br:setOn(false) end
    if bc then bc:setOn(false) end
    local chk = window and window:recursiveGetChildById("convergenceCheck")
    if chk then chk:setVisible(false) end
    if selSlot  then selSlot:setVisible(true) end
    if convList then convList:setVisible(false) end
    if convSbar then convSbar:setVisible(false) end
    local s = window and window:recursiveGetChildById("fusionSlot1Item")
    local b1 = window and window:recursiveGetChildById("fusionBtnItem1")
    local b2 = window and window:recursiveGetChildById("fusionBtnItem2")
    if s  then s:setItemId(0)  end
    if b1 then b1:setItemId(0) end
    if b2 then b2:setItemId(0) end
    updateForgeButton()
  end, 3000)
end

function onTransferResult(data)
  playerMoney   = data.money   or playerMoney
  playerSlivers = data.slivers or playerSlivers
  playerCores   = data.cores   or playerCores
  updateResourcesUI()
  local msg = data.message or (data.success and "Transfer successful!" or "Transfer failed.")
  if data.success then
    local lbl = window:recursiveGetChildById("resultLabel")
    if lbl then lbl:setText(msg) ; lbl:setColor("#44ad25") end
    showResultPanel(true)
  else
    showError(msg)
    displayInfoBox("Exaltation Forge", msg)
  end
  scheduleEvent(function()
    slot1Data = nil ; slot2Data = nil ; convergenceTransfer = false
    local s1 = window and window:recursiveGetChildById("slot1")
    local b1 = window and window:recursiveGetChildById("transferBtnItem1")
    local b2 = window and window:recursiveGetChildById("transferBtnItem2")
    local bc = window and window:recursiveGetChildById("btnConvergenceTransfer")
    if s1 then s1:setItemId(0) end
    if b1 then b1:setItemId(0) end
    if b2 then b2:setItemId(0) end
    if bc then bc:setOn(false) end
    local chkT = window and window:recursiveGetChildById("convergenceTransferCheck")
    if chkT then chkT:setVisible(false) end
    if cl then cl:setText("0 / 1") ; cl:setColor("#d33c3c") end
    updateForgeButton()
  end, 3000)
end

function onConvertResult(data)
  playerMoney   = data.money   or playerMoney
  playerSlivers = data.slivers or playerSlivers
  playerCores   = data.cores   or playerCores
  updateResourcesUI()
  local msg = data.message or "Conversion done."
  if data.success then
    local lbl = window:recursiveGetChildById("resultLabel")
    if lbl then lbl:setText(msg) ; lbl:setColor("#44ad25") end
    showResultPanel(true)
  else
    showError(msg)
    displayInfoBox("Exaltation Forge", msg)
  end
end

function onHistory(data)
  forgeHistory      = data.entries or {}
  historyPage       = data.page or historyPage
  historyTotalPages = data.totalPages or math.max(1, math.ceil(#forgeHistory / HISTORY_PAGE_SIZE))
  renderHistory()
end

-- ============================================================
-- UI HELPERS
-- ============================================================
function selectTab(tab)
  if not window then return end
  activeTab = tab
  local tabs = { "fusion", "transfer", "conversion", "history" }
  for _, t in ipairs(tabs) do
    local panel = window:recursiveGetChildById(t .. "Panel")
    local btn   = window:recursiveGetChildById("btnTab_" .. t)
    if panel then panel:setVisible(t == tab) end
    if btn   then btn:setOn(t == tab) end
  end
  showResultPanel(false)
  if tab == "history" then sendAction("history", { page = historyPage }) end
end

function updateResourcesUI()
  if not window then return end
  local m = window:recursiveGetChildById("moneyCount")
  local d = window:recursiveGetChildById("dustCount")
  local s = window:recursiveGetChildById("sliversCount")
  local c = window:recursiveGetChildById("coresCount")
  if m then m:setText(formatNumber(playerMoney)) end
  if d then d:setText(playerDust .. "/" .. playerDustMax) end
  if s then s:setText(tostring(playerSlivers)) end
  if c then c:setText(tostring(playerCores)) end
end

function updateForgeButton()
  if not window then return end
  local bf = window:recursiveGetChildById("btnFusion")
  local bt = window:recursiveGetChildById("btnTransfer")
  if bf then
    local canFuse
    if convergenceFusion then
      -- Convergence: precisa do item principal (slot1) e do segundo (slot2)
      canFuse = slot1Data ~= nil and slot2Data ~= nil
    else
      canFuse = slot1Data and (slot1Data.count or 0) >= 2
    end
    if canFuse then bf:enable() else bf:disable() end
  end
  if bt then
    if slot1Data and slot2Data then bt:enable() else bt:disable() end
  end
end

function showResultPanel(visible)
  if not window then return end
  local p = window:recursiveGetChildById("resultPanel")
  if p then p:setVisible(visible) end
  local d = window:recursiveGetChildById("descriptionPanel")
  if d then d:setVisible(not visible) end
end

-- ============================================================
-- ACTIONS
-- ============================================================
function doFusion()
  if not slot1Data then
    displayInfoBox("Exaltation Forge", "Select an item to fuse first.")
    return
  end
  local tier = math.floor(slot1Data.tier or 0)
  local cls  = math.floor(slot1Data.classification or 0)
  local costs = {1000,2000,3000,4000,5000,6000,7000,8000,9000,10000,11000}
  local goldCost = costs[tier + 1] or 0
  local dustNeeded = convergenceFusion and 130 or 100

  if convergenceFusion and cls ~= 4 then
    displayInfoBox("Exaltation Forge", "Convergence Fusion is only available for Class 4 items.")
    return
  end
  if playerMoney < goldCost then
    displayInfoBox("Exaltation Forge", "Not enough gold.\nRequired: " .. formatNumber(goldCost) .. " gp")
    return
  end
  if playerDust < dustNeeded then
    displayInfoBox("Exaltation Forge", "Not enough dust.\nRequired: " .. dustNeeded .. "\nYou have: " .. playerDust)
    return
  end
  if not convergenceFusion and (slot1Data.count or 0) < 2 then
    displayInfoBox("Exaltation Forge", "You need 2x " .. (slot1Data.name or "item") .. " Tier " .. tier .. " to fuse.\nYou have: " .. (slot1Data.count or 0))
    return
  end
  local coresNeeded = (improveChance and 1 or 0) + (reduceLoss and 1 or 0)
  if coresNeeded > 0 and playerCores < coresNeeded then
    displayInfoBox("Exaltation Forge", "Not enough Exalted Cores.\nRequired: " .. coresNeeded)
    return
  end
  showResultPanel(false)
  sendAction("fusion", {
    improveChance = improveChance,
    reduceLoss    = reduceLoss,
    convergence   = convergenceFusion,
    selectedId    = slot1Data.id,
    selectedTier  = tier,
    secondItemId  = convergenceFusion and slot2Data and slot2Data.id or nil,
  })
end

function doTransfer()
  if not slot1Data or not slot2Data then
    displayInfoBox("Exaltation Forge", "Select a donor item (Tier 2+) and a receiver item (Tier 0).")
    return
  end
  local donorTier  = math.floor(slot1Data.tier or 0)
  local donorClass = math.floor(slot1Data.classification or 0)
  local recvTier   = math.floor(slot2Data.tier or 0)
  local recvClass  = math.floor(slot2Data.classification or 0)
  local dustNeeded = convergenceTransfer and 160 or 100

  if convergenceTransfer and donorClass ~= 4 then
    displayInfoBox("Exaltation Forge", "Convergence Transfer is only available for Class 4 items.")
    return
  end
  if donorClass <= 1 then
    displayInfoBox("Exaltation Forge", "Class 1 items cannot transfer tiers.")
    return
  end
  if donorTier < 2 then
    displayInfoBox("Exaltation Forge", "Donor item must be Tier 2 or higher.")
    return
  end
  if recvTier ~= 0 then
    displayInfoBox("Exaltation Forge", "Receiver item must be Tier 0.")
    return
  end
  if donorClass ~= recvClass then
    displayInfoBox("Exaltation Forge", "Both items must be of the same class.")
    return
  end
  if playerDust < dustNeeded then
    displayInfoBox("Exaltation Forge", "Not enough Dust. Required: " .. dustNeeded .. "\nYou have: " .. playerDust)
    return
  end
  local targetTier = donorTier - 1
  local costEntry  = getTransferCost(donorClass, targetTier)
  if costEntry then
    if playerMoney < costEntry.gold then
      displayInfoBox("Exaltation Forge", "Not enough gold.\nRequired: " .. formatNumber(costEntry.gold) .. " gp")
      return
    end
    if playerCores < costEntry.cores then
      displayInfoBox("Exaltation Forge", "Not enough Exalted Cores.\nRequired: " .. costEntry.cores)
      return
    end
  end
  showResultPanel(false)
  sendAction("transfer", {
    donorId      = slot1Data.id,
    donorTier    = donorTier,
    receiverId   = slot2Data.id,
    receiverTier = recvTier,
    convergence  = convergenceTransfer,
  })
end

function doConvertDust()
  if playerDust < 60 then
    displayInfoBox("Exaltation Forge", "You need at least 60 dust.\nYou have: " .. playerDust)
    return
  end
  sendAction("convert_dust", {})
end

function doConvertSlivers()
  if playerSlivers < 50 then
    displayInfoBox("Exaltation Forge", "You need at least 50 slivers.\nYou have: " .. playerSlivers)
    return
  end
  showResultPanel(false)
  sendAction("convert_slivers", {})
end

-- ============================================================
-- HISTORY
-- ============================================================
function renderHistory()
  if not window then return end
  local list = window:recursiveGetChildById("historyList")
  if not list then return end
  list:destroyChildren()
  for _, entry in ipairs(forgeHistory) do
    local row = g_ui.createWidget("ForgeHistoryRow", list)
    row:recursiveGetChildById("historyDate"):setText(entry.date or "")
    row:recursiveGetChildById("historyAction"):setText(entry.action or "")
    local dl = row:recursiveGetChildById("historyDetail")
    dl:setText(entry.details or "")
    dl:setColor((entry.action or ""):find("Failed", 1, true) and "#d33c3c" or "#44ad25")
  end
  local total = historyTotalPages
  local pl = window:recursiveGetChildById("historyPageLabel")
  if pl then pl:setText(historyPage .. "/" .. total) end
  local pp = window:recursiveGetChildById("btnHistoryPrev")
  local np = window:recursiveGetChildById("btnHistoryNext")
  if pp then if historyPage <= 1 then pp:disable() else pp:enable() end end
  if np then if historyPage >= total then np:disable() else np:enable() end end
end

function historyPrevPage()
  if historyPage > 1 then historyPage = historyPage - 1 ; sendAction("history", { page = historyPage }) end
end

function historyNextPage()
  if historyPage < historyTotalPages then historyPage = historyPage + 1 ; sendAction("history", { page = historyPage }) end
end

-- ============================================================
-- MISC
-- ============================================================
function showError(msg)
  if not window then return end
  local lbl = window:recursiveGetChildById("errorLabel")
  if lbl then
    lbl:setText(msg) ; lbl:show()
    scheduleEvent(function() if lbl then lbl:hide() end end, 3500)
  end
end

function formatNumber(n)
  local s = tostring(math.floor(n or 0))
  local r, c = "", 0
  for i = #s, 1, -1 do
    if c > 0 and c % 3 == 0 then r = "." .. r end
    r = s:sub(i,i) .. r ; c = c + 1
  end
  return r
end

function show()
  if not window then window = g_ui.displayUI("forge") end
  selectTab(activeTab)
  sendAction("open", {})
  window:show() ; window:raise() ; window:focus()
  if forgeButton then forgeButton:setOn(true) end
end

function hide()
  if not window then return end
  window:hide()
  if forgeButton then forgeButton:setOn(false) end
end

function toggle()
  if window and window:isVisible() then hide() else show() end
end

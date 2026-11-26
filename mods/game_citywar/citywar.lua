-- ==================================================
-- game_citywar - War Private (Anti-Entrosa)
-- Comunica com o servidor pelo opcode 120 (JSON: {action, data})
-- Servidor: data/scripts/customs/citywar/citywar_opcode.lua + data/lib/core/warpv.lua
-- ==================================================

local OPCODE = 120

local MW_FREE = 1
local MW_BLOCKED = 2
local MW_LIMITED = 3

local window = nil

local createPanel, invitesPanel, currentPanel = nil, nil, nil
local createTab, invitesTab, currentTab = nil, nil, nil

local NETWORK_ACTION = {}

local config = {cities = {}, guilds = {}, isLeader = false, limits = {}}
local warState = {state = 'lobby'}
local invites = {}

local timeLeft = 0
local timerEvent = nil

-- Botao rapido "Join War" no canto inferior direito do mapa
local quickJoinButton = nil
-- true = so mostra o botao quando a war tem penalidade de morte (perde XP/itens)
-- false = mostra sempre que a guild estiver em war e o jogador fora da arena
local QUICKJOIN_ONLY_WITH_PENALTY = false

-- Botao de notificacao "War Invite" (mesmo canto do "Join War"); abre a aba Invites
local inviteNotifyButton = nil
local inviteNotifyEvent = nil
local inviteReceivedAt = 0

-- --------------------------------------------------
-- Ciclo de vida
-- --------------------------------------------------
function init()
  connect(g_game, {
    onGameStart = create,
    onGameEnd = destroy
  })

  ProtocolGame.registerExtendedOpcode(OPCODE, onExtendedOpcode)

  NETWORK_ACTION = {
    ['open'] = function(data) show() end,
    ['config'] = onConfig,
    ['state'] = onState,
    ['invites'] = onInvites,
    ['ranking'] = onRanking,
    ['ended'] = function(data)
      displayInfoBox(tr('War Private'), data and data.message or tr('The war has ended.'))
    end,
    ['info'] = function(data)
      setStatus(data and data.message or '', '#2FA02F')
    end,
    ['error'] = function(data)
      local message = data and data.message or tr('Unknown error.')
      setStatus(message, '#E72222')
      displayErrorBox(tr('War Private'), message)
    end
  }

  if g_game.isOnline() then
    create()
  end
end

function terminate()
  disconnect(g_game, {
    onGameStart = create,
    onGameEnd = destroy
  })

  ProtocolGame.unregisterExtendedOpcode(OPCODE)
  destroy()
end

function create()
  if window then
    return
  end

  window = g_ui.displayUI('citywar')
  window:hide()

  -- A janela abre pelo botao "War Private" na aba Wars do Guild Management
  -- (mods/game_guildmanagement/wars.otui) ou pelo comando !citywar.

  window.tabBar:setContentWidget(window.content)

  createPanel = g_ui.loadUI('create')
  createTab = window.tabBar:addTab(tr('New War'), createPanel)

  invitesPanel = g_ui.loadUI('invites')
  invitesTab = window.tabBar:addTab(tr('Invites'), invitesPanel)

  currentPanel = g_ui.loadUI('current')
  currentTab = window.tabBar:addTab(tr('Current War'), currentPanel)

  local mapPanel = modules.game_interface and modules.game_interface.getMapPanel and modules.game_interface.getMapPanel()
  if mapPanel then
    quickJoinButton = g_ui.loadUI('quickjoin', mapPanel)
    inviteNotifyButton = g_ui.loadUI('invitenotify', mapPanel)
  end

  setupCreatePanel()
  onInvites({invites = {}})
  onState({state = 'lobby'})

  -- ja busca config/estado/convites (lider precisa disso antes do convite chegar)
  refresh()
end

function destroy()
  stopTimer()

  config = {cities = {}, guilds = {}, isLeader = false, limits = {}}
  warState = {state = 'lobby'}
  invites = {}

  createPanel, invitesPanel, currentPanel = nil, nil, nil
  createTab, invitesTab, currentTab = nil, nil, nil

  if quickJoinButton then
    quickJoinButton:destroy()
    quickJoinButton = nil
  end

  stopInviteNotify()
  if inviteNotifyButton then
    inviteNotifyButton:destroy()
    inviteNotifyButton = nil
  end

  if window then
    window:destroy()
    window = nil
  end
end

-- --------------------------------------------------
-- Janela
-- --------------------------------------------------
function show()
  if not window then
    create()
  end
  window:show()
  window:raise()
  window:focus()
  updateInviteNotify()
end

function hide()
  if not window then
    return
  end
  window:hide()
  updateInviteNotify()
end

-- Clique no botao de notificacao: abre o modulo na aba Invites
function openInvites()
  show()
  if window and invitesTab then
    window.tabBar:selectTab(invitesTab)
  end
  updateInviteNotify()
end

function toggle()
  if not window then
    return
  end
  if window:isVisible() then
    hide()
  else
    show()
    refresh()
  end
end

function refresh()
  sendPacket('fetch')
end

function openCreateTab()
  if window and createTab then
    window.tabBar:selectTab(createTab)
  end
end

function setStatus(text, color)
  if not window then
    return
  end
  window.statusLabel:setText(text or '')
  window.statusLabel:setColor(color or '#9f9f9f')
end

-- --------------------------------------------------
-- Rede
-- --------------------------------------------------
function sendPacket(action, data)
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedOpcode(OPCODE, json.encode({action = action, data = data or {}}))
  end
end

function onExtendedOpcode(protocol, code, buffer)
  local ok, payload = pcall(function() return json.decode(buffer) end)
  if not ok or type(payload) ~= 'table' then
    g_logger.error('[CityWar] JSON error: ' .. tostring(payload))
    return
  end

  local handler = NETWORK_ACTION[payload.action]
  if handler then
    handler(payload.data or {})
  end
end

-- --------------------------------------------------
-- Aba "Nova War"
-- --------------------------------------------------
local function getWidget(id)
  return createPanel and createPanel:recursiveGetChildById(id)
end

local function formatGold(value)
  local s = tostring(math.floor(value or 0))
  local formatted = s:reverse():gsub('(%d%d%d)', '%1.'):reverse()
  if formatted:sub(1, 1) == '.' then
    formatted = formatted:sub(2)
  end
  return formatted
end

function setupCreatePanel()
  local mwMode = getWidget('mwMode')
  if not mwMode then
    -- create.otui nao carregou (ver erro anterior no log); nao derruba o modulo inteiro
    g_logger.error('[CityWar] create.otui failed to load; the New War tab is disabled.')
    createPanel = nil
    return
  end
  mwMode:addOption(tr('Free'), MW_FREE)
  mwMode:addOption(tr('Blocked'), MW_BLOCKED)
  mwMode:addOption(tr('Limited per player'), MW_LIMITED)
  mwMode.onOptionChange = function() updateCreateForm() end

  getWidget('city').onOptionChange = function() updateCreateForm() end
  getWidget('enemyGuild').onOptionChange = function()
    applyFragCap()
    updateCreateForm()
  end
  getWidget('maxLevelEnabled').onCheckChange = function() updateCreateForm() end
  getWidget('ueAllowed').onCheckChange = function() updateCreateForm() end
  getWidget('deathPenalty').onCheckChange = function() updateCreateForm() end
  local fixedLevel = getWidget('fixedLevel')
  fixedLevel:addOption(tr('Off (own stats)'), 0)
  fixedLevel.onOptionChange = function() updateCreateForm() end
  local xpPenalty = getWidget('xpPenalty')
  xpPenalty:addOption(tr('Off'), 0)
  xpPenalty.onOptionChange = function() updateCreateForm() end

  -- unidades com espaco ("60 min"); o symbol do OTML perde o espaco inicial
  local symbols = {duration = ' min', fragLimit = ' frags', teamSize = ' players', maxLevel = ' lvl',
    mwLimit = ' per player', buyIn = ' gold'}
  for _, id in ipairs({'duration', 'fragLimit', 'teamSize', 'maxLevel', 'mwLimit', 'buyIn'}) do
    local bar = getWidget(id)
    bar.symbol = symbols[id]
    bar.onValueChange = function() updateCreateForm() end
    bar:onGeometryChange()
  end

  updateCreateForm()
end

-- aplica os limites enviados pelo servidor nas barras
local function applyLimits(limits)
  if type(limits) ~= 'table' then
    return
  end
  local function setRange(id, minValue, maxValue)
    local bar = getWidget(id)
    if bar and minValue and maxValue then
      local value = bar:getValue()
      bar:setRange(minValue, maxValue)
      bar:setValue(math.max(minValue, math.min(maxValue, value)))
      bar:onGeometryChange()
    end
  end
  setRange('duration', limits.durationMin, limits.durationMax)
  setRange('teamSize', limits.teamMin, limits.teamMax)
  applyFragCap()
  if limits.maxLevelMax then
    setRange('maxLevel', 50, limits.maxLevelMax)
  end
  if limits.mwMax then
    setRange('mwLimit', 1, limits.mwMax)
  end
end

-- O limite de frags nao pode passar o limite de kills da guild war declarada
-- (game_guildmanagement) contra a guild escolhida. O servidor tambem valida.
function applyFragCap()
  if not createPanel then
    return
  end
  local bar = getWidget('fragLimit')
  local label = getWidget('fragLabel')
  local limits = config.limits or {}
  local minFrags = tonumber(limits.fragMin) or 5
  local maxFrags = tonumber(limits.fragMax) or 500

  local option = getWidget('enemyGuild'):getCurrentOption()
  local cap = option and tonumber(option.data) or 0
  if cap > 0 then
    maxFrags = math.min(maxFrags, cap)
    minFrags = math.min(minFrags, maxFrags)
    label:setText(string.format('Frag limit (max %d - declared guild war)', maxFrags))
  else
    label:setText(tr('Frag limit (kills to win)'))
  end

  local value = bar:getValue()
  bar:setRange(minFrags, maxFrags)
  bar:setValue(math.max(minFrags, math.min(maxFrags, value)))
  bar:onGeometryChange()
end

function updateCreateForm()
  if not createPanel then
    return
  end

  local maxLevelOn = getWidget('maxLevelEnabled'):isChecked()
  getWidget('maxLevel'):setEnabled(maxLevelOn)

  local mwOption = getWidget('mwMode'):getCurrentOption()
  local mwMode = mwOption and mwOption.data or MW_FREE
  getWidget('mwLimit'):setEnabled(mwMode == MW_LIMITED)

  local deathPenalty = getWidget('deathPenalty')
  -- Death penalty ja transfere a XP da morte real; XP penalty e para a morte sem perda
  getWidget('xpPenalty'):setEnabled(not deathPenalty:isChecked())

  local hasGuild = getWidget('enemyGuild'):getCurrentOption() ~= nil
  local hasCity = getWidget('city'):getCurrentOption() ~= nil
  local canSend = config.isLeader and hasGuild and hasCity and warState.state ~= 'running'
  getWidget('sendButton'):setEnabled(canSend)

  local summary = getWidget('summary')
  if not config.isLeader then
    summary:setText(tr('Only guild leaders can create a War Private.'))
  elseif warState.state == 'running' then
    summary:setText(tr('Your guild is already in a War Private.'))
  elseif not hasGuild then
    summary:setText(tr('No enemy guild available (declare a guild war first).'))
  else
    local teamSize = getWidget('teamSize'):getValue()
    summary:setText(string.format('%dx%d | %d frags | %d min | %s gold%s',
      teamSize, teamSize, getWidget('fragLimit'):getValue(), getWidget('duration'):getValue(),
      formatGold(getWidget('buyIn'):getValue()),
      (getWidget('deathPenalty'):isChecked() and ' | death penalty' or '') ..
      (getXpPenalty() > 0 and (' | xp ' .. getXpPenalty() .. '%') or '') ..
      (getFixedLevel() > 0 and (' | lvl ' .. getFixedLevel()) or '')))
  end
end

function sendInvite()
  if not createPanel then
    return
  end

  local guildOption = getWidget('enemyGuild'):getCurrentOption()
  local cityOption = getWidget('city'):getCurrentOption()
  if not guildOption or not cityOption then
    return displayErrorBox(tr('War Private'), tr('Choose the enemy guild and the city.'))
  end

  local mwOption = getWidget('mwMode'):getCurrentOption()
  local mwMode = mwOption and mwOption.data or MW_FREE
  local mwLimit = -1
  if mwMode == MW_BLOCKED then
    mwLimit = 0
  elseif mwMode == MW_LIMITED then
    mwLimit = getWidget('mwLimit'):getValue()
  end

  local maxLevel = 0
  if getWidget('maxLevelEnabled'):isChecked() then
    maxLevel = getWidget('maxLevel'):getValue()
  end

  sendPacket('invite', {
    guild = guildOption.text,
    city = cityOption.data or cityOption.text,
    duration = getWidget('duration'):getValue(),
    fragLimit = getWidget('fragLimit'):getValue(),
    teamSize = getWidget('teamSize'):getValue(),
    maxLevel = maxLevel,
    ultimateExplosion = getWidget('ueAllowed'):isChecked(),
    mwLimit = mwLimit,
    buyIn = getWidget('buyIn'):getValue(),
    deathPenalty = getWidget('deathPenalty'):isChecked(),
    fixedLevel = getFixedLevel(),
    xpPenalty = getXpPenalty()
  })
  setStatus(tr('Sending invite...'))
end

function onConfig(data)
  if not createPanel then
    return
  end
  config.isLeader = data.isLeader and true or false
  config.cities = data.cities or {}
  config.guilds = data.guilds or {}
  config.limits = data.limits or {}

  local guildCombo = getWidget('enemyGuild')
  local previousGuild = guildCombo:getCurrentOption() and guildCombo:getCurrentOption().text
  guildCombo:clearOptions()
  for _, g in ipairs(config.guilds) do
    -- data da opcao = killsMax da guild war declarada (0 = sem teto)
    if type(g) == 'table' then
      guildCombo:addOption(g.name, tonumber(g.killsMax) or 0)
    else
      guildCombo:addOption(tostring(g), 0)
    end
  end
  if previousGuild and guildCombo:isOption(previousGuild) then
    guildCombo:setCurrentOption(previousGuild, true)
  end

  local cityCombo = getWidget('city')
  local previousCity = cityCombo:getCurrentOption() and cityCombo:getCurrentOption().data
  cityCombo:clearOptions()
  for _, city in ipairs(config.cities) do
    local label = city.name
    if not city.free then
      label = label .. ' ' .. tr('(in use)')
    end
    cityCombo:addOption(label, city.name)
  end
  if previousCity then
    cityCombo:setCurrentOptionByData(previousCity, true)
  end

  local levelCombo = getWidget('fixedLevel')
  local previousLevel = getFixedLevel()
  levelCombo:clearOptions()
  levelCombo:addOption(tr('Off (own stats)'), 0)
  for _, tier in ipairs(data.levelTiers or {}) do
    levelCombo:addOption(string.format('%s %d', tr('Level'), tier), tier)
  end
  levelCombo:setCurrentOptionByData(previousLevel, true)

  local xpCombo = getWidget('xpPenalty')
  local previousXp = getXpPenalty()
  xpCombo:clearOptions()
  xpCombo:addOption(tr('Off'), 0)
  for _, tier in ipairs(data.xpPenaltyTiers or {}) do
    xpCombo:addOption(string.format('%d%% %s', tier, tr('of the XP')), tier)
  end
  xpCombo:setCurrentOptionByData(previousXp, true)

  applyLimits(config.limits)
  updateCreateForm()
end

-- XP penalty escolhido (0 = desligado; desligado tambem com Death penalty)
function getXpPenalty()
  if not createPanel or getWidget('deathPenalty'):isChecked() then
    return 0
  end
  local option = getWidget('xpPenalty'):getCurrentOption()
  return option and tonumber(option.data) or 0
end

-- nivel fixo escolhido (0 = desligado)
function getFixedLevel()
  local option = createPanel and getWidget('fixedLevel'):getCurrentOption()
  return option and tonumber(option.data) or 0
end

-- --------------------------------------------------
-- Aba "Convites"
-- --------------------------------------------------
local function describeRules(o)
  if type(o) ~= 'table' then
    return ''
  end
  local mw = tr('free')
  if (o.mwLimit or -1) == 0 then
    mw = tr('blocked')
  elseif (o.mwLimit or -1) > 0 then
    mw = o.mwLimit .. ' ' .. tr('per player')
  end
  local maxLevel = (o.maxLevel or 0) > 0 and tostring(o.maxLevel) or tr('none')
  local text = string.format('%dx%d | %d frags | %d min | max level: %s | UE: %s | MW: %s | buy-in: %s gold | death: %s',
    o.teamSize or 0, o.teamSize or 0, o.fragLimit or 0, o.duration or 0, maxLevel,
    o.ultimateExplosion and tr('allowed') or tr('blocked'), mw, formatGold(o.buyIn),
    o.deathPenalty and 'LOSES XP AND ITEMS (XP to the killers)' or 'no loss')
  if (o.xpPenalty or 0) > 0 then
    text = text .. string.format(' | %s: %d%% %s', tr('XP penalty'), o.xpPenalty, tr('to the killers'))
  end
  if (o.fixedLevel or 0) > 0 then
    text = text .. string.format(' | %s: %s %d', tr('fixed stats'), tr('level'), o.fixedLevel)
  end
  return text
end

function onInvites(data)
  if not invitesPanel then
    return
  end
  invites = data.invites or {}

  local list = invitesPanel.list
  list:destroyChildren()

  for _, invite in ipairs(invites) do
    local entry = g_ui.createWidget('CityWarInviteEntry', list)
    entry:getChildById('title'):setText(string.format('%s  -  %s', invite.inviterGuild or '?', invite.options and invite.options.city or '?'))
    entry:getChildById('details'):setText(describeRules(invite.options))
    -- obs: neste cliente tr() ja formata o texto; nao passar '%s' para tr()
    entry:getChildById('expires'):setText(string.format('Sent by %s. Expires in %d s.', invite.inviter or '?', invite.expiresIn or 0))

    local inviterGuildId = invite.inviterGuildId
    local acceptButton = entry:getChildById('acceptButton')
    local declineButton = entry:getChildById('declineButton')
    acceptButton.onClick = function()
      sendPacket('accept', {inviterGuildId = inviterGuildId})
    end
    declineButton.onClick = function()
      sendPacket('decline', {inviterGuildId = inviterGuildId})
    end
  end

  invitesPanel.emptyLabel:setVisible(#invites == 0)

  if invitesTab then
    invitesTab:setText(#invites > 0 and string.format('%s (%d)', tr('Invites'), #invites) or tr('Invites'))
    invitesTab:setOn(#invites > 0)
  end

  -- convite novo: NAO abre a janela; mostra o botao de notificacao no canto do mapa
  inviteReceivedAt = g_clock.seconds()
  updateInviteNotify()
end

-- --------------------------------------------------
-- Botao de notificacao de convite
-- --------------------------------------------------
-- segundos que ainda faltam para o convite expirar (contado no cliente)
local function inviteSecondsLeft(invite)
  local elapsed = g_clock.seconds() - inviteReceivedAt
  return math.max(0, math.floor((tonumber(invite.expiresIn) or 0) - elapsed))
end

function stopInviteNotify()
  if inviteNotifyEvent then
    removeEvent(inviteNotifyEvent)
    inviteNotifyEvent = nil
  end
end

function updateInviteNotify()
  if not inviteNotifyButton then
    return
  end

  -- convites ainda validos
  local pending = {}
  for _, invite in ipairs(invites) do
    if inviteSecondsLeft(invite) > 0 then
      table.insert(pending, invite)
    end
  end

  -- some enquanto o modulo esta aberto (a aba Invites ja mostra tudo)
  local windowOpen = window and window:isVisible()
  local show = #pending > 0 and not windowOpen
  inviteNotifyButton:setVisible(show)
  if not show then
    stopInviteNotify()
    return
  end

  local first = pending[1]
  local seconds = inviteSecondsLeft(first)
  local info = string.format('%s  |  %d:%02d', first.inviterGuild or '?', math.floor(seconds / 60), seconds % 60)
  if #pending > 1 then
    info = string.format('%s  (+%d)', info, #pending - 1)
  end
  inviteNotifyButton:getChildById('info'):setText(info)

  -- se o "Join War" tambem estiver visivel, fica em cima dele
  local stacked = quickJoinButton and quickJoinButton:isVisible()
  inviteNotifyButton:setMarginBottom(stacked and 64 or 12)
  inviteNotifyButton:raise()

  -- atualiza a contagem a cada segundo
  stopInviteNotify()
  inviteNotifyEvent = scheduleEvent(updateInviteNotify, 1000)
end

-- --------------------------------------------------
-- Aba "War Atual"
-- --------------------------------------------------
local function formatTime(seconds)
  seconds = math.max(0, math.floor(seconds or 0))
  return string.format('%02d:%02d', math.floor(seconds / 60), seconds % 60)
end

function stopTimer()
  if timerEvent then
    removeEvent(timerEvent)
    timerEvent = nil
  end
end

-- Atualiza o botao rapido (placar resumido + tempo)
function updateQuickJoin()
  if not quickJoinButton then
    return
  end

  local running = warState.state == 'running' and type(warState.teams) == 'table' and #warState.teams == 2
  local o = warState.options or {}
  local show = running and not warState.joined
  if show and QUICKJOIN_ONLY_WITH_PENALTY and not o.deathPenalty then
    show = false
  end

  quickJoinButton:setVisible(show)
  if not show then
    return
  end

  local mine = warState.myTeam or 1
  local ally, enemy = warState.teams[1], warState.teams[2]
  if mine == 2 then
    ally, enemy = enemy, ally
  end
  quickJoinButton:getChildById('info'):setText(string.format('%s  |  %d x %d  |  %s',
    warState.city or '?', ally.kills or 0, enemy.kills or 0, formatTime(timeLeft)))
  quickJoinButton:raise()
end

function quickJoin()
  sendPacket('join')
end

local function updateTimer()
  if currentPanel then
    currentPanel.war.score.timer:setText(tr('Time left') .. ': ' .. formatTime(timeLeft))
  end
  updateQuickJoin()
end

-- Texto "x/y in arena" + tempo de inatividade (guild sem ninguem na arena)
local function teamPlayersText(team, teamSize)
  local text = string.format('%d/%d %s', team.players or 0, teamSize or 0, tr('in arena'))
  local inactive = tonumber(team.inactive) or 0
  if inactive > 0 then
    local limit = (warState.inactivity and warState.inactivity.oneGuild) or 600
    text = text .. string.format('  |  inactive %s/%s', formatTime(inactive), formatTime(limit))
  end
  return text
end

function updateTeamLabels()
  if not currentPanel or type(warState.teams) ~= 'table' or #warState.teams ~= 2 then
    return
  end
  local o = warState.options or {}
  local ally, enemy = warState.teams[1], warState.teams[2]
  if (warState.myTeam or 1) == 2 then
    ally, enemy = enemy, ally
  end
  local score = currentPanel.war.score
  score.team1Players:setText(teamPlayersText(ally, o.teamSize))
  score.team1Players:setColor((tonumber(ally.inactive) or 0) > 0 and '#E72222' or '#9f9f9f')
  score.team2Players:setText(teamPlayersText(enemy, o.teamSize))
  score.team2Players:setColor((tonumber(enemy.inactive) or 0) > 0 and '#E72222' or '#9f9f9f')
end

local function startTimer(seconds)
  stopTimer()
  timeLeft = seconds or 0
  updateTimer()
  timerEvent = cycleEvent(function()
    timeLeft = math.max(0, timeLeft - 1)
    -- inatividade conta localmente entre uma atualizacao do servidor e outra
    if type(warState.teams) == 'table' then
      for _, team in ipairs(warState.teams) do
        if (tonumber(team.inactive) or 0) > 0 then
          team.inactive = team.inactive + 1
        end
      end
      updateTeamLabels()
    end
    updateTimer()
    if timeLeft <= 0 then
      stopTimer()
    end
  end, 1000)
end

function onState(data)
  warState = data or {state = 'lobby'}
  if not currentPanel then
    return
  end

  if data.isLeader ~= nil then
    config.isLeader = data.isLeader and true or false
  end

  local running = warState.state == 'running' and type(warState.teams) == 'table' and #warState.teams == 2
  currentPanel.noWar:setVisible(not running)
  currentPanel.war:setVisible(running)

  if currentTab then
    currentTab:setOn(running)
  end

  if not running then
    stopTimer()
    if data.hasGuild == false then
      currentPanel.noWar.noWarText:setText(tr('You need to belong to a guild.'))
    else
      currentPanel.noWar.noWarText:setText(tr('Your guild is not in a War Private.'))
    end
    currentPanel.noWar.createButton:setVisible(config.isLeader)
    updateCreateForm()
    updateQuickJoin()
    return
  end

  local score = currentPanel.war.score
  local t1, t2 = warState.teams[1], warState.teams[2]
  local o = warState.options or {}

  -- a guild do jogador sempre em verde
  local mine = warState.myTeam or 1
  local ally, enemy = t1, t2
  if mine == 2 then
    ally, enemy = t2, t1
  end

  score.team1Name:setText(ally.name)
  score.team1Kills:setText(tostring(ally.kills))
  score.team2Name:setText(enemy.name)
  score.team2Kills:setText(tostring(enemy.kills))
  updateTeamLabels()
  score.cityLabel:setText(string.format('%s: %s  |  %s: %d', tr('City'), warState.city or '?', tr('Frag limit'), o.fragLimit or 0))
  score.rulesText:setText(describeRules(o))

  startTimer(warState.timeLeft)

  local actions = currentPanel.war.actions
  local me = warState.me or {}
  local stats = string.format('%s: %d  |  %s: %d', tr('Your kills'), me.kills or 0, tr('Deaths'), me.deaths or 0)
  if (o.mwLimit or -1) > 0 then
    stats = stats .. string.format('\n%s: %d/%d', tr('Magic Walls used'), me.mwUsed or 0, o.mwLimit)
  end
  actions.myStats:setText(stats)

  actions.joinButton:setVisible(not warState.joined)
  actions.leaveButton:setVisible(warState.joined and true or false)
  actions.cancelButton:setVisible(config.isLeader)

  updateCreateForm()
end

function onRanking(data)
  if not currentPanel then
    return
  end
  local list = currentPanel.war.ranking.rankList
  list:destroyChildren()
  for i, entry in ipairs(data.rankings or {}) do
    local row = g_ui.createWidget('CityWarRankRow', list)
    row:setText(string.format('%d. %s  -  %d/%d  (%s)', i, entry.name or '?', entry.kills or 0, entry.deaths or 0, entry.guildName or '?'))
    if entry.team == warState.myTeam then
      row:setColor('#2FA02F')
    else
      row:setColor('#E72222')
    end
  end
end

function joinWar()
  sendPacket('join')
end

function leaveWar()
  sendPacket('leave')
end

function requestRanking()
  sendPacket('ranking')
end

function cancelWar()
  local box
  box = displayGeneralBox(tr('Forfeit war'), tr('Do you really want to forfeit? The enemy guild will win the war.'),
    {
      { text = tr('Yes'), callback = function() sendPacket('cancel') box:destroy() end },
      { text = tr('No'), callback = function() box:destroy() end },
      anchor = AnchorHorizontalCenter
    },
    function() sendPacket('cancel') box:destroy() end,
    function() box:destroy() end)
end

local OPCODE = 92

local trackerButton = nil
local trackerWindow = nil

local tasksWindow = nil

local jsonData = ""
local config = {}
local tasks = {}
local activeTasks = {}
local playerLevel = 0
local playerReadyFired = false  -- Flag para controlar se já disparou onPlayerReady

local RewardType = {
  Points = 1,
  Ranking = 2,
  Experience = 3,
  Gold = 4,
  Item = 5,
  Storage = 6,
  Teleport = 7,
}

function init()
  connect(
    g_game,
    {
      onGameStart = create,
      onGameEnd = destroy
    }
  )

  -- Adicionar evento para detectar quando player está pronto
  connect(
    LocalPlayer,
    {
      onPositionChange = onPlayerReady
    }
  )

  ProtocolGame.registerExtendedOpcode(OPCODE, onExtendedOpcode)

  if g_game.isOnline() then
    create()
  end
end

function terminate()
  disconnect(
    g_game,
    {
      onGameStart = create,
      onGameEnd = destroy
    }
  )

  disconnect(
    LocalPlayer,
    {
      onPositionChange = onPlayerReady
    }
  )

  ProtocolGame.unregisterExtendedOpcode(OPCODE, onExtendedOpcode)

  destroy()
end

function create()
  if tasksWindow then
    return
  end
  -- pbOT/TVP: botoes ficam no sidemenu (fallback: topmenu)
  local side = modules.game_sidemenu
  openTasksButton = side and side.getTasksButton and side.getTasksButton()
    or modules.client_topmenu.addLeftGameToggleButton("openTasksButton", tr("Open Tasks Panel"), "/images/topbuttons/ancestraltask", toggleTasksPanel)
  openTasksButton:setOn(false)
  trackerButton = side and side.getTasksTrackerButton and side.getTasksTrackerButton()
    or modules.client_topmenu.addLeftGameToggleButton("trackerButton", tr("Tasks Tracker"), "/images/topbuttons/ancestraltasktracker", toggleTracker)
  trackerButton:setOn(true)
  trackerWindow = g_ui.loadUI("tasks_tracker", modules.game_interface.getRightPanel())
  trackerWindow.miniwindowScrollBar:mergeStyle({["$!on"] = {}})
  trackerWindow:setContentMinimumHeight(120)
  trackerWindow:setup()

  tasksWindow = g_ui.displayUI("tasks")
  tasksWindow:hide()

  tasksWindow.info.kills.bar.scroll.onValueChange = onKillsValueChange
end

function toggleTasksPanel()
  if not tasksWindow then return end
  if tasksWindow:isVisible() then
    tasksWindow:hide()
  else
    tasksWindow:show()
    tasksWindow:raise()
  end
  if openTasksButton then openTasksButton:setOn(tasksWindow:isVisible()) end
end

function destroy()
  playerReadyFired = false  -- Reset para próximo login

  if tasksWindow then
    if trackerButton then trackerButton:setOn(false) end -- botao pertence ao sidemenu
    if openTasksButton then openTasksButton:setOn(false) end
    trackerButton = nil
    openTasksButton = nil
    trackerPanel = nil
    trackerWindow:destroy()
    trackerWindow = nil

    tasksWindow:destroy()
    tasksWindow = nil
  end

  config = {}
  tasks = {}
  activeTasks = {}
  playerLevel = 0
  jsonData = ""
end

function onPlayerReady(player, newPos, oldPos)
  -- Só dispara uma vez quando o player está pronto no jogo
  if not playerReadyFired and newPos and newPos.x > 0 then
    playerReadyFired = true
    
    -- Garante que a interface existe
    if not tasksWindow then
      create()
    end
    
    -- Aguarda 500ms para garantir que a conexão está estável
    scheduleEvent(function()
      requestTasksData()
    end, 500)
  end
end

function requestTasksData()
  -- Solicita todos os dados do servidor novamente
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedOpcode(OPCODE, json.encode({action = "refresh"}))
  end
end

function onExtendedOpcode(protocol, code, buffer)
  local char = buffer:sub(1, 1)
  local endData = false
  if char == "E" then
    endData = true
  end

  local partialData = false
  if char == "S" or char == "P" or char == "E" then
    partialData = true
    buffer = buffer:sub(2)
    jsonData = jsonData .. buffer
  end

  if partialData and not endData then
    return
  end

  -- Debug: mostrar tamanho dos dados (comentado para produção)
  local dataToProcess = endData and jsonData or buffer
  -- if #dataToProcess > 10000 then
  --   g_logger.info("[Tasks] Processing large JSON: " .. #dataToProcess .. " bytes")
  -- end

  local json_status, json_data =
    pcall(
    function()
      return json.decode(dataToProcess)
    end
  )

  -- Limpar o buffer após processar (importante!)
  if endData then
    jsonData = ""
  end

  if not json_status then
    g_logger.error("[Tasks] JSON error: " .. json_data)
    g_logger.error("[Tasks] Data length: " .. #dataToProcess)
    g_logger.error("[Tasks] First 200 chars: " .. dataToProcess:sub(1, 200))
    g_logger.error("[Tasks] Last 200 chars: " .. dataToProcess:sub(-200))
    jsonData = "" -- Limpar buffer em caso de erro
    return
  end

  local action = json_data.action
  local data = json_data.data

  if action == "config" then
    onTasksConfig(data)
  elseif action == "tasks" then
    onTasksList(data)
  elseif action == "active" then
    onTasksActive(data)
  elseif action == "update" then
    onTaskUpdate(data)
  elseif action == "points" then
    onTasksPoints(data)
  elseif action == "ranking" then
    onTasksRanking(data)
  elseif action == "open" then
    show()
  elseif action == "close" then
    hide()
  end
end

function onTasksConfig(data)
  config = data

  tasksWindow.info.kills.bar.min:setText(config.kills.Min)
  tasksWindow.info.kills.bar.max:setText(config.kills.Max)
  tasksWindow.info.kills.bar.scroll:setRange(config.kills.Min, config.kills.Max)
  tasksWindow.info.kills.bar.scroll:setValue(config.kills.Min)
end

function onTasksList(data)
  tasks = data
  local localPlayer = g_game.getLocalPlayer()
  local level = localPlayer:getLevel()
  for taskId, task in ipairs(data) do
   -- print("Debug: Processando taskId =", taskId, "task =", task)

    -- Criao do widget
    local widget = g_ui.createWidget("TaskMenuEntry", tasksWindow.tasksList)
    widget:setId(taskId)

    -- Verificao do campo 'outfits'
    if not task.outfits or #task.outfits == 0 then
        --print("Erro: task.outfits est vazio ou nil para taskId =", taskId)
    else
        local outfit = task.outfits[1] -- Acessando o primeiro outfit
      --  print("Debug: outfit encontrado =", outfit)
        widget.preview:setOutfit(outfit)
        widget.preview:setCenter(true)
    end

    -- Configurao de outras informaes
    widget.info.title:setText(task.name)
    widget.info.level:setText("Level " .. task.lvl)

    -- Configurao de bnus com verificao de nvel
    if not (task.lvl >= level - config.range and task.lvl <= level + config.range) then
        widget.info.bonus:hide()
    end
end

  tasksWindow.tasksList.onChildFocusChange = onTaskSelected
  onTaskSelected(nil, tasksWindow.tasksList:getChildByIndex(1))
  playerLevel = g_game.getLocalPlayer():getLevel()
end

function onTasksActive(data)
  for _, active in ipairs(data) do
    local task = tasks[active.taskId]
    if not task then
      goto continue
    end
    
    local widget = g_ui.createWidget("TrackerButton", trackerWindow.contentsPanel.trackerPanel)
    widget:setId(active.taskId)
    
    -- Verificação segura de outfits
    if task.outfits and #task.outfits > 0 then
      local outfit = task.outfits[1]
      widget.creature:setOutfit(outfit)
      widget.creature:setCenter(true)
    end
    
    if task.name:len() > 12 then
      widget.label:setText(task.name:sub(1, 9) .. "...")
    else
      widget.label:setText(task.name)
    end
    widget.kills:setText(active.kills .. "/" .. active.required)
    local percent = active.kills * 100 / active.required
    setBarPercent(widget, percent)
    widget.onMouseRelease = onTrackerClick
    activeTasks[active.taskId] = true
    
    ::continue::
  end
end

function collectReward(taskId)
  if not taskId then
    local focused = tasksWindow.tasksList:getFocusedChild()
    if not focused then
      return
    end

    taskId = tonumber(focused:getId())
  end

  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedOpcode(OPCODE, json.encode({action = "collect", data = {taskId = taskId}}))
  end
end



function onTaskUpdate(data)
  local widget = trackerWindow.contentsPanel.trackerPanel[tostring(data.taskId)]
  local task = tasks[data.taskId] -- Get the task object here

  if data.status == 1 then -- Task ativa/em progresso
    if not widget then
      widget = g_ui.createWidget("TrackerButton", trackerWindow.contentsPanel.trackerPanel)
      widget:setId(data.taskId)
      
      -- Verificação segura de outfits
      if task and task.outfits and #task.outfits > 0 then
        local outfit = task.outfits[1]
        widget.creature:setOutfit(outfit)
        widget.creature:setCenter(true)
      end
      
      if task and task.name:len() > 12 then
        widget.label:setText(task.name:sub(1, 9) .. "...")
      elseif task then
        widget.label:setText(task.name)
      end
      widget.onMouseRelease = onTrackerClick
      activeTasks[data.taskId] = true
    end
    widget.kills:setText(data.kills .. "/" .. data.required)
    local percent = data.kills * 100 / data.required
    setBarPercent(widget, percent)
    if task then
        task.isCompleted = false -- Ensure it's not marked as completed if it's active
    end
  elseif data.status == 2 then -- Task cancelada
    activeTasks[data.taskId] = nil
    if widget then
      widget:destroy()
    end
    if task then
        task.isCompleted = false -- Ensure it's not marked as completed
    end
  elseif data.status == 3 then -- Task concluda
  --  activeTasks[data.taskId] = nil -- Remove da lista de tasks ativas
    setBarPercent(widget, 100)
    if widget then
      widget.kills:setText("Complete") 
    end
    if task then
        task.isCompleted = true -- Mark the task as completed
    end
  end

  local focused = tasksWindow.tasksList:getFocusedChild()
  if focused and tonumber(focused:getId()) == data.taskId then -- Only update if the selected task is the one being updated
    onTaskSelected(nil, focused) -- Recalculate button visibility for the focused task
  end
end

function onTasksPoints(points)
  tasksWindow.points:setText("Current Ancestral Tasks Points: " .. points)
end

function onTasksRanking(data)
    tasksWindow.ranking:setText("Current Ancestral Ranking: " .. data.rank)
end


-- function onTrackerClick(widget, mousePosition, mouseButton)
--   local taskId = tonumber(widget:getId())
--   local menu = g_ui.createWidget("PopupMenu")
--   menu:setGameMenu(true)
--   menu:addOption(
--     "Abandon this task",
--     function()
--       cancel(taskId)
--     end
--   )
--   menu:display(menuPosition)

--   return true
-- end
function onTrackerClick(widget, mousePosition, mouseButton)
  local taskId = tonumber(widget:getId())
  local task = tasks[taskId] -- Obtenha o objeto task
  local menu = g_ui.createWidget("PopupMenu")
  menu:setGameMenu(true)

  if task and task.isCompleted then
    menu:addOption(
      "Collect Reward",
      function()
       collectReward(taskId)
      end
    )
  else
    menu:addOption(
      "Abandon this task",
      function()
        cancel(taskId) 
      end
    )
  end

  menu:display(mousePosition)

  return true
end

function setBarPercent(widget, percent)
  if percent > 92 then
    widget.killsBar:setBackgroundColor("#00BC00")
  elseif percent > 60 then
    widget.killsBar:setBackgroundColor("#50A150")
  elseif percent > 30 then
    widget.killsBar:setBackgroundColor("#A1A100")
  elseif percent > 8 then
    widget.killsBar:setBackgroundColor("#BF0A0A")
  elseif percent > 3 then
    widget.killsBar:setBackgroundColor("#910F0F")
  else
    widget.killsBar:setBackgroundColor("#850C0C")
  end
  widget.killsBar:setPercent(percent)
end

function onTaskSelected(parent, child, reason)
  if not child then
    return
  end

  local taskId = tonumber(child:getId())
  local task = tasks[taskId]

  -- Ensure 'task' and 'task.rewards' exist before iterating
  tasksWindow.info.rewards:destroyChildren()
  if task and task.rewards then
    for _, reward in ipairs(task.rewards) do
      local widget = g_ui.createWidget("Label", tasksWindow.info.rewards)
      widget:setTextAlign(AlignCenter)
      if reward.type == RewardType.Points then
        widget:setText("Tasks Points: " .. reward.value)
      elseif reward.type == RewardType.Ranking then
        widget:setText("Ranking Points: " .. reward.value)
      elseif reward.type == RewardType.Experience then
        widget:setText("Experience: " .. reward.value)
      elseif reward.type == RewardType.Gold then
        widget:setText("Gold: " .. reward.value)
      elseif reward.type == RewardType.Item then
        widget:setText(reward.amount .. "x " .. reward.name)
      elseif reward.type == RewardType.Storage then
        widget:setText(reward.desc)
      elseif reward.type == RewardType.Teleport then
        widget:setText("Teleport to " .. reward.desc)
      end
    end
  end

  -- Ensure 'task' and 'task.mobs' exist before iterating
  tasksWindow.info.monsters:destroyChildren()
  if task and task.mobs and task.outfits then
    for id, monster in ipairs(task.mobs) do
      local widget = g_ui.createWidget("UICreature", tasksWindow.info.monsters)
      -- Verificação segura de outfits
      if task.outfits[id] then
        local outfit = task.outfits[id]
        widget:setOutfit(outfit)
        widget:setCenter(true)
      end
      widget:setPhantom(false)
      widget:setTooltip(monster)
    end
  end
  
  if task and task.isCompleted then
    print("Valor: ", task.isCompleted)
  end
  
  if activeTasks[taskId] and task and not task.isCompleted then -- Check if the task is present in the 'activeTasks' table
    tasksWindow.start:hide()
    tasksWindow.cancel:show()
    tasksWindow.collect:hide()

  elseif task and task.isCompleted then -- Assuming 'task.isCompleted' is a boolean flag set by onTaskUpdate
    tasksWindow.start:hide()
    tasksWindow.cancel:hide()
    tasksWindow.collect:show()
  else
    -- Se a task no est ativa nem concluda, assume-se que pode ser iniciada
    tasksWindow.start:show()
    tasksWindow.cancel:hide()
    tasksWindow.collect:hide()
  end
end
function onKillsValueChange(widget, value, delta)
  tasksWindow.info.kills.bar.value:setText(value)

  local focused = tasksWindow.tasksList:getFocusedChild()
  if not focused then
    return
  end

  local taskId = tonumber(focused:getId())
  local task = tasks[taskId]

  local bonus = math.floor((math.max(0, value - config.bonus) / config.bonus) + 0.5)
  if bonus == 0 then
    tasksWindow.info.kills.bonuses.none:show()
    tasksWindow.info.kills.bonuses.points:hide()
    tasksWindow.info.kills.bonuses.exp:hide()
    tasksWindow.info.kills.bonuses.gold:hide()
  else
    tasksWindow.info.kills.bonuses.none:hide()
    tasksWindow.info.kills.bonuses.points:hide()
    tasksWindow.info.kills.bonuses.exp:hide()
    tasksWindow.info.kills.bonuses.gold:hide()

    for _, reward in ipairs(task.rewards) do
      if reward.type == RewardType.Points then
        local finalBonus = bonus * config.points
        tasksWindow.info.kills.bonuses.points:show()
        tasksWindow.info.kills.bonuses.points:setText("+" .. finalBonus .. "% Tasks Points")
      elseif reward.type == RewardType.Experience then
        local finalBonus = bonus * config.exp
        tasksWindow.info.kills.bonuses.exp:show()
        tasksWindow.info.kills.bonuses.exp:setText("+" .. finalBonus .. "% Exp")
      elseif reward.type == RewardType.Gold then
        local finalBonus = bonus * config.gold
        tasksWindow.info.kills.bonuses.gold:show()
        tasksWindow.info.kills.bonuses.gold:setText("+" .. finalBonus .. "% Gold")
      end
    end
  end
end

function onSearch()
  scheduleEvent(
    function()
      local searchInput = tasksWindow.searchInput
      local text = searchInput:getText():lower()

      if text:len() >= 1 then
        local children = tasksWindow.tasksList:getChildren()
        for i, child in ipairs(children) do
          local found = false
          for _, mob in ipairs(tasks[i].mobs) do
            if mob:lower():find(text) then
              found = true
              break
            end
          end

          if found then
            child:show()
          else
            child:hide()
          end
        end
      else
        local children = tasksWindow.tasksList:getChildren()
        for _, child in ipairs(children) do
          child:show()
        end
      end
    end,
    50
  )
end

function start()
  local focused = tasksWindow.tasksList:getFocusedChild()
  local taskId = tonumber(focused:getId())
  local kills = tasksWindow.info.kills.bar.scroll:getValue()

  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedOpcode(OPCODE, json.encode({action = "start", data = {taskId = taskId, kills = kills}}))
  end
end

function cancel(taskId)
  if not taskId then
    local focused = tasksWindow.tasksList:getFocusedChild()
    if not focused then
      return
    end

    taskId = tonumber(focused:getId())
  end

  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedOpcode(OPCODE, json.encode({action = "cancel", data = taskId}))
  end
end

function onTrackerClose()
  trackerButton:setOn(false)
end

function toggleTracker()
  if not trackerWindow then
    return
  end

  if trackerButton:isOn() then
    trackerWindow:close()
    trackerButton:setOn(false)
  else
    trackerWindow:open()
    trackerButton:setOn(true)
  end
end

function toggle()
  if not tasksWindow then
    return
  end
  if tasksWindow:isVisible() then
    return hide()
  end
  show()
end

function show()
  if not tasksWindow then
    return
  end

  local level = g_game.getLocalPlayer():getLevel()
  if playerLevel ~= level then
    local children = tasksWindow.tasksList:getChildren()
    for taskId, child in ipairs(children) do
      local task = tasks[taskId]
      if task.lvl >= level - config.range and task.lvl <= level + config.range then
        child.info.bonus:show()
      else
        child.info.bonus:hide()
      end
    end
    playerLevel = level
  end

  local focused = tasksWindow.tasksList:getFocusedChild()
  if focused then
    local taskId = tonumber(focused:getId())
    local task = tasks[taskId] -- Obtenha a task para verificar 'isCompleted'

    if activeTasks[taskId] then
      tasksWindow.start:hide()
      tasksWindow.cancel:show()
      tasksWindow.collect:hide()
    elseif task and task.isCompleted then -- Verifica se a task est concluda
      tasksWindow.start:hide()
      tasksWindow.cancel:hide()
      tasksWindow.collect:show()
    else
      tasksWindow.start:show()
      tasksWindow.cancel:hide()
      tasksWindow.collect:hide()
    end
  end

  tasksWindow:show()
  tasksWindow:raise()
  tasksWindow:focus()
end

function hide()
  if not tasksWindow then
    return
  end
  tasksWindow:hide()
end

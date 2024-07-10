tradeWindow = nil

function init()
  g_ui.importStyle('tradewindow')

  connect(g_game, { onOwnTrade = onGameOwnTrade,
                    onCounterTrade = onGameCounterTrade,
                    onCloseTrade = onGameCloseTrade,
                    onGameEnd = onGameCloseTrade })
end

function terminate()
  disconnect(g_game, { onOwnTrade = onGameOwnTrade,
                       onCounterTrade = onGameCounterTrade,
                       onCloseTrade = onGameCloseTrade,
                       onGameEnd = onGameCloseTrade })

  if tradeWindow then
    tradeWindow:destroy()
  end
end

local maxRows
function createTrade()
  tradeWindow = g_ui.createWidget('TradeWindow', modules.game_interface.getRightPanel())
  tradeWindow.onClose = function()
    g_game.rejectTrade()
    tradeWindow:hide()
  end
  tradeWindow.lockButton:hide()
  tradeWindow:setup()
  tradeWindow:setContentMinimumHeight(97)
  maxRows = 0
end


function fillTrade(name, items, counter)
  if not tradeWindow then
    createTrade()
  end

  local tradeContainer
  local label
  if counter then
    tradeContainer = tradeWindow:recursiveGetChildById('counterTradeContainer')
    label = tradeWindow:recursiveGetChildById('counterTradeLabel')
    tradeWindow:recursiveGetChildById('acceptButton'):enable()
    tradeWindow:recursiveGetChildById('counteroffertext'):hide()
    tradeWindow:recursiveGetChildById('counteroffertext2'):hide()
    tradeWindow:recursiveGetChildById('rejectButton'):setText("Reject")
  else
    tradeContainer = tradeWindow:recursiveGetChildById('ownTradeContainer')
    label = tradeWindow:recursiveGetChildById('ownTradeLabel')
  end
  label:setText(name)
  

  for index,item in ipairs(items) do
    local itemWidget = g_ui.createWidget('Item', tradeContainer)
    itemWidget:setItem(item)
    itemWidget:setVirtual(true)
    itemWidget:setMargin(0)
    itemWidget.onClick = function()
      g_game.inspectTrade(counter, index-1)
    end

    
  end
  maxRows = math.max(maxRows, math.ceil(#items/2+0.5))
  local maxHeight = 97 + (maxRows-1) * (133 - 97)
  tradeWindow:setContentMaximumHeight(maxHeight)
  tradeWindow:setHeight(maxHeight)
end

function onGameOwnTrade(name, items)
  fillTrade(name, items, false)
end

function onGameCounterTrade(name, items)
  fillTrade(name, items, true)
end

function onGameCloseTrade()
  modules.game_interface.updatePanels()
  if tradeWindow then
    tradeWindow:destroy()
    tradeWindow = nil
  end
end

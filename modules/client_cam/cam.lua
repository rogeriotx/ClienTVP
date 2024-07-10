updateCamTimeEvent = nil
ui = nil
camPauseEvent = nil

function init()
  ui = g_ui.loadUI('cam', modules.game_interface.getMapPanel())

  connect(g_game, { onPlayRecord = online })
  connect(PacketPlayer, { onCamStart = onCamStart,
                     onCamEnd = onCamEnd,
					 onSpeedChange = onSpeedChange,
					 onCamProcessing = onCamProcessing,
					 onCamPause = onCamPause,
                     onCamLoad = onCamLoad })
end

function terminate()
  disconnect(g_game, { onPlayRecord = online })
  disconnect(PacketPlayer, { onCamStart = onCamStart,
                     onCamEnd = onCamEnd,
					 onSpeedChange = onSpeedChange,
					 onCamProcessing = onCamProcessing,
					 onCamPause = onCamPause,
                     onCamLoad = onCamLoad })
  removeEvent(updateCamTimeEvent)
end


function onCamEnd()
removeEvent(updateCamTimeEvent)
  ui.camSpeed:hide()
  ui.camTime:hide()
  ui.camPause:hide()
end

function onSpeedChange(camPlayer, speed, oldSpeed)
  ui.camSpeed:setText("CAM Player speed: " .. speed)
  ui.camSpeed:setColor("green")
end

function onCamPause()
  ui:setSize({ width = 160, height = 44 })
  ui.camPause:setText("CAM Pause")
  ui.camPause:setColor("red")
  ui.camPause:show()
end

function onCamStart(camPlayer)
  ui.camSpeed:setText("CAM Player speed: " .. camPlayer:getSpeed())
  ui.camSpeed:setColor("green")
  ui.camTime:setText("Time ".. formatPlayTime(camPlayer:getCurrentPlayTime() / 1000) .." of " .. formatPlayTime(camPlayer:getTotalPlayTime() / 1000))
  ui.camTime:setColor("#5FF7F7")
  ui.camSpeed:show()
  ui.camTime:show()
end

function onCamProcessing(camPlayer)
  if not ui.camPause:isHidden() then ui:setSize({ width = 160, height = 30 }) ui.camPause:hide() end
  ui.camTime:setText("Time ".. formatPlayTime(camPlayer:getCurrentPlayTime() / 1000) .." of " .. formatPlayTime(camPlayer:getTotalPlayTime() / 1000))
  ui.camTime:setColor("#5FF7F7")
end

function formatPlayTime(totalPlayTime)
    local hours = math.floor(totalPlayTime / 3600)
    local minutes = math.floor((totalPlayTime % 3600) / 60)
    local seconds = totalPlayTime % 60
    local formattedTime = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    return formattedTime
end

function online()
  scheduleEvent(function()
    local camPlayer = g_game.getCamPlayer()
    local message = "Welcome to CAM player, command set:\n"
    message = message .. "speed x - sets playback speed to x value\n"
    message = message .. "ff hh:mm:ss - Fast forward till given time"
    modules.game_textmessage.displayBroadcastMessage(message)
	modules.game_textmessage.displayFailureMessage(camPlayer:getCamFile())
  end, 100)
end
-- private variables
local background
local accessAccountLink = ""..Services.accessAccountWebsite..""

-- public functions
function init()
  background = g_ui.displayUI('background')
  background:lower()
  check_sprites_loading()
  connect(g_game, { onGameStart = hide })
  connect(g_game, { onGameEnd = show })
end

function terminate()
  disconnect(g_game, { onGameStart = hide })
  disconnect(g_game, { onGameEnd = show })
  background:destroy()
  Background = nil
end

function accessAccount()
   g_platform.openUrl(accessAccountLink)
end

function hide()
  background:hide()
end

function show()
  background:show()
end

function getBackground()
  return background
end

function check_sprites_loading()
    local frequency = 2 -- 5 vezes por segundo
    if g_sprites.isLoaded() then
      for _, child in pairs(background:getChildren()) do
        child:enable()
        -- child:setOpacity(1)
        g_effects.fadeIn(child, 800)
        child:removeTooltip()
      end
      g_effects.fadeOut(background.loadingSpinner, 800)
      g_effects.fadeOut(background.warning, 800)
    else
      local miliseconds = g_clock.millis()
      
      local opacity = 0.2 + 0.2 *  math.sin(2 * math.pi * frequency * (miliseconds / 1000))
      
      for _, child in pairs(background:getChildren()) do
        child:disable()
        child:setOpacity(0)
      end
      background.loadingSpinner:setOpacity(1)
      background.warning:setOpacity(1)
      scheduleEvent(check_sprites_loading, 15)
    end
end
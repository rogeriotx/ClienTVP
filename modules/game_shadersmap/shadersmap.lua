SHADER_CONFIG = {
   checkInterval = 300,
}

AREAS = {
   -- Main
   {fromPos = {x = 0, y = 0, z = 7}, toPos = {x = 1, y = 1, z = 7}, shader = "map_HeavyRain"},
}


-- Shader
local showPosEvent
local playingShader
local SHADER_EXTENTED_OPCODE = 105


function init()
   for i = 1, #AREAS do
       AREAS[i].shader =  AREAS[i].shader
   end

   connect(g_game, { onGameStart = onGameStart,
                   onGameEnd = onGameEnd })

   if(g_game.isOnline()) then
       onGameStart()
   end
   ProtocolGame.registerExtendedJSONOpcode(SHADER_EXTENTED_OPCODE, onExtendedJSONOpcode)
end



function onExtendedJSONOpcode(protocol, code, json_data)
   local action = json_data['action']
   local data = json_data['data']
   local status = json_data['status']

   otcv8shop = true
   if action == 'remove' then
     stopShader()
   elseif action == 'setMap' then
     playShader(data.shader)
   end
 
   if status then
     processStatus(status)
   end
 end

function terminate()
   disconnect(g_game, { onGameStart = onGameStart,
                      onGameEnd = onGameEnd })
   onGameEnd()
   ProtocolGame.unregisterExtendedJSONOpcode(SHADER_EXTENTED_OPCODE, onExtendedJSONOpcode)
end


function onGameStart()
   stopShader()
   toggleShaderEvent = addEvent(toggleShader, SHADER_CONFIG.checkInterval)
end


function onGameEnd()
   stopShader()
   removeEvent(toggleShaderEvent)
end


function isInPos(pos, fromPos, toPos)
   return
       pos.x>=fromPos.x and
       pos.y>=fromPos.y and
       pos.z>=fromPos.z and
       pos.x<=toPos.x and
       pos.y<=toPos.y and
       pos.z<=toPos.z
end


function toggleShader()
   local player = g_game.getLocalPlayer()
   if not player then return end

   local pos = player:getPosition()
   local toPlay = nil


   for i = 1, #AREAS do
       if(isInPos(pos, AREAS[i].fromPos, AREAS[i].toPos)) then
           if(toPlay) then
               toPlay.priority = toPlay.priority or 0
               if((toPlay.shader~=AREAS[i].shader) and (AREAS[i].priority>toPlay.priority)) then
                   toPlay = AREAS[i]
               end
           else
               toPlay = AREAS[i]
           end
       end
   end


   playingShader = playingShader or {shader='', priority=0}

   if(toPlay~=nil and playingShader.shader~=toPlay.shader) then
       stopShader()
       playShader(toPlay.shader)
       playingShader = toPlay
   elseif(toPlay==nil) and (playingShader.shader~='') then
       stopShader()
   end


   toggleShaderEvent = scheduleEvent(toggleShader, SHADER_CONFIG.checkInterval)
end


function playShader(shader)
   modules.game_interface.gameMapPanel:setShader(shader)
end



function stopShader()
   playingShader = nil
   modules.game_interface.gameMapPanel:setShader('map_default')
end


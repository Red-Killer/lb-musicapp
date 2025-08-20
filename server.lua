local activeSounds = {}

local function getPlayersInRange(position, range)
   local players = {}
   local allPlayers = GetPlayers()
   
   for _, playerId in ipairs(allPlayers) do
       local ped = GetPlayerPed(playerId)
       if ped and ped > 0 then
           local playerCoords = GetEntityCoords(ped)
           local distance = #(playerCoords - vector3(position.x, position.y, position.z))
           
           if distance <= range then
               table.insert(players, tonumber(playerId))
           end
       end
   end
   
   return players
end

RegisterNetEvent("phone:utune_music:soundStatus", function(type, data)
   local src = source
   local musicId = "phone_utuneemusic_id_" .. src

   if not type or not musicId then return end
   if not ({
       position = true, play = true, volume = true, stop = true,
       pause = true, resume = true
   })[type] then
       print("Invalid type for phone:utune_music:soundStatus: " .. type)
       return
   end

   if type == "play" then
       activeSounds[src] = {
           position = data.position,
           musicId = musicId,
           data = data,
           startTime = os.time(),
           pausedAt = nil,
           totalPausedTime = 0
       }

       data.startTime = os.time()
       
       local nearbyPlayers = getPlayersInRange(data.position, Config.MUSIC_RANGE)
       for _, playerId in ipairs(nearbyPlayers) do
           TriggerClientEvent("phone:utune_music:soundStatus", playerId, "play", musicId, data)
       end

   elseif type == "stop" then
       if activeSounds[src] then
           local lastPosition = activeSounds[src].position
           activeSounds[src] = nil

           local nearbyPlayers = getPlayersInRange(lastPosition, Config.MUSIC_RANGE)
           for _, playerId in ipairs(nearbyPlayers) do
               TriggerClientEvent("phone:utune_music:soundStatus", playerId, "stop", musicId)
           end
       end

   elseif type == "position" then
       if activeSounds[src] then
           activeSounds[src].position = data.position

           local nearbyPlayers = getPlayersInRange(data.position, Config.POSITION_UPDATE_RANGE)
           for _, playerId in ipairs(nearbyPlayers) do
               TriggerClientEvent("phone:utune_music:soundStatus", playerId, "position", musicId, data)
           end
       end

   elseif type == "volume" then
       if activeSounds[src] then
           if activeSounds[src].data then
               activeSounds[src].data.volume = data.volume
           end

           local nearbyPlayers = getPlayersInRange(activeSounds[src].position, Config.MUSIC_RANGE)
           for _, playerId in ipairs(nearbyPlayers) do
               TriggerClientEvent("phone:utune_music:soundStatus", playerId, "volume", musicId, data)
           end
       end

   elseif type == "pause" then
       if activeSounds[src] then
           activeSounds[src].pausedAt = os.time()
           
           local nearbyPlayers = getPlayersInRange(activeSounds[src].position, Config.MUSIC_RANGE)
           for _, playerId in ipairs(nearbyPlayers) do
               TriggerClientEvent("phone:utune_music:soundStatus", playerId, "pause", musicId, data)
           end
       end

   elseif type == "resume" then
       if activeSounds[src] then
           if activeSounds[src].pausedAt then
               local pauseDuration = os.time() - activeSounds[src].pausedAt
               activeSounds[src].totalPausedTime = activeSounds[src].totalPausedTime + pauseDuration
               activeSounds[src].pausedAt = nil
           end
           
           local nearbyPlayers = getPlayersInRange(activeSounds[src].position, Config.MUSIC_RANGE)
           for _, playerId in ipairs(nearbyPlayers) do
               TriggerClientEvent("phone:utune_music:soundStatus", playerId, "resume", musicId, data)
           end
       end
   end
end)

RegisterNetEvent("phone:utune_music:requestSync", function(targetPlayer)
   local src = source
   
   if activeSounds[targetPlayer] then
       local soundData = activeSounds[targetPlayer]
       local musicId = "phone_utuneemusic_id_" .. targetPlayer
       
       local currentTime = os.time()
       local elapsedTime = currentTime - soundData.startTime - soundData.totalPausedTime
       
       if soundData.pausedAt then
           elapsedTime = soundData.pausedAt - soundData.startTime - soundData.totalPausedTime
       end
       
       local syncData = {
           position = soundData.position,
           link = soundData.data.link,
           volume = soundData.data.volume,
           startTime = soundData.startTime,
           elapsedTime = elapsedTime,
           isPaused = soundData.pausedAt ~= nil
       }
       
       TriggerClientEvent("phone:utune_music:syncPlay", src, musicId, syncData)
   end
end)

AddEventHandler("playerDropped", function()
   local src = source
   local musicId = "phone_utuneemusic_id_" .. src

   if activeSounds[src] then
       local lastPosition = activeSounds[src].position
       local nearbyPlayers = getPlayersInRange(lastPosition, Config.MUSIC_RANGE)

       activeSounds[src] = nil

       for _, playerId in ipairs(nearbyPlayers) do
           TriggerClientEvent("phone:utune_music:soundStatus", playerId, "stop", musicId)
       end
   end
end)
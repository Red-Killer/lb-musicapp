RegisterNetEvent("phone:utune_music:soundStatus", function(type, data)
    local src = source
    local musicId = "phone_utuneemusic_id_" ..src
    if type ~= "position" and type ~= "play" and type ~= "volume" and type ~= "stop" then 
        print("Invalid type for phone:utune_music:soundStatus: " .. type)
    end

    TriggerClientEvent("phone:utune_music:soundStatus", -1, type, musicId, data)
end)

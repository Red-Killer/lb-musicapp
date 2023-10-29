RegisterNetEvent("phone:youtube_music:soundStatus", function(type, data)
    local src = source
    local musicId = "phone_youtubemusic_id_" ..src
    if type ~= "position" and type ~= "play" and type ~= "volume" and type ~= "stop" then 
        print("Invalid type for phone:youtube_music:soundStatus: " .. type)
    end

    TriggerClientEvent("phone:youtube_music:soundStatus", -1, type, musicId, data)
end)
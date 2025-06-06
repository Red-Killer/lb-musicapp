local activeSounds = {}

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
        activeSounds[src] = true
        TriggerClientEvent("phone:utune_music:soundStatus", -1, "play", musicId, data)
        TriggerClientEvent("phone:utune_music:soundStatus", -1, "position", musicId, {
            position = data.position
        })

    elseif type == "stop" then
        activeSounds[src] = nil
        TriggerClientEvent("phone:utune_music:soundStatus", -1, "stop", musicId)

    elseif type == "volume" or type == "position" or type == "pause" or type == "resume" then
        TriggerClientEvent("phone:utune_music:soundStatus", -1, type, musicId, data)
    end
end)


-- 🧹 Clean up sound when player disconnects
AddEventHandler("playerDropped", function()
    local src = source
    local musicId = "phone_utuneemusic_id_" .. src

    if activeSounds[src] then
        activeSounds[src] = nil
        TriggerClientEvent("phone:utune_music:soundStatus", -1, "stop", musicId)
    end
end)

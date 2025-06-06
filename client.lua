local identifier = "utune_music2"

CreateThread(function()
    while GetResourceState("lb-phone") ~= "started" do
        Wait(500)
    end

    local function AddApp()
        local added, errorMessage = exports["lb-phone"]:AddCustomApp({
            identifier = identifier,
            name = "uTune Music",
            description = "Play your favorite music",
            developer = "RK Development",
            defaultApp = false,
            size = 59812,
            images = {},
            ui = GetCurrentResourceName() .. "/ui/index.html",
            icon = "https://cfx-nui-" .. GetCurrentResourceName() .. "/ui/assets/icon.png"
        })

        if not added then
            print("Could not add app:", errorMessage)
        end
    end

    AddApp()

    AddEventHandler("onResourceStart", function(resource)
        if resource == "lb-phone" then
            AddApp()
        end
    end)
end)

local xSound = exports.xsound
local playing = false
local volume = 50.0
local utuneUrl = nil
local myMusicId = "phone_utuneemusic_id_" .. GetPlayerServerId(PlayerId())

-- 📦 Play music
RegisterNUICallback("playSound", function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())
    utuneUrl = data.url
    playing = true

    -- Initial play trigger
    TriggerServerEvent("phone:utune_music:soundStatus", "play", {
        position = coords,
        link = utuneUrl
    })

    -- 🔁 Force position updates to help sync sound position for nearby clients
    CreateThread(function()
        Wait(500)
        local pos = GetEntityCoords(PlayerPedId())
        TriggerServerEvent("phone:utune_music:soundStatus", "position", {
            position = pos
        })

        Wait(1000)
        local pos2 = GetEntityCoords(PlayerPedId())
        TriggerServerEvent("phone:utune_music:soundStatus", "position", {
            position = pos2
        })
    end)
end)

-- 📦 Stop music
RegisterNUICallback("stopSound", function(_, cb)
    playing = false
    TriggerServerEvent("phone:utune_music:soundStatus", "stop", {})
end)

-- 🔊 Change volume
RegisterNUICallback("changeVolume", function(data, cb)
    volume = data.volume
    TriggerServerEvent("phone:utune_music:soundStatus", "volume", {
        volume = volume
    })
end)

-- 📦 Send current state to UI
RegisterNUICallback("getData", function(_, cb)
    cb({
        isPlay = playing,
        volume = volume,
        utuneUrl = utuneUrl
    })
end)

-- 🔄 Only the source player updates position
local function getSpeed(ped)
    local vel = GetEntityVelocity(ped)
    return #(vector3(vel.x, vel.y, vel.z)) * 2.23694 -- m/s to mph
end

local lastTier = 0
local tierExpireTime = 0

-- Tiers: { [tierLevel] = { speedThreshold, waitTime } }
local tiers = {
    { speed = 125, wait = 10, level = 4 },
    { speed = 100, wait = 25, level = 3 },
    { speed = 80,  wait = 50, level = 2 },
    { speed = 30,  wait = 75, level = 1 },
    { speed = 0,   wait = 500, level = 0 },
}

CreateThread(function()
    Wait(1000)
    while true do
        if playing then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local speed = getSpeed(ped)
            local currentTime = GetGameTimer()
            local selectedWait = 1000
            local selectedTier = 0

            -- Determine the highest tier currently valid
            for _, tier in ipairs(tiers) do
                if speed >= tier.speed then
                    selectedWait = tier.wait
                    selectedTier = tier.level
                    break
                end
            end

            -- If we enter a higher tier, update and set the "stickiness" timer
            if selectedTier > lastTier then
                lastTier = selectedTier
                tierExpireTime = currentTime + 3000 -- 3 seconds of stickiness
            elseif currentTime < tierExpireTime then
                -- Maintain higher tier wait time even if speed drops
                for _, tier in ipairs(tiers) do
                    if tier.level == lastTier then
                        selectedWait = tier.wait
                        break
                    end
                end
            else
                lastTier = selectedTier
            end

            -- Send position update
            TriggerServerEvent("phone:utune_music:soundStatus", "position", {
                position = coords
            })

            Wait(selectedWait)
        else
            Wait(1000)
        end
    end
end)


-- 🎧 Receive music updates from server
RegisterNetEvent("phone:utune_music:soundStatus", function(type, musicId, data)
    if type == "play" then
        xSound:PlayUrlPos(musicId, data.link, 1.0, data.position)
        xSound:setSoundDynamic(musicId, true)
        xSound:Distance(musicId, 15)
        xSound:destroyOnFinish(musicId, true)

        local vol = data.volume or volume or 50
        xSound:setVolumeMax(musicId, vol / 100)

    elseif type == "stop" then
        if xSound:soundExists(musicId) then
            xSound:Destroy(musicId)
        end

    elseif type == "volume" then
        if xSound:soundExists(musicId) then
            xSound:setVolumeMax(musicId, data.volume / 100)
        end

    elseif type == "position" then
        if xSound:soundExists(musicId) then
            xSound:Position(musicId, data.position)
        end

    elseif type == "pause" then
        if xSound:soundExists(musicId) then
            xSound:Pause(musicId)
        end

    elseif type == "resume" then
        if xSound:soundExists(musicId) then
            xSound:Resume(musicId)
        end
    end
end)


RegisterNUICallback("pauseSound", function(_, cb)
    TriggerServerEvent("phone:utune_music:soundStatus", "pause", {})
    cb({})
end)

RegisterNUICallback("resumeSound", function(_, cb)
    TriggerServerEvent("phone:utune_music:soundStatus", "resume", {})
    cb({})
end)

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
local volume = Config.DEFAULT_VOLUME
local utuneUrl = nil
local myMusicId = "phone_utuneemusic_id_" .. GetPlayerServerId(PlayerId())


local playlist = {}
local currentPlaylistIndex = 0
local isPaused = false

local function loadPlaylist()
    local savedPlaylist = GetResourceKvpString("utune_playlist")
    if savedPlaylist then
        playlist = json.decode(savedPlaylist) or {}
    else
        playlist = {}
    end
end

-- Save playlist to KVP (by using KVP we can save playlists across servers/characters)
local function savePlaylist()
    SetResourceKvp("utune_playlist", json.encode(playlist))
end

-- Load playlist on resource start
loadPlaylist()


-- Play music
RegisterNUICallback("playSound", function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())
    utuneUrl = data.url
    playing = true


    TriggerServerEvent("phone:utune_music:soundStatus", "play", {
        position = coords,
        link = utuneUrl,
        volume = volume
    })


    --  Force position updates to help sync sound position for nearby clients

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

    cb({})
end)

-- Stop music
RegisterNUICallback("stopSound", function(_, cb)
    playing = false
    isPaused = false
    currentPlaylistIndex = 0
    TriggerServerEvent("phone:utune_music:soundStatus", "stop", {})
    cb({})
end)

-- Change volume
RegisterNUICallback("changeVolume", function(data, cb)
    volume = data.volume
    TriggerServerEvent("phone:utune_music:soundStatus", "volume", {
        volume = volume
    })
    cb({})
end)

-- Send current state to UI
RegisterNUICallback("getData", function(_, cb)
    cb({
        isPlay = playing,
        volume = volume,
        utuneUrl = utuneUrl,
        playlist = playlist,
        currentPlaylistIndex = currentPlaylistIndex
    })
end)

-- Playlist callbacks
RegisterNUICallback("addToPlaylist", function(data, cb)
    table.insert(playlist, {
        url = data.url,
        title = data.title,
        thumbnail = data.thumbnail
    })
    savePlaylist()
    cb({ success = true, playlist = playlist })
end)

RegisterNUICallback("removeFromPlaylist", function(data, cb)
    table.remove(playlist, data.index)
    savePlaylist()
    cb({ success = true, playlist = playlist })
end)

RegisterNUICallback("playFromPlaylist", function(data, cb)
    if playlist[data.index] then
        currentPlaylistIndex = data.index
        local song = playlist[data.index]
        local coords = GetEntityCoords(PlayerPedId())
        utuneUrl = song.url
        playing = true

        TriggerServerEvent("phone:utune_music:soundStatus", "play", {
            position = coords,
            link = utuneUrl,
            volume = volume
        })

        -- Force position updates
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
    end
    cb({})
end)

RegisterNUICallback("getPlaylist", function(_, cb)
    cb({ playlist = playlist })
end)

RegisterNUICallback("playNext", function(_, cb)
    if #playlist > 0 then
        currentPlaylistIndex = currentPlaylistIndex + 1
        if currentPlaylistIndex > #playlist then
            currentPlaylistIndex = 1
        end

        local song = playlist[currentPlaylistIndex]
        if song then
            local coords = GetEntityCoords(PlayerPedId())
            utuneUrl = song.url
            playing = true

            TriggerServerEvent("phone:utune_music:soundStatus", "play", {
                position = coords,
                link = utuneUrl,
                volume = volume
            })
        end
    end
    cb({})
end)

RegisterNUICallback("playPrevious", function(_, cb)
    if #playlist > 0 then
        currentPlaylistIndex = currentPlaylistIndex - 1
        if currentPlaylistIndex < 1 then
            currentPlaylistIndex = #playlist
        end

        local song = playlist[currentPlaylistIndex]
        if song then
            local coords = GetEntityCoords(PlayerPedId())
            utuneUrl = song.url
            playing = true

            TriggerServerEvent("phone:utune_music:soundStatus", "play", {
                position = coords,
                link = utuneUrl,
                volume = volume
            })
        end
    end
    cb({})
end)


local function getSpeed(ped)
    local vel = GetEntityVelocity(ped)
    return #(vector3(vel.x, vel.y, vel.z)) * 2.23694 -- m/s to mph
end

local lastTier = 0
local tierExpireTime = 0
local lastPosition = vector3(0, 0, 0)
local tiers = Config.UPDATE_TIERS

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
                tierExpireTime = currentTime + Config.TIER_STICKY_TIME -- Use config value
            elseif currentTime < tierExpireTime then
                -- Maintain higher-tier wait time even if speed drops
                for _, tier in ipairs(tiers) do
                    if tier.level == lastTier then
                        selectedWait = tier.wait
                        break
                    end
                end
            else
                lastTier = selectedTier
            end
            -- Calculate distance moved since last update
            local distanceMoved = #(coords - lastPosition)

            -- Smart update logic - only send if necessary
            local shouldUpdate = false

            if selectedTier >= 3 then
                -- High speed (100+ mph): always update at interval
                shouldUpdate = true
            elseif distanceMoved > Config.MIN_DISTANCE_THRESHOLD then
                -- Moved significantly (more than 2 meters)
                shouldUpdate = true
            elseif selectedWait >= 1000 and distanceMoved > 0.5 then
                -- Stationary/slow: only update if moved at least 0.5 meters
                shouldUpdate = true
            end

            -- Only send update if we should
            if shouldUpdate then
                TriggerServerEvent("phone:utune_music:soundStatus", "position", {
                    position = coords
                })
                lastPosition = coords
            end

            Wait(selectedWait)
        else
            Wait(1000)
        end
    end
end)

-- Receive music updates from server

RegisterNetEvent("phone:utune_music:soundStatus", function(type, musicId, data)
    -- Distance check for position updates
    if type == "position" and data.position then
        local myPed = PlayerPedId()
        local myCoords = GetEntityCoords(myPed)
        local distance = #(myCoords - vector3(data.position.x, data.position.y, data.position.z))

        if distance > Config.MUSIC_RANGE then
            if xSound:soundExists(musicId) then
                xSound:Destroy(musicId)
            end
            return
        end
    end

    if type == "play" then
        if data.position then
            local myPed = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)
            local distance = #(myCoords - vector3(data.position.x, data.position.y, data.position.z))
            
            if distance > Config.MUSIC_RANGE then
                return
            end
        end

        xSound:PlayUrlPos(musicId, data.link, 1.0, data.position)
        xSound:setSoundDynamic(musicId, true)
        xSound:Distance(musicId, Config.XSOUND_DISTANCE)
        xSound:destroyOnFinish(musicId, true)


        local vol = data.volume or volume or Config.DEFAULT_VOLUME

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

-- Autoplay logic
CreateThread(function()
    while true do
        Wait(1000)
        if playing and currentPlaylistIndex > 0 and not isPaused then
            local musicId = "phone_utuneemusic_id_" .. GetPlayerServerId(PlayerId())

            -- Check if sound exists and is playing
            if not xSound:soundExists(musicId) then
                -- Song has ended, check if we should play next
                if currentPlaylistIndex < #playlist then
                    -- Play next song
                    currentPlaylistIndex = currentPlaylistIndex + 1
                    local song = playlist[currentPlaylistIndex]
                    if song then
                        Wait(500) -- Small delay
                        local coords = GetEntityCoords(PlayerPedId())
                        utuneUrl = song.url

                        TriggerServerEvent("phone:utune_music:soundStatus", "play", {
                            position = coords,
                            link = utuneUrl,
                            volume = volume
                        })

                        -- Notify UI
                        SendNUIMessage({
                            action = "songChanged",
                            url = song.url,
                            index = currentPlaylistIndex
                        })
                    end
                else
                    -- Last song in playlist, stop playing
                    playing = false
                    currentPlaylistIndex = 0
                    SendNUIMessage({
                        action = "playlistEnded"
                    })
                end
            end
        end
    end
end)

RegisterNUICallback("pauseSound", function(_, cb)
    isPaused = true
    TriggerServerEvent("phone:utune_music:soundStatus", "pause", {})
    cb({})
end)

RegisterNUICallback("resumeSound", function(_, cb)
    isPaused = false
    TriggerServerEvent("phone:utune_music:soundStatus", "resume", {})
    cb({})
end)
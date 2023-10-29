local identifier = "youtube_music2"

CreateThread(function ()
    while GetResourceState("lb-phone") ~= "started" do
        Wait(500)
    end

    local function AddApp()
        local added, errorMessage = exports["lb-phone"]:AddCustomApp({
            identifier = identifier,
            name = "YouTube Music",
            description = "Play your favorite music",
            developer = "YouTube",
            defaultApp = false, -- OPTIONAL if set to true, app should be added without having to download it,
            size = 59812, -- OPTIONAL in kb
            --price = 999999, -- OPTIONAL, Make players pay with in-game money to download the app
            images = {}, -- OPTIONAL array of images for the app on the app store
            ui = GetCurrentResourceName() .. "/ui/index.html", -- this is the path to the HTML file, can also be a URL
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

--callback for /playSound
xSound = exports.xsound
local playing = false
local musicId = "phone_youtubemusic_id_" .. GetPlayerServerId(PlayerId())

RegisterNUICallback("playSound", function(data, cb)
    local plrPed = PlayerPedId()
    local plrCoords = GetEntityCoords(plrPed)
    local url = data.url

    TriggerServerEvent("phone:youtube_music:soundStatus", "play", { position = plrCoords, link = url })
    playing = true
end)

RegisterNUICallback("changeVolume", function(data, cb)
    TriggerServerEvent("phone:youtube_music:soundStatus", "volume", { volume = data.volume })
end)

RegisterNUICallback("stopSound", function(data, cb)
    TriggerServerEvent("phone:youtube_music:soundStatus", "stop", { })
    playing = false
end)

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    local pos
    while true do
        Citizen.Wait(100)
        if xSound:soundExists(musicId) and playing then
            if xSound:isPlaying(musicId) then
                pos = GetEntityCoords(PlayerPedId())
                TriggerServerEvent("phone:youtube_music:soundStatus", "position", { position = pos })
            else
                Citizen.Wait(1000)
            end
        else
            Citizen.Wait(1000)
        end
    end
end)

RegisterNetEvent("phone:youtube_music:soundStatus", function(type, musicId, data)
    if type == "position" then
        if xSound:soundExists(musicId) then
            xSound:Position(musicId, data.position)
        end
    elseif type == "play" then
        xSound:PlayUrlPos(musicId, data.link, 1, data.position)
        xSound:destroyOnFinish(musicId, true)
        xSound:setSoundDynamic(musicId, true)
        xSound:Distance(musicId, 20)
    elseif type == "volume" then
        if xSound:soundExists(musicId) then
            -- convert volume 0 - 100 to 0.0 - 1.0
            data.volume = data.volume / 100
            xSound:setVolumeMax(musicId, data.volume)
            print("Volume changed to " .. data.volume)
        end
        elseif type == "stop" then
        if xSound:soundExists(musicId) then
            xSound:Destroy(musicId)
        end
    end
end)
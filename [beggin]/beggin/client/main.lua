Beggin.PlayerData = {}
Beggin.IsLoaded = false

local function sendReady()
    TriggerServerEvent('beggin:clientReady')
end

AddEventHandler('playerSpawned', function()
    sendReady()
end)

CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(250)
    end
    Wait(500)
    if not Beggin.IsLoaded then
        sendReady()
    end
end)

RegisterNetEvent('beggin:setPlayerData', function(data)
    Beggin.PlayerData = data or {}
    Beggin.IsLoaded = true
    TriggerEvent('beggin:playerLoaded', Beggin.PlayerData)
    Beggin.Log('info', 'player data received')
end)

RegisterNetEvent('beggin:updatePlayerData', function(patch)
    if type(patch) ~= 'table' then return end
    for k, v in pairs(patch) do
        if type(v) == 'table' and type(Beggin.PlayerData[k]) == 'table' then
            for kk, vv in pairs(v) do
                Beggin.PlayerData[k][kk] = vv
            end
        else
            Beggin.PlayerData[k] = v
        end
    end
    TriggerEvent('beggin:playerDataUpdated', patch)
end)

-- Inventory full-replace sync: removals must be visible on the client,
-- so we swap the whole table rather than merging a patch.
RegisterNetEvent('beggin:inventory:sync', function(inventory)
    Beggin.PlayerData.inventory = inventory or {}
    TriggerEvent('beggin:inventoryChanged', Beggin.PlayerData.inventory)
end)

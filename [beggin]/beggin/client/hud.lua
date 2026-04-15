local WALLET = `MP0_WALLET_BALANCE`
local BANK = `BANK_BALANCE`

local hudVisible = true

local function syncMoneyStats(accounts)
    if type(accounts) ~= 'table' then return end
    if accounts.cash ~= nil then
        StatSetInt(WALLET, math.floor(tonumber(accounts.cash) or 0), true)
    end
    if accounts.bank ~= nil then
        StatSetInt(BANK, math.floor(tonumber(accounts.bank) or 0), true)
    end
end

AddEventHandler('beggin:playerLoaded', function(data)
    syncMoneyStats(data and data.accounts)
end)

AddEventHandler('beggin:playerDataUpdated', function(patch)
    if patch and patch.accounts then
        syncMoneyStats(patch.accounts)
    end
end)

local function getWeatherName()
    local hash = GetPrevWeatherTypeHashName()
    local names = {
        'EXTRASUNNY','CLEAR','CLOUDS','SMOG','FOGGY','OVERCAST',
        'RAIN','THUNDER','CLEARING','NEUTRAL','SNOW','BLIZZARD',
        'SNOWLIGHT','XMAS','HALLOWEEN',
    }
    for _, n in ipairs(names) do
        if GetHashKey(n) == hash then return n end
    end
    return 'CLEAR'
end

local function getStreetLabel()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash)
    if street == nil or street == '' then
        return GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z)) or '---'
    end
    return street
end

local function getFoodThirst()
    local md = (Beggin.PlayerData and Beggin.PlayerData.metadata) or {}
    local food = tonumber(md.food)
    local thirst = tonumber(md.thirst)
    if food == nil then food = 100 end
    if thirst == nil then thirst = 100 end
    return food, thirst
end

CreateThread(function()
    SendNUIMessage({ action = 'setVisible', visible = true })
    while true do
        Wait(0)
        DisplayRadar(false)
    end
end)

CreateThread(function()
    while true do
        local id = GetPlayerServerId(PlayerId())
        if id and id > 0 then
            SendNUIMessage({ action = 'updateTopbar', playerId = id })
        end
        Wait(5000)
    end
end)

CreateThread(function()
    while true do
        if hudVisible and Beggin.IsLoaded then
            local ped = PlayerPedId()
            local health = GetEntityHealth(ped) - 100
            if health < 0 then health = 0 end
            local armor = GetPedArmour(ped)
            local food, thirst = getFoodThirst()

            SendNUIMessage({
                action = 'updateStats',
                health = health,
                armor = armor,
                food = food,
                thirst = thirst,
            })
        end
        Wait(500)
    end
end)

CreateThread(function()
    while true do
        if hudVisible then
            local h = GetClockHours()
            local m = GetClockMinutes()
            SendNUIMessage({
                action = 'updateEnv',
                weather = getWeatherName(),
                time = ('%02d:%02d'):format(h, m),
                street = getStreetLabel(),
            })
        end
        Wait(2000)
    end
end)

local function notify(payload)
    if type(payload) ~= 'table' then
        payload = { message = tostring(payload) }
    end
    SendNUIMessage({
        action = 'notify',
        title = payload.title,
        message = payload.message or '',
        type = payload.type or 'info',
        duration = tonumber(payload.duration) or 5000,
    })
end

RegisterNetEvent('beggin:notify', notify)

exports('Notify', notify)

exports('SetHudVisible', function(v)
    hudVisible = v and true or false
    SendNUIMessage({ action = 'setVisible', visible = hudVisible })
end)

RegisterCommand('hud', function()
    hudVisible = not hudVisible
    SendNUIMessage({ action = 'setVisible', visible = hudVisible })
end, false)

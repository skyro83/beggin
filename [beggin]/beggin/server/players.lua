Beggin.Players = {}

local function getLicense(source)
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if id:sub(1, 8) == 'license:' then
            return id
        end
    end
    return nil
end

function Beggin.GetPlayer(source)
    return Beggin.Players[tonumber(source)]
end

function Beggin.GetPlayerFromIdentifier(identifier)
    for _, player in pairs(Beggin.Players) do
        if player.identifier == identifier then
            return player
        end
    end
    return nil
end

function Beggin.GetPlayers()
    local out = {}
    for src in pairs(Beggin.Players) do
        out[#out + 1] = src
    end
    return out
end

local function loadPlayer(source)
    source = tonumber(source)
    if Beggin.Players[source] then return end

    local identifier = getLicense(source)
    if not identifier then
        Beggin.Log('error', 'no license for source %d, cannot load', source)
        return
    end

    local row = Beggin.DB.Single('SELECT * FROM users WHERE identifier = ?', { identifier })

    if not row then
        local defaults = {
            identifier = identifier,
            name = GetPlayerName(source) or '',
            accounts = json.encode(Config.DefaultAccounts),
            position = json.encode(Config.DefaultSpawn),
            metadata = json.encode({}),
        }
        Beggin.DB.Execute(
            'INSERT INTO users (identifier, name, accounts, position, metadata) VALUES (?, ?, ?, ?, ?)',
            { defaults.identifier, defaults.name, defaults.accounts, defaults.position, defaults.metadata }
        )
        row = defaults
        Beggin.Log('info', 'new user created: %s', identifier)
    end

    local player = Beggin.CreatePlayer(source, row)
    Beggin.Players[source] = player

    TriggerClientEvent('beggin:setPlayerData', source, player.getData())
    TriggerEvent('beggin:playerLoaded', source, player)

    Beggin.Log('info', 'player loaded: %s (%s)', player.name, identifier)
end

local function saveAll()
    for _, player in pairs(Beggin.Players) do
        local ok, err = pcall(player.save)
        if not ok then
            Beggin.Log('error', 'save failed for %s: %s', tostring(player.identifier), tostring(err))
        end
    end
end

Beggin.SaveAll = saveAll

RegisterNetEvent('beggin:clientReady', function()
    local src = source
    while not Beggin.Ready do Wait(50) end
    loadPlayer(src)
end)

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)
    deferrals.update('Beggin: checking identifiers...')

    local identifier = getLicense(src)
    if not identifier then
        deferrals.done('[beggin] no Rockstar license found — cannot connect.')
        return
    end

    if Beggin.Admin and Beggin.Admin.CheckBan then
        deferrals.update('Beggin: verification ban...')
        local ban = Beggin.Admin.CheckBan(identifier)
        if ban then
            local until_ = ban.expires_at and (' (jusqu\'au ' .. tostring(ban.expires_at) .. ')') or ' (permanent)'
            deferrals.done('[BAN] ' .. (ban.reason or '') .. until_)
            return
        end
    end

    deferrals.done()
end)

AddEventHandler('playerDropped', function()
    local src = source
    local player = Beggin.Players[src]
    if not player then return end
    local ok, err = pcall(player.save)
    if not ok then
        Beggin.Log('error', 'save on drop failed: %s', tostring(err))
    end
    Beggin.Players[src] = nil
    Beggin.Log('info', 'player dropped: %s', player.identifier)
end)

CreateThread(function()
    while true do
        Wait(Config.SaveInterval)
        saveAll()
        Beggin.Log('debug', 'periodic save complete (%d players)', #Beggin.GetPlayers())
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    saveAll()
end)

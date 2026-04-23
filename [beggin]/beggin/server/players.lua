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

-- Phase 1: ensure user exists, send character list to client
local function initPlayer(source)
    source = tonumber(source)
    if Beggin.Players[source] then return end

    local identifier = getLicense(source)
    if not identifier then
        Beggin.Log('error', 'no license for source %d, cannot load', source)
        return
    end

    -- Ensure user row exists in users table (license registry)
    local userRow = Beggin.DB.Single('SELECT identifier FROM users WHERE identifier = ?', { identifier })
    if not userRow then
        Beggin.DB.Execute(
            'INSERT INTO users (identifier, name, accounts, position, metadata) VALUES (?, ?, ?, ?, ?)',
            {
                identifier,
                GetPlayerName(source) or '',
                json.encode(Config.DefaultAccounts),
                json.encode(Config.DefaultSpawn),
                json.encode({}),
            }
        )
        Beggin.Log('info', 'new user registered: %s', identifier)
    end

    -- Get characters for this license
    local chars = Beggin.Characters.GetByIdentifier(identifier)

    if #chars == 0 then
        TriggerClientEvent('beggin:showCharacterCreate', source, { mustCreate = true })
        Beggin.Log('info', 'no characters for %s, showing creation screen', identifier)
    else
        local list = {}
        for _, c in ipairs(chars) do
            list[#list + 1] = {
                id = c.id,
                firstname = c.firstname,
                lastname = c.lastname,
                dateofbirth = c.dateofbirth,
                gender = c.gender,
                last_played = c.last_played,
            }
        end
        local canCreate = #chars < Config.Characters.MaxPerPlayer
        TriggerClientEvent('beggin:showCharacterSelect', source, list, canCreate)
        Beggin.Log('info', 'sent %d characters for %s', #chars, identifier)
    end
end

-- Phase 2: load a specific character into the Player Object
local function loadCharacter(source, charId)
    source = tonumber(source)
    if Beggin.Players[source] then return end

    local identifier = getLicense(source)
    if not identifier then return end

    local row = Beggin.Characters.GetById(charId)
    if not row or row.identifier ~= identifier then
        Beggin.Log('error', 'character %d does not belong to %s', charId, identifier)
        return
    end

    Beggin.Characters.UpdateLastPlayed(charId)

    local player = Beggin.CreatePlayer(source, row)
    Beggin.Players[source] = player

    TriggerClientEvent('beggin:setPlayerData', source, player.getData())
    TriggerEvent('beggin:playerLoaded', source, player)

    Beggin.Log('info', 'player loaded: %s %s (char %d, %s)', player.firstname, player.lastname, charId, identifier)
end

-- Character selected by client
RegisterNetEvent('beggin:characterSelected', function(charId)
    local src = source
    charId = tonumber(charId)
    if not charId then return end
    loadCharacter(src, charId)
end)

-- Character creation from client
RegisterNetEvent('beggin:characterCreate', function(data)
    local src = source
    if Beggin.Players[src] then return end
    if type(data) ~= 'table' then return end

    local identifier = getLicense(src)
    if not identifier then return end

    -- Check max characters
    local count = Beggin.Characters.Count(identifier)
    if count >= Config.Characters.MaxPerPlayer then
        TriggerClientEvent('beggin:notify', src, {
            title = 'Erreur',
            message = 'Nombre maximum de personnages atteint',
            type = 'error',
        })
        return
    end

    -- Validate input
    local ok, err = Beggin.Characters.ValidateInput(data)
    if not ok then
        TriggerClientEvent('beggin:notify', src, {
            title = 'Erreur',
            message = err,
            type = 'error',
        })
        return
    end

    -- Capitalize names
    local firstname = data.firstname:sub(1, 1):upper() .. data.firstname:sub(2):lower()
    local lastname = data.lastname:upper()

    local charId = Beggin.Characters.Create(identifier, {
        firstname = firstname,
        lastname = lastname,
        dateofbirth = data.dateofbirth,
        gender = data.gender,
        appearance = data.appearance and json.encode(data.appearance) or nil,
    })

    if not charId then
        TriggerClientEvent('beggin:notify', src, {
            title = 'Erreur',
            message = 'Impossible de creer le personnage',
            type = 'error',
        })
        return
    end

    Beggin.Log('info', 'character created: %s %s (id %d) for %s', firstname, lastname, charId, identifier)
    loadCharacter(src, charId)
end)

-- Character deletion from client
RegisterNetEvent('beggin:characterDelete', function(charId)
    local src = source
    charId = tonumber(charId)
    if not charId then return end

    -- Cannot delete while loaded
    if Beggin.Players[src] then return end

    local identifier = getLicense(src)
    if not identifier then return end

    -- Verify ownership
    local row = Beggin.Characters.GetById(charId)
    if not row or row.identifier ~= identifier then return end

    Beggin.Characters.Delete(charId, identifier)
    Beggin.Log('info', 'character deleted: id %d for %s', charId, identifier)

    -- Re-send updated list
    local chars = Beggin.Characters.GetByIdentifier(identifier)
    if #chars == 0 then
        TriggerClientEvent('beggin:showCharacterCreate', src, { mustCreate = true })
    else
        local list = {}
        for _, c in ipairs(chars) do
            list[#list + 1] = {
                id = c.id,
                firstname = c.firstname,
                lastname = c.lastname,
                dateofbirth = c.dateofbirth,
                gender = c.gender,
                last_played = c.last_played,
            }
        end
        local canCreate = #chars < Config.Characters.MaxPerPlayer
        TriggerClientEvent('beggin:showCharacterSelect', src, list, canCreate)
    end

    TriggerClientEvent('beggin:notify', src, {
        title = 'Personnage',
        message = 'Personnage supprime',
        type = 'success',
    })
end)

local function saveAll()
    local saved = 0
    for _, player in pairs(Beggin.Players) do
        if player.isDirty() then
            local ok, err = pcall(player.save)
            if ok then
                saved = saved + 1
            else
                Beggin.Log('error', 'save failed for %s: %s', tostring(player.identifier), tostring(err))
            end
        end
    end
    return saved
end

Beggin.SaveAll = saveAll

RegisterNetEvent('beggin:clientReady', function()
    local src = source
    while not Beggin.Ready do Wait(50) end
    initPlayer(src)
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
    Beggin.Log('info', 'player dropped: %s (char %d)', player.identifier, player.charid)
end)

CreateThread(function()
    while true do
        Wait(Config.SaveInterval)
        local saved = saveAll()
        Beggin.Log('debug', 'periodic save complete (%d/%d players)', saved, #Beggin.GetPlayers())
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    saveAll()
end)

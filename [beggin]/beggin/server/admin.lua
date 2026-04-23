Beggin.Admin = {}

local AdminModeActive = {}

local function getIdentifier(source)
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if id:sub(1, 8) == 'license:' then return id end
    end
    return nil
end

local function isAllowed(source)
    if source == 0 then return true end
    return IsPlayerAceAllowed(source, Config.Admin.Ace)
end

local function isAdminMode(source)
    if source == 0 then return true end
    return AdminModeActive[source] == true and isAllowed(source)
end

Beggin.Admin.IsAllowed = isAllowed
Beggin.Admin.IsAdminMode = isAdminMode

local function notify(source, msg, ntype)
    TriggerClientEvent('beggin:notify', source, {
        title = 'Admin',
        message = msg,
        type = ntype or 'info',
        duration = 4000,
    })
end

local function denyAccess(source, reason)
    notify(source, reason or 'Acces refuse — mode admin desactive.', 'error')
    Beggin.Log('warn', 'admin action denied for source %d (%s)', source, reason or 'no mode')
end

local function logAction(source, action, target, details)
    local adminName = source == 0 and 'CONSOLE' or (GetPlayerName(source) or ('src:' .. source))
    local adminId = source == 0 and 'console' or (getIdentifier(source) or 'unknown')
    local targetStr = target and tostring(target) or ''
    local detailsStr = details and (type(details) == 'table' and json.encode(details) or tostring(details)) or nil

    Beggin.Log('info', '[ADMIN] %s -> %s (target=%s) %s',
        adminName, action, targetStr, detailsStr or '')

    pcall(function()
        Beggin.DB.Execute(
            'INSERT INTO admin_logs (admin, action, target, details) VALUES (?, ?, ?, ?)',
            { adminId, action, targetStr, detailsStr }
        )
    end)
end

Beggin.Admin.Log = logAction

local function adminEvent(name, handler)
    RegisterNetEvent(name, function(...)
        local src = source
        if not isAdminMode(src) then
            denyAccess(src)
            return
        end
        handler(src, ...)
    end)
end

-- ============================================================
-- ADMIN MODE TOGGLE
-- ============================================================

RegisterNetEvent('beggin:admin:toggleMode', function()
    local src = source
    if not isAllowed(src) then
        notify(src, 'Vous n\'avez pas la permission admin.', 'error')
        return
    end
    local new = not AdminModeActive[src]
    AdminModeActive[src] = new
    TriggerClientEvent('beggin:admin:modeChanged', src, new)
    notify(src, new and 'Mode admin ACTIVE' or 'Mode admin desactive', new and 'success' or 'warning')
    logAction(src, new and 'mode_on' or 'mode_off', src)
end)

RegisterNetEvent('beggin:admin:queryMode', function()
    local src = source
    TriggerClientEvent('beggin:admin:modeChanged', src, AdminModeActive[src] == true and isAllowed(src))
end)

AddEventHandler('playerDropped', function()
    AdminModeActive[source] = nil
end)

-- ============================================================
-- PLAYER LIST
-- ============================================================

local function buildPlayerList(requesterSrc)
    local list = {}
    local reqPed = GetPlayerPed(requesterSrc)
    local reqCoords = reqPed and GetEntityCoords(reqPed) or vector3(0, 0, 0)

    for _, src in ipairs(GetPlayers()) do
        src = tonumber(src)
        local player = Beggin.GetPlayer(src)
        local ped = GetPlayerPed(src)
        local coords = ped and GetEntityCoords(ped) or vector3(0, 0, 0)
        local hp = ped and (GetEntityHealth(ped) - 100) or 0
        if hp < 0 then hp = 0 end
        local armor = ped and GetPedArmour(ped) or 0
        local dist = #(coords - reqCoords)

        list[#list + 1] = {
            source = src,
            name = GetPlayerName(src) or 'unknown',
            ping = GetPlayerPing(src),
            identifier = player and player.identifier or (getIdentifier(src) or ''),
            cash = player and player.getMoney('cash') or 0,
            bank = player and player.getMoney('bank') or 0,
            food = player and (tonumber(player.getMetadata('food')) or 100) or 100,
            thirst = player and (tonumber(player.getMetadata('thirst')) or 100) or 100,
            health = hp,
            armor = armor,
            x = math.floor(coords.x),
            y = math.floor(coords.y),
            z = math.floor(coords.z),
            distance = math.floor(dist),
        }
    end

    table.sort(list, function(a, b) return a.source < b.source end)
    return list
end

adminEvent('beggin:admin:requestPlayers', function(src)
    TriggerClientEvent('beggin:admin:playerList', src, buildPlayerList(src))
end)

-- ============================================================
-- TELEPORTS
-- ============================================================

local function getCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local c = GetEntityCoords(ped)
    return { x = c.x, y = c.y, z = c.z, heading = GetEntityHeading(ped) }
end

adminEvent('beggin:admin:tpToPlayer', function(src, targetId)
    targetId = tonumber(targetId)
    local coords = getCoords(targetId)
    if not coords then notify(src, 'Joueur introuvable.', 'error'); return end
    TriggerClientEvent('beggin:admin:teleport', src, coords)
    logAction(src, 'tp_to_player', targetId, coords)
end)

adminEvent('beggin:admin:tpPlayerHere', function(src, targetId)
    targetId = tonumber(targetId)
    local coords = getCoords(src)
    if not coords then return end
    TriggerClientEvent('beggin:admin:teleport', targetId, coords)
    notify(targetId, 'Vous avez ete teleporte par un admin.', 'warning')
    logAction(src, 'tp_player_here', targetId, coords)
end)

adminEvent('beggin:admin:tpIntoVehicle', function(src, targetId)
    targetId = tonumber(targetId)
    TriggerClientEvent('beggin:admin:tpIntoVehicle', src, targetId)
    logAction(src, 'tp_into_vehicle', targetId)
end)

adminEvent('beggin:admin:tpToCoords', function(src, coords)
    if type(coords) ~= 'table' then return end
    TriggerClientEvent('beggin:admin:teleport', src, coords)
    logAction(src, 'tp_coords', src, coords)
end)

-- ============================================================
-- PLAYER ACTIONS
-- ============================================================

adminEvent('beggin:admin:heal', function(src, targetId)
    targetId = tonumber(targetId)
    TriggerClientEvent('beggin:admin:heal', targetId)
    local p = Beggin.GetPlayer(targetId)
    if p then
        p.setMetadata('food', 100)
        p.setMetadata('thirst', 100)
    end
    notify(targetId, 'Vous avez ete soigne par un admin.', 'success')
    logAction(src, 'heal', targetId)
end)

adminEvent('beggin:admin:revive', function(src, targetId)
    targetId = tonumber(targetId)
    TriggerClientEvent('beggin:admin:revive', targetId)
    notify(targetId, 'Vous avez ete reanime par un admin.', 'success')
    logAction(src, 'revive', targetId)
end)

adminEvent('beggin:admin:setNeed', function(src, targetId, key, value)
    targetId = tonumber(targetId)
    if key ~= 'food' and key ~= 'thirst' then return end
    Beggin.SetNeed(targetId, key, tonumber(value) or 0)
    logAction(src, 'set_need', targetId, { key = key, value = value })
end)

adminEvent('beggin:admin:freeze', function(src, targetId, freeze)
    targetId = tonumber(targetId)
    TriggerClientEvent('beggin:admin:freeze', targetId, freeze and true or false)
    logAction(src, freeze and 'freeze' or 'unfreeze', targetId)
end)

adminEvent('beggin:admin:money', function(src, targetId, account, amount, op)
    targetId = tonumber(targetId)
    amount = tonumber(amount) or 0
    local p = Beggin.GetPlayer(targetId)
    if not p then notify(src, 'Joueur introuvable.', 'error'); return end
    if account ~= 'cash' and account ~= 'bank' then return end

    local adminId = src == 0 and 'console' or (getIdentifier(src) or ('src:' .. src))
    local reason = 'admin:' .. adminId
    if op == 'add' then
        p.addMoney(account, amount, reason)
    elseif op == 'remove' then
        p.removeMoney(account, amount, reason)
    else
        p.setMoney(account, amount, reason)
    end
    notify(src, ('%s %s.%s = %s'):format(op or 'set', p.name, account, amount), 'success')
    logAction(src, 'money_' .. (op or 'set'), targetId, { account = account, amount = amount })
end)

adminEvent('beggin:admin:kick', function(src, targetId, reason)
    targetId = tonumber(targetId)
    if targetId == src then notify(src, 'Auto-action interdite.', 'error'); return end
    reason = reason and tostring(reason) or 'Aucune raison'
    DropPlayer(targetId, '[KICK] ' .. reason)
    logAction(src, 'kick', targetId, { reason = reason })
end)

adminEvent('beggin:admin:ban', function(src, targetId, reason, durationHours)
    targetId = tonumber(targetId)
    if targetId == src then notify(src, 'Auto-action interdite.', 'error'); return end
    local identifier = getIdentifier(targetId)
    if not identifier then notify(src, 'Identifier introuvable.', 'error'); return end
    reason = reason and tostring(reason) or 'Aucune raison'

    local expires = nil
    if tonumber(durationHours) and tonumber(durationHours) > 0 then
        expires = os.date('%Y-%m-%d %H:%M:%S', os.time() + tonumber(durationHours) * 3600)
    end

    Beggin.DB.Insert(
        'INSERT INTO bans (identifier, name, reason, banned_by, expires_at) VALUES (?, ?, ?, ?, ?)',
        { identifier, GetPlayerName(targetId) or '', reason, getIdentifier(src) or 'console', expires }
    )

    DropPlayer(targetId, '[BAN] ' .. reason .. (expires and (' (jusqu\'au ' .. expires .. ')') or ' (permanent)'))
    logAction(src, 'ban', targetId, { reason = reason, expires = expires })
    notify(src, 'Joueur banni: ' .. (GetPlayerName(targetId) or targetId), 'success')
end)

adminEvent('beggin:admin:unban', function(src, identifier)
    if not identifier or identifier == '' then return end
    local affected = Beggin.DB.Execute('DELETE FROM bans WHERE identifier = ?', { identifier })
    notify(src, ('Unban: %d entree(s) supprimee(s).'):format(affected or 0), 'success')
    logAction(src, 'unban', identifier)
end)

adminEvent('beggin:admin:listBans', function(src)
    local rows = Beggin.DB.Query('SELECT id, identifier, name, reason, banned_by, expires_at, created_at FROM bans ORDER BY created_at DESC LIMIT 100', {})
    TriggerClientEvent('beggin:admin:banList', src, rows or {})
end)

adminEvent('beggin:admin:mute', function(src, targetId, mute)
    targetId = tonumber(targetId)
    TriggerClientEvent('beggin:admin:mute', targetId, mute and true or false)
    MumbleSetPlayerMuted(targetId, mute and true or false)
    logAction(src, mute and 'mute' or 'unmute', targetId)
end)

adminEvent('beggin:admin:announce', function(src, message)
    if not message or message == '' then return end
    TriggerClientEvent('beggin:notify', -1, {
        title = 'Annonce',
        message = tostring(message),
        type = 'warning',
        duration = 8000,
    })
    logAction(src, 'announce', '', message)
end)

-- ============================================================
-- VEHICLE ACTIONS (relais vers client)
-- ============================================================

adminEvent('beggin:admin:vehicle', function(src, action, payload)
    TriggerClientEvent('beggin:admin:vehicleAction', src, action, payload)
    logAction(src, 'vehicle_' .. tostring(action), src, payload)
end)

adminEvent('beggin:admin:giveWeapon', function(src, targetId, weapon, ammo)
    targetId = tonumber(targetId)
    TriggerClientEvent('beggin:admin:giveWeapon', targetId, weapon, tonumber(ammo) or 250)
    logAction(src, 'give_weapon', targetId, { weapon = weapon, ammo = ammo })
end)

-- ============================================================
-- BAN CHECK (appele depuis players.lua)
-- ============================================================

function Beggin.Admin.CheckBan(identifier)
    if not identifier then return nil end
    local row = Beggin.DB.Single(
        'SELECT reason, expires_at FROM bans WHERE identifier = ? AND (expires_at IS NULL OR expires_at > NOW()) ORDER BY id DESC LIMIT 1',
        { identifier }
    )
    return row
end

-- ============================================================
-- ACE PERMISSIONS
-- ============================================================

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    ExecuteCommand('add_ace group.admin ' .. Config.Admin.Ace .. ' allow')
end)

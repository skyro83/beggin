-- ============================================================
-- BEGGIN ADMIN — client
-- ============================================================

local AdminMode = false
local PanelOpen = false
local Spectating = nil
local SpectateOrigin = nil

local Noclip = false
local Fly = false
local God = false
local Invisible = false
local Esp = false

local PositionHistory = {}

local function pushHistory()
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    table.insert(PositionHistory, 1, {
        x = c.x, y = c.y, z = c.z, heading = GetEntityHeading(ped)
    })
    while #PositionHistory > Config.Admin.PositionHistorySize do
        table.remove(PositionHistory)
    end
end

local function teleport(coords)
    if not coords then return end
    pushHistory()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local entity = (veh and veh ~= 0) and veh or ped
    SetEntityCoords(entity, coords.x + 0.0, coords.y + 0.0, coords.z + 0.0, false, false, false, false)
    if coords.heading then SetEntityHeading(entity, coords.heading + 0.0) end
end

local function notify(msg, ntype)
    SendNUIMessage({ action = 'notify', title = 'Admin', message = msg, type = ntype or 'info', duration = 3500 })
end

-- ============================================================
-- PANEL OPEN/CLOSE
-- ============================================================

local function openPanel()
    if not AdminMode then
        notify('Activez d\'abord le mode admin (/admin).', 'error')
        return
    end
    PanelOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openAdmin', locations = Config.Admin.Locations, vehicles = Config.Admin.QuickVehicles, weapons = Config.Admin.QuickWeapons })
    TriggerServerEvent('beggin:admin:requestPlayers')
end

local function closePanel()
    PanelOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeAdmin' })
end

RegisterCommand('admin', function()
    TriggerServerEvent('beggin:admin:toggleMode')
end, false)

RegisterCommand('+adminPanel', openPanel, false)
RegisterCommand('-adminPanel', function() end, false)
RegisterKeyMapping('+adminPanel', 'Ouvrir le panel admin', 'keyboard', 'F6')

RegisterNetEvent('beggin:admin:modeChanged', function(active)
    AdminMode = active and true or false
    if not AdminMode and PanelOpen then closePanel() end
    if not AdminMode then
        if Noclip then Noclip = false; SetupNoclip(false) end
        if Fly then Fly = false; SetupFly(false) end
        if God then SetEntityInvincible(PlayerPedId(), false); God = false end
        if Invisible then SetEntityVisible(PlayerPedId(), true, false); SetEntityAlpha(PlayerPedId(), 255, false); Invisible = false end
        if Esp then Esp = false end
    end
end)

CreateThread(function()
    Wait(2000)
    TriggerServerEvent('beggin:admin:queryMode')
end)

-- ============================================================
-- NUI CALLBACKS
-- ============================================================

RegisterNUICallback('close', function(_, cb)
    closePanel()
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    TriggerServerEvent('beggin:admin:requestPlayers')
    cb({ ok = true })
end)

RegisterNUICallback('action', function(data, cb)
    local a = data.action
    local target = tonumber(data.target)

    if a == 'tpTo' then
        TriggerServerEvent('beggin:admin:tpToPlayer', target)
    elseif a == 'tpHere' then
        TriggerServerEvent('beggin:admin:tpPlayerHere', target)
    elseif a == 'tpInVeh' then
        TriggerServerEvent('beggin:admin:tpIntoVehicle', target)
    elseif a == 'spectate' then
        ToggleSpectate(target)
    elseif a == 'heal' then
        TriggerServerEvent('beggin:admin:heal', target)
    elseif a == 'revive' then
        TriggerServerEvent('beggin:admin:revive', target)
    elseif a == 'freeze' then
        TriggerServerEvent('beggin:admin:freeze', target, data.value and true or false)
    elseif a == 'mute' then
        TriggerServerEvent('beggin:admin:mute', target, data.value and true or false)
    elseif a == 'kick' then
        TriggerServerEvent('beggin:admin:kick', target, data.reason)
    elseif a == 'ban' then
        TriggerServerEvent('beggin:admin:ban', target, data.reason, tonumber(data.duration))
    elseif a == 'unban' then
        TriggerServerEvent('beggin:admin:unban', data.identifier)
    elseif a == 'listBans' then
        TriggerServerEvent('beggin:admin:listBans')
    elseif a == 'money' then
        TriggerServerEvent('beggin:admin:money', target, data.account, tonumber(data.amount), data.op)
    elseif a == 'setNeed' then
        TriggerServerEvent('beggin:admin:setNeed', target, data.key, tonumber(data.value))
    elseif a == 'announce' then
        TriggerServerEvent('beggin:admin:announce', data.message)
    elseif a == 'giveWeapon' then
        TriggerServerEvent('beggin:admin:giveWeapon', target, data.weapon, data.ammo)
    elseif a == 'tpWaypoint' then
        TpWaypoint()
    elseif a == 'tpCoords' then
        teleport({ x = tonumber(data.x), y = tonumber(data.y), z = tonumber(data.z), heading = tonumber(data.heading) or 0.0 })
    elseif a == 'tpBack' then
        local prev = table.remove(PositionHistory, 1)
        if prev then
            local ped = PlayerPedId()
            SetEntityCoords(ped, prev.x, prev.y, prev.z, false, false, false, false)
            SetEntityHeading(ped, prev.heading or 0.0)
        else
            notify('Aucune position precedente.', 'warning')
        end
    elseif a == 'vehicle' then
        TriggerServerEvent('beggin:admin:vehicle', data.sub, data.payload)
        DoVehicleAction(data.sub, data.payload)
    elseif a == 'staff' then
        ToggleStaff(data.feature, data.value)
    end

    cb({ ok = true })
end)

-- ============================================================
-- TELEPORT EVENT
-- ============================================================

RegisterNetEvent('beggin:admin:teleport', function(coords)
    teleport(coords)
end)

RegisterNetEvent('beggin:admin:tpIntoVehicle', function(targetId)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    if not targetPed or targetPed == 0 then notify('Joueur introuvable a proximite.', 'error'); return end
    local veh = GetVehiclePedIsIn(targetPed, false)
    if not veh or veh == 0 then notify('Cible n\'est pas dans un vehicule.', 'warning'); return end
    for seat = -1, 4 do
        if IsVehicleSeatFree(veh, seat) then
            SetPedIntoVehicle(PlayerPedId(), veh, seat)
            return
        end
    end
    notify('Aucune place libre.', 'warning')
end)

function TpWaypoint()
    local blip = GetFirstBlipInfoId(8)
    if not DoesBlipExist(blip) then notify('Aucun waypoint.', 'warning'); return end
    local coords = GetBlipInfoIdCoord(blip)
    local found, z = GetGroundZFor_3dCoord(coords.x, coords.y, 1000.0, false)
    teleport({ x = coords.x, y = coords.y, z = found and z or coords.z, heading = 0.0 })
end

-- ============================================================
-- HEAL / REVIVE / FREEZE / MUTE
-- ============================================================

RegisterNetEvent('beggin:admin:heal', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 100)
    ClearPedBloodDamage(ped)
end)

RegisterNetEvent('beggin:admin:revive', function()
    local ped = PlayerPedId()
    if IsEntityDead(ped) then
        local c = GetEntityCoords(ped)
        NetworkResurrectLocalPlayer(c.x, c.y, c.z, GetEntityHeading(ped), true, false)
    end
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
end)

RegisterNetEvent('beggin:admin:freeze', function(freeze)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, freeze and true or false)
    notify(freeze and 'Vous etes freeze.' or 'Vous etes unfreeze.', 'warning')
end)

RegisterNetEvent('beggin:admin:mute', function(mute)
    notify(mute and 'Vous etes mute.' or 'Vous etes unmute.', 'warning')
end)

RegisterNetEvent('beggin:admin:giveWeapon', function(weapon, ammo)
    GiveWeaponToPed(PlayerPedId(), GetHashKey(weapon), tonumber(ammo) or 250, false, true)
end)

-- ============================================================
-- SPECTATE
-- ============================================================

function ToggleSpectate(targetId)
    local target = GetPlayerFromServerId(targetId)
    if Spectating then
        NetworkSetInSpectatorMode(false, PlayerPedId())
        if SpectateOrigin then
            SetEntityCoords(PlayerPedId(), SpectateOrigin.x, SpectateOrigin.y, SpectateOrigin.z, false, false, false, false)
        end
        Spectating = nil
        SpectateOrigin = nil
        notify('Spectate desactive.', 'info')
        return
    end
    if target == -1 or target == PlayerId() then notify('Cible invalide.', 'error'); return end
    local targetPed = GetPlayerPed(target)
    if not targetPed or targetPed == 0 then notify('Joueur trop loin (one-sync ?).', 'warning'); return end
    SpectateOrigin = GetEntityCoords(PlayerPedId())
    NetworkSetInSpectatorMode(true, targetPed)
    Spectating = targetId
    notify('Spectate: ' .. GetPlayerName(target), 'info')
end

-- ============================================================
-- STAFF MODES (noclip / fly / god / invis / esp)
-- ============================================================

function ToggleStaff(feature, value)
    local v = value and true or false
    local ped = PlayerPedId()
    if feature == 'god' then
        God = v
        SetEntityInvincible(ped, v)
        SetPedCanRagdoll(ped, not v)
    elseif feature == 'invis' then
        Invisible = v
        SetEntityVisible(ped, not v, false)
        SetEntityAlpha(ped, v and 0 or 255, false)
    elseif feature == 'noclip' then
        if v and Fly then Fly = false; SetupFly(false) end
        Noclip = v
        SetupNoclip(v)
    elseif feature == 'fly' then
        if v and Noclip then Noclip = false; SetupNoclip(false) end
        Fly = v
        SetupFly(v)
    elseif feature == 'esp' then
        Esp = v
    elseif feature == 'staff' then
        ToggleStaff('god', v)
        ToggleStaff('invis', v)
        ToggleStaff('noclip', v)
        ToggleStaff('esp', v)
    end
    notify(feature .. ' = ' .. (v and 'ON' or 'OFF'), v and 'success' or 'info')
end

function SetupNoclip(active)
    local ped = PlayerPedId()
    SetEntityInvincible(ped, active or God)
    SetEntityVisible(ped, not (active or Invisible), false)
    SetEntityCollision(ped, not active, not active)
    FreezeEntityPosition(ped, active)
    SetPedGravity(ped, not active)
end

function SetupFly(active)
    local ped = PlayerPedId()
    SetEntityInvincible(ped, active or God)
    SetPedGravity(ped, not active)
    SetEntityCollision(ped, not active, not active)
end

function RotationToDirection(rot)
    local rz = math.rad(rot.z)
    local rx = math.rad(rot.x)
    local absX = math.abs(math.cos(rx))
    return vector3(-math.sin(rz) * absX, math.cos(rz) * absX, math.sin(rx))
end

local function rightVector(rot)
    local rz = math.rad(rot.z)
    return vector3(math.cos(rz), math.sin(rz), 0.0)
end

CreateThread(function()
    while true do
        if Noclip or Fly then
            local ped = PlayerPedId()
            if IsNuiFocused then -- skip movement if panel has focus
                -- still tick fast
            end

            local camRot = GetGameplayCamRot(2)
            local fwd = RotationToDirection(camRot)
            local right = rightVector(camRot)
            local fast = IsControlPressed(0, 21) -- Shift
            local slow = IsControlPressed(0, 36) -- Ctrl

            local base = Noclip and Config.Admin.NoclipSpeed or Config.Admin.FlySpeed
            local speed = base
            if fast then speed = base * 4.0 end
            if slow then speed = base * 0.25 end

            local dx, dy, dz = 0.0, 0.0, 0.0

            if IsControlPressed(0, 32) then -- W
                dx = dx + fwd.x * speed; dy = dy + fwd.y * speed; dz = dz + fwd.z * speed
            end
            if IsControlPressed(0, 33) then -- S
                dx = dx - fwd.x * speed; dy = dy - fwd.y * speed; dz = dz - fwd.z * speed
            end
            if IsControlPressed(0, 34) then -- A
                dx = dx - right.x * speed; dy = dy - right.y * speed
            end
            if IsControlPressed(0, 35) then -- D
                dx = dx + right.x * speed; dy = dy + right.y * speed
            end
            if IsControlPressed(0, 22) or IsControlPressed(0, 44) then dz = dz + speed end -- Space/Q up
            if IsControlPressed(0, 36) or IsControlPressed(0, 38) then dz = dz - speed end -- Ctrl/E down

            if Noclip then
                local x, y, z = table.unpack(GetEntityCoords(ped, true))
                SetEntityCoordsNoOffset(ped, x + dx, y + dy, z + dz, true, true, true)
                SetEntityVelocity(ped, 0.0, 0.0, 0.0)
            elseif Fly then
                -- fly = velocity-based, collisions off, gravite off
                SetEntityVelocity(ped, dx * 10.0, dy * 10.0, dz * 10.0)
            end

            Wait(0)
        else
            Wait(200)
        end
    end
end)

-- ============================================================
-- ESP
-- ============================================================

CreateThread(function()
    while true do
        if Esp then
            local myPed = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)
            for _, pid in ipairs(GetActivePlayers()) do
                if pid ~= PlayerId() then
                    local ped = GetPlayerPed(pid)
                    if ped and ped ~= 0 and DoesEntityExist(ped) then
                        local coords = GetEntityCoords(ped)
                        local dist = #(coords - myCoords)
                        if dist < Config.Admin.EspMaxDistance then
                            local hp = GetEntityHealth(ped) - 100
                            if hp < 0 then hp = 0 end
                            local name = GetPlayerName(pid) or '?'
                            local sid = GetPlayerServerId(pid)
                            DrawText3D(coords.x, coords.y, coords.z + 1.0, ('[%d] %s\n%dm  HP:%d'):format(sid, name, math.floor(dist), hp))
                        end
                    end
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

function DrawText3D(x, y, z, text)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

-- ============================================================
-- VEHICLE ACTIONS
-- ============================================================

function DoVehicleAction(sub, payload)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    if sub == 'spawn' then
        local model = payload and payload.model
        if not model then notify('Modele manquant.', 'error'); return end
        local hash = GetHashKey(model)
        if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then notify('Modele invalide.', 'error'); return end
        RequestModel(hash)
        local t0 = GetGameTimer()
        while not HasModelLoaded(hash) and GetGameTimer() - t0 < 5000 do Wait(10) end
        if not HasModelLoaded(hash) then notify('Echec chargement modele.', 'error'); return end
        local c = GetEntityCoords(ped)
        local h = GetEntityHeading(ped)
        local newVeh = CreateVehicle(hash, c.x + 2.0, c.y + 2.0, c.z, h, true, false)
        SetVehicleOnGroundProperly(newVeh)
        SetPedIntoVehicle(ped, newVeh, -1)
        SetModelAsNoLongerNeeded(hash)
        notify('Vehicule spawne: ' .. model, 'success')
    elseif sub == 'repair' then
        if veh ~= 0 then
            SetVehicleFixed(veh)
            SetVehicleDeformationFixed(veh)
            SetVehicleEngineHealth(veh, 1000.0)
            notify('Vehicule repare.', 'success')
        end
    elseif sub == 'clean' then
        if veh ~= 0 then SetVehicleDirtLevel(veh, 0.0); notify('Nettoye.', 'success') end
    elseif sub == 'destroy' then
        if veh ~= 0 then SetVehicleEngineHealth(veh, -1.0); SetVehicleEngineOn(veh, false, true, true); notify('Detruit.', 'warning') end
    elseif sub == 'invincible' then
        if veh ~= 0 then SetEntityInvincible(veh, payload and payload.value and true or false); notify('Veh invincible = ' .. tostring(payload and payload.value), 'info') end
    elseif sub == 'deleteNear' then
        local c = GetEntityCoords(ped)
        local count = 0
        for veh2 in EnumerateVehicles() do
            if veh2 ~= veh and #(GetEntityCoords(veh2) - c) < 15.0 then
                SetEntityAsMissionEntity(veh2, true, true)
                DeleteVehicle(veh2)
                count = count + 1
            end
        end
        notify(('%d vehicules supprimes.'):format(count), 'success')
    end
end

function EnumerateVehicles()
    return coroutine.wrap(function()
        local handle, veh = FindFirstVehicle()
        local success
        repeat
            coroutine.yield(veh)
            success, veh = FindNextVehicle(handle)
        until not success
        EndFindVehicle(handle)
    end)
end

RegisterNetEvent('beggin:admin:vehicleAction', function(action, payload)
    DoVehicleAction(action, payload)
end)

-- ============================================================
-- PLAYER LIST INCOMING
-- ============================================================

RegisterNetEvent('beggin:admin:playerList', function(list)
    SendNUIMessage({ action = 'playerList', list = list })
end)

RegisterNetEvent('beggin:admin:banList', function(list)
    SendNUIMessage({ action = 'banList', list = list })
end)

-- Refresh loop while panel open
CreateThread(function()
    while true do
        if PanelOpen and AdminMode then
            TriggerServerEvent('beggin:admin:requestPlayers')
            Wait(Config.Admin.PlayerListInterval)
        else
            Wait(1000)
        end
    end
end)

-- ESC to close
CreateThread(function()
    while true do
        if PanelOpen then
            DisableControlAction(0, 200, true)
            if IsDisabledControlJustReleased(0, 200) then
                closePanel()
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

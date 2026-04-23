-- ─── Inventory — client ─────────────────────────────────────────────
-- Keybind opens the NUI, which acts as a read-only view over the live
-- server inventory. All mutations go through server events that the
-- Player Object validates; the client never writes to inventory.

local Open = false

local function isBusy()
    local ped = PlayerPedId()
    if IsEntityDead(ped) or IsPedInMeleeCombat(ped) then return true end
    if IsPedCuffed(ped) or IsPauseMenuActive() then return true end
    return false
end

local function currentInventory()
    local data = Beggin.PlayerData or {}
    return data.inventory or {}
end

local function openUI()
    if Open then return end
    if not Beggin.IsLoaded then return end
    if isBusy() then return end

    Open = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action    = 'inv_open',
        inventory = currentInventory(),
        items     = Config.Items,
        maxWeight = Config.Inventory.MaxWeight,
    })
end

local function closeUI()
    if not Open then return end
    Open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'inv_close' })
end

-- Toggle via command + keybind (default I)
RegisterCommand('inventory', function()
    if Open then closeUI() else openUI() end
end, false)

RegisterCommand('+invOpen', openUI, false)
RegisterCommand('-invOpen', function() end, false)
RegisterKeyMapping('+invOpen', 'Ouvrir l\'inventaire', 'keyboard', 'I')

-- ─── Sync: server pushes full inventory → refresh UI if open ───────
RegisterNetEvent('beggin:inventory:sync', function(inventory)
    if not Open then return end
    SendNUIMessage({ action = 'inv_update', inventory = inventory or {} })
end)

-- ─── NUI callbacks ──────────────────────────────────────────────────

RegisterNUICallback('inv_close', function(_, cb)
    closeUI()
    cb({ ok = true })
end)

RegisterNUICallback('inv_use', function(data, cb)
    if type(data) == 'table' and type(data.item) == 'string' then
        TriggerServerEvent('beggin:inventory:use', data.item)
    end
    cb({ ok = true })
end)

RegisterNUICallback('inv_drop', function(data, cb)
    if type(data) == 'table' and type(data.item) == 'string' then
        TriggerServerEvent('beggin:inventory:drop', data.item, tonumber(data.amount) or 1)
    end
    cb({ ok = true })
end)

RegisterNUICallback('inv_give', function(data, cb)
    if type(data) == 'table' and type(data.item) == 'string' then
        TriggerServerEvent('beggin:inventory:give',
            data.item,
            tonumber(data.amount) or 1,
            tonumber(data.target) or 0)
    end
    cb({ ok = true })
end)

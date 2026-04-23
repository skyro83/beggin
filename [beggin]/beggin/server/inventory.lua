-- ─── Inventory module ────────────────────────────────────────────────
-- Slotless, count-based inventory: { [itemName] = amount }. Parallels
-- the money module: every mutation flows through the Player Object,
-- which delegates logging here. No client event mutates inventory.

Beggin.Inventory = {}

-- ─── Validation helpers ──────────────────────────────────────────────

function Beggin.Inventory.IsItem(name)
    return type(name) == 'string' and Config.Items[name] ~= nil
end

function Beggin.Inventory.GetItem(name)
    return Config.Items[name]
end

function Beggin.Inventory.SanitizeAmount(amount)
    amount = tonumber(amount)
    if not amount or amount ~= amount then return nil end
    if amount <= 0 or amount == math.huge then return nil end
    return math.floor(amount)
end

-- ─── Transaction history ─────────────────────────────────────────────

function Beggin.Inventory.LogTx(charid, item, delta, balance, kind, reason, otherCharId)
    if not Config.Inventory.LogHistory then return end
    Beggin.DB.Execute(
        'INSERT INTO item_transactions (charid, item, delta, balance, kind, reason, other_charid) VALUES (?, ?, ?, ?, ?, ?, ?)',
        {
            charid,
            item,
            math.floor(tonumber(delta) or 0),
            math.floor(tonumber(balance) or 0),
            kind or 'unknown',
            tostring(reason or ''):sub(1, 120),
            otherCharId,
        }
    )
end

function Beggin.Inventory.GetHistory(charid, limit)
    limit = math.min(tonumber(limit) or Config.Inventory.HistoryLimit, Config.Inventory.HistoryMax)
    return Beggin.DB.Query(
        'SELECT item, delta, balance, kind, reason, other_charid, created_at FROM item_transactions WHERE charid = ? ORDER BY id DESC LIMIT ?',
        { charid, limit }
    ) or {}
end

-- ─── Use handlers (item -> callback) ─────────────────────────────────
-- Other resources can register effects for items. Handler signature:
--   function(player, item, amount) -> boolean (true to consume)
-- If the handler returns false, the item is NOT consumed.

local UseHandlers = {}

function Beggin.Inventory.RegisterUseHandler(name, fn)
    if type(name) ~= 'string' or type(fn) ~= 'function' then return end
    UseHandlers[name] = fn
    Beggin.Log('debug', 'inventory: use handler registered for "%s"', name)
end

function Beggin.Inventory.GetUseHandler(name)
    return UseHandlers[name]
end

-- ─── High-level server API (by source) ───────────────────────────────

local function resolve(source)
    return Beggin.GetPlayer(tonumber(source))
end

function Beggin.Inventory.GetInventory(source)
    local p = resolve(source); if not p then return {} end
    return p.getInventory()
end

function Beggin.Inventory.Get(source, item)
    local p = resolve(source); if not p then return 0 end
    return p.getItemCount(item)
end

function Beggin.Inventory.Has(source, item, amount)
    local p = resolve(source); if not p then return false end
    return p.hasItem(item, amount)
end

function Beggin.Inventory.Add(source, item, amount, reason)
    local p = resolve(source); if not p then return false end
    return p.addItem(item, amount, reason)
end

function Beggin.Inventory.Remove(source, item, amount, reason)
    local p = resolve(source); if not p then return false end
    return p.removeItem(item, amount, reason)
end

function Beggin.Inventory.Give(fromSource, toSource, item, amount, reason)
    local a = resolve(fromSource); if not a then return false end
    local b = resolve(toSource); if not b then return false end
    return a.giveItem(b, item, amount, reason)
end

function Beggin.Inventory.Use(source, item, reason)
    local p = resolve(source); if not p then return false end
    return p.useItem(item, reason)
end

function Beggin.Inventory.Clear(source, reason)
    local p = resolve(source); if not p then return false end
    return p.clearInventory(reason)
end

-- ─── Default use handlers ────────────────────────────────────────────
-- Food/drink restore needs. Kept here so the inventory module is
-- self-contained; other resources may override via RegisterUseHandler.

Beggin.Inventory.RegisterUseHandler('bread', function(player)
    Beggin.ModifyNeed(player.source, 'food', 25)
    return true
end)
Beggin.Inventory.RegisterUseHandler('sandwich', function(player)
    Beggin.ModifyNeed(player.source, 'food', 40)
    return true
end)
Beggin.Inventory.RegisterUseHandler('water', function(player)
    Beggin.ModifyNeed(player.source, 'thirst', 30)
    return true
end)
Beggin.Inventory.RegisterUseHandler('soda', function(player)
    Beggin.ModifyNeed(player.source, 'thirst', 20)
    Beggin.ModifyNeed(player.source, 'food', 5)
    return true
end)
Beggin.Inventory.RegisterUseHandler('bandage', function(player)
    local ped = GetPlayerPed(player.source)
    if ped and ped ~= 0 then
        local hp = GetEntityHealth(ped)
        SetEntityHealth(ped, math.min(hp + 25, 200))
    end
    return true
end)

-- ─── NUI action handlers (use / drop / give) ─────────────────────────
-- Per-player soft rate limit: drop calls that arrive faster than this
-- cooldown, so a spammed button click can't thrash the DB or duplicate.

local COOLDOWN_MS = 200
local lastCall = {}

local function onCooldown(src)
    local now = GetGameTimer()
    local prev = lastCall[src]
    if prev and (now - prev) < COOLDOWN_MS then return true end
    lastCall[src] = now
    return false
end

AddEventHandler('playerDropped', function()
    lastCall[source] = nil
end)

RegisterNetEvent('beggin:inventory:use', function(item)
    local src = source
    if onCooldown(src) then return end
    local p = Beggin.GetPlayer(src); if not p then return end
    if type(item) ~= 'string' then return end
    p.useItem(item, 'nui_use')
end)

RegisterNetEvent('beggin:inventory:drop', function(item, amount)
    local src = source
    if onCooldown(src) then return end
    local p = Beggin.GetPlayer(src); if not p then return end
    if type(item) ~= 'string' then return end
    amount = Beggin.Inventory.SanitizeAmount(amount)
    if not amount then return end
    p.removeItem(item, amount, 'drop')
end)

RegisterNetEvent('beggin:inventory:give', function(item, amount, targetId)
    local src = source
    if onCooldown(src) then return end
    local p = Beggin.GetPlayer(src); if not p then return end
    if type(item) ~= 'string' then return end
    targetId = tonumber(targetId); if not targetId or targetId == src then return end
    amount = Beggin.Inventory.SanitizeAmount(amount)
    if not amount then return end
    local target = Beggin.GetPlayer(targetId); if not target then return end

    -- Proximity check: both peds must be within ~5m
    local srcPed = GetPlayerPed(src)
    local tgtPed = GetPlayerPed(targetId)
    if not srcPed or srcPed == 0 or not tgtPed or tgtPed == 0 then return end
    local srcCoords = GetEntityCoords(srcPed)
    local tgtCoords = GetEntityCoords(tgtPed)
    if #(srcCoords - tgtCoords) > 5.0 then
        TriggerClientEvent('beggin:notify', src, {
            title = 'Inventaire', message = 'Joueur trop loin.', type = 'warning',
        })
        return
    end

    p.giveItem(target, item, amount, 'give')
end)

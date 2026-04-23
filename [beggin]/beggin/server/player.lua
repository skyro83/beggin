-- ─── Player Object ───────────────────────────────────────────────────
-- Metatabled player class: one shared method table, per-instance state.
-- All fields are private; access only through getters/setters.

local Player = {}
Player.__index = Player

-- ─── Constructor ─────────────────────────────────────────────────────

function Beggin.CreatePlayer(source, row)
    local accounts = Beggin.Utils.JsonDecodeSafe(row.accounts, Beggin.Utils.DeepCopy(Config.DefaultAccounts))
    local position = Beggin.Utils.JsonDecodeSafe(row.position, Beggin.Utils.DeepCopy(Config.DefaultSpawn))
    local metadata = Beggin.Utils.JsonDecodeSafe(row.metadata, {})
    local appearance = Beggin.Utils.JsonDecodeSafe(row.appearance, Beggin.Utils.DeepCopy(Config.Characters.DefaultAppearance))
    local inventory = Beggin.Utils.JsonDecodeSafe(row.inventory, {})

    local self = setmetatable({
        _source     = source,
        _identifier = row.identifier,
        _charid     = row.id,
        _firstname  = row.firstname or '',
        _lastname   = row.lastname or '',
        _dateofbirth = row.dateofbirth or '2000-01-01',
        _gender     = row.gender or 'male',
        _accounts   = accounts,
        _position   = position,
        _metadata   = metadata,
        _appearance = appearance,
        _inventory  = inventory,
        _dirty      = false,
        _loaded     = true,
    }, Player)

    return self
end

-- ─── Identity getters ────────────────────────────────────────────────

function Player:getSource()      return self._source end
function Player:getIdentifier()  return self._identifier end
function Player:getCharId()      return self._charid end
function Player:getFirstname()   return self._firstname end
function Player:getLastname()    return self._lastname end
function Player:getDateOfBirth() return self._dateofbirth end
function Player:getGender()      return self._gender end

function Player:getName()
    return self._firstname .. ' ' .. self._lastname
end

function Player:getFullName()
    return self._firstname .. ' ' .. self._lastname
end

-- ─── Accounts (money) ────────────────────────────────────────────────
-- All mutations go through these methods. Amounts are coerced to
-- positive integers; negative balances are never allowed.

function Player:getAccounts()
    return Beggin.Utils.DeepCopy(self._accounts)
end

function Player:getMoney(account)
    return self._accounts[account] or 0
end

local function validateAccount(self, account)
    if Beggin.Money.IsAccount(account) then return true end
    if self._accounts[account] ~= nil then return true end
    Beggin.Log('warn', 'unknown account "%s" for char %d', tostring(account), self._charid)
    return false
end

local function pushAccountsToClient(self)
    TriggerClientEvent('beggin:updatePlayerData', self._source, { accounts = self._accounts })
end

local function fireChange(self, account, delta, kind, reason)
    TriggerClientEvent('beggin:money:changed', self._source, {
        account = account,
        delta   = delta,
        balance = self._accounts[account],
        kind    = kind,
        reason  = reason,
    })
    TriggerEvent('beggin:playerMoneyChanged', self._source, account, self._accounts[account], kind, delta, reason)
end

function Player:setMoney(account, amount, reason)
    if not validateAccount(self, account) then return false end
    amount = tonumber(amount) or 0
    if amount < 0 then amount = 0 end
    amount = math.floor(amount)
    local old = self._accounts[account] or 0
    self._accounts[account] = amount
    self._dirty = true
    local delta = amount - old
    Beggin.Money.LogTx(self._charid, account, delta, amount, 'set', reason)
    pushAccountsToClient(self)
    fireChange(self, account, delta, 'set', reason)
    return true
end

function Player:addMoney(account, amount, reason)
    if not validateAccount(self, account) then return false end
    amount = Beggin.Money.SanitizeAmount(amount)
    if not amount then return false end
    self._accounts[account] = (self._accounts[account] or 0) + amount
    self._dirty = true
    Beggin.Money.LogTx(self._charid, account, amount, self._accounts[account], 'add', reason)
    pushAccountsToClient(self)
    fireChange(self, account, amount, 'add', reason)
    return true
end

function Player:removeMoney(account, amount, reason)
    if not validateAccount(self, account) then return false end
    amount = Beggin.Money.SanitizeAmount(amount)
    if not amount then return false end
    local current = self._accounts[account] or 0
    if current < amount then return false end
    self._accounts[account] = current - amount
    self._dirty = true
    Beggin.Money.LogTx(self._charid, account, -amount, self._accounts[account], 'remove', reason)
    pushAccountsToClient(self)
    fireChange(self, account, -amount, 'remove', reason)
    return true
end

--- Move money between two accounts owned by this player (e.g. cash <-> bank).
--- Atomic in-memory: balance check + both sides mutated before any side-effect.
function Player:transferMoney(fromAccount, toAccount, amount, reason)
    if fromAccount == toAccount then return false end
    if not validateAccount(self, fromAccount) then return false end
    if not validateAccount(self, toAccount) then return false end
    amount = Beggin.Money.SanitizeAmount(amount)
    if not amount then return false end
    local current = self._accounts[fromAccount] or 0
    if current < amount then return false end

    self._accounts[fromAccount] = current - amount
    self._accounts[toAccount]   = (self._accounts[toAccount] or 0) + amount
    self._dirty = true

    Beggin.Money.LogTx(self._charid, fromAccount, -amount, self._accounts[fromAccount], 'transfer_out', reason)
    Beggin.Money.LogTx(self._charid, toAccount,    amount, self._accounts[toAccount],   'transfer_in',  reason)

    pushAccountsToClient(self)
    fireChange(self, fromAccount, -amount, 'transfer_out', reason)
    fireChange(self, toAccount,    amount, 'transfer_in',  reason)
    return true
end

--- Pay another Player object from the same account name on both sides.
--- Balance check then mutate-both then log-both; in-memory atomicity only,
--- but it's the source of truth during the session.
function Player:payPlayer(target, account, amount, reason)
    if not target or target == self then return false end
    if not validateAccount(self, account) then return false end
    if not validateAccount(target, account) then return false end
    amount = Beggin.Money.SanitizeAmount(amount)
    if not amount then return false end
    local current = self._accounts[account] or 0
    if current < amount then return false end

    self._accounts[account]       = current - amount
    target._accounts[account]     = (target._accounts[account] or 0) + amount
    self._dirty, target._dirty    = true, true

    Beggin.Money.LogTx(self._charid,   account, -amount, self._accounts[account],   'pay_out', reason, target._charid)
    Beggin.Money.LogTx(target._charid, account,  amount, target._accounts[account], 'pay_in',  reason, self._charid)

    pushAccountsToClient(self)
    pushAccountsToClient(target)
    fireChange(self,   account, -amount, 'pay_out', reason)
    fireChange(target, account,  amount, 'pay_in',  reason)
    return true
end

function Player:getTransactions(limit)
    return Beggin.Money.GetHistory(self._charid, limit)
end

-- ─── Position ────────────────────────────────────────────────────────

function Player:getPosition()
    return Beggin.Utils.DeepCopy(self._position)
end

function Player:setPosition(coords)
    self._position = {
        x = tonumber(coords.x) or 0.0,
        y = tonumber(coords.y) or 0.0,
        z = tonumber(coords.z) or 0.0,
        heading = tonumber(coords.heading or coords.w) or 0.0,
    }
    self._dirty = true
end

-- ─── Metadata ────────────────────────────────────────────────────────

function Player:getMetadata(key)
    if key == nil then return Beggin.Utils.DeepCopy(self._metadata) end
    return self._metadata[key]
end

function Player:setMetadata(key, value)
    if self._metadata[key] == value then return end
    self._metadata[key] = value
    self._dirty = true
    TriggerClientEvent('beggin:updatePlayerData', self._source, { metadata = { [key] = value } })
end

--- Set multiple metadata keys at once (single client sync)
function Player:setMetadataBulk(data)
    local changed = false
    for k, v in pairs(data) do
        if self._metadata[k] ~= v then
            self._metadata[k] = v
            changed = true
        end
    end
    if changed then
        self._dirty = true
        TriggerClientEvent('beggin:updatePlayerData', self._source, { metadata = data })
    end
end

-- ─── Inventory ───────────────────────────────────────────────────────
-- Slotless, count-based: self._inventory = { [itemName] = amount }.
-- All mutations validate item via Config.Items and sanitize amount.

function Player:getInventory()
    return Beggin.Utils.DeepCopy(self._inventory)
end

function Player:getItemCount(item)
    return self._inventory[item] or 0
end

function Player:hasItem(item, amount)
    amount = tonumber(amount) or 1
    return (self._inventory[item] or 0) >= amount
end

function Player:getWeight()
    local total = 0
    for name, count in pairs(self._inventory) do
        local def = Config.Items[name]
        if def and def.weight then total = total + def.weight * count end
    end
    return total
end

function Player:getMaxWeight()
    return Config.Inventory.MaxWeight
end

function Player:canCarry(item, amount)
    local def = Config.Items[item]
    if not def then return false end
    amount = tonumber(amount) or 1
    local extra = (def.weight or 0) * amount
    -- Dot-call: the __index closure pre-binds self, so self:method() would
    -- double-pass and break. Use self.method() style for intra-method calls.
    return (self.getWeight() + extra) <= self.getMaxWeight()
end

local function syncInventory(self)
    TriggerClientEvent('beggin:inventory:sync', self._source, self._inventory)
end

local function fireItemChange(self, item, delta, kind, reason)
    TriggerClientEvent('beggin:inventory:changed', self._source, {
        item    = item,
        delta   = delta,
        balance = self._inventory[item] or 0,
        kind    = kind,
        reason  = reason,
    })
end

function Player:addItem(item, amount, reason)
    if not Beggin.Inventory.IsItem(item) then
        Beggin.Log('warn', 'unknown item "%s" (add) for char %d', tostring(item), self._charid)
        return false
    end
    amount = Beggin.Inventory.SanitizeAmount(amount)
    if not amount then return false end
    if not self.canCarry(item, amount) then return false end

    self._inventory[item] = (self._inventory[item] or 0) + amount
    self._dirty = true
    Beggin.Inventory.LogTx(self._charid, item, amount, self._inventory[item], 'add', reason)
    syncInventory(self)
    fireItemChange(self, item, amount, 'add', reason)
    return true
end

function Player:removeItem(item, amount, reason)
    if not Beggin.Inventory.IsItem(item) then return false end
    amount = Beggin.Inventory.SanitizeAmount(amount)
    if not amount then return false end
    local current = self._inventory[item] or 0
    if current < amount then return false end

    local newAmount = current - amount
    self._inventory[item] = newAmount > 0 and newAmount or nil
    self._dirty = true
    Beggin.Inventory.LogTx(self._charid, item, -amount, newAmount, 'remove', reason)
    syncInventory(self)
    fireItemChange(self, item, -amount, 'remove', reason)
    return true
end

--- Transfer items to another Player. Weight-checked on receiver; fails
--- atomically if receiver can't carry.
function Player:giveItem(target, item, amount, reason)
    if not target or target == self then return false end
    if not Beggin.Inventory.IsItem(item) then return false end
    amount = Beggin.Inventory.SanitizeAmount(amount)
    if not amount then return false end
    local current = self._inventory[item] or 0
    if current < amount then return false end
    if not target.canCarry(item, amount) then return false end

    local newSelf = current - amount
    self._inventory[item]    = newSelf > 0 and newSelf or nil
    target._inventory[item]  = (target._inventory[item] or 0) + amount
    self._dirty, target._dirty = true, true

    Beggin.Inventory.LogTx(self._charid,   item, -amount, newSelf,                         'give_out', reason, target._charid)
    Beggin.Inventory.LogTx(target._charid, item,  amount, target._inventory[item],         'give_in',  reason, self._charid)

    syncInventory(self); syncInventory(target)
    fireItemChange(self,   item, -amount, 'give_out', reason)
    fireItemChange(target, item,  amount, 'give_in',  reason)
    return true
end

--- Use one unit of an item. If a handler is registered and returns false,
--- the item is NOT consumed (e.g. use was blocked by state).
function Player:useItem(item, reason)
    if not Beggin.Inventory.IsItem(item) then return false end
    local def = Config.Items[item]
    if not def.usable then return false end
    if (self._inventory[item] or 0) < 1 then return false end

    local handler = Beggin.Inventory.GetUseHandler(item)
    local consume = true
    if handler then
        local ok, res = pcall(handler, self, item, 1)
        if not ok then
            Beggin.Log('error', 'use handler for "%s" errored: %s', item, tostring(res))
            return false
        end
        consume = res ~= false
    end

    if consume then
        self.removeItem(item, 1, reason or 'use')
    end
    TriggerEvent('beggin:playerUsedItem', self._source, item)
    return true
end

function Player:clearInventory(reason)
    for item, count in pairs(self._inventory) do
        Beggin.Inventory.LogTx(self._charid, item, -count, 0, 'clear', reason)
    end
    self._inventory = {}
    self._dirty = true
    syncInventory(self)
    return true
end

function Player:getItemHistory(limit)
    return Beggin.Inventory.GetHistory(self._charid, limit)
end

-- ─── Appearance ──────────────────────────────────────────────────────

function Player:getAppearance()
    return Beggin.Utils.DeepCopy(self._appearance)
end

function Player:setAppearance(data)
    if type(data) ~= 'table' then return end
    self._appearance = data
    self._dirty = true
end

-- ─── Utilities ───────────────────────────────────────────────────────

function Player:triggerEvent(name, ...)
    TriggerClientEvent(name, self._source, ...)
end

function Player:isDirty()
    return self._dirty
end

function Player:getData()
    return {
        source      = self._source,
        identifier  = self._identifier,
        charid      = self._charid,
        firstname   = self._firstname,
        lastname    = self._lastname,
        dateofbirth = self._dateofbirth,
        gender      = self._gender,
        name        = self:getName(),
        accounts    = Beggin.Utils.DeepCopy(self._accounts),
        position    = Beggin.Utils.DeepCopy(self._position),
        metadata    = Beggin.Utils.DeepCopy(self._metadata),
        appearance  = Beggin.Utils.DeepCopy(self._appearance),
        inventory   = Beggin.Utils.DeepCopy(self._inventory),
    }
end

-- ─── Save ────────────────────────────────────────────────────────────

function Player:save()
    if not self._loaded then return end

    -- Snapshot live position from ped if available
    local ped = GetPlayerPed(self._source)
    if ped and ped ~= 0 then
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        if coords and coords.x ~= 0.0 then
            self._position = {
                x = Beggin.Utils.Round(coords.x, 2),
                y = Beggin.Utils.Round(coords.y, 2),
                z = Beggin.Utils.Round(coords.z, 2),
                heading = Beggin.Utils.Round(heading, 2),
            }
        end
    end

    Beggin.Characters.Save(
        self._charid,
        json.encode(self._accounts),
        json.encode(self._position),
        json.encode(self._metadata),
        json.encode(self._appearance),
        json.encode(self._inventory)
    )

    self._dirty = false
end

-- ─── Backward-compat shims (dot-call style) ─────────────────────────
-- The rest of the codebase calls player.method() (no colon).
-- Metatable __index handles colon calls; this layer handles dot calls
-- by checking if the key is a Player method and returning a bound closure.
-- Closures are cached per instance to avoid re-creation.

local FIELD_ALIASES = {
    source     = '_source',
    identifier = '_identifier',
    charid     = '_charid',
    firstname  = '_firstname',
    lastname   = '_lastname',
    name       = true, -- computed
}

Player.__index = function(self, key)
    -- Direct field lookup (e.g. player.name, player.identifier for commands.lua)
    local alias = FIELD_ALIASES[key]
    if alias then
        if alias == true then return self:getName() end
        return rawget(self, alias)
    end

    -- Method lookup
    local method = rawget(Player, key)
    if type(method) == 'function' then
        -- Return a cached bound closure so player.save() works without colon
        local cache = rawget(self, '_cache')
        if not cache then
            cache = {}
            rawset(self, '_cache', cache)
        end
        if not cache[key] then
            cache[key] = function(...) return method(self, ...) end
        end
        return cache[key]
    end

    return nil
end

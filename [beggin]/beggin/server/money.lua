-- ─── Money module ────────────────────────────────────────────────────
-- Central money API. Every mutation must flow through the Player Object
-- methods (addMoney/removeMoney/setMoney/transferMoney/payPlayer), which
-- delegate logging here. No client-triggered event mutates money.

Beggin.Money = {}

-- ─── Validation helpers ──────────────────────────────────────────────

function Beggin.Money.IsAccount(account)
    return type(account) == 'string' and Config.DefaultAccounts[account] ~= nil
end

--- Coerce arbitrary input into a strictly positive integer amount.
--- Rejects NaN/Inf/<=0. Returns nil on failure.
function Beggin.Money.SanitizeAmount(amount)
    amount = tonumber(amount)
    if not amount or amount ~= amount then return nil end
    if amount <= 0 or amount == math.huge then return nil end
    return math.floor(amount)
end

-- ─── Transaction history ─────────────────────────────────────────────

--- Append a transaction row. Fire-and-forget; the in-memory mutation is
--- already committed by the caller, so a DB hiccup costs a log row, not
--- money state.
function Beggin.Money.LogTx(charid, account, delta, balance, kind, reason, otherCharId)
    if not Config.Money.LogHistory then return end
    Beggin.DB.Execute(
        'INSERT INTO money_transactions (charid, account, delta, balance, kind, reason, other_charid) VALUES (?, ?, ?, ?, ?, ?, ?)',
        {
            charid,
            account,
            math.floor(tonumber(delta) or 0),
            math.floor(tonumber(balance) or 0),
            kind or 'unknown',
            tostring(reason or ''):sub(1, 120),
            otherCharId,
        }
    )
end

function Beggin.Money.GetHistory(charid, limit)
    limit = math.min(tonumber(limit) or Config.Money.HistoryLimit, Config.Money.HistoryMax)
    return Beggin.DB.Query(
        'SELECT account, delta, balance, kind, reason, other_charid, created_at FROM money_transactions WHERE charid = ? ORDER BY id DESC LIMIT ?',
        { charid, limit }
    ) or {}
end

-- ─── High-level server API (by source) ───────────────────────────────
-- Exposed via exports for other resources; resolves source -> Player.

local function resolve(source)
    return Beggin.GetPlayer(tonumber(source))
end

function Beggin.Money.Get(source, account)
    local p = resolve(source); if not p then return 0 end
    return p.getMoney(account)
end

function Beggin.Money.Add(source, account, amount, reason)
    local p = resolve(source); if not p then return false end
    return p.addMoney(account, amount, reason)
end

function Beggin.Money.Remove(source, account, amount, reason)
    local p = resolve(source); if not p then return false end
    return p.removeMoney(account, amount, reason)
end

function Beggin.Money.Set(source, account, amount, reason)
    local p = resolve(source); if not p then return false end
    return p.setMoney(account, amount, reason)
end

function Beggin.Money.Transfer(source, from, to, amount, reason)
    local p = resolve(source); if not p then return false end
    return p.transferMoney(from, to, amount, reason)
end

function Beggin.Money.Pay(fromSource, toSource, account, amount, reason)
    local a = resolve(fromSource); if not a then return false end
    local b = resolve(toSource); if not b then return false end
    return a.payPlayer(b, account, amount, reason)
end

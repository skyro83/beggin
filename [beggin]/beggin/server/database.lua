Beggin.DB = { Ready = false }

<<<<<<< HEAD
-- ─── Schemas & Migrations ────────────────────────────────────────────

=======
>>>>>>> 56c38019c40a8813a66fc58a17af3a18589f39e9
local SCHEMAS = {
[[
CREATE TABLE IF NOT EXISTS `users` (
  `identifier` VARCHAR(60) NOT NULL,
  `name`       VARCHAR(60) NOT NULL DEFAULT '',
  `accounts`   LONGTEXT    NOT NULL,
  `position`   LONGTEXT    NOT NULL,
  `metadata`   LONGTEXT    NOT NULL,
  `last_seen`  TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_at` TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]],
[[
CREATE TABLE IF NOT EXISTS `bans` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(60)  NOT NULL,
  `name`       VARCHAR(60)  NOT NULL DEFAULT '',
  `reason`     VARCHAR(255) NOT NULL DEFAULT '',
  `banned_by`  VARCHAR(60)  NOT NULL DEFAULT '',
  `expires_at` TIMESTAMP    NULL DEFAULT NULL,
  `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]],
[[
CREATE TABLE IF NOT EXISTS `admin_logs` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `admin`      VARCHAR(60)  NOT NULL DEFAULT '',
  `action`     VARCHAR(60)  NOT NULL DEFAULT '',
  `target`     VARCHAR(60)  NOT NULL DEFAULT '',
  `details`    LONGTEXT     NULL,
  `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_admin` (`admin`),
  KEY `idx_action` (`action`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]],
<<<<<<< HEAD
[[
CREATE TABLE IF NOT EXISTS `item_transactions` (
  `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `charid`       INT UNSIGNED NOT NULL,
  `item`         VARCHAR(60)  NOT NULL,
  `delta`        INT          NOT NULL,
  `balance`      INT          NOT NULL,
  `kind`         VARCHAR(20)  NOT NULL,
  `reason`       VARCHAR(120) NOT NULL DEFAULT '',
  `other_charid` INT UNSIGNED NULL,
  `created_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_charid_id` (`charid`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]],
[[
CREATE TABLE IF NOT EXISTS `money_transactions` (
  `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `charid`       INT UNSIGNED NOT NULL,
  `account`      VARCHAR(20)  NOT NULL,
  `delta`        BIGINT       NOT NULL,
  `balance`      BIGINT       NOT NULL,
  `kind`         VARCHAR(20)  NOT NULL,
  `reason`       VARCHAR(120) NOT NULL DEFAULT '',
  `other_charid` INT UNSIGNED NULL,
  `created_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_charid_id` (`charid`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]],
[[
CREATE TABLE IF NOT EXISTS `characters` (
  `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `identifier`  VARCHAR(60)  NOT NULL,
  `firstname`   VARCHAR(50)  NOT NULL DEFAULT '',
  `lastname`    VARCHAR(50)  NOT NULL DEFAULT '',
  `dateofbirth` VARCHAR(10)  NOT NULL DEFAULT '2000-01-01',
  `gender`      ENUM('male','female') NOT NULL DEFAULT 'male',
  `accounts`    LONGTEXT     NOT NULL,
  `position`    LONGTEXT     NOT NULL,
  `metadata`    LONGTEXT     NOT NULL,
  `appearance`  LONGTEXT     NOT NULL DEFAULT '{}',
  `inventory`   LONGTEXT     NOT NULL DEFAULT '{}',
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_played` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]],
=======
>>>>>>> 56c38019c40a8813a66fc58a17af3a18589f39e9
}

local MIGRATIONS = {
    "ALTER TABLE `characters` ADD COLUMN IF NOT EXISTS `appearance` LONGTEXT NOT NULL DEFAULT '{}' AFTER `metadata`",
    "ALTER TABLE `characters` ADD COLUMN IF NOT EXISTS `inventory` LONGTEXT NOT NULL DEFAULT '{}' AFTER `appearance`",
}

-- ─── Internal helpers ────────────────────────────────────────────────

local readyPromise = promise.new()

local function ensureReady()
    if Beggin.DB.Ready then return end
    Citizen.Await(readyPromise)
end

local function safeCall(method, sql, params)
    ensureReady()
    local ok, result = pcall(method, sql, params or {})
    if not ok then
        Beggin.Log('error', 'DB query failed: %s | SQL: %s', tostring(result), sql)
        return nil
    end
    return result
end

-- ─── Public API ──────────────────────────────────────────────────────

--- Fetch multiple rows (SELECT)
---@param sql string
---@param params? table
---@return table|nil rows
function Beggin.DB.Query(sql, params)
    return safeCall(MySQL.query.await, sql, params)
end

--- Fetch a single row (SELECT ... LIMIT 1)
---@param sql string
---@param params? table
---@return table|nil row
function Beggin.DB.Single(sql, params)
    return safeCall(MySQL.single.await, sql, params)
end

--- Fetch a single scalar value (SELECT COUNT(*) ...)
---@param sql string
---@param params? table
---@return any|nil value
function Beggin.DB.Scalar(sql, params)
    return safeCall(MySQL.scalar.await, sql, params)
end

--- Execute an UPDATE / DELETE and return affected row count
---@param sql string
---@param params? table
---@return number|nil affectedRows
function Beggin.DB.Execute(sql, params)
    return safeCall(MySQL.update.await, sql, params)
end

--- Execute an INSERT and return the last insert id
---@param sql string
---@param params? table
---@return number|nil insertId
function Beggin.DB.Insert(sql, params)
    return safeCall(MySQL.insert.await, sql, params)
end

--- Run multiple queries inside a transaction.
--- The callback receives `query` functions bound to the transaction.
--- Return true to COMMIT, false/nil or throw to ROLLBACK.
---@param cb fun(): boolean?
---@return boolean success
function Beggin.DB.Transaction(cb)
    ensureReady()
    local ok, err = pcall(function()
        MySQL.query.await('START TRANSACTION')
        local result = cb()
        if result == false then
            MySQL.query.await('ROLLBACK')
        else
            MySQL.query.await('COMMIT')
        end
    end)
    if not ok then
        pcall(MySQL.query.await, 'ROLLBACK')
        Beggin.Log('error', 'DB transaction failed (rolled back): %s', tostring(err))
        return false
    end
    return true
end

--- Wait until the database is ready. Use this instead of manual polling loops.
function Beggin.DB.AwaitReady()
    ensureReady()
end

-- ─── Bootstrap ───────────────────────────────────────────────────────

CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do
        Wait(100)
    end
    local ok, err = pcall(function()
        for _, schema in ipairs(SCHEMAS) do
            MySQL.query.await(schema)
        end
<<<<<<< HEAD
        for _, migration in ipairs(MIGRATIONS) do
            pcall(MySQL.query.await, migration)
        end
=======
>>>>>>> 56c38019c40a8813a66fc58a17af3a18589f39e9
    end)
    if not ok then
        Beggin.Log('error', 'failed to ensure schema: %s', tostring(err))
        return
    end
    Beggin.DB.Ready = true
    readyPromise:resolve()
    Beggin.Log('info', 'database ready')
end)

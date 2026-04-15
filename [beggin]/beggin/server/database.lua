Beggin.DB = { Ready = false }

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
}

function Beggin.DB.Query(sql, params)
    return MySQL.query.await(sql, params)
end

function Beggin.DB.Single(sql, params)
    return MySQL.single.await(sql, params)
end

function Beggin.DB.Scalar(sql, params)
    return MySQL.scalar.await(sql, params)
end

function Beggin.DB.Execute(sql, params)
    return MySQL.update.await(sql, params)
end

function Beggin.DB.Insert(sql, params)
    return MySQL.insert.await(sql, params)
end

CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do
        Wait(100)
    end
    local ok, err = pcall(function()
        for _, schema in ipairs(SCHEMAS) do
            MySQL.query.await(schema)
        end
    end)
    if not ok then
        Beggin.Log('error', 'failed to ensure schema: %s', tostring(err))
        return
    end
    Beggin.DB.Ready = true
    Beggin.Log('info', 'database ready')
end)

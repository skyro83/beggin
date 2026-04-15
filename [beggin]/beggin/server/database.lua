Beggin.DB = { Ready = false }

local SCHEMA = [[
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
]]

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
        MySQL.query.await(SCHEMA)
    end)
    if not ok then
        Beggin.Log('error', 'failed to ensure schema: %s', tostring(err))
        return
    end
    Beggin.DB.Ready = true
    Beggin.Log('info', 'database ready')
end)

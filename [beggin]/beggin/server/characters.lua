Beggin.Characters = {}

function Beggin.Characters.GetByIdentifier(identifier)
    return Beggin.DB.Query('SELECT * FROM characters WHERE identifier = ? ORDER BY last_played DESC', { identifier }) or {}
end

function Beggin.Characters.GetById(charId)
    return Beggin.DB.Single('SELECT * FROM characters WHERE id = ?', { charId })
end

local function defaultInventory()
    local inv = {}
    for _, entry in ipairs(Config.Inventory.StartingItems or {}) do
        if entry.name and Config.Items[entry.name] and entry.amount then
            inv[entry.name] = (inv[entry.name] or 0) + math.floor(entry.amount)
        end
    end
    return inv
end

function Beggin.Characters.Create(identifier, data)
    return Beggin.DB.Insert(
        'INSERT INTO characters (identifier, firstname, lastname, dateofbirth, gender, accounts, position, metadata, appearance, inventory) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            identifier,
            data.firstname,
            data.lastname,
            data.dateofbirth,
            data.gender,
            data.accounts or json.encode(Config.DefaultAccounts),
            data.position or json.encode(Config.DefaultSpawn),
            data.metadata or json.encode({}),
            data.appearance or json.encode(Config.Characters.DefaultAppearance),
            data.inventory or json.encode(defaultInventory()),
        }
    )
end

function Beggin.Characters.Delete(charId, identifier)
    return Beggin.DB.Execute('DELETE FROM characters WHERE id = ? AND identifier = ?', { charId, identifier })
end

function Beggin.Characters.Save(charId, accounts, position, metadata, appearance, inventory)
    return Beggin.DB.Execute(
        'UPDATE characters SET accounts = ?, position = ?, metadata = ?, appearance = ?, inventory = ? WHERE id = ?',
        { accounts, position, metadata, appearance, inventory, charId }
    )
end

function Beggin.Characters.Count(identifier)
    return Beggin.DB.Scalar('SELECT COUNT(*) FROM characters WHERE identifier = ?', { identifier }) or 0
end

function Beggin.Characters.UpdateLastPlayed(charId)
    Beggin.DB.Execute('UPDATE characters SET last_played = NOW() WHERE id = ?', { charId })
end

function Beggin.Characters.ValidateInput(data)
    if type(data.firstname) ~= 'string' then return false, 'Prenom invalide' end
    if type(data.lastname) ~= 'string' then return false, 'Nom invalide' end

    local fn = data.firstname:gsub('%s+', '')
    local ln = data.lastname:gsub('%s+', '')

    if #fn < Config.Characters.MinNameLen or #fn > Config.Characters.MaxNameLen then
        return false, ('Le prenom doit contenir entre %d et %d caracteres'):format(Config.Characters.MinNameLen, Config.Characters.MaxNameLen)
    end
    if #ln < Config.Characters.MinNameLen or #ln > Config.Characters.MaxNameLen then
        return false, ('Le nom doit contenir entre %d et %d caracteres'):format(Config.Characters.MinNameLen, Config.Characters.MaxNameLen)
    end

    if not fn:match('^[A-Za-z%u00C0-%u00FF%-]+$') then
        return false, 'Le prenom contient des caracteres invalides'
    end
    if not ln:match('^[A-Za-z%u00C0-%u00FF%-]+$') then
        return false, 'Le nom contient des caracteres invalides'
    end

    if data.gender ~= 'male' and data.gender ~= 'female' then
        return false, 'Genre invalide'
    end

    if type(data.dateofbirth) ~= 'string' or not data.dateofbirth:match('^%d%d%d%d%-%d%d%-%d%d$') then
        return false, 'Date de naissance invalide (format YYYY-MM-DD)'
    end

    local year, month, day = data.dateofbirth:match('^(%d+)-(%d+)-(%d+)$')
    year, month, day = tonumber(year), tonumber(month), tonumber(day)

    if month < 1 or month > 12 or day < 1 or day > 31 then
        return false, 'Date de naissance invalide'
    end

    local currentYear = tonumber(os.date('%Y'))
    local age = currentYear - year
    if age < Config.Characters.MinAge or age > Config.Characters.MaxAge then
        return false, ('L\'age doit etre entre %d et %d ans'):format(Config.Characters.MinAge, Config.Characters.MaxAge)
    end

    return true, nil
end

-- Migration: if characters table is empty but users have data, migrate them
CreateThread(function()
    Beggin.DB.AwaitReady()

    local charCount = Beggin.DB.Scalar('SELECT COUNT(*) FROM characters')
    if charCount and charCount > 0 then return end

    local users = Beggin.DB.Query('SELECT * FROM users')
    if not users or #users == 0 then return end

    Beggin.Log('info', 'migrating %d existing users to characters table...', #users)
    for _, user in ipairs(users) do
        Beggin.Characters.Create(user.identifier, {
            firstname = 'Personnage',
            lastname = '#1',
            dateofbirth = '2000-01-01',
            gender = 'male',
            accounts = user.accounts,
            position = user.position,
            metadata = user.metadata,
        })
    end
    Beggin.Log('info', 'migration complete')
end)

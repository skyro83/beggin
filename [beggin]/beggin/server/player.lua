function Beggin.CreatePlayer(source, row)
    local self = {}

    self.source = source
    self.identifier = row.identifier
    self.name = row.name or GetPlayerName(source) or ''
    self.accounts = Beggin.Utils.JsonDecodeSafe(row.accounts, Beggin.Utils.DeepCopy(Config.DefaultAccounts))
    self.position = Beggin.Utils.JsonDecodeSafe(row.position, Beggin.Utils.DeepCopy(Config.DefaultSpawn))
    self.metadata = Beggin.Utils.JsonDecodeSafe(row.metadata, {})
    self.loaded = true

    function self.getSource() return self.source end
    function self.getIdentifier() return self.identifier end
    function self.getName() return self.name end

    function self.getAccounts()
        return Beggin.Utils.DeepCopy(self.accounts)
    end

    function self.getMoney(account)
        return self.accounts[account] or 0
    end

    local function syncAccounts(reason, account)
        TriggerClientEvent('beggin:updatePlayerData', self.source, { accounts = self.accounts })
        TriggerEvent('beggin:playerMoneyChanged', self.source, account, self.accounts[account], reason)
    end

    function self.setMoney(account, amount)
        amount = tonumber(amount) or 0
        if amount < 0 then amount = 0 end
        self.accounts[account] = Beggin.Utils.Round(amount, 2)
        syncAccounts('set', account)
    end

    function self.addMoney(account, amount)
        amount = tonumber(amount) or 0
        if amount <= 0 then return end
        self.accounts[account] = Beggin.Utils.Round((self.accounts[account] or 0) + amount, 2)
        syncAccounts('add', account)
    end

    function self.removeMoney(account, amount)
        amount = tonumber(amount) or 0
        if amount <= 0 then return false end
        local current = self.accounts[account] or 0
        if current < amount then return false end
        self.accounts[account] = Beggin.Utils.Round(current - amount, 2)
        syncAccounts('remove', account)
        return true
    end

    function self.setPosition(coords)
        self.position = {
            x = coords.x,
            y = coords.y,
            z = coords.z,
            heading = coords.heading or coords.w or 0.0,
        }
    end

    function self.getPosition()
        return Beggin.Utils.DeepCopy(self.position)
    end

    function self.setMetadata(k, v)
        self.metadata[k] = v
        TriggerClientEvent('beggin:updatePlayerData', self.source, { metadata = { [k] = v } })
    end

    function self.getMetadata(k)
        if k == nil then return Beggin.Utils.DeepCopy(self.metadata) end
        return self.metadata[k]
    end

    function self.triggerEvent(name, ...)
        TriggerClientEvent(name, self.source, ...)
    end

    function self.getData()
        return {
            source = self.source,
            identifier = self.identifier,
            name = self.name,
            accounts = Beggin.Utils.DeepCopy(self.accounts),
            position = Beggin.Utils.DeepCopy(self.position),
            metadata = Beggin.Utils.DeepCopy(self.metadata),
        }
    end

    function self.save()
        local ped = GetPlayerPed(self.source)
        if ped and ped ~= 0 then
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            if coords and coords.x ~= 0.0 then
                self.position = {
                    x = Beggin.Utils.Round(coords.x, 2),
                    y = Beggin.Utils.Round(coords.y, 2),
                    z = Beggin.Utils.Round(coords.z, 2),
                    heading = Beggin.Utils.Round(heading, 2),
                }
            end
            local name = GetPlayerName(self.source)
            if name then self.name = name end
        end

        Beggin.DB.Execute(
            'UPDATE users SET name = ?, accounts = ?, position = ?, metadata = ? WHERE identifier = ?',
            {
                self.name,
                json.encode(self.accounts),
                json.encode(self.position),
                json.encode(self.metadata),
                self.identifier,
            }
        )
    end

    return self
end

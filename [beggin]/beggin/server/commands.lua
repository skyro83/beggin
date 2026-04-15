RegisterCommand('bwho', function(source)
    local lines = { '^2[beggin]^7 loaded players:' }
    for src, player in pairs(Beggin.Players) do
        lines[#lines + 1] = ('  [%d] %s  (%s)  cash=%s bank=%s'):format(
            src, player.name, player.identifier,
            tostring(player.getMoney('cash')), tostring(player.getMoney('bank'))
        )
    end
    if #lines == 1 then lines[#lines + 1] = '  (none)' end
    if source == 0 then
        for _, l in ipairs(lines) do print(l) end
    else
        for _, l in ipairs(lines) do
            TriggerClientEvent('chat:addMessage', source, { args = { l } })
        end
    end
end, true)

RegisterCommand('bsaveall', function(source)
    Beggin.SaveAll()
    local msg = '^2[beggin]^7 saveAll done.'
    if source == 0 then print(msg) else
        TriggerClientEvent('chat:addMessage', source, { args = { msg } })
    end
end, true)

RegisterCommand('bmoney', function(source, args)
    local target = tonumber(args[1])
    local account = args[2]
    local amount = tonumber(args[3])
    if not target or not account or not amount then
        local msg = '^1[beggin]^7 usage: /bmoney <id> <account> <amount>'
        if source == 0 then print(msg) else
            TriggerClientEvent('chat:addMessage', source, { args = { msg } })
        end
        return
    end
    local player = Beggin.GetPlayer(target)
    if not player then
        local msg = '^1[beggin]^7 player not found.'
        if source == 0 then print(msg) else
            TriggerClientEvent('chat:addMessage', source, { args = { msg } })
        end
        return
    end
    player.setMoney(account, amount)
    local msg = ('^2[beggin]^7 set %s.%s = %s'):format(player.name, account, amount)
    if source == 0 then print(msg) else
        TriggerClientEvent('chat:addMessage', source, { args = { msg } })
    end
end, true)

RegisterCommand('testnotif', function(source, args)
    local ntype = args[1] or 'info'
    TriggerClientEvent('beggin:notify', source, {
        title = 'Test ' .. ntype,
        message = 'Ceci est une notification de test (' .. ntype .. ').',
        type = ntype,
        duration = 4000,
    })
end, false)

RegisterCommand('setneed', function(source, args)
    local target = tonumber(args[1])
    local key = args[2]
    local value = tonumber(args[3])
    if not target or not key or not value then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1[beggin]^7 usage: /setneed <id> <food|thirst> <0-100>' } })
        return
    end
    Beggin.SetNeed(target, key, value)
end, true)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, ace in ipairs({
        'add_ace group.admin beggin.admin allow',
        'add_ace beggin.admin command.bwho allow',
        'add_ace beggin.admin command.bsaveall allow',
        'add_ace beggin.admin command.bmoney allow',
        'add_ace beggin.admin command.setneed allow',
    }) do
        ExecuteCommand(ace)
    end
end)

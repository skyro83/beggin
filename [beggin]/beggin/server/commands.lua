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

local function reply(source, msg)
    if source == 0 then print(msg) else
        TriggerClientEvent('chat:addMessage', source, { args = { msg } })
    end
end

local function adminReason(source)
    if source == 0 then return 'admin:console' end
    return 'admin:' .. tostring(source)
end

RegisterCommand('bmoney', function(source, args)
    local target = tonumber(args[1])
    local account = args[2]
    local amount = tonumber(args[3])
    local op = args[4] or 'set'
    if not target or not account or not amount then
        reply(source, '^1[beggin]^7 usage: /bmoney <id> <account> <amount> [set|add|remove]')
        return
    end
    local player = Beggin.GetPlayer(target)
    if not player then reply(source, '^1[beggin]^7 player not found.'); return end

    local reason = adminReason(source)
    local ok
    if op == 'add' then
        ok = player.addMoney(account, amount, reason)
    elseif op == 'remove' then
        ok = player.removeMoney(account, amount, reason)
    else
        ok = player.setMoney(account, amount, reason)
    end
    if not ok then reply(source, '^1[beggin]^7 money op rejected.'); return end
    reply(source, ('^2[beggin]^7 %s %s.%s %s (new=%s)'):format(op, player.name, account, amount, player.getMoney(account)))
end, true)

RegisterCommand('bbalance', function(source, args)
    local target = tonumber(args[1]) or source
    local player = Beggin.GetPlayer(target)
    if not player then reply(source, '^1[beggin]^7 player not found.'); return end
    local accounts = player.getAccounts()
    local parts = {}
    for acc, bal in pairs(accounts) do parts[#parts + 1] = ('%s=%s'):format(acc, bal) end
    reply(source, ('^2[beggin]^7 %s %s'):format(player.name, table.concat(parts, ' ')))
end, true)

RegisterCommand('bpay', function(source, args)
    if source == 0 then reply(source, '^1[beggin]^7 /bpay is player-only.'); return end
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    if not targetId or not amount then
        reply(source, '^1[beggin]^7 usage: /bpay <id> <amount>')
        return
    end
    local from = Beggin.GetPlayer(source)
    local to = Beggin.GetPlayer(targetId)
    if not from or not to then reply(source, '^1[beggin]^7 joueur introuvable.'); return end
    if from == to then reply(source, '^1[beggin]^7 vous ne pouvez pas vous payer vous-meme.'); return end

    local ok = from.payPlayer(to, 'cash', amount, 'player_pay')
    if not ok then reply(source, '^1[beggin]^7 paiement refuse (solde insuffisant ?).'); return end

    TriggerClientEvent('beggin:notify', source, {
        title = 'Paiement', message = ('Envoye $%d a %s'):format(amount, to.name), type = 'success',
    })
    TriggerClientEvent('beggin:notify', to.source, {
        title = 'Paiement', message = ('Recu $%d de %s'):format(amount, from.name), type = 'success',
    })
end, false)

RegisterCommand('bhistory', function(source, args)
    local limit = tonumber(args[1]) or 10
    local target = tonumber(args[2]) or source
    local player = Beggin.GetPlayer(target)
    if not player then reply(source, '^1[beggin]^7 player not found.'); return end
    local rows = player.getTransactions(limit)
    reply(source, ('^2[beggin]^7 %d derniere(s) tx de %s:'):format(#rows, player.name))
    for _, r in ipairs(rows) do
        local delta = tonumber(r.delta) or 0
        reply(source, ('  [%s] %s %s%s -> %s (%s)'):format(
            tostring(r.created_at), r.account, (delta >= 0 and '+' or ''),
            tostring(delta), tostring(r.balance), r.reason or ''))
    end
end, true)

RegisterCommand('bgiveitem', function(source, args)
    local target = tonumber(args[1])
    local item = args[2]
    local amount = tonumber(args[3]) or 1
    if not target or not item then
        reply(source, '^1[beggin]^7 usage: /bgiveitem <id> <item> [amount]')
        return
    end
    local player = Beggin.GetPlayer(target)
    if not player then reply(source, '^1[beggin]^7 player not found.'); return end
    if not Beggin.Inventory.IsItem(item) then reply(source, '^1[beggin]^7 item inconnu.'); return end
    local ok = player.addItem(item, amount, adminReason(source))
    if not ok then reply(source, '^1[beggin]^7 refuse (poids ou item invalide).'); return end
    reply(source, ('^2[beggin]^7 +%d %s -> %s (total=%d)'):format(amount, item, player.name, player.getItemCount(item)))
end, true)

RegisterCommand('btakeitem', function(source, args)
    local target = tonumber(args[1])
    local item = args[2]
    local amount = tonumber(args[3]) or 1
    if not target or not item then
        reply(source, '^1[beggin]^7 usage: /btakeitem <id> <item> [amount]')
        return
    end
    local player = Beggin.GetPlayer(target)
    if not player then reply(source, '^1[beggin]^7 player not found.'); return end
    local ok = player.removeItem(item, amount, adminReason(source))
    if not ok then reply(source, '^1[beggin]^7 refuse (stock insuffisant ?).'); return end
    reply(source, ('^2[beggin]^7 -%d %s -> %s (reste=%d)'):format(amount, item, player.name, player.getItemCount(item)))
end, true)

RegisterCommand('binv', function(source, args)
    local target = tonumber(args[1]) or source
    local player = Beggin.GetPlayer(target)
    if not player then reply(source, '^1[beggin]^7 player not found.'); return end
    local inv = player.getInventory()
    local parts = {}
    for name, count in pairs(inv) do parts[#parts + 1] = ('%s x%d'):format(name, count) end
    if #parts == 0 then parts[1] = '(vide)' end
    reply(source, ('^2[beggin]^7 inv %s [%d/%dg]: %s'):format(
        player.name, player.getWeight(), player.getMaxWeight(), table.concat(parts, ', ')))
end, true)

RegisterCommand('bitems', function(source)
    reply(source, '^2[beggin]^7 items registres:')
    for name, def in pairs(Config.Items) do
        reply(source, ('  %s — %s (%dg%s)'):format(name, def.label, def.weight or 0, def.usable and ', usable' or ''))
    end
end, true)

RegisterCommand('bihistory', function(source, args)
    local limit = tonumber(args[1]) or 10
    local target = tonumber(args[2]) or source
    local player = Beggin.GetPlayer(target)
    if not player then reply(source, '^1[beggin]^7 player not found.'); return end
    local rows = player.getItemHistory(limit)
    reply(source, ('^2[beggin]^7 %d derniere(s) tx item de %s:'):format(#rows, player.name))
    for _, r in ipairs(rows) do
        local delta = tonumber(r.delta) or 0
        reply(source, ('  [%s] %s %s%s -> %s (%s)'):format(
            tostring(r.created_at), r.item, (delta >= 0 and '+' or ''),
            tostring(delta), tostring(r.balance), r.reason or ''))
    end
end, true)

RegisterCommand('buse', function(source, args)
    if source == 0 then reply(source, '^1[beggin]^7 /buse is player-only.'); return end
    local item = args[1]
    if not item then reply(source, '^1[beggin]^7 usage: /buse <item>'); return end
    local player = Beggin.GetPlayer(source)
    if not player then return end
    local ok = player.useItem(item, 'cmd')
    if not ok then reply(source, '^1[beggin]^7 impossible d\'utiliser cet item.') end
end, false)

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
        'add_ace beggin.admin command.bbalance allow',
        'add_ace beggin.admin command.bhistory allow',
        'add_ace beggin.admin command.bgiveitem allow',
        'add_ace beggin.admin command.btakeitem allow',
        'add_ace beggin.admin command.binv allow',
        'add_ace beggin.admin command.bitems allow',
        'add_ace beggin.admin command.bihistory allow',
        'add_ace beggin.admin command.setneed allow',
    }) do
        ExecuteCommand(ace)
    end
end)

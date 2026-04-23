exports('GetPlayer', function(source)
    return Beggin.GetPlayer(source)
end)

exports('GetPlayerFromIdentifier', function(identifier)
    return Beggin.GetPlayerFromIdentifier(identifier)
end)

exports('GetPlayers', function()
    return Beggin.GetPlayers()
end)

exports('GetCoreObject', function()
    return Beggin
end)

-- ─── Money ───────────────────────────────────────────────────────────

exports('GetMoney',      function(src, acc)              return Beggin.Money.Get(src, acc) end)
exports('AddMoney',      function(src, acc, amt, reason) return Beggin.Money.Add(src, acc, amt, reason) end)
exports('RemoveMoney',   function(src, acc, amt, reason) return Beggin.Money.Remove(src, acc, amt, reason) end)
exports('SetMoney',      function(src, acc, amt, reason) return Beggin.Money.Set(src, acc, amt, reason) end)
exports('TransferMoney', function(src, from, to, amt, reason) return Beggin.Money.Transfer(src, from, to, amt, reason) end)
exports('PayPlayer',     function(fromSrc, toSrc, acc, amt, reason) return Beggin.Money.Pay(fromSrc, toSrc, acc, amt, reason) end)
exports('GetMoneyHistory', function(src, limit)
    local p = Beggin.GetPlayer(tonumber(src))
    if not p then return {} end
    return p.getTransactions(limit)
end)

-- ─── Inventory ───────────────────────────────────────────────────────

exports('GetInventory',    function(src)                     return Beggin.Inventory.GetInventory(src) end)
exports('GetItem',         function(src, item)               return Beggin.Inventory.Get(src, item) end)
exports('HasItem',         function(src, item, amt)          return Beggin.Inventory.Has(src, item, amt) end)
exports('AddItem',         function(src, item, amt, reason)  return Beggin.Inventory.Add(src, item, amt, reason) end)
exports('RemoveItem',      function(src, item, amt, reason)  return Beggin.Inventory.Remove(src, item, amt, reason) end)
exports('GiveItem',        function(fromSrc, toSrc, item, amt, reason) return Beggin.Inventory.Give(fromSrc, toSrc, item, amt, reason) end)
exports('UseItem',         function(src, item, reason)       return Beggin.Inventory.Use(src, item, reason) end)
exports('ClearInventory',  function(src, reason)             return Beggin.Inventory.Clear(src, reason) end)
exports('RegisterUseHandler', function(item, fn)             return Beggin.Inventory.RegisterUseHandler(item, fn) end)
exports('GetInventoryHistory', function(src, limit)
    local p = Beggin.GetPlayer(tonumber(src))
    if not p then return {} end
    return p.getItemHistory(limit)
end)
exports('GetItemDef', function(name) return Beggin.Inventory.GetItem(name) end)

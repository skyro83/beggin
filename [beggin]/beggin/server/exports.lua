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

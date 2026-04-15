local function clamp(v)
    if v < 0 then return 0 end
    if v > 100 then return 100 end
    return v
end

local function ensureNeeds(player)
    local md = player.getMetadata()
    local changed = false
    if md.food == nil then player.setMetadata('food', 100); changed = true end
    if md.thirst == nil then player.setMetadata('thirst', 100); changed = true end
    return changed
end

function Beggin.GetNeed(source, key)
    local player = Beggin.GetPlayer(source)
    if not player then return nil end
    local v = player.getMetadata(key)
    return tonumber(v) or 100
end

function Beggin.SetNeed(source, key, value)
    local player = Beggin.GetPlayer(source)
    if not player then return end
    player.setMetadata(key, clamp(tonumber(value) or 0))
end

function Beggin.ModifyNeed(source, key, delta)
    local player = Beggin.GetPlayer(source)
    if not player then return end
    local cur = tonumber(player.getMetadata(key)) or 100
    player.setMetadata(key, clamp(cur + (tonumber(delta) or 0)))
end

AddEventHandler('beggin:playerLoaded', function(source, player)
    ensureNeeds(player)
end)

CreateThread(function()
    while not Beggin.Ready do Wait(100) end
    while true do
        Wait(Config.Needs.DrainInterval)
        for src, player in pairs(Beggin.Players) do
            local food = tonumber(player.getMetadata('food')) or 100
            local thirst = tonumber(player.getMetadata('thirst')) or 100
            food = clamp(food - Config.Needs.FoodDrain)
            thirst = clamp(thirst - Config.Needs.ThirstDrain)
            player.setMetadata('food', food)
            player.setMetadata('thirst', thirst)

            if food <= 0 or thirst <= 0 then
                local ped = GetPlayerPed(src)
                if ped and ped ~= 0 then
                    local hp = GetEntityHealth(ped)
                    if hp > 101 then
                        SetEntityHealth(ped, hp - Config.Needs.DamageWhenEmpty)
                    end
                end
            end
        end
    end
end)

exports('Notify', function(source, payload)
    TriggerClientEvent('beggin:notify', source, payload)
end)

exports('NotifyAll', function(payload)
    TriggerClientEvent('beggin:notify', -1, payload)
end)

exports('GetNeed', function(source, key) return Beggin.GetNeed(source, key) end)
exports('SetNeed', function(source, key, value) Beggin.SetNeed(source, key, value) end)
exports('ModifyNeed', function(source, key, delta) Beggin.ModifyNeed(source, key, delta) end)

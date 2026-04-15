Beggin.Ready = false

CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do
        Wait(100)
    end
    while not Beggin.DB or not Beggin.DB.Ready do
        Wait(50)
    end
    Beggin.Ready = true
    Beggin.Log('info', 'beggin v%s ready', Beggin.Version)
end)

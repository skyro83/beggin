Beggin.Ready = false

CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do
        Wait(100)
    end
    Beggin.DB.AwaitReady()
    Beggin.Ready = true
    Beggin.Log('info', 'beggin v%s ready', Beggin.Version)
end)

Beggin = {
    Version = '0.1.0',
    Players = {},
    Callbacks = {},
}

local levelTag = {
    info = '^2[beggin]^7',
    warn = '^3[beggin]^7',
    error = '^1[beggin]^7',
    debug = '^5[beggin]^7',
}

function Beggin.Log(level, msg, ...)
    if level == 'debug' and not Config.Debug then return end
    local tag = levelTag[level] or levelTag.info
    local body = select('#', ...) > 0 and msg:format(...) or msg
    print(('%s %s'):format(tag, body))
end

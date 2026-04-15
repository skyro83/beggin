Beggin.Utils = {}

function Beggin.Utils.Round(n, d)
    d = d or 0
    local m = 10 ^ d
    return math.floor(n * m + 0.5) / m
end

function Beggin.Utils.DeepCopy(t)
    if type(t) ~= 'table' then return t end
    local out = {}
    for k, v in pairs(t) do
        out[k] = Beggin.Utils.DeepCopy(v)
    end
    return out
end

function Beggin.Utils.JsonDecodeSafe(s, fallback)
    if not s or s == '' then return fallback end
    local ok, decoded = pcall(json.decode, s)
    if not ok or decoded == nil then return fallback end
    return decoded
end

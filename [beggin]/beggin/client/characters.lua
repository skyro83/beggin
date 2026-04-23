local InCharacterScreen = false
local CreationCam = nil
local CreationActive = false

-- ============================================================
-- APPEARANCE APPLY (reusable for creation + loading)
-- ============================================================
function Beggin.ApplyAppearance(ped, app)
    if not app then return end

    -- Heritage
    local h = app.heritage
    if h then
        SetPedHeadBlendData(ped, h.mother or 0, h.father or 0, 0, h.skinMix or 0.5, h.shapeMix or 0.5, 0.0, false)
    end

    -- Face features (0-19)
    local features = app.features
    if features then
        for i = 0, 19 do
            SetPedFaceFeature(ped, i, tonumber(features[i + 1]) or 0.0)
        end
    end

    -- Hair
    local hair = app.hair
    if hair then
        SetPedComponentVariation(ped, 2, hair.style or 0, 0, 2)
        SetPedHairColor(ped, hair.color or 0, hair.highlight or 0)
    end

    -- Eyebrows (overlay 2)
    local eb = app.eyebrows
    if eb and eb.style and eb.style >= 0 then
        SetPedHeadOverlay(ped, 2, eb.style, eb.opacity or 1.0)
        SetPedHeadOverlayColor(ped, 2, 1, eb.color or 0, eb.color or 0)
    end

    -- Beard (overlay 1)
    local beard = app.beard
    if beard and beard.style and beard.style >= 0 then
        SetPedHeadOverlay(ped, 1, beard.style, beard.opacity or 1.0)
        SetPedHeadOverlayColor(ped, 1, 1, beard.color or 0, beard.color or 0)
    else
        SetPedHeadOverlay(ped, 1, 255, 0.0)
    end

    -- Eye color
    if app.eyeColor then
        SetPedEyeColor(ped, app.eyeColor)
    end

    -- Overlays (0-12, skip 1=beard, 2=eyebrows already set)
    local overlays = app.overlays
    if overlays then
        for idStr, ov in pairs(overlays) do
            local id = tonumber(idStr)
            if id and id ~= 1 and id ~= 2 then
                if ov.index and ov.index >= 0 then
                    SetPedHeadOverlay(ped, id, ov.index, ov.opacity or 1.0)
                    if ov.color then
                        local colorType = (id == 5 or id == 8) and 2 or 1
                        SetPedHeadOverlayColor(ped, id, colorType, ov.color, ov.color)
                    end
                else
                    SetPedHeadOverlay(ped, id, 255, 0.0)
                end
            end
        end
    end

    -- Components (clothing)
    local comps = app.components
    if comps then
        for idStr, comp in pairs(comps) do
            local id = tonumber(idStr)
            if id then
                SetPedComponentVariation(ped, id, comp.drawable or 0, comp.texture or 0, 2)
            end
        end
    end

    -- Props (hats, glasses, etc.)
    local props = app.props
    if props then
        for idStr, prop in pairs(props) do
            local id = tonumber(idStr)
            if id then
                if prop.drawable and prop.drawable >= 0 then
                    SetPedPropIndex(ped, id, prop.drawable, prop.texture or 0, true)
                else
                    ClearPedProp(ped, id)
                end
            end
        end
    end
end

-- ============================================================
-- CAMERA SYSTEM
-- ============================================================
local function switchCam(camType)
    local cfg = Config.Characters.CreationCam[camType]
    if not cfg then return end

    if CreationCam then
        DestroyCam(CreationCam, true)
    end

    CreationCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', cfg.x, cfg.y, cfg.z, cfg.rx, cfg.ry, cfg.rz, cfg.fov, false, 0)
    SetCamActive(CreationCam, true)
    RenderScriptCams(true, true, 800, true, true)
end

local function destroyCam()
    if CreationCam then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(CreationCam, true)
        CreationCam = nil
    end
end

-- ============================================================
-- INTERIOR MANAGEMENT
-- ============================================================
local function loadCreationInterior()
    RequestIpl(Config.Characters.CreationIpl)
    Wait(500)
end

local function unloadCreationInterior()
    RemoveIpl(Config.Characters.CreationIpl)
end

-- ============================================================
-- PED MODEL
-- ============================================================
local function applyGenderModel(gender)
    local model
    if gender == 'female' then
        model = `mp_f_freemode_01`
    else
        model = `mp_m_freemode_01`
    end
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    if HasModelLoaded(model) then
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)
    end
end

-- ============================================================
-- CHARACTER SELECTION SCREEN
-- ============================================================
RegisterNetEvent('beggin:showCharacterSelect', function(characters, canCreate)
    InCharacterScreen = true
    Beggin.SetHudVisible(false)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)
    SetEntityInvincible(ped, true)
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'showCharacterSelect',
        characters = characters,
        canCreate = canCreate,
    })
end)

-- ============================================================
-- CHARACTER CREATION SCREEN
-- ============================================================
RegisterNetEvent('beggin:showCharacterCreate', function(opts)
    InCharacterScreen = true
    CreationActive = false
    Beggin.SetHudVisible(false)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)
    SetEntityInvincible(ped, true)
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'showCharacterCreate',
        mustCreate = opts and opts.mustCreate or false,
    })
end)

-- ============================================================
-- CLOSE CHARACTER SCREEN
-- ============================================================
local function closeCharacterScreen()
    if not InCharacterScreen then return end
    InCharacterScreen = false
    CreationActive = false

    destroyCam()
    unloadCreationInterior()

    SendNUIMessage({ action = 'hideCharacterScreen' })
    SetNuiFocus(false, false)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityInvincible(ped, false)
    Beggin.SetHudVisible(true)
end

-- ============================================================
-- PLAYER LOADED HOOK
-- ============================================================
AddEventHandler('beggin:playerLoaded', function(data)
    if InCharacterScreen then
        closeCharacterScreen()
    end

    if data and data.gender then
        applyGenderModel(data.gender)
        Wait(200)
    end

    if data and data.appearance then
        Beggin.ApplyAppearance(PlayerPedId(), data.appearance)
    end

    if data and data.position then
        Wait(300)
        local ped = PlayerPedId()
        local p = data.position
        SetEntityCoords(ped, p.x + 0.0, p.y + 0.0, p.z + 0.0, false, false, false, false)
        if p.heading then
            SetEntityHeading(ped, p.heading + 0.0)
        end
    end
end)

-- ============================================================
-- NUI CALLBACKS — Selection
-- ============================================================
RegisterNUICallback('selectCharacter', function(data, cb)
    local charId = tonumber(data.id)
    if not charId then cb({ ok = false }) return end
    TriggerServerEvent('beggin:characterSelected', charId)
    cb({ ok = true })
end)

RegisterNUICallback('deleteCharacter', function(data, cb)
    local charId = tonumber(data.id)
    if not charId then cb({ ok = false }) return end
    TriggerServerEvent('beggin:characterDelete', charId)
    cb({ ok = true })
end)

-- ============================================================
-- NUI CALLBACKS — Creation Setup
-- ============================================================
RegisterNUICallback('setupCreation', function(data, cb)
    CreationActive = true

    -- Apply gender model
    applyGenderModel(data.gender or 'male')
    Wait(300)

    -- Load interior + teleport
    loadCreationInterior()
    local c = Config.Characters.CreationCoords
    local ped = PlayerPedId()
    SetEntityCoords(ped, c.x, c.y, c.z, false, false, false, false)
    SetEntityHeading(ped, c.heading)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, true, false)

    -- Apply default appearance
    Beggin.ApplyAppearance(ped, Config.Characters.DefaultAppearance)

    -- Setup camera
    Wait(200)
    switchCam('face')

    -- Get max drawables for NUI
    local maxData = {}
    for comp = 0, 11 do
        maxData['comp_' .. comp] = GetNumberOfPedDrawableVariations(ped, comp)
    end
    for prop = 0, 7 do
        maxData['prop_' .. prop] = GetNumberOfPedPropDrawableVariations(ped, prop)
    end
    maxData.hair_colors = 64
    maxData.eye_colors = 32

    cb({ ok = true, maxData = maxData })
end)

-- ============================================================
-- NUI CALLBACKS — Real-time Appearance Updates
-- ============================================================
RegisterNUICallback('updateHeritage', function(data, cb)
    local ped = PlayerPedId()
    SetPedHeadBlendData(ped,
        tonumber(data.mother) or 0,
        tonumber(data.father) or 0,
        0,
        tonumber(data.skinMix) or 0.5,
        tonumber(data.shapeMix) or 0.5,
        0.0, false
    )
    cb({ ok = true })
end)

RegisterNUICallback('updateFeature', function(data, cb)
    local ped = PlayerPedId()
    SetPedFaceFeature(ped, tonumber(data.index) or 0, tonumber(data.value) or 0.0)
    cb({ ok = true })
end)

RegisterNUICallback('updateHair', function(data, cb)
    local ped = PlayerPedId()
    SetPedComponentVariation(ped, 2, tonumber(data.style) or 0, 0, 2)
    SetPedHairColor(ped, tonumber(data.color) or 0, tonumber(data.highlight) or 0)
    cb({ ok = true })
end)

RegisterNUICallback('updateBeard', function(data, cb)
    local ped = PlayerPedId()
    local style = tonumber(data.style) or -1
    if style >= 0 then
        SetPedHeadOverlay(ped, 1, style, tonumber(data.opacity) or 1.0)
        SetPedHeadOverlayColor(ped, 1, 1, tonumber(data.color) or 0, tonumber(data.color) or 0)
    else
        SetPedHeadOverlay(ped, 1, 255, 0.0)
    end
    cb({ ok = true })
end)

RegisterNUICallback('updateEyebrows', function(data, cb)
    local ped = PlayerPedId()
    local style = tonumber(data.style) or 0
    SetPedHeadOverlay(ped, 2, style, tonumber(data.opacity) or 1.0)
    SetPedHeadOverlayColor(ped, 2, 1, tonumber(data.color) or 0, tonumber(data.color) or 0)
    cb({ ok = true })
end)

RegisterNUICallback('updateEyeColor', function(data, cb)
    SetPedEyeColor(PlayerPedId(), tonumber(data.color) or 0)
    cb({ ok = true })
end)

RegisterNUICallback('updateOverlay', function(data, cb)
    local ped = PlayerPedId()
    local id = tonumber(data.id)
    local index = tonumber(data.index) or -1
    if not id then cb({ ok = false }) return end
    if index >= 0 then
        SetPedHeadOverlay(ped, id, index, tonumber(data.opacity) or 1.0)
        if data.color then
            local colorType = (id == 5 or id == 8) and 2 or 1
            SetPedHeadOverlayColor(ped, id, colorType, tonumber(data.color), tonumber(data.color))
        end
    else
        SetPedHeadOverlay(ped, id, 255, 0.0)
    end
    cb({ ok = true })
end)

RegisterNUICallback('updateComponent', function(data, cb)
    local ped = PlayerPedId()
    local compId = tonumber(data.id)
    if not compId then cb({ ok = false }) return end
    SetPedComponentVariation(ped, compId, tonumber(data.drawable) or 0, tonumber(data.texture) or 0, 2)
    -- Return max textures for this drawable
    local maxTex = GetNumberOfPedTextureVariations(ped, compId, tonumber(data.drawable) or 0)
    cb({ ok = true, maxTextures = maxTex })
end)

RegisterNUICallback('updateProp', function(data, cb)
    local ped = PlayerPedId()
    local propId = tonumber(data.id)
    if not propId then cb({ ok = false }) return end
    local drawable = tonumber(data.drawable) or -1
    if drawable >= 0 then
        SetPedPropIndex(ped, propId, drawable, tonumber(data.texture) or 0, true)
        local maxTex = GetNumberOfPedPropTextureVariations(ped, propId, drawable)
        cb({ ok = true, maxTextures = maxTex })
    else
        ClearPedProp(ped, propId)
        cb({ ok = true, maxTextures = 0 })
    end
end)

RegisterNUICallback('switchCamera', function(data, cb)
    switchCam(data.cam or 'face')
    cb({ ok = true })
end)

RegisterNUICallback('changeGender', function(data, cb)
    local gender = data.gender or 'male'
    applyGenderModel(gender)
    Wait(300)
    local ped = PlayerPedId()
    local c = Config.Characters.CreationCoords
    SetEntityCoords(ped, c.x, c.y, c.z, false, false, false, false)
    SetEntityHeading(ped, c.heading)
    FreezeEntityPosition(ped, true)
    Beggin.ApplyAppearance(ped, Config.Characters.DefaultAppearance)

    -- Return new max drawables
    local maxData = {}
    for comp = 0, 11 do
        maxData['comp_' .. comp] = GetNumberOfPedDrawableVariations(ped, comp)
    end
    for prop = 0, 7 do
        maxData['prop_' .. prop] = GetNumberOfPedPropDrawableVariations(ped, prop)
    end
    cb({ ok = true, maxData = maxData })
end)

RegisterNUICallback('getMaxTextures', function(data, cb)
    local ped = PlayerPedId()
    local compId = tonumber(data.compId)
    local drawable = tonumber(data.drawable) or 0
    if data.isProp then
        cb({ max = GetNumberOfPedPropTextureVariations(ped, compId, drawable) })
    else
        cb({ max = GetNumberOfPedTextureVariations(ped, compId, drawable) })
    end
end)

-- ============================================================
-- NUI CALLBACK — Finish Creation
-- ============================================================
RegisterNUICallback('finishCreation', function(data, cb)
    if type(data) ~= 'table' then cb({ ok = false }) return end
    TriggerServerEvent('beggin:characterCreate', {
        firstname = tostring(data.firstname or ''),
        lastname = tostring(data.lastname or ''),
        dateofbirth = tostring(data.dateofbirth or ''),
        gender = tostring(data.gender or 'male'),
        appearance = data.appearance,
    })
    cb({ ok = true })
end)

-- Keep createCharacter callback for backward compat (simple creation)
RegisterNUICallback('createCharacter', function(data, cb)
    if type(data) ~= 'table' then cb({ ok = false }) return end
    TriggerServerEvent('beggin:characterCreate', {
        firstname = tostring(data.firstname or ''),
        lastname = tostring(data.lastname or ''),
        dateofbirth = tostring(data.dateofbirth or ''),
        gender = tostring(data.gender or 'male'),
    })
    cb({ ok = true })
end)

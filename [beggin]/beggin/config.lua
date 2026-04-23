Config = {}

Config.Locale = 'fr'
Config.SaveInterval = 5 * 60 * 1000

Config.DefaultAccounts = {
    cash = 500,
    bank = 5000,
}

Config.Money = {
    LogHistory = true,
    HistoryLimit = 25,
    HistoryMax = 200,
}

Config.Inventory = {
    MaxWeight = 30000, -- en grammes (30 kg)
    LogHistory = true,
    HistoryLimit = 25,
    HistoryMax = 200,
    StartingItems = {
        { name = 'bread', amount = 2 },
        { name = 'water', amount = 2 },
    },
}

-- Item registry. `weight` en grammes.
Config.Items = {
    bread       = { label = 'Pain',             weight = 150, type = 'food',   usable = true,  description = 'Un morceau de pain frais.' },
    water       = { label = 'Bouteille d\'eau', weight = 500, type = 'drink',  usable = true,  description = 'De l\'eau fraiche.' },
    sandwich    = { label = 'Sandwich',         weight = 250, type = 'food',   usable = true,  description = 'Sandwich jambon-beurre.' },
    soda        = { label = 'Soda',             weight = 330, type = 'drink',  usable = true,  description = 'Boisson gazeuse.' },
    phone       = { label = 'Telephone',        weight = 200, type = 'item',   usable = false, description = 'Un telephone portable.' },
    lockpick    = { label = 'Crochet',          weight = 50,  type = 'tool',   usable = false, description = 'Pour forcer les serrures.' },
    bandage     = { label = 'Bandage',          weight = 80,  type = 'medic',  usable = true,  description = 'Soigne les blessures legeres.' },
    cash_bundle = { label = 'Liasse de cash',   weight = 100, type = 'item',   usable = false, description = 'Une liasse de billets.' },
}

Config.DefaultSpawn = {
    x = -269.4,
    y = -955.3,
    z = 31.2,
    heading = 205.0,
}

Config.Debug = true

Config.Characters = {
    MaxPerPlayer = 5,
    MinNameLen = 2,
    MaxNameLen = 20,
    MinAge = 18,
    MaxAge = 80,

    CreationIpl = 'apa_v_mp_h_01_a',
    CreationCoords = { x = -774.22, y = 342.03, z = 206.85, heading = 0.0 },
    CreationCam = {
        face  = { x = -774.22, y = 343.5, z = 208.45, rx = -8.0,  ry = 0.0, rz = 180.0, fov = 32.0 },
        upper = { x = -774.22, y = 344.2, z = 208.05, rx = -5.0,  ry = 0.0, rz = 180.0, fov = 45.0 },
        full  = { x = -774.22, y = 343.5, z = 207.45, rx = -3.0,  ry = 0.0, rz = 180.0, fov = 65.0 },
    },

    DefaultAppearance = {
        heritage = { mother = 0, father = 0, shapeMix = 0.5, skinMix = 0.5 },
        features = { 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 },
        hair = { style = 0, color = 0, highlight = 0 },
        beard = { style = -1, color = 0, opacity = 1.0 },
        eyebrows = { style = 0, color = 0, opacity = 1.0 },
        eyeColor = 0,
        overlays = {},
        components = {},
        props = {},
    },
}

Config.HUD = {
    StatsUpdateInterval = 500,
    EnvUpdateInterval = 2000,
}

Config.Needs = {
    DrainInterval = 60 * 1000,
    FoodDrain = 1.0,
    ThirstDrain = 1.5,
    DamageWhenEmpty = 5,
}

Config.Admin = {
    Ace = 'beggin.admin',
    OpenKey = 168,
    NoclipSpeed = 1.0,
    NoclipSpeedFast = 4.0,
    FlySpeed = 1.5,
    EspMaxDistance = 250.0,
    PositionHistorySize = 10,
    PlayerListInterval = 2000,

    Locations = {
        { label = 'Mission Row PD',  x = 425.1,    y = -979.5,   z = 30.7,  heading = 0.0   },
        { label = 'Sandy Shores PD', x = 1853.2,   y = 3689.5,   z = 34.3,  heading = 209.0 },
        { label = 'Paleto Bay PD',   x = -448.9,   y = 6012.5,   z = 31.7,  heading = 41.0  },
        { label = 'Hopital Pillbox', x = 307.7,    y = -1433.0,  z = 30.0,  heading = 230.0 },
        { label = 'Hopital Sandy',   x = 1839.6,   y = 3672.9,   z = 34.3,  heading = 211.0 },
        { label = 'Aeroport LSIA',   x = -1037.5,  y = -2737.6,  z = 20.2,  heading = 327.0 },
        { label = 'Mont Chiliad',    x = 501.0,    y = 5604.0,   z = 797.9, heading = 0.0   },
        { label = 'Casino',          x = 925.0,    y = 46.0,     z = 81.1,  heading = 235.0 },
        { label = 'Vespucci Beach',  x = -1223.5,  y = -1491.5,  z = 4.4,   heading = 130.0 },
        { label = 'Vinewood Sign',   x = 711.6,    y = 1199.4,   z = 351.7, heading = 240.0 },
    },

    QuickVehicles = {
        'adder', 'zentorno', 'sultan', 'kuruma', 'comet2',
        'baller', 'sandking', 'rebel', 'maverick', 'buzzard',
        'lazer', 'rhino', 'police', 'ambulance', 'firetruk',
    },

    QuickWeapons = {
        { label = 'Pistolet',     hash = 'WEAPON_PISTOL',     ammo = 250  },
        { label = 'Combat Pistol',hash = 'WEAPON_COMBATPISTOL',ammo = 250 },
        { label = 'Micro SMG',    hash = 'WEAPON_MICROSMG',   ammo = 500  },
        { label = 'SMG',          hash = 'WEAPON_SMG',        ammo = 500  },
        { label = 'Carabine',     hash = 'WEAPON_CARBINERIFLE',ammo = 500 },
        { label = 'Assault Rifle',hash = 'WEAPON_ASSAULTRIFLE',ammo = 500 },
        { label = 'Pump Shotgun', hash = 'WEAPON_PUMPSHOTGUN',ammo = 80   },
        { label = 'Sniper',       hash = 'WEAPON_SNIPERRIFLE',ammo = 50   },
        { label = 'Lance-roquettes', hash = 'WEAPON_RPG',     ammo = 10   },
    },
}

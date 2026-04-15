Config = {}

Config.Locale = 'fr'
Config.SaveInterval = 5 * 60 * 1000

Config.DefaultAccounts = {
    cash = 500,
    bank = 5000,
}

Config.DefaultSpawn = {
    x = -269.4,
    y = -955.3,
    z = 31.2,
    heading = 205.0,
}

Config.Debug = true

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

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Beggin'
description 'Beggin Framework'
version '0.1.0'

shared_scripts {
    'config.lua',
    'shared/main.lua',
    'shared/utils.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/database.lua',
    'server/player.lua',
    'server/characters.lua',
    'server/players.lua',
    'server/money.lua',
    'server/needs.lua',
    'server/inventory.lua',
    'server/commands.lua',
    'server/exports.lua',
    'server/admin.lua',
}

client_scripts {
    'client/main.lua',
    'client/characters.lua',
    'client/player.lua',
    'client/hud.lua',
    'client/admin.lua',
<<<<<<< HEAD
    'client/inventory.lua',
=======
>>>>>>> 56c38019c40a8813a66fc58a17af3a18589f39e9
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
<<<<<<< HEAD
    'html/characters.css',
    'html/characters.js',
    'html/admin.css',
    'html/admin.js',
    'html/inventory.css',
    'html/inventory.js',
=======
    'html/admin.css',
    'html/admin.js',
>>>>>>> 56c38019c40a8813a66fc58a17af3a18589f39e9
}

dependencies {
    'oxmysql',
}

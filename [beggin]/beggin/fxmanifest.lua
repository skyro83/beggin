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
    'server/players.lua',
    'server/needs.lua',
    'server/commands.lua',
    'server/exports.lua',
    'server/admin.lua',
}

client_scripts {
    'client/main.lua',
    'client/player.lua',
    'client/hud.lua',
    'client/admin.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/admin.css',
    'html/admin.js',
}

dependencies {
    'oxmysql',
}

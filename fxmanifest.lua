fx_version 'cerulean'
game 'gta5'

description 'QB-TruckRobbery'
version '1.0.0'

server_script 'server/*.lua'
client_script 'client/*.lua'
shared_script 'config.lua'

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    'client/*.lua',
}

ui_page {
    'html/index.html'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

lua54 'yes'

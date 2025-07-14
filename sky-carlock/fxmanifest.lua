fx_version 'cerulean'
game 'gta5'

author 'SkyInside'
description 'Car Lock System with ESX, oxmysql, and ox_lib'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

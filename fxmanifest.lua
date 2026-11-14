fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'hype-wallet'
author 'HypeScripts'
version '1.0.0'
description 'Card wallet built with Veyra UI'

dependencies {
    'ox_lib',
    'ox_inventory',
    'qbx_core',
}

-- language: set `setr ox:locale "en"` (en, tr) in server.cfg, falls back to English
ox_lib 'locale'

shared_script '@ox_lib/init.lua'

client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page 'web/dist/index.html'

files {
    'config/shared.lua',
    'locales/*.json',
    'web/dist/index.html',
    'web/dist/**/*',
}

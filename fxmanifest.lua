fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'hype-wallet'
author 'HypeScripts'
version '1.0.0'
description 'Hype Wallet is a card wallet for Qbox servers. Players keep their ID card and licenses in a wallet item, view them full size and show them to nearby players. Cards keep their item metadata, so the name, photo and citizen ID are always the real ones.'

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

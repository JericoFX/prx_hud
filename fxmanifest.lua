fx_version 'cerulean'
games { 'gta5' }
author 'Ivan_44'

ui_page "dist/index.html"
shared_scripts { '@ox_lib/init.lua' }
client_scripts {
  "config.lua",
  "client/*"
}
lua54 'yes'
files {
  "dist/*",
  "dist/**/*",
  "dist/**/**/*",
}

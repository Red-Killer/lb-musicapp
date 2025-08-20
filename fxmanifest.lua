fx_version "cerulean"
game "gta5"

author "Red Killer & PrinceAlbert (Popcorn RP)"
description "Play your favourite music through lb-phone"
version "2.1.0"

shared_script "config.lua"
client_script "client.lua"
server_script "server.lua"

files {
    "ui/**/*"
}

ui_page "ui/index.html"

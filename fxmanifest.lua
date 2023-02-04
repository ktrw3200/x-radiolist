fx_version "cerulean"
use_experimental_fxv2_oal "yes"
lua54 "yes"
game "gta5"

name "x-radiolist"
version "0.0.0"
description "Project-X Radio List : List of players in each radio for pma-voice"

ui_page "web/index.html"

files {
    "web/index.html"
}

dependencies {
    "ox_lib",
}

shared_scripts {
    "@ox_lib/init.lua",
    "shared/*.lua",
}

server_script {
    "server/*.lua"
}

client_script {
    "client/*.lua"
}
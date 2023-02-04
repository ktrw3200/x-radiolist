local pma_voice = exports["pma-voice"]
local Framework = nil
local Core = nil

if Config.UseRPName then
    if GetResourceState("es_extended") ~= "missing" then
        Framework = "ESX"
        Core = exports["es_extended"]:getSharedObject()
    elseif GetResourceState("qb-core") ~= "missing" then
        Framework = "QB"
        Core = exports["qb-core"]:GetCoreObject()
    elseif GetResourceState("JLRP-Framework") ~= "missing" then
        Framework = "JLRP"
        Core = exports["JLRP-Framework"]:getSharedObject()
    end
end

local CustomNames = {}
local RadioNames = {}

AddEventHandler("playerDropped", function()
    local src = source
    
    local currentRadioChannel = Player(src).state.currentRadioChannel
    
    local playersInCurrentRadioChannel = CreateFullRadioListOfChannel(currentRadioChannel)
    for _, player in pairs(playersInCurrentRadioChannel) do
        --if player.Source ~= src then
            TriggerClientEvent("JLRP-RadioList:Client:SyncRadioChannelPlayers", player.Source, src, 0, playersInCurrentRadioChannel)
        --end
    end
    playersInCurrentRadioChannel = {}
    
    if Config.LetPlayersSetTheirOwnNameInRadio and Config.ResetPlayersCustomizedNameOnExit then
        local playerIdentifier = GetIdentifier(src)
        if CustomNames[playerIdentifier] and CustomNames[playerIdentifier] ~= nil then
            CustomNames[playerIdentifier] = nil
        end
    end
end)

function GetPlayerNameForRadio(source)
    if Config.LetPlayersSetTheirOwnNameInRadio then
        local playerIdentifier = GetIdentifier(source)
        if CustomNames[playerIdentifier] then
            return CustomNames[playerIdentifier]
        end
    end

    local name = nil
    if Config.UseRPName then
        if Framework == "ESX" then
            if xPlayer then
                name = Core.GetPlayerFromId(source)?.getName()
            end
        elseif Framework == "QB" then
            local xPlayer = Core.Functions.GetPlayer(source)
            if xPlayer then
                name = xPlayer.PlayerData.charinfo.firstname.." "..xPlayer.PlayerData.charinfo.lastname
            end
        elseif Framework == "JLRP" then
            if xPlayer then
                name = Core.GetPlayerFromId(source)?.getName()
            end
        end
        if name == nil then -- extra check to make sure player sends a name to client
            name = GetPlayerName(source)
        end
    else
        name = GetPlayerName(source)
    end
    Player(source).state:set(Shared.State.nameInRadio, name, true)
    return name
end

if Config.LetPlayersSetTheirOwnNameInRadio then
    local commandLength = string.len(Config.RadioListChangeNameCommand)
    local argumentStartIndex = commandLength + 2
    RegisterCommand(Config.RadioListChangeNameCommand, function(source, _, rawCommand)
        if source and source > 0 then
            local customizedName = rawCommand:sub(argumentStartIndex)
            if customizedName ~= "" and customizedName ~= " " and customizedName ~= nil then
                CustomNames[GetIdentifier(source)] = customizedName
                Player(source).state:set(Shared.State.nameInRadio, customizedName, true)
                local currentRadioChannel = Player(source).state.radioChannel
                if currentRadioChannel > 0 then
                    Connect(source, currentRadioChannel, currentRadioChannel)
                end
            end
        end
    end, false)
end

function GetIdentifier(source)
    for _, v in ipairs(GetPlayerIdentifiers(source)) do
        if string.match(v, "license:") then
            local identifier = string.gsub(v, "license:", "")
            return identifier
        end
    end
end

lib.callback.register(Shared.Callback.getPlayersInRadio, function(source, radioChannel)
    local playersInRadio = {}
    if not source then return playersInRadio end
    radioChannel = radioChannel or Player(source).state.radioChannel
    if not radioChannel then return playersInRadio end
    for player in pairs(pma_voice:getPlayersInRadioChannel(radioChannel)) do
        playersInRadio[player] = GetPlayerNameForRadio(player)
    end
    local radioChannelName = RadioNames[tostring(radioChannel)] or radioChannel
    return playersInRadio, radioChannel, radioChannelName
end)

lib.callback.register(Shared.Callback.getPlayerName, function(source, player)
    return GetPlayerNameForRadio(player)
end)
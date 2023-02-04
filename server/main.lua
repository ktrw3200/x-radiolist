local pma_voice = exports["pma-voice"]
local Framework = {}
local customPlayerNames = {}
local customRadioNames = {}

if Config.UseRPName then
    if GetResourceState("es_extended"):find("start") then
        Framework.Object = exports["es_extended"]:getSharedObject()
        Framework.Initial = "esx"
        Framework.GetPlayer = Framework.Object.Functions.GetPlayer
        Framework.GetPlayerName = function(source)
            local xPlayer = Framework.GetPlayer(source)
            return xPlayer and xPlayer.getName() or nil
        end
    elseif GetResourceState("qb-core"):find("start") then
        Framework.Object = exports["qb-core"]:GetCoreObject()
        Framework.Initial = "qb"
        Framework.GetPlayer = Framework.Object.Functions.GetPlayer
        Framework.GetPlayerName = function(source)
            local xPlayer = Framework.GetPlayer(source)
            return xPlayer and ("%s %s"):format(xPlayer.PlayerData.charinfo.firstname, xPlayer.PlayerData.charinfo.lastname) or nil
        end
    elseif GetResourceState("JLRP-Framework"):find("start") then
        Framework.Object = exports["JLRP-Framework"]:getSharedObject()
        Framework.Initial = "jlrp"
        Framework.GetPlayer = Framework.Object.Functions.GetPlayer
        Framework.GetPlayerName = function(source)
            local xPlayer = Framework.GetPlayer(source)
            return xPlayer and xPlayer.getName() or nil
        end
    end
    Framework.Object = nil -- free up the memory
end

local function getPlayerIdentifier(source)
    local identifier
    for _, v in ipairs(GetPlayerIdentifiers(source)) do
        if string.match(v, "license:") then
            identifier = string.gsub(v, "license:", "")
            break
        end
    end
    return identifier
end

local function getPlayerName(source)
    if Config.LetPlayersSetTheirOwnNameInRadio then
        local playerIdentifier = getPlayerIdentifier(source)
        if customPlayerNames[playerIdentifier] then
            return customPlayerNames[playerIdentifier]
        end
    end
    local playerName = (Config.UseRPName and (Framework.GetPlayerName(source) or GetPlayerName(source))) or (not Config.UseRPName and GetPlayerName(source))
    Player(source).state:set(Shared.State.nameInRadio, playerName, true)
    return playerName
end

lib.callback.register(Shared.Callback.getPlayersInRadio, function(source, radioChannel)
    local playersInRadio = {}
    if not source then return playersInRadio end
    radioChannel = radioChannel or Player(source).state.radioChannel
    if not radioChannel then return playersInRadio end
    for player in pairs(pma_voice:getPlayersInRadioChannel(radioChannel)) do
        playersInRadio[player] = getPlayerName(player)
    end
    local radioChannelName = customRadioNames[tostring(radioChannel)] or radioChannel
    return playersInRadio, radioChannel, radioChannelName
end)

lib.callback.register(Shared.Callback.getPlayerName, function(_, player)
    return getPlayerName(player)
end)

if Config.LetPlayersSetTheirOwnNameInRadio then
    local commandLength = string.len(Config.RadioListChangeNameCommand)
    local argumentStartIndex = commandLength + 2
    RegisterCommand(Config.RadioListChangeNameCommand, function(source, _, rawCommand)
        if source and source > 0 then
            local customizedName = rawCommand:sub(argumentStartIndex)
            if customizedName ~= "" and customizedName ~= " " and customizedName ~= nil then
                customPlayerNames[getPlayerIdentifier(source)] = customizedName
                Player(source).state:set(Shared.State.nameInRadio, customizedName, true)
                local currentRadioChannel = Player(source).state.radioChannel
                if currentRadioChannel then
                    pma_voice:setPlayerRadio(source, 0)
                    pma_voice:setPlayerRadio(source, currentRadioChannel)
                end
            end
        end
    end, false)
end

AddEventHandler("playerDropped", function()
    local source = source
    if Config.LetPlayersSetTheirOwnNameInRadio and Config.ResetPlayersCustomizedNameOnExit then
        local playerIdentifier = getPlayerIdentifier(source)
        if customPlayerNames[playerIdentifier] then
            customPlayerNames[playerIdentifier] = nil
        end
    end
end)
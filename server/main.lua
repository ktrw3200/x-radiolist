local pma_voice = exports["pma-voice"]
local Framework = {}
local customPlayerNames = {}
local customRadioNames = {}
Config.PlayerServerIdPosition = (Config.PlayerServerIdPosition == "right" or Config.PlayerServerIdPosition == "left") and Config.PlayerServerIdPosition or "right"

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
    if Config.ShowPlayersServerIdNextToTheirName then
        if Config.PlayerServerIdPosition == "left" then playerName = ("(%s) %s"):format(source, playerName)
        elseif Config.PlayerServerIdPosition == "right" then playerName = ("%s (%s)"):format(playerName, source) end
    end
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
                if Config.ShowPlayersServerIdNextToTheirName then
                    if Config.PlayerServerIdPosition == "left" then customizedName = ("(%s) %s"):format(source, customizedName)
                    elseif Config.PlayerServerIdPosition == "right" then customizedName = ("%s (%s)"):format(customizedName, source) end
                end
                customPlayerNames[getPlayerIdentifier(source)] = customizedName
                Player(source).state:set(Shared.State.nameInRadio, customizedName, true)
                TriggerClientEvent("ox_lib:notify", source, {
                    title = ("You successfully changed your name on radio to %s"):format(customizedName),
                    type = "success",
                    duration = 5000
                })
                local currentRadioChannel = Player(source).state.radioChannel
                if not currentRadioChannel or not (currentRadioChannel > 0) then return end
                pma_voice:setPlayerRadio(source, 0)
                pma_voice:setPlayerRadio(source, currentRadioChannel)
            end
        end
    end, false)
end

if Config.LetPlayersChangeRadioChannelsName then
    local commandLength = string.len(Config.ModifyRadioChannelNameCommand)
    local argumentStartIndex = commandLength + 2
    RegisterCommand(Config.ModifyRadioChannelNameCommand, function(source, _, rawCommand)
        if source and source > 0 then
            local currentRadioChannel = Player(source).state.radioChannel
            if not currentRadioChannel or not (currentRadioChannel > 0) then
                return TriggerClientEvent("ox_lib:notify", source, {title = "You must be in a radio channel to modify its name", type = "error"})
            end
            local customizedName = rawCommand:sub(argumentStartIndex)
            if customizedName ~= "" and customizedName ~= " " and customizedName ~= nil then
                customRadioNames[tostring(currentRadioChannel)] = customizedName
                for player in pairs(pma_voice:getPlayersInRadioChannel(currentRadioChannel)) do
                    pma_voice:setPlayerRadio(player, 0)
                    pma_voice:setPlayerRadio(player, currentRadioChannel)
                    TriggerClientEvent("ox_lib:notify", player, {
                        title = ("Player %s changed the radio channel(%s)'s name to %s"):format(Player(source).state[Shared.State.nameInRadio], currentRadioChannel, customizedName),
                        type = "inform",
                        duration = 5000
                    })
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
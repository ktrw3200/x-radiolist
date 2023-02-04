local pma_voice = exports["pma-voice"]
local Framework = {}
local customPlayerNames = {}
local customRadioNames = {}

local function isPlayerAllowedToChangeName(_, _)
    return Config.LetPlayersSetTheirOwnNameInRadio
end
if Config.UseRPName then
    if GetResourceState("es_extended"):find("start") then
        Framework.Object = exports["es_extended"]:getSharedObject()
        Framework.Initial = "esx"
        Framework.GetPlayer = Framework.Object.GetPlayerFromId
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
        isPlayerAllowedToChangeName = function(source, notify) -- override isPlayerAllowedToChangeName
            local response = Config.LetPlayersSetTheirOwnNameInRadio
            local xPlayer = Framework.GetPlayer(source)
            if xPlayer then
                if Config.JobsWithCallsign[xPlayer.PlayerData?.job?.name] and xPlayer.PlayerData?.job?.onduty then
                    response = false
                    if notify then
                        TriggerClientEvent("ox_lib:notify", source, { title = "You cannot change your name on radio while on duty!", type = "error", duration = 5000 })
                    end
                end
            end
            return response
        end
    elseif GetResourceState("JLRP-Framework"):find("start") then
        Framework.Object = exports["JLRP-Framework"]:getSharedObject()
        Framework.Initial = "jlrp"
        Framework.GetPlayer = Framework.Object.GetPlayerFromId
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

local function refreshRadioForPlayer(source)
    local currentRadioChannel = Player(source).state.radioChannel
    if not currentRadioChannel or not (currentRadioChannel > 0) then return end
    pma_voice:setPlayerRadio(source, 0)
    Wait(100)
    pma_voice:setPlayerRadio(source, currentRadioChannel)
end

local function setPlayerName(source, newName)
    local currentName = Player(source).state[Shared.State.nameInRadio]
    if currentName and currentName == newName then return end
    customPlayerNames[getPlayerIdentifier(source)] = newName
    Player(source).state:set(Shared.State.nameInRadio, newName, true)
    refreshRadioForPlayer(source)
    TriggerClientEvent("ox_lib:notify", source, {
        title = ("Your name on radio changed to %s"):format(newName),
        type = "inform",
        duration = 5000
    })
end

local function getPlayerName(source)
    local playerName = Player(source).state[Shared.State.nameInRadio]
    if not playerName then
        playerName = (Config.UseRPName and (Framework.GetPlayerName(source) or GetPlayerName(source))) or (not Config.UseRPName and GetPlayerName(source))
        setPlayerName(source, playerName)
    end
    return playerName
end

local function resetPlayerName(source)
    Player(source).state:set(Shared.State.nameInRadio, nil, true)
    getPlayerName(source)
    refreshRadioForPlayer(source)
end

local function getRadioChannelName(radioChannel)
    return customRadioNames[tostring(radioChannel)] or Config.RadioChannelsWithName[tostring(math.floor(radioChannel))] or radioChannel
end

lib.callback.register(Shared.Callback.getPlayersInRadio, function(source, radioChannel)
    local playersInRadio = {}
    if not source then return playersInRadio end
    radioChannel = radioChannel or Player(source).state.radioChannel
    if not radioChannel then return playersInRadio end
    for player in pairs(pma_voice:getPlayersInRadioChannel(radioChannel)) do
        playersInRadio[player] = getPlayerName(player)
    end
    local radioChannelName = getRadioChannelName(radioChannel)
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
                if isPlayerAllowedToChangeName(source, true) then
                    setPlayerName(source, customizedName)
                end
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
                if not Config.LetPlayersOverrideRadioChannelsWithName and Config.RadioChannelsWithName[tostring(math.floor(currentRadioChannel))] then
                    return TriggerClientEvent("ox_lib:notify", source, {
                        title = "You are not permitted to change this radio channel name!",
                        type = "error",
                        duration = 5000
                    })
                end
                customRadioNames[tostring(currentRadioChannel)] = customizedName
                for player in pairs(pma_voice:getPlayersInRadioChannel(currentRadioChannel)) do
                    refreshRadioForPlayer(player)
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

if Framework.Initial == "qb" then
    AddEventHandler("QBCore:Player:SetPlayerData", function(playerData)
        local source = playerData.source
        if not source then return end
        local isAllowedToChangeName = isPlayerAllowedToChangeName(source, false)
        local hasCallsignSetAsName = Player(source).state[Shared.State.callsignIsSet]
        if not isAllowedToChangeName then
            setPlayerName(source, playerData.metadata?.callsign or Player(source).state[Shared.State.nameInRadio])
            Player(source).state:set(Shared.State.callsignIsSet, true)
        elseif isAllowedToChangeName and hasCallsignSetAsName then
            resetPlayerName(source)
            Player(source).state:set(Shared.State.callsignIsSet, false)
        end
    end)
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
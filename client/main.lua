local playerServerID = GetPlayerServerId(PlayerId())
local currentRadioChannel, currentRadioChannelName = nil, nil
local radioListVisibility = true

local function closeTheRadioList()
    SendNUIMessage({ clearRadioList = true })
    currentRadioChannel, currentRadioChannelName = nil, nil
end

local function modifyTheRadioListVisibility(state)
    SendNUIMessage({ changeVisibility = true, visible = state })
end

local function addServerIdToPlayerName(serverId, playerName)
    if Config.ShowPlayersServerIdNextToTheirName then
        if Config.PlayerServerIdPosition == "left" then playerName = ("(%s) %s"):format(serverId, playerName)
        elseif Config.PlayerServerIdPosition == "right" then playerName = ("%s (%s)"):format(playerName, serverId) end
    end
    return playerName
end

RegisterNetEvent("pma-voice:addPlayerToRadio", function(playerId)
    if not currentRadioChannel or not (currentRadioChannel > 0) or playerId == playerServerID then return end
    local playerName = Player(playerId).state[Shared.State.nameInRadio] or callback.await(Shared.Callback.getPlayerName, false, playerId)
    playerName = addServerIdToPlayerName(playerId, playerName)
    SendNUIMessage({ radioId = playerId, radioName = playerName, channel = currentRadioChannelName })
end)

RegisterNetEvent("pma-voice:removePlayerFromRadio", function(playerId)
    if not currentRadioChannel or not (currentRadioChannel > 0) then return end
    if playerId == playerServerID then
        closeTheRadioList()
    else
        SendNUIMessage({ radioId = playerId })
    end
end)

RegisterNetEvent("pma-voice:syncRadioData", function()
    closeTheRadioList()
    local playersInRadio
    playersInRadio, currentRadioChannel, currentRadioChannelName = callback.await(Shared.Callback.getPlayersInRadio, false)
    for playerId, playerName in pairs(playersInRadio) do
        playerName = addServerIdToPlayerName(playerId, playerName)
        SendNUIMessage({ self = playerId == playerServerID, radioId = playerId, radioName = playerName, channel = currentRadioChannelName })
    end
    playersInRadio = nil
end)

-- set talkingState on radio for self
RegisterNetEvent("pma-voice:radioActive")
AddEventHandler("pma-voice:radioActive", function(talkingState)
    SendNUIMessage({ radioId = playerServerID, radioTalking = talkingState })
end)

-- set talkingState on radio for other radio members
RegisterNetEvent("pma-voice:setTalkingOnRadio")
AddEventHandler("pma-voice:setTalkingOnRadio", function(source, talkingState)
    SendNUIMessage({ radioId = source, radioTalking = talkingState })
end)

if Config.LetPlayersChangeVisibilityOfRadioList then
    ---@diagnostic disable-next-line: missing-parameter
    RegisterCommand(Config.RadioListVisibilityCommand,function()
        radioListVisibility = not radioListVisibility
        modifyTheRadioListVisibility(radioListVisibility)
    end)
    TriggerEvent("chat:addSuggestion", "/"..Config.RadioListVisibilityCommand, "Show/Hide Radio List")
end

if Config.LetPlayersSetTheirOwnNameInRadio then
    TriggerEvent("chat:addSuggestion", "/"..Config.RadioListChangeNameCommand, "Customize your name to be shown in radio list", { { name = "customized name", help = "Enter your desired name to be shown in radio list" } })
end

if Config.HideRadioListVisibilityByDefault then
    SetTimeout(1000, function()
        radioListVisibility = false
        modifyTheRadioListVisibility(radioListVisibility)
    end)
end

if Config.LetPlayersChangeRadioChannelsName then
    TriggerEvent("chat:addSuggestion", "/"..Config.ModifyRadioChannelNameCommand, "Modify the name of the radio channel you are currently in", { { name = "customized name", help = "Enter your desired name to set it as you current radio channel's name" } })
end

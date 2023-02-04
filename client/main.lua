local playerServerID = GetPlayerServerId(PlayerId())
local currentRadioChannel, currentRadioChannelName
local radioListVisibility = true

local function closeTheRadioList()
    SendNUIMessage({ clearRadioList = true })
end

local function modifyTheRadioListVisibility(state)
    SendNUIMessage({ changeVisibility = true, visible = state })
end

RegisterNetEvent("pma-voice:addPlayerToRadio", function(playerId)
    if not currentRadioChannel or not (currentRadioChannel > 0) then return end
    local playerName = Player(playerId).state[Shared.State.nameInRadio] or lib.callback.await(Shared.Callback.getPlayerName, false, playerId)
    SendNUIMessage({ self = playerId == playerServerID, radioId = playerId, radioName = playerName, channel = currentRadioChannelName })
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
    playersInRadio, currentRadioChannel, currentRadioChannelName = lib.callback.await(Shared.Callback.getPlayersInRadio, false)
    for playerId, playerName in pairs(playersInRadio) do
        SendNUIMessage({ self = playerId == playerServerID, radioId = playerId, radioName = playerName, channel = currentRadioChannelName })
    end
    playersInRadio = nil
end)

-- set talkingState on radio for another radio members
RegisterNetEvent("pma-voice:setTalkingOnRadio")
AddEventHandler("pma-voice:setTalkingOnRadio", function(source, talkingState)
    SendNUIMessage({ radioId = source, radioTalking = talkingState })
end)

-- set talkingState on radio for self
RegisterNetEvent("pma-voice:radioActive")
AddEventHandler("pma-voice:radioActive", function(talkingState)
    SendNUIMessage({ radioId = playerServerID, radioTalking = talkingState })
end)

if Config.LetPlayersChangeVisibilityOfRadioList then
    ---@diagnostic disable-next-line: missing-parameter
    RegisterCommand(Config.RadioListVisibilityCommand,function()
        visibility = not visibility
        modifyTheRadioListVisibility(visibility)
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
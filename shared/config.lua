Config = {}

Config.UseRPName = true                                 -- If set to true, it uses either esx-legacy or qb-core built-in function to get players' RP name

Config.LetPlayersChangeVisibilityOfRadioList = true     -- Let players to toggle visibility of the list
Config.RadioListVisibilityCommand = "radiolist"         -- Only works if Config.LetPlayersChangeVisibilityOfRadioList is set to true
Config.HideRadioListVisibilityByDefault = false         -- If set to true and a player joins the server, don't show the radio list until the player execute the Config.RadioListVisibilityCommand command

Config.LetPlayersSetTheirOwnNameInRadio = true          -- Let players to customize how their name is displayed on the list
Config.ResetPlayersCustomizedNameOnExit = true          -- Only works if Config.LetPlayersSetTheirOwnNameInRadio is set to true - Removes customized name players set for themselves on their server exit
Config.RadioListChangeNameCommand = "nameinradio"       -- Only works if Config.LetPlayersSetTheirOwnNameInRadio is set to true

Config.LetPlayersChangeRadioChannelsName = true         -- Let players to change the name of the radio channels **they are currently joined in**
Config.ModifyRadioChannelNameCommand = "nameofradio"    -- Changes the name of the radio channel **that the player is currently joined in** => this is a validation to prevent normal players from modifying the name of the restricted channels they don't have access to(such as police, & etc)

Config.ShowPlayersServerIdNextToTheirName = true        -- Shows the players' server id next to their name on the radio list
Config.PlayerServerIdPosition = "right"                 -- Position of player's server id next to their name on the radio list ("right" or "left") => Only works if Config.ShowPlayersServerIdNextToTheirName is set to true

Config.JobsWithCallsign = {                             -- It only detects callsign if your framework is "qb"
    ["police"] = true,
    ["ambulance"] = true,
}

Config.RadioChannelsWithName = {
    ["0"] = "Admin",
    ["1"] = "Police",
    ["2"] = "Sheriff",
    ["3"] = "Fbi",
    ["4"] = "Ambulance",
    ["5"] = "Artesh"
}
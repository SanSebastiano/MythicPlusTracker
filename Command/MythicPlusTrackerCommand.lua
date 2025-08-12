local addonName, addon = ...

-- Slash command handler for MythicPlusTracker
local function handleSlashCommand(msg)
    local command = string.lower(string.trim(msg or ""))

    if command == "debug" then
        addon.setDebugMode()

    elseif command == "test" then
        C_MythicPlus.RequestMapInfo()
        print('C_MythicPlus.GetCurrentSeason(): ' .. C_MythicPlus.GetCurrentSeason())
        print('C_MythicPlus.IsMythicPlusActive(): ' .. tostring(C_MythicPlus.IsMythicPlusActive()))
        print('C_MythicPlus.GetRunHistory():')
        for i, run in ipairs(C_MythicPlus.GetRunHistory()) do
            print(string.format("Run %d: %s, %s, %s, %s", i, run.mapChallengeModeID, run.completed, run.bestRunTime, run.bestRunLevel))
        end
        print('C_ChallengeMode.GetMapScoreInfo()')
        for key, value in pairs(C_ChallengeMode.GetMapScoreInfo()) do
            print(key)
            for subKey, subValue in pairs(value) do
                if subKey == "mapChallengeModeID" then
                    print(C_ChallengeMode.GetMapUIInfo(subValue))
                end
            end
        end

    elseif command == "debug on" then
        addon.setDebugMode(true)

    elseif command == "debug off" then
        addon.setDebugMode(false)

    elseif command == "help" or command == "" then
        addon.chatMessage(" ")
        addon.addonMessage("Available commands:", addon.colors.INFO)
        addon.chatMessage("  /mpt debug - Toggle debug mode on/off", addon.colors.WHITE)
        addon.chatMessage("  /mpt debug on - Enable debug mode", addon.colors.WHITE)
        addon.chatMessage("  /mpt debug off - Disable debug mode", addon.colors.WHITE)
        addon.chatMessage("  /mpt help - Show this help", addon.colors.WHITE)
    else
        addon.errorMessage("Unknown command: " .. command)
        addon.infoMessage("Type '/mpt help' for available commands")
    end
end

-- Register slash commands
SLASH_MYTHICPLUSTRACKER1 = "/mpt"
SLASH_MYTHICPLUSTRACKER2 = "/mythicplustracker"
SlashCmdList["MYTHICPLUSTRACKER"] = handleSlashCommand

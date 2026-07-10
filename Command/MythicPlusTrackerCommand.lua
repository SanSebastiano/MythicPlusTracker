local addonName, addon = ...

local function handleSlashCommand(msg)
    local command = string.lower(string.trim(msg or ""))

    if command == "debug" then
        addon.setDebugMode()

    elseif command == "test" then
        C_MythicPlus.RequestMapInfo()
        print('C_MythicPlus.IsMythicPlusActive(): ' .. tostring(C_MythicPlus.IsMythicPlusActive()))
        print('C_MythicPlus.GetCurrentSeason(): ' .. C_MythicPlus.GetCurrentSeason())
        print('C_MythicPlus.GetRunHistory():')
         for i, run in ipairs(C_MythicPlus.GetRunHistory(true, true, true)) do
                local dateStr = ""
                if run.completionDate then
                    dateStr = string.format(" | Date: %04d-%02d-%02d %02d:%02d (Weekday: %d)",
                        run.completionDate.year,
                        run.completionDate.month,
                        run.completionDate.day,
                        run.completionDate.hour,
                        run.completionDate.minute,
                        run.completionDate.weekday
                    )
                end

                print(string.format(
                    "Run %d: MapID=%d, Level=%d, Score=%.1f, Duration=%ds, Completed=%s, ThisWeek=%s, Season=%d%s",
                    i,
                    run.mapChallengeModeID,
                    run.level,
                    run.runScore or 0,
                    run.durationSec or 0,
                    tostring(run.completed),
                    tostring(run.thisWeek),
                    run.season or 0,
                    dateStr
                ))
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

SLASH_MYTHICPLUSTRACKER1 = "/mpt"
SLASH_MYTHICPLUSTRACKER2 = "/mythicplustracker"
SlashCmdList["MYTHICPLUSTRACKER"] = handleSlashCommand

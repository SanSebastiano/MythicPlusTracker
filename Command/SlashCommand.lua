local addonName, addon = ...

---Developer-only diagnostic dump of the raw C_MythicPlus run data behind the
---Runs tab. Not listed in "/mpt help" — it exists to compare what the API
---reports against what the addon renders.
local function dumpRunHistoryDiagnostics()
    C_MythicPlus.RequestMapInfo()

    addon.chatMessage("C_MythicPlus.IsMythicPlusActive(): "
        .. tostring(C_MythicPlus.IsMythicPlusActive()), addon.colors.WHITE)
    addon.chatMessage("C_MythicPlus.GetCurrentSeason(): "
        .. tostring(C_MythicPlus.GetCurrentSeason()), addon.colors.WHITE)
    addon.chatMessage("C_MythicPlus.GetRunHistory():", addon.colors.WHITE)

    for i, run in ipairs(C_MythicPlus.GetRunHistory(true, true, true)) do
        local dateText = ""
        if run.completionDate then
            dateText = string.format(" | Date: %04d-%02d-%02d %02d:%02d (Weekday: %d)",
                run.completionDate.year,
                run.completionDate.month,
                run.completionDate.day,
                run.completionDate.hour,
                run.completionDate.minute,
                run.completionDate.weekday
            )
        end

        addon.chatMessage(string.format(
            "Run %d: MapID=%d, Level=%d, Score=%.1f, Duration=%ds, Completed=%s, ThisWeek=%s, Season=%d%s",
            i,
            run.mapChallengeModeID,
            run.level,
            run.runScore or 0,
            run.durationSec or 0,
            tostring(run.completed),
            tostring(run.thisWeek),
            run.season or 0,
            dateText
        ), addon.colors.WHITE)
    end
end

local function showHelp()
    addon.chatMessage(" ")
    addon.addonMessage("Available commands:", addon.colors.INFO)
    addon.chatMessage("  /mpt show - Show the tracker window", addon.colors.WHITE)
    addon.chatMessage("  /mpt settings - Open the settings panel", addon.colors.WHITE)
    addon.chatMessage("  /mpt announce - Post your current keystone to group/instance chat", addon.colors.WHITE)
    addon.chatMessage("  /mpt debug - Toggle debug mode on/off", addon.colors.WHITE)
    addon.chatMessage("  /mpt debug on - Enable debug mode", addon.colors.WHITE)
    addon.chatMessage("  /mpt debug off - Disable debug mode", addon.colors.WHITE)
    addon.chatMessage("  /mpt help - Show this help", addon.colors.WHITE)
end

local function handleSlashCommand(msg)
    local command = string.lower(string.trim(msg or "")) -- luacheck: ignore 143

    if command == "debug" then
        addon.setDebugMode()

    elseif command == "debug on" then
        addon.setDebugMode(true)

    elseif command == "debug off" then
        addon.setDebugMode(false)

    elseif command == "test" then
        dumpRunHistoryDiagnostics()

    elseif command == "show" then
        MPT_Tracker:show()

    elseif command == "settings" or command == "options" then
        MPT_Settings:open()

    elseif command == "announce" then
        addon.KeystoneService:announceToGroup()

    elseif command == "help" or command == "" then
        showHelp()

    else
        addon.errorMessage("Unknown command: " .. command)
        addon.infoMessage("Type '/mpt help' for available commands")
    end
end

SLASH_MYTHICPLUSTRACKER1 = "/mpt"
SLASH_MYTHICPLUSTRACKER2 = "/mythicplustracker"
SlashCmdList["MYTHICPLUSTRACKER"] = handleSlashCommand

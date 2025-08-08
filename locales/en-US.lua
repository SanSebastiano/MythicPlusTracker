local addonName, addon = ...

addon.locale = addon.locale or {}

local L = {
    ["WELCOME_MESSAGE"] = "%s v%s by %s loaded successfully!",
    ["WELCOME_MESSAGE_DEBUG"] = "Debug mode is enabled. Some features may be limited.",
    -- Mythic Plus specific messages
    ["KEYSTONE_UPGRADED"] = "Keystone upgraded to level %d!",
    ["KEYSTONE_DEPLETED"] = "Keystone depleted.",
    ["RUN_STARTED"] = "Mythic Plus run started!",
    ["RUN_ENDED"] = "Mythic Plus run ended.",
    ["RUN_FAILED"] = "Mythic Plus run failed.",
    ["RUN_SUCCESS"] = "Mythic Plus run completed successfully!",
    ["DUNGEON_STARTED"] = "Dungeon started: %s",
    ["DUNGEON_ENDED"] = "Dungeon ended: %s",
    ["DUNGEON_COMPLETED"] = "Dungeon completed!",
    ["TIMER_EXPIRED"] = "Timer expired",
    ["DEATHS"] = "Deaths: %d",
    ["KEYSTONE_LEVEL"] = "Keystone Level: %d"
}

for key, value in pairs(L) do
    addon.locale[key] = value
end

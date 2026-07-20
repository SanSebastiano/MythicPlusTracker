local addonName, addon = ...

addon.locale = addon.locale or {}

local locale = {
    ["WELCOME_MESSAGE"] = "%s v%s by %s loaded successfully!",
    ["WELCOME_MESSAGE_DEBUG"] = "Debug mode is enabled. Some features may be limited.",
    -- Minimap Button
    ["MINIMAP_BUTTON_NAME"] = "Mythic Plus Tracker",
    ["MINIMAP_BUTTON_CLICK_LEFT"] = "Left Click: Toggle Dashboard",
    ["MINIMAP_BUTTON_CLICK_RIGHT"] = "Right Click: Open Great Vault",
    ["MINIMAP_BUTTON_DRAG"] = "Drag: Move along minimap edge (Shift+Drag: Move freely)",
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
    ["KEYSTONE_LEVEL"] = "Keystone Level: %d",
    ["SIDEBAR_NO_KEYSTONE"] = "No keystone in bag",
    ["SIDEBAR_KEYSTONE_LEVEL"] = "Key Level",
    ["SIDEBAR_VAULT_TITLE"] = "Weekly Vault",
    ["SIDEBAR_VAULT_SLOT"] = "Slot %d",
    ["SIDEBAR_VAULT_UNLOCK_RUNS"] = "Complete %d more M+ to unlock",
    ["SIDEBAR_VAULT_PROGRESS"] = "%d / %d M+ runs completed",
    ["SIDEBAR_VAULT_REWARD_ILVL"] = "Reward Item Level: %d",
    ["SIDEBAR_VAULT_KEY_LEVEL"] = "Best Run: M+%d",
    ["SIDEBAR_VAULT_NOT_AVAILABLE"] = "–",
    ["SIDEBAR_VAULT_UNLOCKED"] = "Unlocked",
    ["SIDEBAR_VAULT_TOP_RUNS"] = "Top Runs This Week:",
    ["DASHBOARD_NOT_MAX_LEVEL"] = "You have not reached max level yet.",
    -- Dashboard navigation tabs
    ["DASHBOARD_TAB_OVERVIEW"]  = "Overview",
    ["DASHBOARD_TAB_RUNS"]      = "Runs",
    ["DASHBOARD_TAB_KEYSTONES"] = "Keystones",
    -- Dungeon table column headers
    ["DUNGEON_COL_DUNGEON"]    = "Dungeon",
    ["DUNGEON_COL_BEST_LEVEL"] = "Level",
    ["DUNGEON_COL_SCORE"]      = "Score",
    ["DUNGEON_COL_RUNS"]       = "Runs",
    ["DUNGEON_COL_SUCCESS"]    = "Success",
    ["DUNGEON_COL_TIME_LIMIT"] = "Limit",
    ["DUNGEON_COL_BEST_TIME"]  = "Best Time",
    ["DUNGEON_TOOLTIP_TIME_LIMIT"] = "Time Limit",
    ["DUNGEON_TELEPORT_TOOLTIP"] = "Click to teleport",
    ["DUNGEON_TELEPORT_NOT_OWNED"] = "No teleport toy known or owned for this dungeon",
    -- Overview summary boxes
    ["DASHBOARD_SUMMARY_HIGHEST_KEY"]   = "Highest Keystone",
    ["DASHBOARD_SUMMARY_TOTAL_RUNS"]    = "Total Runs",
    ["DASHBOARD_SUMMARY_SUCCESS_RUNS"]  = "Successful Runs",
    -- Runs table column headers
    ["RUN_COL_DUNGEON"]   = "Dungeon",
    ["RUN_COL_LEVEL"]     = "Level",
    ["RUN_COL_COMPLETED"] = "Timed",
    ["RUN_COL_SCORE"]     = "Score",
    ["RUN_COL_DURATION"]  = "Time",
    ["RUN_COL_DATE"]      = "Date",
    ["RUN_COL_SEASON"]    = "Season",
    -- Runs table tooltips
    ["RUN_TOOLTIP_TIME_LIMIT"]    = "Time Limit",
    ["RUN_TOOLTIP_DUNGEON_SCORE"] = "Dungeon Score",
    -- Dashboard
    ["DASHBOARD_OVERALL"] = "Overall",
    ["DASHBOARD_WEEKLY"] = "Weekly",
    ["DASHBOARD_BEST"] = "Best",
    ["DASHBOARD_RUNS"] = "Runs",
    ["DASHBOARD_SUCCESS"] = "Success",
    ["DASHBOARD_RUN_TIME"] = "Time",
    -- Sidebar: Runs tab
    ["SIDEBAR_RUNS_BEST_RUN"]    = "Best Run",
    ["SIDEBAR_RUNS_NO_RUNS"]     = "No successful Mythic Plus run completed yet.",
    ["SIDEBAR_RUNS_TIER_HEADER"] = "Timed Runs",
    ["SIDEBAR_GROUP_HEADER"]     = "Group",
    ["SIDEBAR_GROUP_NO_MEMBERS"] = "Not currently in a group.",
    -- Keystones tab: group keystone overview
    ["KEYSTONES_COL_PLAYER"]  = "Player",
    ["KEYSTONES_COL_DUNGEON"] = "Dungeon",
    ["KEYSTONES_COL_LEVEL"]   = "Level",
    ["KEYSTONES_NO_ADDON"]    = "No addon",
    ["KEYSTONES_NO_KEY"]      = "No key",
    ["KEYSTONES_REFRESH_TOOLTIP"] = "Refresh group view",
    -- Settings panel
    ["SETTINGS_CATEGORY_NAME"]         = "Mythic Plus Tracker",
    ["SETTINGS_DEBUG_MODE_LABEL"]      = "Debug Mode",
    ["SETTINGS_DEBUG_MODE_TOOLTIP"]    = "Prints additional diagnostic messages to the chat window.",
    ["SETTINGS_MINIMAP_BUTTON_LABEL"]  = "Show Minimap Button",
    ["SETTINGS_MINIMAP_BUTTON_TOOLTIP"] = "Shows or hides the Mythic Plus Tracker minimap button.",
    ["SETTINGS_WELCOME_MESSAGE_LABEL"]  = "Show Welcome Message",
    ["SETTINGS_WELCOME_MESSAGE_TOOLTIP"] = "Shows or hides the Mythic Plus Tracker welcome message on login.",
}

for key, value in pairs(locale) do
    addon.locale[key] = value
end

local addonName, addon = ...

-- Color definitions
addon.colors = {
    -- Base colors
    WHITE = "|cFFFFFFFF",
    BLACK = "|cFF000000",
    RED = "|cFFFF0000",
    GREEN = "|cFF00FF00",
    BLUE = "|cFF0000FF",

    -- WoW-specific colors
    GOLD = "|cFFFFD700",
    ORANGE = "|cFFFF8C00",
    YELLOW = "|cFFFFFF00",
    PURPLE = "|cFF9932CC",
    PINK = "|cFFFF69B4",

    -- Quality colors (WoW Item Quality)
    POOR = "|cFF9d9d9d",        -- Gray
    COMMON = "|cFFffffff",      -- White
    UNCOMMON = "|cFF1eff00",    -- Green
    RARE = "|cFF0070dd",        -- Blue
    EPIC = "|cFFa335ee",        -- Purple
    LEGENDARY = "|cFFff8000",   -- Orange
    ARTIFACT = "|cFFe6cc80",    -- Golden
    HEIRLOOM = "|cFFe6cc80",    -- Golden

    -- UI-specific colors
    ERROR = "|cFFFF0000",       -- Red for error messages
    SUCCESS = "|cFF00FF00",     -- Green for success messages
    WARNING = "|cFFFFFF00",     -- Yellow for warnings
    INFO = "|cFF00BFFF",        -- Light blue for information

    -- Mythic Plus specific colors
    KEYSTONE_LEVEL_LOW = "|cFF1eff00",     -- Green for low levels (2-4)
    KEYSTONE_LEVEL_MID = "|cFF0070dd",     -- Blue for mid levels (5-9)
    KEYSTONE_LEVEL_HIGH = "|cFFa335ee",    -- Purple for high levels (10-14)
    KEYSTONE_LEVEL_VERY_HIGH = "|cFFff8000", -- Orange for very high levels (15+)

    -- Timer colors
    TIMER_SUCCESS = "|cFF00FF00",   -- Green for successful timers
    TIMER_WARNING = "|cFFFFFF00",   -- Yellow for close timers
    TIMER_DANGER = "|cFFFF0000",    -- Red for missed timers

    -- Reset code (to end colors)
    RESET = "|r"
}

-- Function for keystone level colors
addon.colorKeystoneLevel = function(level)
    local levelNum = tonumber(level)
    if not levelNum then
        return addon.colors.WHITE
    end

    if levelNum <= 4 then
        return addon.colors.KEYSTONE_LEVEL_LOW
    elseif levelNum <= 9 then
        return addon.colors.KEYSTONE_LEVEL_MID
    elseif levelNum <= 14 then
        return addon.colors.KEYSTONE_LEVEL_HIGH
    else
        return addon.colors.KEYSTONE_LEVEL_VERY_HIGH
    end
end

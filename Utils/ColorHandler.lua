local addonName, addon = ...

addon.colors = {
    WHITE = "|cFFFFFFFF",
    BLACK = "|cFF000000",
    RED = "|cFFFF0000",
    GREEN = "|cFF00FF00",
    BLUE = "|cFF0000FF",

    GOLD = "|cFFFFD700",
    ORANGE = "|cFFFF8C00",
    YELLOW = "|cFFFFFF00",
    PURPLE = "|cFF9932CC",
    PINK = "|cFFFF69B4",

    POOR = "|cFF9d9d9d",
    COMMON = "|cFFffffff",
    UNCOMMON = "|cFF1eff00",
    RARE = "|cFF0070dd",
    EPIC = "|cFFa335ee",
    LEGENDARY = "|cFFff8000",
    ARTIFACT = "|cFFe6cc80",
    HEIRLOOM = "|cFF00ccff",

    ERROR = "|cFFFF0000",
    SUCCESS = "|cFF00FF00",
    WARNING = "|cFFFFFF00",
    INFO = "|cFF00BFFF",

    KEYSTONE_LEVEL_LOW = "|cFF1eff00",
    KEYSTONE_LEVEL_MID = "|cFF0070dd",
    KEYSTONE_LEVEL_HIGH = "|cFFa335ee",
    KEYSTONE_LEVEL_VERY_HIGH = "|cFFff8000",

    TIMER_SUCCESS = "|cFF00FF00",
    TIMER_WARNING = "|cFFFFFF00",
    TIMER_DANGER = "|cFFFF0000",

    RESET = "|r"
}

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

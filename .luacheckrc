-- luacheck configuration for MythicPlusTracker
-- WoW addons run on Lua 5.1

std = "lua51"

-- Ignore the "defined but not used" warning for the addon vararg pattern
-- Every file starts with: local addonName, addon = ...
unused_args = false

-- Allow defining globals in files (WoW addon pattern)
allow_defined = true

-- Increase the max line length slightly (WoW UI code can be verbose)
max_line_length = 160

-- Files / directories to exclude
exclude_files = {
    ".luarocks/**",
}

-- Translated UI strings vary a lot in length across locales; don't enforce
-- the code line-length limit on locale tables.
files["Locales/*.lua"] = {
    max_line_length = false,
}

ignore = {
    -- `local addonName, addon = ...` is present in every file; addonName is
    -- rarely used but is part of the required vararg destructuring pattern.
    "211/addonName",
    "211/addon",

    -- Set by this addon but only ever read by the WoW client itself.
    "131/SLASH_MYTHICPLUSTRACKER1",
    "131/SLASH_MYTHICPLUSTRACKER2",

    -- WoW frame callbacks conventionally receive their frame as `self`,
    -- which intentionally shadows an outer method's `self`.
    "432/self",
}

-- ---------------------------------------------------------------------------
-- WoW Lua global whitelist
-- These globals are injected by the WoW client and not defined in Lua source.
-- ---------------------------------------------------------------------------

globals = {
    -- -----------------------------------------------------------------------
    -- Addon-specific module globals (MPT_* pattern)
    -- -----------------------------------------------------------------------
    "MPT_Dashboard",
    "MPT_MAIN",
    "MPT_Sidebar",

    -- -----------------------------------------------------------------------
    -- WoW Addon loading system
    -- -----------------------------------------------------------------------
    "IsAddOnLoaded",
    "GetAddOnMetadata",
    "DisableAddOn",
    "EnableAddOn",

    -- -----------------------------------------------------------------------
    -- WoW slash command system
    -- -----------------------------------------------------------------------
    "SlashCmdList",
    "SLASH_MPT1",
    "SLASH_MPT2",
    "SLASH_MYTHICPLUSTRACKER1",
    "SLASH_MYTHICPLUSTRACKER2",

    -- -----------------------------------------------------------------------
    -- WoW C_ API namespaces (used in this addon)
    -- -----------------------------------------------------------------------
    "C_MythicPlus",
    "C_ChallengeMode",
    "C_Container",
    "C_Timer",
    "C_Item",
    "C_PlayerInfo",
    "C_Seasons",
    "C_CurrencyInfo",
    "C_WeeklyRewards",
    "C_Map",
    "C_Texture",
    "C_UI",
    "C_ChatInfo",
    "C_AddOns",
    "C_SpellBook",
    "C_Spell",
    "C_Traits",
    "C_DateAndTime",
    "C_GuildInfo",
    "Enum",

    -- -----------------------------------------------------------------------
    -- WoW locale detection
    -- -----------------------------------------------------------------------
    "GAME_LOCALE",
    "GetLocale",

    -- -----------------------------------------------------------------------
    -- WoW modern Settings API
    -- -----------------------------------------------------------------------
    "Settings",

    -- -----------------------------------------------------------------------
    -- WoW modern scroll framework (MinimalScrollBar wiring)
    -- -----------------------------------------------------------------------
    "ScrollUtil",

    -- -----------------------------------------------------------------------
    -- WoW combat / input state
    -- -----------------------------------------------------------------------
    "InCombatLockdown",
    "GetCursorPosition",
    "IsShiftKeyDown",

    -- -----------------------------------------------------------------------
    -- WoW built-in frames referenced by this addon
    -- -----------------------------------------------------------------------
    "UISpecialFrames",
    "WeeklyRewardsFrame",
    "WeeklyRewardsActivityMixin",
    "WeeklyRewards_ShowUI",
    "PVEFrame",
    "PVEFrame_ToggleFrame",

    -- -----------------------------------------------------------------------
    -- WoW UI frame factory & parenting
    -- -----------------------------------------------------------------------
    "CreateFrame",
    "UIParent",
    "WorldFrame",
    "GameMenuFrame",

    -- -----------------------------------------------------------------------
    -- WoW tooltip globals
    -- -----------------------------------------------------------------------
    "GameTooltip",
    "ItemRefTooltip",

    -- -----------------------------------------------------------------------
    -- WoW chat globals
    -- -----------------------------------------------------------------------
    "DEFAULT_CHAT_FRAME",
    "ChatFrame_AddMessageEventFilter",
    "ChatFrame_RemoveMessageEventFilter",
    "SendChatMessage",

    -- -----------------------------------------------------------------------
    -- WoW unit / player functions
    -- -----------------------------------------------------------------------
    "UnitLevel",
    "UnitName",
    "UnitClass",
    "UnitExists",
    "UnitIsPlayer",
    "GetMaxPlayerLevel",
    "IsInGroup",
    "IsInRaid",
    "IsInGuild",
    "GetNumGuildMembers",
    "GetGuildRosterInfo",
    "GetNumGroupMembers",
    "LE_PARTY_CATEGORY_INSTANCE",
    "GetRaidRosterInfo",
    "UnitFullName",
    "UnitGroupRolesAssigned",
    "GetNormalizedRealmName",
    "SetPortraitTexture",
    "GetSpecialization",
    "GetSpecializationRole",

    -- -----------------------------------------------------------------------
    -- WoW item / currency functions
    -- -----------------------------------------------------------------------
    "GetItemInfo",
    "GetItemIcon",
    "GetCurrencyInfo",
    "GetContainerNumSlots",
    "GetContainerItemInfo",
    "GetContainerItemLink",

    -- -----------------------------------------------------------------------
    -- WoW time & date
    -- -----------------------------------------------------------------------
    "GetTime",
    "GetServerTime",
    "GetTimePreciseSec",
    "date",
    "time",
    "difftime",

    -- -----------------------------------------------------------------------
    -- WoW event system
    -- -----------------------------------------------------------------------
    "RegisterEvent",
    "UnregisterEvent",

    -- -----------------------------------------------------------------------
    -- WoW sound
    -- -----------------------------------------------------------------------
    "PlaySound",
    "PlaySoundFile",
    "StopSound",

    -- -----------------------------------------------------------------------
    -- WoW minimap / LibDBIcon (common pattern)
    -- -----------------------------------------------------------------------
    "Minimap",
    "MinimapCluster",
    "MinimapBackdrop",

    -- -----------------------------------------------------------------------
    -- WoW table / string utility globals injected by WoW
    -- -----------------------------------------------------------------------
    "wipe",
    "tinsert",
    "tremove",
    "tContains",
    "tIndexOf",
    "tFilter",
    "tMap",
    "strtrim",
    "strsplit",
    "strjoin",
    "strsub",
    "strmatch",
    "strfind",
    "gsub",
    "format",

    -- -----------------------------------------------------------------------
    -- WoW screen / frame layout helpers
    -- -----------------------------------------------------------------------
    "GetScreenWidth",
    "GetScreenHeight",
    "GetPhysicalScreenSize",

    -- -----------------------------------------------------------------------
    -- WoW font objects
    -- -----------------------------------------------------------------------
    "GameFontNormal",
    "GameFontNormalLarge",
    "GameFontNormalSmall",
    "GameFontHighlight",
    "GameFontHighlightSmall",
    "GameFontHighlightLarge",
    "GameFontDisable",
    "GameFontDisableSmall",
    "GameFontDisableLarge",
    "NumberFont_Normal_Med",
    "NumberFont_Outline_Med",

    -- -----------------------------------------------------------------------
    -- WoW print / debug (we use addon helpers, but these exist in WoW env)
    -- -----------------------------------------------------------------------
    "print",
    "debugstack",
    "debuglocals",

    -- -----------------------------------------------------------------------
    -- Miscellaneous WoW globals
    -- -----------------------------------------------------------------------
    "GRAY_FONT_COLOR_CODE",
    "RED_FONT_COLOR_CODE",
    "GREEN_FONT_COLOR_CODE",
    "YELLOW_FONT_COLOR_CODE",
    "WHITE_FONT_COLOR_CODE",
    "FONT_COLOR_CODE_CLOSE",
    "NORMAL_FONT_COLOR_CODE",
    "HIGHLIGHT_FONT_COLOR_CODE",
    "CLASS_ICON_TCOORDS",
    "RAID_CLASS_COLORS",
}

local addonName, addon = ...

addon.theme = addon.theme or {}

-- Catalog of every static/decorative Atlas texture name used across the UI.
-- Edit the values below to re-skin the addon without touching any UI logic —
-- the same principle as swapping strings in Locales/en-US.lua for translations.
local theme = {
    FRAME_BACKGROUND      = "ui-frame-midnight-cardparchmentwider",
    FRAME_BORDER          = "ui-frame-midnight-border",
    CARD_TITLE_BACKGROUND = "ui-frame-midnight-border-title-bg",
    CARD_ICON_BACKGROUND  = "ui-frame-midnight-portraitdisable",
    TAB_BAR_LEFT          = "midnight-scenario-barframe-borderleft",
    TAB_BAR_RIGHT         = "midnight-scenario-barframe-borderright",
    TAB_BAR_CENTER        = "midnight-scenario-barframe-bordercenter",
    TAB_BAR_FILL          = "midnight-scenario-barfill",
    SIDEBAR_DIVIDER_BAR   = "midnight-scenario-bar-frame",
    SIDEBAR_DIVIDER_FILL  = "midnight-scenario-barfill",
    MINIMAP_BUTTON_ICON   = "mythicplus-greatvault-collect",
    MINIMAP_BUTTON_NORMAL_ICON = "Interface\\AddOns\\MythicPlusTracker\\mplus-icon-64.png",
    MINIMAP_BUTTON_NORMAL_BORDER = "Interface\\Minimap\\MiniMap-TrackingBorder",
    NOT_MAX_LEVEL_ICON    = "Bags-padlock-authenticator",
    RUN_COMPLETED_ICON    = "common-icon-checkmark",
    RUN_FAILED_ICON       = "common-icon-redx",
    GROUP_REFRESH_ICON    = "common-icon-undo",
    KEYSTONES_INFO_ICON   = "common-icon-undo",
    RUN_TIMED_HEADER_ICON = "icon_cooldownmanager",
    -- Recurring-quest crosshair glyphs. The atlas names don't reveal which
    -- symbol they hold: "!" while the quest is open, "?" once its objectives
    -- are done and it can be handed in, and a greyed-out "!" after turn-in.
    DUNGEON_BONUS_EVENT_ICON         = "Crosshair_Recurring_128",
    DUNGEON_BONUS_EVENT_TURN_IN_ICON = "Crosshair_Recurringturnin_128",
    DUNGEON_BONUS_EVENT_DONE_ICON    = "Crosshair_unableRecurring_128",
    -- Nine-slice border of the minimap quick-teleport flyout, matching
    -- Blizzard's own TooltipAzeriteLayout. The leading "_" (tiles horizontally)
    -- and "!" (tiles vertically) are part of the atlas name, not a marker —
    -- drop them and SetAtlas silently sets no texture at all.
    FLYOUT_BORDER_CORNER_TOP_LEFT     = "Tooltip-Azerite-NineSlice-CornerTopLeft",
    FLYOUT_BORDER_CORNER_TOP_RIGHT    = "Tooltip-Azerite-NineSlice-CornerTopRight",
    FLYOUT_BORDER_CORNER_BOTTOM_LEFT  = "Tooltip-Azerite-NineSlice-CornerBottomLeft",
    FLYOUT_BORDER_CORNER_BOTTOM_RIGHT = "Tooltip-Azerite-NineSlice-CornerBottomRight",
    FLYOUT_BORDER_EDGE_TOP            = "_Tooltip-Azerite-NineSlice-EdgeTop",
    FLYOUT_BORDER_EDGE_BOTTOM         = "_Tooltip-Azerite-NineSlice-EdgeBottom",
    FLYOUT_BORDER_EDGE_LEFT           = "!Tooltip-Azerite-NineSlice-EdgeLeft",
    FLYOUT_BORDER_EDGE_RIGHT          = "!Tooltip-Azerite-NineSlice-EdgeRight",
}

for key, value in pairs(theme) do
    addon.theme[key] = value
end

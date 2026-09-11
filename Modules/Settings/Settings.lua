local addonName, addon = ...

MPT_Settings = {}

MythicPlusTrackerDB = MythicPlusTrackerDB or {}

-- Every setting below is registered with Settings.RegisterProxySetting, and
-- that is structural rather than a matter of taste: RegisterAddOnSetting holds
-- on to the *table* it is handed at registration time. This function runs at
-- file scope, before WoW has restored the SavedVariables, so the table it would
-- capture is the throwaway {} from the MythicPlusTrackerDB = ... or {} line at
-- the top of this file. WoW then replaces the global with the loaded one, and
-- every write the Settings API makes lands in an orphan nothing else reads --
-- which is exactly how the "default to Keystones in a group" option managed to
-- do nothing at all from 1.4.0 on. Proxy getters/setters resolve the global by
-- name when they run, so they always reach the current table.
local function createSettingsPanel()
    local category, layout = Settings.RegisterVerticalLayoutCategory(addon.locale["SETTINGS_CATEGORY_NAME"])

    -- Section headers are inserted directly into the layout (not attached to
    -- any single setting); the template requires its data as a table
    -- ({ name = ... }), a bare string silently fails with a nil-call error.
    layout:AddInitializer(Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", { name = addon.locale["SETTINGS_SECTION_GENERAL_LABEL"] }))

    local function getWelcomeMessageShown()
        return not MythicPlusTrackerDB.welcomeMessageDisabled
    end

    local function setWelcomeMessageShown(value)
        MythicPlusTrackerDB.welcomeMessageDisabled = not value
    end

    -- Proxy for the reason given above the function, and a second one here: the
    -- stored flag is inverted (welcomeMessageDisabled) relative to what the
    -- checkbox displays (welcome message shown).
    local welcomeMessageSetting = Settings.RegisterProxySetting(
        category,
        "MPT_ShowWelcomeMessage",
        Settings.VarType.Boolean,
        addon.locale["SETTINGS_WELCOME_MESSAGE_LABEL"],
        true,
        getWelcomeMessageShown,
        setWelcomeMessageShown
    )
    Settings.CreateCheckbox(category, welcomeMessageSetting, addon.locale["SETTINGS_WELCOME_MESSAGE_TOOLTIP"])

    local function getDebugMode()
        return addon.isDebugMode()
    end

    -- Also writes the value through to SavedVariables and prints the on/off
    -- message, so display state and stored state cannot drift apart.
    local function setDebugMode(value)
        addon.setDebugMode(value)
    end

    local debugSetting = Settings.RegisterProxySetting(
        category,
        "MPT_DebugMode",
        Settings.VarType.Boolean,
        addon.locale["SETTINGS_DEBUG_MODE_LABEL"],
        false,
        getDebugMode,
        setDebugMode
    )
    Settings.CreateCheckbox(category, debugSetting, addon.locale["SETTINGS_DEBUG_MODE_TOOLTIP"])

    layout:AddInitializer(Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", { name = addon.locale["SETTINGS_SECTION_MINIMAP_LABEL"] }))

    local function getMinimapButtonShown()
        return not MythicPlusTrackerDB.minimapButtonHidden
    end

    local function setMinimapButtonShown(value)
        MythicPlusTrackerDB.minimapButtonHidden = not value
        MPT_MinimapButton:setHidden(not value)
    end

    -- Proxy setting again: the stored flag is inverted (minimapButtonHidden)
    -- and the setter must also forward the change to the live button frame.
    local minimapSetting = Settings.RegisterProxySetting(
        category,
        "MPT_ShowMinimapButton",
        Settings.VarType.Boolean,
        addon.locale["SETTINGS_MINIMAP_BUTTON_LABEL"],
        true,
        getMinimapButtonShown,
        setMinimapButtonShown
    )
    Settings.CreateCheckbox(category, minimapSetting, addon.locale["SETTINGS_MINIMAP_BUTTON_TOOLTIP"])

    local function getMinimapButtonStyle()
        local minimapButton = MythicPlusTrackerDB.minimapButton
        return (minimapButton and minimapButton.style) or "large"
    end

    local function setMinimapButtonStyle(value)
        MPT_MinimapButton:setStyle(value)
    end

    local function getMinimapButtonStyleOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add("large", addon.locale["MINIMAP_BUTTON_STYLE_LARGE"])
        container:Add("normal", addon.locale["MINIMAP_BUTTON_STYLE_NORMAL"])
        return container:GetData()
    end

    local minimapStyleSetting = Settings.RegisterProxySetting(
        category,
        "MPT_MinimapButtonStyle",
        Settings.VarType.String,
        addon.locale["SETTINGS_MINIMAP_BUTTON_STYLE_LABEL"],
        "large",
        getMinimapButtonStyle,
        setMinimapButtonStyle
    )
    Settings.CreateDropdown(category, minimapStyleSetting, getMinimapButtonStyleOptions, addon.locale["SETTINGS_MINIMAP_BUTTON_STYLE_TOOLTIP"])

    -- Both flyout settings are proxies: the stored flag is inverted (as with
    -- the minimap button above) and the delay has to reach the live frame so a
    -- hover timer that is already counting down gets dropped.
    local function getTeleportFlyoutShown()
        return MPT_MinimapTeleportFlyout:isEnabled()
    end

    local function setTeleportFlyoutShown(value)
        MPT_MinimapTeleportFlyout:setEnabled(value)
    end

    local teleportFlyoutSetting = Settings.RegisterProxySetting(
        category,
        "MPT_ShowMinimapTeleportFlyout",
        Settings.VarType.Boolean,
        addon.locale["SETTINGS_MINIMAP_TELEPORT_FLYOUT_LABEL"],
        true,
        getTeleportFlyoutShown,
        setTeleportFlyoutShown
    )
    Settings.CreateCheckbox(category, teleportFlyoutSetting, addon.locale["SETTINGS_MINIMAP_TELEPORT_FLYOUT_TOOLTIP"])

    local function getTeleportFlyoutOrientation()
        return MPT_MinimapTeleportFlyout:getOrientation()
    end

    local function setTeleportFlyoutOrientation(value)
        MPT_MinimapTeleportFlyout:setOrientation(value)
    end

    local function getTeleportFlyoutOrientationOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add("horizontal", addon.locale["TELEPORT_FLYOUT_ORIENTATION_HORIZONTAL"])
        container:Add("vertical", addon.locale["TELEPORT_FLYOUT_ORIENTATION_VERTICAL"])
        return container:GetData()
    end

    local teleportFlyoutOrientationSetting = Settings.RegisterProxySetting(
        category,
        "MPT_MinimapTeleportFlyoutOrientation",
        Settings.VarType.String,
        addon.locale["SETTINGS_MINIMAP_TELEPORT_FLYOUT_ORIENTATION_LABEL"],
        "horizontal",
        getTeleportFlyoutOrientation,
        setTeleportFlyoutOrientation
    )
    Settings.CreateDropdown(
        category,
        teleportFlyoutOrientationSetting,
        getTeleportFlyoutOrientationOptions,
        addon.locale["SETTINGS_MINIMAP_TELEPORT_FLYOUT_ORIENTATION_TOOLTIP"]
    )

    local function getTeleportFlyoutDelay()
        return MPT_MinimapTeleportFlyout:getHoverDelay()
    end

    local function setTeleportFlyoutDelay(value)
        MPT_MinimapTeleportFlyout:setHoverDelay(value)
    end

    local minimumDelay, maximumDelay, delayStep, defaultDelay = MPT_MinimapTeleportFlyout:getHoverDelayBounds()

    local teleportFlyoutDelaySetting = Settings.RegisterProxySetting(
        category,
        "MPT_MinimapTeleportFlyoutDelay",
        Settings.VarType.Number,
        addon.locale["SETTINGS_MINIMAP_TELEPORT_FLYOUT_DELAY_LABEL"],
        defaultDelay,
        getTeleportFlyoutDelay,
        setTeleportFlyoutDelay
    )
    -- Without a label formatter the slider renders as a bare track, with no way
    -- to tell 0.5s from 3s. Right is where Blizzard's own sliders put the
    -- current value.
    local delaySliderOptions = Settings.CreateSliderOptions(minimumDelay, maximumDelay, delayStep)
    delaySliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
        return addon.formatSeconds(value)
    end)

    Settings.CreateSlider(
        category,
        teleportFlyoutDelaySetting,
        delaySliderOptions,
        addon.locale["SETTINGS_MINIMAP_TELEPORT_FLYOUT_DELAY_TOOLTIP"]
    )

    layout:AddInitializer(Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", { name = addon.locale["SETTINGS_SECTION_DASHBOARD_LABEL"] }))

    -- Proxy for the orphaned-table reason spelled out at the debug setting
    -- above. No value-changed callback is needed: Dashboard.lua reads this flag
    -- fresh on every OnShow, so the next time the window opens it is current.
    local function getDashboardDefaultTabInGroup()
        return MythicPlusTrackerDB.dashboardDefaultTabInGroup == true
    end

    local function setDashboardDefaultTabInGroup(value)
        MythicPlusTrackerDB.dashboardDefaultTabInGroup = value
    end

    local dashboardDefaultTabSetting = Settings.RegisterProxySetting(
        category,
        "MPT_DashboardDefaultTabInGroup",
        Settings.VarType.Boolean,
        addon.locale["SETTINGS_DASHBOARD_DEFAULT_TAB_LABEL"],
        false,
        getDashboardDefaultTabInGroup,
        setDashboardDefaultTabInGroup
    )
    Settings.CreateCheckbox(category, dashboardDefaultTabSetting, addon.locale["SETTINGS_DASHBOARD_DEFAULT_TAB_TOOLTIP"])

    local function getBonusEventIconShown()
        return not MythicPlusTrackerDB.bonusEventIconHidden
    end

    local function setBonusEventIconShown(value)
        MythicPlusTrackerDB.bonusEventIconHidden = not value
        MPT_Dashboard:refreshBonusEventIcon()
    end

    -- Proxy setting for the same two reasons as the minimap button above: the
    -- stored flag is inverted, so a missing field (an older saved-variables
    -- file) still means "shown", and the setter has to reach a tracker window
    -- that may already be open behind the settings panel.
    local bonusEventIconSetting = Settings.RegisterProxySetting(
        category,
        "MPT_ShowDungeonBonusEventIcon",
        Settings.VarType.Boolean,
        addon.locale["SETTINGS_BONUS_EVENT_ICON_LABEL"],
        true,
        getBonusEventIconShown,
        setBonusEventIconShown
    )
    Settings.CreateCheckbox(category, bonusEventIconSetting, addon.locale["SETTINGS_BONUS_EVENT_ICON_TOOLTIP"])

    Settings.RegisterAddOnCategory(category)

    MPT_Settings.category = category
end

function MPT_Settings:open()
    if self.category then
        Settings.OpenToCategory(self.category:GetID())
    end
end

createSettingsPanel()

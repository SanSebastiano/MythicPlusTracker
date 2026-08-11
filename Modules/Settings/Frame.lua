local addonName, addon = ...

MythicPlusTrackerDB = MythicPlusTrackerDB or {}

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

    -- RegisterProxySetting (rather than RegisterAddOnSetting) is used here
    -- because the stored flag is inverted (welcomeMessageDisabled) relative
    -- to what the checkbox displays (welcome message shown).
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

    local debugSetting = Settings.RegisterAddOnSetting(
        category,
        "MPT_DebugMode",
        "debugMode",
        MythicPlusTrackerDB,
        Settings.VarType.Boolean,
        addon.locale["SETTINGS_DEBUG_MODE_LABEL"],
        false
    )
    debugSetting:SetValueChangedCallback(function(setting, value)
        addon.setDebugMode(value)
    end)
    Settings.CreateCheckbox(category, debugSetting, addon.locale["SETTINGS_DEBUG_MODE_TOOLTIP"])

    layout:AddInitializer(Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", { name = addon.locale["SETTINGS_SECTION_MINIMAP_LABEL"] }))

    local function getMinimapButtonShown()
        return not MythicPlusTrackerDB.minimapButtonHidden
    end

    local function setMinimapButtonShown(value)
        MythicPlusTrackerDB.minimapButtonHidden = not value
        MPT_MinimapButton:SetHidden(not value)
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
        MPT_MinimapButton:SetStyle(value)
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

    layout:AddInitializer(Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", { name = addon.locale["SETTINGS_SECTION_DASHBOARD_LABEL"] }))

    local dashboardDefaultTabSetting = Settings.RegisterAddOnSetting(
        category,
        "MPT_DashboardDefaultTabInGroup",
        "dashboardDefaultTabInGroup",
        MythicPlusTrackerDB,
        Settings.VarType.Boolean,
        addon.locale["SETTINGS_DASHBOARD_DEFAULT_TAB_LABEL"],
        false
    )
    Settings.CreateCheckbox(category, dashboardDefaultTabSetting, addon.locale["SETTINGS_DASHBOARD_DEFAULT_TAB_TOOLTIP"])

    Settings.RegisterAddOnCategory(category)

    MPT_Settings.category = category
end

function MPT_Settings:Open()
    if self.category then
        Settings.OpenToCategory(self.category:GetID())
    end
end

createSettingsPanel()

local addonName, addon = ...

MythicPlusTrackerDB = MythicPlusTrackerDB or {}

local function createSettingsPanel()
    local category = Settings.RegisterVerticalLayoutCategory(addon.locale["SETTINGS_CATEGORY_NAME"])

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

    local function getMinimapButtonShown()
        return not MythicPlusTrackerDB.minimapButtonHidden
    end

    local function setMinimapButtonShown(value)
        MythicPlusTrackerDB.minimapButtonHidden = not value
        MPT_MinimapButton:SetHidden(not value)
    end

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

    local function getWelcomeMessageShown()
        return not MythicPlusTrackerDB.welcomeMessageDisabled
    end

    local function setWelcomeMessageShown(value)
        MythicPlusTrackerDB.welcomeMessageDisabled = not value
    end

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

    Settings.RegisterAddOnCategory(category)

    MPT_Settings.category = category
end

function MPT_Settings:Open()
    if self.category then
        Settings.OpenToCategory(self.category:GetID())
    end
end

createSettingsPanel()

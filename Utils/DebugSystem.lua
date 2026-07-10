local addonName, addon = ...

MythicPlusTrackerDB = MythicPlusTrackerDB or {}

local function initializeDebugSystem()
    addon.debugMode = MythicPlusTrackerDB.debugMode or false
end

local function saveDebugState()
    MythicPlusTrackerDB.debugMode = addon.debugMode
end

---Toggle debug mode on/off and save state
---@param enabled boolean|nil If provided, sets debug mode to this value. If nil, toggles current state
---@return void
addon.setDebugMode = function(enabled)
    if enabled == nil then
        addon.debugMode = not addon.debugMode
    else
        addon.debugMode = enabled
    end

    saveDebugState()

    if addon.debugMode then
        addon.successMessage("Debug mode ENABLED")
    else
        addon.infoMessage("Debug mode DISABLED")
    end
end

addon.debugMessage = function(text, color)
    if addon.debugMode then
        local debugColor = color or addon.colors.WHITE
        addon.addonMessage("[DEBUG] " .. text, debugColor)
    end
end

addon.isDebugMode = function()
    return addon.debugMode or false
end

local debugFrame = CreateFrame("Frame")
debugFrame:RegisterEvent("ADDON_LOADED")
debugFrame:RegisterEvent("PLAYER_LOGIN")
debugFrame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if event == "ADDON_LOADED" and loadedAddonName == addonName then
        initializeDebugSystem()
    elseif event == "PLAYER_LOGIN" then
        initializeDebugSystem()
        debugFrame:UnregisterAllEvents()
    end
end)

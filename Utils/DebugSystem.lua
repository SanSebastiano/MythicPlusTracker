local addonName, addon = ...

-- Saved Variables for persistent debug state
MythicPlusTrackerDB = MythicPlusTrackerDB or {}

---Initialize debug system with saved variables
---@return void
local function initializeDebugSystem()
    -- Load debug state from saved variables
    addon.debugMode = MythicPlusTrackerDB.debugMode or false
end

---Save debug state to saved variables
---@return void
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

---Send a debug message if debug mode is enabled
---@param text string The debug message text
---@param color string|nil Optional color for the debug message
---@return void
addon.debugMessage = function(text, color)
    if addon.debugMode then
        local debugColor = color or addon.colors.PURPLE
        addon.addonMessage("[DEBUG] " .. text, debugColor)
    end
end

---Get current debug mode status
---@return boolean Current debug mode state
addon.isDebugMode = function()
    return addon.debugMode or false
end

-- Initialize debug system when addon loads
local debugFrame = CreateFrame("Frame")
debugFrame:RegisterEvent("ADDON_LOADED")
debugFrame:RegisterEvent("PLAYER_LOGIN")
debugFrame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if event == "ADDON_LOADED" and loadedAddonName == addonName then
        initializeDebugSystem()
    elseif event == "PLAYER_LOGIN" then
        -- Ensure debug state is properly loaded after all addons are loaded
        initializeDebugSystem()
        debugFrame:UnregisterAllEvents()
    end
end)

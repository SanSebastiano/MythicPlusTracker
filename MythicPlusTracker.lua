local addonName, addon = ...

-- Main addon namespace
addon.MythicPlusTracker = addon.MythicPlusTracker or {}
local MPT = addon.MythicPlusTracker

-- Addon state
MPT.isLoaded = false

-- Initialization
function MPT:Initialize()
    if self.isLoaded then
        return
    end

    self.isLoaded = true
end

-- Event frame for main logic
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName == addonName then
        end
    elseif event == "PLAYER_LOGIN" then
        MPT:Initialize()
        frame:UnregisterEvent("PLAYER_LOGIN")
    end
end)

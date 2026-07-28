local addonName, addon = ...

addon.MythicPlusTracker = addon.MythicPlusTracker or {}
local MPT = addon.MythicPlusTracker

MPT.isLoaded = false

function MPT:Initialize()
    if self.isLoaded then
        return
    end

    self.isLoaded = true
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    MPT:Initialize()
    frame:UnregisterEvent("PLAYER_LOGIN")
end)

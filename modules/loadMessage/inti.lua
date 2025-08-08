local addonName, addon = ...

local function getAddonMetadata()
    return C_AddOns.GetAddOnMetadata(addonName, "Title") or addonName,
            C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0",
            C_AddOns.GetAddOnMetadata(addonName, "Author") or "SanSebastiano"
end

local function ShowWelcomeMessage()
    local title, version, author = getAddonMetadata()
    local L = addon.locale

    if not L then
        print(string.format("|cFFFF0000 %s: Locale not loaded yet!|r"), addonName)
        return
    end

    print("|cFFE6CC80" .. string.format(L["WELCOME_MESSAGE"], title, version, author) .. "|r")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if loadedAddonName == addonName then
        C_Timer.After(2, ShowWelcomeMessage)
        frame:UnregisterEvent("ADDON_LOADED")
    end
end)

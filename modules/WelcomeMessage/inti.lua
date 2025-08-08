local addonName, addon = ...

local function getAddonMetadata()
    return C_AddOns.GetAddOnMetadata(addonName, "Title") or addonName,
            C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0",
            C_AddOns.GetAddOnMetadata(addonName, "Author") or "SanSebastiano"
end

local function ShowWelcomeMessage()
    local title, version, author = getAddonMetadata()
    local locale = addon.locale

    if not locale then
        print(addon.errorMessage(string.format("%s: Locale not loaded yet!", addonName)))
        return
    end

    print(addon.coloredMessage(string.format(locale["WELCOME_MESSAGE"], title, version, author), addon.colors.ARTIFACT))
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if loadedAddonName == addonName then
        C_Timer.After(2, ShowWelcomeMessage)
        frame:UnregisterEvent("ADDON_LOADED")
    end
end)

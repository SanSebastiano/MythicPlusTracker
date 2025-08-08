local addonName, addon = ...

-- Haupt-AddOn-Namespace
addon.MythicPlusTracker = addon.MythicPlusTracker or {}
local MPT = addon.MythicPlusTracker

-- AddOn-Status
MPT.isLoaded = false

-- Initialisierungsfunktion
function MPT:Initialize()
    if self.isLoaded then
        return
    end

    -- Hier wird später die Hauptlogik für Mythic Plus Tracking stehen
    -- Zum Beispiel: Event-Handler für Dungeon-Events, UI-Elemente, etc.

    self.isLoaded = true
end

-- Event Frame für die Hauptlogik
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName == addonName then
            -- AddOn ist geladen, aber warten auf PLAYER_LOGIN für Initialisierung
        end
    elseif event == "PLAYER_LOGIN" then
        -- Spieler ist eingeloggt, jetzt können wir sicher initialisieren
        MPT:Initialize()
        frame:UnregisterEvent("PLAYER_LOGIN")
    end
end)

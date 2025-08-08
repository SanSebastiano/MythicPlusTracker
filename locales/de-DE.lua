if not ((GAME_LOCALE or GetLocale()) == "deDE") then
    return
end
local addonName, addon = ...

addon.locale = addon.locale or {}

local L = {
    ["WELCOME_MESSAGE"] = "%s v%s von %s erfolgreich geladen!",
    -- Mythic Plus specific messages
    ["KEYSTONE_UPGRADED"] = "Schlüsselstein auf Level %d aufgewertet!",
    ["KEYSTONE_DEPLETED"] = "Schlüsselstein erschöpft.",
    ["RUN_STARTED"] = "Mythic Plus Run gestartet!",
    ["RUN_ENDED"] = "Mythic Plus Run beendet.",
    ["RUN_FAILED"] = "Mythic Plus Run fehlgeschlagen.",
    ["RUN_SUCCESS"] = "Mythic Plus Run erfolgreich abgeschlossen!",
    ["DUNGEON_STARTED"] = "Dungeon gestartet: %s",
    ["DUNGEON_ENDED"] = "Dungeon beendet: %s",
    ["DUNGEON_COMPLETED"] = "Dungeon abgeschlossen!",
    ["TIMER_EXPIRED"] = "Zeit abgelaufen",
    ["DEATHS"] = "Tode: %d",
    ["KEYSTONE_LEVEL"] = "Schlüsselstein Level: %d"
}

for key, value in pairs(L) do
    addon.locale[key] = value
end

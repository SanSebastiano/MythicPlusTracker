if not ((GAME_LOCALE or GetLocale()) == "deDE") then
    return
end

local addonName, addon = ...

addon.locale = addon.locale or {}

local locale = {
    ["WELCOME_MESSAGE"] = "%s v%s von %s erfolgreich geladen!",
    ["WELCOME_MESSAGE_DEBUG"] = "Debug-Modus ist aktiviert. Einige Funktionen sind möglicherweise eingeschränkt.",
    -- Minimap Button
    ["MINIMAP_BUTTON_NAME"] = "Mythic Plus Tracker",
    ["MINIMAP_BUTTON_CLICK_LEFT"] = "Linksklick: Dashboard umschalten",
    ["MINIMAP_BUTTON_CLICK_RIGHT"] = "Rechtsklick: Große Schatzkammer öffnen",
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
    ["KEYSTONE_LEVEL"] = "Schlüsselstein Level: %d",
    ["SIDEBAR_NO_KEYSTONE"] = "Kein Schlüsselstein im Inventar",
    ["SIDEBAR_KEYSTONE_LEVEL"] = "Key Level",
    ["SIDEBAR_VAULT_TITLE"] = "Wochenkammer",
    ["SIDEBAR_VAULT_SLOT"] = "Slot %d",
    ["SIDEBAR_VAULT_UNLOCK_RUNS"] = "Noch %d M+-Runs zum Freischalten",
    ["SIDEBAR_VAULT_PROGRESS"] = "%d / %d M+-Runs absolviert",
    ["SIDEBAR_VAULT_REWARD_ILVL"] = "Belohnungs-Itemlevel: %d",
    ["SIDEBAR_VAULT_KEY_LEVEL"] = "Bester Run: M+%d",
    ["SIDEBAR_VAULT_NOT_AVAILABLE"] = "–",
    ["SIDEBAR_VAULT_UNLOCKED"] = "Freigeschaltet",
    ["SIDEBAR_VAULT_TOP_RUNS"] = "Top-Runs diese Woche:",
    ["DASHBOARD_NOT_MAX_LEVEL"] = "Du hast noch nicht die Höchststufe erreicht.",
    -- Dashboard navigation tabs
    ["DASHBOARD_TAB_OVERVIEW"]  = "Übersicht",
    ["DASHBOARD_TAB_RUNS"]      = "Läufe",
    ["DASHBOARD_TAB_KEYSTONES"] = "Schlüsselsteine",
    -- Dungeon table column headers
    ["DUNGEON_COL_DUNGEON"]    = "Dungeon",
    ["DUNGEON_COL_BEST_LEVEL"] = "Stufe",
    ["DUNGEON_COL_SCORE"]      = "Wertung",
    ["DUNGEON_COL_RUNS"]       = "Läufe",
    ["DUNGEON_COL_SUCCESS"]    = "Erfolge",
    ["DUNGEON_COL_TIME_LIMIT"] = "Limit",
    ["DUNGEON_COL_BEST_TIME"]  = "Beste Zeit",
    ["DUNGEON_TOOLTIP_TIME_LIMIT"] = "Zeitlimit",
    -- Overview summary boxes
    ["DASHBOARD_SUMMARY_HIGHEST_KEY"]   = "Höchster Schlüsselstein",
    ["DASHBOARD_SUMMARY_TOTAL_RUNS"]    = "Anzahl Läufe",
    ["DASHBOARD_SUMMARY_SUCCESS_RUNS"]  = "Erfolgreiche Läufe",
    -- Dashboard
    ["DASHBOARD_OVERALL"] = "Gesamt",
    ["DASHBOARD_WEEKLY"] = "Wöchentlich",
    ["DASHBOARD_BEST"] = "Bestes",
    ["DASHBOARD_RUNS"] = "Läufe",
    ["DASHBOARD_SUCCESS"] = "Erfolgreich",
    ["DASHBOARD_RUN_TIME"] = "Zeit",
}

for key, value in pairs(locale) do
    addon.locale[key] = value
end

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
    ["MINIMAP_BUTTON_DRAG"] = "Ziehen: Entlang der Minimap verschieben (Shift+Ziehen: Frei verschieben)",
    ["MINIMAP_BUTTON_DRAG_NORMAL"] = "Ziehen: Entlang der Minimap verschieben",
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
    ["DUNGEON_TELEPORT_TOOLTIP"] = "Klicken zum Teleportieren",
    ["DUNGEON_TELEPORT_NOT_OWNED"] = "Kein Teleport-Spielzeug für diesen Dungeon bekannt oder besessen",
    -- Overview summary boxes
    ["DASHBOARD_SUMMARY_HIGHEST_KEY"]   = "Höchster Schlüsselstein",
    ["DASHBOARD_SUMMARY_TOTAL_RUNS"]    = "Anzahl Läufe",
    ["DASHBOARD_SUMMARY_SUCCESS_RUNS"]  = "Erfolgreiche Läufe",
    -- Runs table column headers
    ["RUN_COL_DUNGEON"]   = "Dungeon",
    ["RUN_COL_LEVEL"]     = "Stufe",
    ["RUN_COL_COMPLETED"] = "Im Zeitlimit",
    ["RUN_COL_SCORE"]     = "Wertung",
    ["RUN_COL_DURATION"]  = "Zeit",
    ["RUN_COL_DATE"]      = "Datum",
    ["RUN_COL_SEASON"]    = "Season",
    -- Runs table tooltips
    ["RUN_TOOLTIP_TIME_LIMIT"]    = "Zeitlimit",
    ["RUN_TOOLTIP_DUNGEON_SCORE"] = "Dungeon-Wertung",
    -- Dashboard
    ["DASHBOARD_OVERALL"] = "Gesamt",
    ["DASHBOARD_WEEKLY"] = "Wöchentlich",
    ["DASHBOARD_BEST"] = "Bestes",
    ["DASHBOARD_RUNS"] = "Läufe",
    ["DASHBOARD_SUCCESS"] = "Erfolgreich",
    ["DASHBOARD_RUN_TIME"] = "Zeit",
    -- Sidebar: Runs tab
    ["SIDEBAR_RUNS_BEST_RUN"]    = "Bester Durchlauf",
    ["SIDEBAR_RUNS_NO_RUNS"]     = "Noch keinen erfolgreichen Mythisch Plus Lauf absolviert.",
    ["SIDEBAR_RUNS_TIER_HEADER"] = "Zeitliche Durchläufe",
    ["SIDEBAR_GROUP_HEADER"]     = "Gruppe",
    ["SIDEBAR_GROUP_NO_MEMBERS"] = "Aktuell in keiner Gruppe.",
    -- Keystones tab: group keystone overview
    ["KEYSTONES_COL_PLAYER"]  = "Spieler",
    ["KEYSTONES_COL_DUNGEON"] = "Dungeon",
    ["KEYSTONES_COL_LEVEL"]   = "Stufe",
    ["KEYSTONES_NO_ADDON"]    = "Kein Addon",
    ["KEYSTONES_NO_KEY"]      = "Kein Schlüsselstein",
    ["KEYSTONES_REFRESH_TOOLTIP"] = "Gruppenansicht aktualisieren",
    -- Settings panel
    ["SETTINGS_CATEGORY_NAME"]         = "Mythic Plus Tracker",
    ["SETTINGS_SECTION_GENERAL_LABEL"] = "Allgemein",
    ["SETTINGS_SECTION_MINIMAP_LABEL"] = "Minimap",
    ["SETTINGS_DEBUG_MODE_LABEL"]      = "Debug-Modus",
    ["SETTINGS_DEBUG_MODE_TOOLTIP"]    = "Zeigt zusätzliche Diagnosemeldungen im Chatfenster an.",
    ["SETTINGS_MINIMAP_BUTTON_LABEL"]  = "Minimap-Button anzeigen",
    ["SETTINGS_MINIMAP_BUTTON_TOOLTIP"] = "Zeigt oder versteckt den Mythic Plus Tracker Minimap-Button.",
    ["SETTINGS_MINIMAP_BUTTON_STYLE_LABEL"] = "Minimap-Button-Stil",
    ["SETTINGS_MINIMAP_BUTTON_STYLE_TOOLTIP"] = "Wähle den großen, frei verschiebbaren Button oder den normalen Button, nur am Minimap-Rand verschiebbar.",
    ["MINIMAP_BUTTON_STYLE_LARGE"] = "Groß",
    ["MINIMAP_BUTTON_STYLE_NORMAL"] = "Normal",
    ["SETTINGS_WELCOME_MESSAGE_LABEL"]  = "Willkommensnachricht anzeigen",
    ["SETTINGS_WELCOME_MESSAGE_TOOLTIP"] = "Zeigt oder versteckt die Mythic Plus Tracker Willkommensnachricht beim Login.",
}

for key, value in pairs(locale) do
    addon.locale[key] = value
end

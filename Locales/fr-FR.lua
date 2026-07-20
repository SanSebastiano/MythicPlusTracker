if not ((GAME_LOCALE or GetLocale()) == "frFR") then
    return
end

local addonName, addon = ...

addon.locale = addon.locale or {}

local locale = {
    ["WELCOME_MESSAGE"] = "%s v%s de %s chargé avec succès !",
    ["WELCOME_MESSAGE_DEBUG"] = "Le mode débogage est activé. Certaines fonctionnalités peuvent être limitées.",
    -- Minimap Button
    ["MINIMAP_BUTTON_NAME"] = "Mythic Plus Tracker",
    ["MINIMAP_BUTTON_CLICK_LEFT"] = "Clic gauche : Afficher/Masquer le tableau de bord",
    ["MINIMAP_BUTTON_CLICK_RIGHT"] = "Clic droit : Ouvrir le Grand Coffre",
    ["MINIMAP_BUTTON_DRAG"] = "Glisser : Déplacer le long de la minimap (Maj+Glisser : Déplacer librement)",
    -- Mythic Plus specific messages
    ["KEYSTONE_UPGRADED"] = "Clé mythique améliorée au niveau %d !",
    ["KEYSTONE_DEPLETED"] = "Clé mythique épuisée.",
    ["RUN_STARTED"] = "Donjon Mythique+ commencé !",
    ["RUN_ENDED"] = "Donjon Mythique+ terminé.",
    ["RUN_FAILED"] = "Le donjon Mythique+ a échoué.",
    ["RUN_SUCCESS"] = "Donjon Mythique+ réussi !",
    ["DUNGEON_STARTED"] = "Donjon commencé : %s",
    ["DUNGEON_ENDED"] = "Donjon terminé : %s",
    ["DUNGEON_COMPLETED"] = "Donjon terminé !",
    ["TIMER_EXPIRED"] = "Temps écoulé",
    ["DEATHS"] = "Morts : %d",
    ["KEYSTONE_LEVEL"] = "Niveau de clé : %d",
    ["SIDEBAR_NO_KEYSTONE"] = "Aucune clé mythique dans le sac",
    ["SIDEBAR_KEYSTONE_LEVEL"] = "Niveau de clé",
    ["SIDEBAR_VAULT_TITLE"] = "Coffre hebdomadaire",
    ["SIDEBAR_VAULT_SLOT"] = "Emplacement %d",
    ["SIDEBAR_VAULT_UNLOCK_RUNS"] = "Terminez %d M+ de plus pour débloquer",
    ["SIDEBAR_VAULT_PROGRESS"] = "%d / %d donjons M+ terminés",
    ["SIDEBAR_VAULT_REWARD_ILVL"] = "Niveau d'objet de la récompense : %d",
    ["SIDEBAR_VAULT_KEY_LEVEL"] = "Meilleur donjon : M+%d",
    ["SIDEBAR_VAULT_NOT_AVAILABLE"] = "–",
    ["SIDEBAR_VAULT_UNLOCKED"] = "Débloqué",
    ["SIDEBAR_VAULT_TOP_RUNS"] = "Meilleurs donjons de la semaine :",
    ["DASHBOARD_NOT_MAX_LEVEL"] = "Vous n'avez pas encore atteint le niveau maximum.",
    -- Dashboard navigation tabs
    ["DASHBOARD_TAB_OVERVIEW"]  = "Aperçu",
    ["DASHBOARD_TAB_RUNS"]      = "Donjons",
    ["DASHBOARD_TAB_KEYSTONES"] = "Clés mythiques",
    -- Dungeon table column headers
    ["DUNGEON_COL_DUNGEON"]    = "Donjon",
    ["DUNGEON_COL_BEST_LEVEL"] = "Niveau",
    ["DUNGEON_COL_SCORE"]      = "Score",
    ["DUNGEON_COL_RUNS"]       = "Donjons",
    ["DUNGEON_COL_SUCCESS"]    = "Réussite",
    ["DUNGEON_COL_TIME_LIMIT"] = "Limite",
    ["DUNGEON_COL_BEST_TIME"]  = "Meilleur temps",
    ["DUNGEON_TOOLTIP_TIME_LIMIT"] = "Limite de temps",
    ["DUNGEON_TELEPORT_TOOLTIP"] = "Cliquez pour vous téléporter",
    ["DUNGEON_TELEPORT_NOT_OWNED"] = "Aucun jouet de téléportation connu ou possédé pour ce donjon",
    -- Overview summary boxes
    ["DASHBOARD_SUMMARY_HIGHEST_KEY"]   = "Clé la plus élevée",
    ["DASHBOARD_SUMMARY_TOTAL_RUNS"]    = "Donjons totaux",
    ["DASHBOARD_SUMMARY_SUCCESS_RUNS"]  = "Donjons réussis",
    -- Runs table column headers
    ["RUN_COL_DUNGEON"]   = "Donjon",
    ["RUN_COL_LEVEL"]     = "Niveau",
    ["RUN_COL_COMPLETED"] = "Terminé",
    ["RUN_COL_SCORE"]     = "Score",
    ["RUN_COL_DURATION"]  = "Temps",
    ["RUN_COL_DATE"]      = "Date",
    ["RUN_COL_SEASON"]    = "Saison",
    -- Runs table tooltips
    ["RUN_TOOLTIP_TIME_LIMIT"]    = "Limite de temps",
    ["RUN_TOOLTIP_DUNGEON_SCORE"] = "Score du donjon",
    -- Dashboard
    ["DASHBOARD_OVERALL"] = "Global",
    ["DASHBOARD_WEEKLY"] = "Hebdomadaire",
    ["DASHBOARD_BEST"] = "Meilleur",
    ["DASHBOARD_RUNS"] = "Donjons",
    ["DASHBOARD_SUCCESS"] = "Réussite",
    ["DASHBOARD_RUN_TIME"] = "Temps",
    -- Sidebar: Runs tab
    ["SIDEBAR_RUNS_BEST_RUN"]    = "Meilleur donjon",
    ["SIDEBAR_RUNS_NO_RUNS"]     = "Aucun donjon Mythique+ réussi pour le moment.",
    ["SIDEBAR_RUNS_TIER_HEADER"] = "Donjons dans les temps",
    ["SIDEBAR_GROUP_HEADER"]     = "Groupe",
    ["SIDEBAR_GROUP_NO_MEMBERS"] = "Vous n'êtes actuellement pas en groupe.",
    -- Keystones tab: group keystone overview
    ["KEYSTONES_COL_PLAYER"]  = "Joueur",
    ["KEYSTONES_COL_DUNGEON"] = "Donjon",
    ["KEYSTONES_COL_LEVEL"]   = "Niveau",
    ["KEYSTONES_NO_ADDON"]    = "Aucun addon",
    ["KEYSTONES_NO_KEY"]      = "Aucune clé",
    -- Settings panel
    ["SETTINGS_CATEGORY_NAME"]         = "Mythic Plus Tracker",
    ["SETTINGS_DEBUG_MODE_LABEL"]      = "Mode débogage",
    ["SETTINGS_DEBUG_MODE_TOOLTIP"]    = "Affiche des messages de diagnostic supplémentaires dans la fenêtre de discussion.",
    ["SETTINGS_MINIMAP_BUTTON_LABEL"]  = "Afficher le bouton de la minimap",
    ["SETTINGS_MINIMAP_BUTTON_TOOLTIP"] = "Affiche ou masque le bouton de la minimap de Mythic Plus Tracker.",
    ["SETTINGS_WELCOME_MESSAGE_LABEL"]  = "Afficher le message de bienvenue",
    ["SETTINGS_WELCOME_MESSAGE_TOOLTIP"] = "Affiche ou masque le message de bienvenue de Mythic Plus Tracker à la connexion.",
}

for key, value in pairs(locale) do
    addon.locale[key] = value
end

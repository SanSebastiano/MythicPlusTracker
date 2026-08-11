if (GAME_LOCALE or GetLocale()) ~= "esES" then
    return
end

local addonName, addon = ...

addon.locale = addon.locale or {}

local locale = {
    ["WELCOME_MESSAGE"] = "¡%s v%s de %s se cargó correctamente!",
    ["WELCOME_MESSAGE_DEBUG"] = "El modo de depuración está activado. Algunas funciones pueden estar limitadas.",
    -- Minimap Button
    ["MINIMAP_BUTTON_NAME"] = "Mythic Plus Tracker",
    ["MINIMAP_BUTTON_CLICK_LEFT"] = "Clic izquierdo: Mostrar/Ocultar el panel",
    ["MINIMAP_BUTTON_CLICK_RIGHT"] = "Clic derecho: Abrir la Gran Bóveda",
    ["MINIMAP_BUTTON_DRAG"] = "Arrastrar: Mover a lo largo del borde del minimapa (Mayús+Arrastrar: Mover libremente)",
    ["MINIMAP_BUTTON_DRAG_NORMAL"] = "Arrastrar: Mover a lo largo del borde del minimapa",
    -- Mythic Plus specific messages
    ["KEYSTONE_UPGRADED"] = "¡Llave mítica mejorada al nivel %d!",
    ["KEYSTONE_DEPLETED"] = "Llave mítica agotada.",
    ["RUN_STARTED"] = "¡Mazmorra Mítica+ iniciada!",
    ["RUN_ENDED"] = "Mazmorra Mítica+ finalizada.",
    ["RUN_FAILED"] = "La mazmorra Mítica+ ha fallado.",
    ["RUN_SUCCESS"] = "¡Mazmorra Mítica+ completada con éxito!",
    ["DUNGEON_STARTED"] = "Mazmorra iniciada: %s",
    ["DUNGEON_ENDED"] = "Mazmorra finalizada: %s",
    ["DUNGEON_COMPLETED"] = "¡Mazmorra completada!",
    ["TIMER_EXPIRED"] = "Tiempo agotado",
    ["DEATHS"] = "Muertes: %d",
    ["KEYSTONE_LEVEL"] = "Nivel de llave: %d",
    ["SIDEBAR_NO_KEYSTONE"] = "No hay llave mítica en la bolsa",
    ["SIDEBAR_NO_AFFIXES"] = "No se encontraron afijos.",
    ["SIDEBAR_KEYSTONE_LEVEL"] = "Nivel de llave",
    ["KEYSTONE_ANNOUNCE_MESSAGE"] = "Mi llave mítica actual: %s",
    ["KEYSTONE_ANNOUNCE_NOT_IN_GROUP"] = "Debes estar en un grupo para anunciar tu llave mítica.",
    ["KEYSTONE_ANNOUNCE_NO_KEYSTONE"] = "No tienes ninguna llave mítica para anunciar.",
    ["SIDEBAR_VAULT_TITLE"] = "Bóveda semanal",
    ["SIDEBAR_VAULT_SLOT"] = "Ranura %d",
    ["SIDEBAR_VAULT_UNLOCK_RUNS"] = "Completa %d M+ más para desbloquear",
    ["SIDEBAR_VAULT_PROGRESS"] = "%d / %d mazmorras M+ completadas",
    ["SIDEBAR_VAULT_REWARD_ILVL"] = "Nivel de objeto de la recompensa: %d",
    ["SIDEBAR_VAULT_KEY_LEVEL"] = "Mejor mazmorra: M+%d",
    ["SIDEBAR_VAULT_NOT_AVAILABLE"] = "–",
    ["SIDEBAR_VAULT_UNLOCKED"] = "Desbloqueado",
    ["SIDEBAR_VAULT_TOP_RUNS"] = "Mejores mazmorras de la semana:",
    -- Sidebar: Overview tab section headers
    ["SIDEBAR_TRAITNODES_HEADER"] = "Runas de poder",
    ["SIDEBAR_CURRENCY_HEADER"]   = "Monedas",
    ["DASHBOARD_NOT_MAX_LEVEL"] = "Aún no has alcanzado el nivel máximo.",
    -- Dashboard navigation tabs
    ["DASHBOARD_TAB_OVERVIEW"]  = "Resumen",
    ["DASHBOARD_TAB_RUNS"]      = "Mazmorras",
    ["DASHBOARD_TAB_KEYSTONES"] = "Llaves míticas",
    -- Dungeon table column headers
    ["DUNGEON_COL_DUNGEON"]    = "Mazmorra",
    ["DUNGEON_COL_BEST_LEVEL"] = "Nivel",
    ["DUNGEON_COL_SCORE"]      = "Puntuación",
    ["DUNGEON_COL_RUNS"]       = "Mazmorras",
    ["DUNGEON_COL_SUCCESS"]    = "Éxito",
    ["DUNGEON_COL_TIME_LIMIT"] = "Límite",
    ["DUNGEON_COL_BEST_TIME"]  = "Mejor tiempo",
    ["DUNGEON_TOOLTIP_TIME_LIMIT"] = "Límite de tiempo",
    ["DUNGEON_TELEPORT_TOOLTIP"] = "Haz clic para teletransportarte",
    ["DUNGEON_TELEPORT_NOT_OWNED"] = "No se conoce ni se posee ningún juguete de teletransporte para esta mazmorra",
    -- Overview summary boxes
    ["DASHBOARD_SUMMARY_HIGHEST_KEY"]   = "Llave más alta",
    ["DASHBOARD_SUMMARY_TOTAL_RUNS"]    = "Mazmorras totales",
    ["DASHBOARD_SUMMARY_SUCCESS_RUNS"]  = "Mazmorras exitosas",
    -- Runs table column headers
    ["RUN_COL_DUNGEON"]   = "Mazmorra",
    ["RUN_COL_LEVEL"]     = "Nivel",
    ["RUN_COL_COMPLETED"] = "A tiempo",
    ["RUN_COL_SCORE"]     = "Puntuación",
    ["RUN_COL_DURATION"]  = "Tiempo",
    ["RUN_COL_DATE"]      = "Fecha",
    ["RUN_COL_SEASON"]    = "Temporada",
    ["RUN_TABLE_NO_RUNS"] = "Aún no se ha registrado ninguna mazmorra.",
    -- Runs table tooltips
    ["RUN_TOOLTIP_TIME_LIMIT"]    = "Límite de tiempo",
    ["RUN_TOOLTIP_DUNGEON_SCORE"] = "Puntuación de la mazmorra",
    -- Dashboard
    ["DASHBOARD_OVERALL"] = "General",
    ["DASHBOARD_WEEKLY"] = "Semanal",
    ["DASHBOARD_BEST"] = "Mejor",
    ["DASHBOARD_RUNS"] = "Mazmorras",
    ["DASHBOARD_SUCCESS"] = "Éxito",
    ["DASHBOARD_RUN_TIME"] = "Tiempo",
    -- Sidebar: Runs tab
    ["SIDEBAR_RUNS_BEST_RUN"]    = "Mejor mazmorra",
    ["SIDEBAR_RUNS_NO_RUNS"]     = "Ninguna mazmorra M+ superada aún.",
    ["SIDEBAR_RUNS_TIER_HEADER"] = "Mazmorras a tiempo",
    ["SIDEBAR_GROUP_HEADER"]     = "Grupo",
    ["SIDEBAR_GROUP_NO_MEMBERS"] = "Actualmente no estás en un grupo.",
    -- Keystones tab: group keystone overview
    ["KEYSTONES_COL_PLAYER"]  = "Jugador",
    ["KEYSTONES_COL_DUNGEON"] = "Mazmorra",
    ["KEYSTONES_COL_LEVEL"]   = "Nivel",
    ["KEYSTONES_NO_ADDON"]    = "Sin addon",
    ["KEYSTONES_NO_KEY"]      = "Sin llave",
    ["KEYSTONES_REFRESH_TOOLTIP"] = "Actualizar vista de grupo",
    -- Settings panel
    ["SETTINGS_CATEGORY_NAME"]         = "Mythic Plus Tracker",
    ["SETTINGS_SECTION_GENERAL_LABEL"] = "General",
    ["SETTINGS_SECTION_MINIMAP_LABEL"] = "Minimapa",
    ["SETTINGS_SECTION_DASHBOARD_LABEL"] = "Panel",
    ["SETTINGS_DASHBOARD_DEFAULT_TAB_LABEL"] = "Pestaña Llaves míticas por defecto en grupo",
    ["SETTINGS_DASHBOARD_DEFAULT_TAB_TOOLTIP"] = "Cuando estás en un grupo o banda, abre el panel directamente en la pestaña Llaves míticas en lugar de Resumen.",
    ["SETTINGS_DEBUG_MODE_LABEL"]      = "Modo de depuración",
    ["SETTINGS_DEBUG_MODE_TOOLTIP"]    = "Muestra mensajes de diagnóstico adicionales en la ventana de chat.",
    ["SETTINGS_MINIMAP_BUTTON_LABEL"]  = "Mostrar botón del minimapa",
    ["SETTINGS_MINIMAP_BUTTON_TOOLTIP"] = "Muestra u oculta el botón del minimapa de Mythic Plus Tracker.",
    ["SETTINGS_MINIMAP_BUTTON_STYLE_LABEL"] = "Estilo del botón del minimapa",
    ["SETTINGS_MINIMAP_BUTTON_STYLE_TOOLTIP"] = "Elige entre el botón grande movible libremente o un botón normal movible solo por el borde del minimapa.",
    ["MINIMAP_BUTTON_STYLE_LARGE"] = "Grande",
    ["MINIMAP_BUTTON_STYLE_NORMAL"] = "Normal",
    ["SETTINGS_WELCOME_MESSAGE_LABEL"]  = "Mostrar mensaje de bienvenida",
    ["SETTINGS_WELCOME_MESSAGE_TOOLTIP"] = "Muestra u oculta el mensaje de bienvenida de Mythic Plus Tracker al iniciar sesión.",
}

for key, value in pairs(locale) do
    addon.locale[key] = value
end

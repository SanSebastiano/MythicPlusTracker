if not ((GAME_LOCALE or GetLocale()) == "ruRU") then
    return
end

local addonName, addon = ...

addon.locale = addon.locale or {}

local locale = {
    ["WELCOME_MESSAGE"] = "%s v%s от %s успешно загружен!",
    ["WELCOME_MESSAGE_DEBUG"] = "Режим отладки включён. Некоторые функции могут быть ограничены.",
    -- Minimap Button
    ["MINIMAP_BUTTON_NAME"] = "Mythic Plus Tracker",
    ["MINIMAP_BUTTON_CLICK_LEFT"] = "ЛКМ: Открыть/закрыть панель",
    ["MINIMAP_BUTTON_CLICK_RIGHT"] = "ПКМ: Открыть Великое Хранилище",
    ["MINIMAP_BUTTON_DRAG"] = "Перетаскивание: перемещение по краю миникарты (Shift + перетаскивание: свободное перемещение)",
    ["MINIMAP_BUTTON_DRAG_NORMAL"] = "Перетаскивание: перемещение по краю миникарты",
    -- Mythic Plus specific messages
    ["KEYSTONE_UPGRADED"] = "Ключ улучшен до %d уровня!",
    ["KEYSTONE_DEPLETED"] = "Ключ сломан.",
    ["RUN_STARTED"] = "Прохождение М+ начато!",
    ["RUN_ENDED"] = "Прохождение М+ завершено.",
    ["RUN_FAILED"] = "Прохождение М+ провалено.",
    ["RUN_SUCCESS"] = "Прохождение М+ успешно завершено!",
    ["DUNGEON_STARTED"] = "Подземелье начато: %s",
    ["DUNGEON_ENDED"] = "Подземелье завершено: %s",
    ["DUNGEON_COMPLETED"] = "Подземелье пройдено!",
    ["TIMER_EXPIRED"] = "Таймер истёк",
    ["DEATHS"] = "Смертей: %d",
    ["KEYSTONE_LEVEL"] = "Уровень ключа: %d",
    ["SIDEBAR_NO_KEYSTONE"] = "Нет ключа в сумке",
    ["SIDEBAR_KEYSTONE_LEVEL"] = "Уровень ключа",
    ["SIDEBAR_VAULT_TITLE"] = "Еженедельное хранилище",
    ["SIDEBAR_VAULT_SLOT"] = "Слот %d",
    ["SIDEBAR_VAULT_UNLOCK_RUNS"] = "Пройдите ещё %d M+ для открытия",
    ["SIDEBAR_VAULT_PROGRESS"] = "Завершено прохождений M+: %d / %d",
    ["SIDEBAR_VAULT_REWARD_ILVL"] = "Уровень предмета награды: %d",
    ["SIDEBAR_VAULT_KEY_LEVEL"] = "Лучшее прохождение: M+%d",
    ["SIDEBAR_VAULT_NOT_AVAILABLE"] = "-",
    ["SIDEBAR_VAULT_UNLOCKED"] = "Открыто",
    ["SIDEBAR_VAULT_TOP_RUNS"] = "Лучшие прохождения за неделю:",
    ["DASHBOARD_NOT_MAX_LEVEL"] = "Вы ещё не достигли максимального уровня.",
    -- Dashboard navigation tabs
    ["DASHBOARD_TAB_OVERVIEW"]  = "Обзор",
    ["DASHBOARD_TAB_RUNS"]      = "Прохождения",
    ["DASHBOARD_TAB_KEYSTONES"] = "Ключи М+",
    -- Dungeon table column headers
    ["DUNGEON_COL_DUNGEON"]    = "Подземелье",
    ["DUNGEON_COL_BEST_LEVEL"] = "Уровень",
    ["DUNGEON_COL_SCORE"]      = "Результат",
    ["DUNGEON_COL_RUNS"]       = "Прохождения",
    ["DUNGEON_COL_SUCCESS"]    = "Успешно",
    ["DUNGEON_COL_TIME_LIMIT"] = "Предел",
    ["DUNGEON_COL_BEST_TIME"]  = "Лучшее время",
    ["DUNGEON_TOOLTIP_TIME_LIMIT"] = "Ограничение по времени",
    ["DUNGEON_TELEPORT_TOOLTIP"] = "Нажмите, чтобы телепортироваться",
    ["DUNGEON_TELEPORT_NOT_OWNED"] = "Нет известной или имеющейся игрушки-телепорта для этого подземелья",
    -- Overview summary boxes
    ["DASHBOARD_SUMMARY_HIGHEST_KEY"]   = "Самый высокий ключ",
    ["DASHBOARD_SUMMARY_TOTAL_RUNS"]    = "Всего прохождений",
    ["DASHBOARD_SUMMARY_SUCCESS_RUNS"]  = "Успешных прохождений",
    -- Runs table column headers
    ["RUN_COL_DUNGEON"]   = "Подземелье",
    ["RUN_COL_LEVEL"]     = "Уровень",
    ["RUN_COL_COMPLETED"] = "Вовремя",
    ["RUN_COL_SCORE"]     = "Результат",
    ["RUN_COL_DURATION"]  = "Время",
    ["RUN_COL_DATE"]      = "Дата",
    ["RUN_COL_SEASON"]    = "Сезон",
    -- Runs table tooltips
    ["RUN_TOOLTIP_TIME_LIMIT"]    = "Ограничение по времени",
    ["RUN_TOOLTIP_DUNGEON_SCORE"] = "Результат подземелья",
    -- Dashboard
    ["DASHBOARD_OVERALL"] = "Общее",
    ["DASHBOARD_WEEKLY"] = "За неделю",
    ["DASHBOARD_BEST"] = "Лучшее",
    ["DASHBOARD_RUNS"] = "Прохождения",
    ["DASHBOARD_SUCCESS"] = "Успешно",
    ["DASHBOARD_RUN_TIME"] = "Время",
    -- Sidebar: Runs tab
    ["SIDEBAR_RUNS_BEST_RUN"]    = "Лучшее прохождение",
    ["SIDEBAR_RUNS_NO_RUNS"]     = "Успешных прохождений М+ пока не завершено.",
    ["SIDEBAR_RUNS_TIER_HEADER"] = "Прохождений вовремя",
    ["SIDEBAR_GROUP_HEADER"]     = "Группа",
    ["SIDEBAR_GROUP_NO_MEMBERS"] = "Сейчас не в группе.",
    -- Sidebar: Overview tab section headers
    ["SIDEBAR_TRAITNODES_HEADER"] = "Руны мощи",
    ["SIDEBAR_CURRENCY_HEADER"]   = "Валюты",
    -- Keystones tab: group keystone overview
    ["KEYSTONES_COL_PLAYER"]  = "Игрок",
    ["KEYSTONES_COL_DUNGEON"] = "Подземелье",
    ["KEYSTONES_COL_LEVEL"]   = "Уровень",
    ["KEYSTONES_NO_ADDON"]    = "Нет аддона",
    ["KEYSTONES_NO_KEY"]      = "Нет ключа",
    ["KEYSTONES_REFRESH_TOOLTIP"] = "Обновить вид группы",
    -- Settings panel
    ["SETTINGS_CATEGORY_NAME"]         = "Mythic Plus Tracker",
    ["SETTINGS_SECTION_GENERAL_LABEL"] = "Основное",
    ["SETTINGS_SECTION_MINIMAP_LABEL"] = "Миникарта",
    ["SETTINGS_DEBUG_MODE_LABEL"]      = "Режим отладки",
    ["SETTINGS_DEBUG_MODE_TOOLTIP"]    = "Выводит дополнительные диагностические сообщения в окно чата.",
    ["SETTINGS_MINIMAP_BUTTON_LABEL"]  = "Показывать кнопку на миникарте",
    ["SETTINGS_MINIMAP_BUTTON_TOOLTIP"] = "Показывает или скрывает кнопку Mythic Plus Tracker на миникарте.",
    ["SETTINGS_MINIMAP_BUTTON_STYLE_LABEL"] = "Стиль кнопки миникарты",
    ["SETTINGS_MINIMAP_BUTTON_STYLE_TOOLTIP"] = "Выберите между большой кнопкой со свободным перемещением или обычной кнопкой, перемещаемой только по краю миникарты.",
    ["MINIMAP_BUTTON_STYLE_LARGE"] = "Большой",
    ["MINIMAP_BUTTON_STYLE_NORMAL"] = "Обычный",
    ["SETTINGS_WELCOME_MESSAGE_LABEL"]  = "Показывать приветственное сообщение",
    ["SETTINGS_WELCOME_MESSAGE_TOOLTIP"] = "Отображает или скрывает приветственное сообщение Mythic Plus Tracker при входе в систему.",
}

for key, value in pairs(locale) do
    addon.locale[key] = value
end

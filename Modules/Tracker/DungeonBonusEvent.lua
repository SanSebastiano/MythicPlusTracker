local addonName, addon = ...

addon.DungeonBonusEvent = addon.DungeonBonusEvent or {}

-- "Sign of the Warrior", the player buff the weekly Mythic dungeon bonus event
-- applies. Unchanged since Legion (patch 12.0.1 only swapped its icon), which
-- is why this is a single constant instead of a per-expansion table.
local BONUS_EVENT_AURA_SPELL_ID = 225787

-- "Emissary of War", the bonus event's weekly quest. Unlike the aura above,
-- this ID is re-issued every expansion. Two things have to change together
-- when it does: this constant, and BONUS_EVENT_QUEST_AVAILABLE in the five
-- Locales/*.lua files, which names the quest giver and the city. Confirm with:
--   /run print(C_QuestLog.GetTitleForQuestID(93598))
local EMISSARY_OF_WAR_QUEST_ID = 93598

---Quest states the tracker's header icon distinguishes. UNKNOWN is not an
---error for the player: it means this client knows no such quest, which after
---an expansion patch is exactly what a stale EMISSARY_OF_WAR_QUEST_ID looks
---like.
addon.DungeonBonusEvent.QUEST_STATUS = {
    UNKNOWN            = "unknown",
    AVAILABLE          = "available",
    ON_QUEST           = "onQuest",
    READY_FOR_TURN_IN  = "readyForTurnIn",
    COMPLETED          = "completed",
}

local QUEST_STATUS = addon.DungeonBonusEvent.QUEST_STATUS

local function isEventAuraActive()
    if not (C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID) then return false end
    return C_UnitAuras.GetPlayerAuraBySpellID(BONUS_EVENT_AURA_SPELL_ID) ~= nil
end

---The client's own localized quest title. Returns nil while the quest is not
---cached yet — the first call for a given quest routinely does, and is itself
---what triggers the lookup.
local function getQuestTitle()
    local title = C_QuestLog.GetTitleForQuestID(EMISSARY_OF_WAR_QUEST_ID)
    if type(title) ~= "string" or title == "" then
        return nil
    end
    return title
end

---The quest's first objective as Blizzard phrases it ("0/4 Mythic dungeons
---completed"), so no addon-side string has to reproduce the game's wording or
---carry its own translation. Falls back to a bare count when the objective
---text has not been cached but the numbers have.
---@return string|nil progressText nil when no objective data is available at all
local function getQuestProgressText()
    local succeeded, objectives = pcall(C_QuestLog.GetQuestObjectives, EMISSARY_OF_WAR_QUEST_ID)
    if not succeeded then
        addon.debugMessage("GetQuestObjectives failed for quest " .. EMISSARY_OF_WAR_QUEST_ID .. ": " .. tostring(objectives))
        return nil
    end

    if type(objectives) ~= "table" then
        return nil
    end

    local objective = objectives[1]
    if type(objective) ~= "table" then
        return nil
    end

    if type(objective.text) == "string" and objective.text ~= "" then
        return objective.text
    end

    local required = tonumber(objective.numRequired)
    if not required or required <= 0 then
        return nil
    end

    return string.format(addon.locale["BONUS_EVENT_QUEST_PROGRESS"], tonumber(objective.numFulfilled) or 0, required)
end

---@class MPTDungeonBonusEventStatus
---@field isEventActive boolean whether the weekly Mythic dungeon bonus event is running
---@field questStatus string one of addon.DungeonBonusEvent.QUEST_STATUS
---@field questTitle string|nil nil while the client has not cached the title yet
---@field progressText string|nil only set while the quest sits in the quest log (ON_QUEST or READY_FOR_TURN_IN)

---Resolves everything the header icon needs in one read, so no UI code queries
---game state itself.
---
---questStatus is only AVAILABLE when the client actually knows a title for the
---quest ID; otherwise it stays UNKNOWN and callers have to stay silent about
---the quest rather than claim it can be picked up. That is what keeps a stale
---quest ID from turning into a wrong statement in the tooltip.
---@return MPTDungeonBonusEventStatus status
function addon.DungeonBonusEvent:getStatus()
    local status = {
        isEventActive = isEventAuraActive(),
        questStatus   = QUEST_STATUS.UNKNOWN,
        questTitle    = getQuestTitle(),
        progressText  = nil,
    }

    -- Checked completion first: a finished weekly cannot also sit in the log,
    -- and IsQuestFlaggedCompleted resets server-side at the weekly reset, so
    -- it already means "this week" without any date arithmetic.
    if C_QuestLog.IsQuestFlaggedCompleted(EMISSARY_OF_WAR_QUEST_ID) then
        status.questStatus = QUEST_STATUS.COMPLETED
    elseif C_QuestLog.IsOnQuest(EMISSARY_OF_WAR_QUEST_ID) then
        -- ReadyForTurnIn is only meaningful for a quest that is in the log, so
        -- it is deliberately asked inside this branch rather than alongside
        -- IsQuestFlaggedCompleted above.
        if C_QuestLog.ReadyForTurnIn(EMISSARY_OF_WAR_QUEST_ID) then
            status.questStatus = QUEST_STATUS.READY_FOR_TURN_IN
        else
            status.questStatus = QUEST_STATUS.ON_QUEST
        end
        status.progressText = getQuestProgressText()
    elseif status.questTitle then
        status.questStatus = QUEST_STATUS.AVAILABLE
    end

    addon.debugMessage("Bonus event: active=" .. tostring(status.isEventActive)
            .. ", quest " .. EMISSARY_OF_WAR_QUEST_ID .. "=" .. status.questStatus
            .. ", title=" .. tostring(status.questTitle))

    return status
end

---Whether a questID from a QUEST_ACCEPTED/QUEST_TURNED_IN payload is the quest
---this feature tracks. Exists so the quest ID never leaves this file.
---@param questID number|nil straight from the event payload, unvalidated
---@return boolean
function addon.DungeonBonusEvent:isTrackedQuest(questID)
    return tonumber(questID) == EMISSARY_OF_WAR_QUEST_ID
end

local addonName, addon = ...

addon.RunsFilterService = addon.RunsFilterService or {}

MythicPlusTrackerDB = MythicPlusTrackerDB or {}

-- The dimension values are the SavedVariables field names themselves, so the
-- mapping is the identity and the stored shape is stated in exactly one place.
addon.RunsFilterService.DIMENSIONS = {
    DUNGEONS       = "dungeons",
    TIMED_STATES   = "timedStates",
    LEVEL_BRACKETS = "levelBrackets",
}

-- Persisted set keys for the timed dimension, not display strings.
addon.RunsFilterService.TIMED_STATES = {
    TIMED   = "timed",
    UNTIMED = "untimed",
}

-- Stufen-Brackets, as given by the addon's maintainer to match how this group
-- talks about key levels — not derived from the color-tier thresholds in
-- Core/Colors.lua, which cut differently. Ascending, with max = nil for the
-- open-ended bracket. Both the Runs tab's filter dropdown and the Sidebar's
-- breakdown read these, so the two can no longer disagree about a boundary;
-- each formats its own labels, since those are presentation.
addon.RunsFilterService.LEVEL_BRACKETS = {
    { key = "2-3",   min = 2,  max = 3 },
    { key = "4-6",   min = 4,  max = 6 },
    { key = "7-9",   min = 7,  max = 9 },
    { key = "10-11", min = 10, max = 11 },
    { key = "12-14", min = 12, max = 14 },
    { key = "15+",   min = 15, max = nil },
}

local DIMENSIONS   = addon.RunsFilterService.DIMENSIONS
local TIMED_STATES = addon.RunsFilterService.TIMED_STATES

---"Only the current reset week" is a boolean, not a set of selected values, so
---it lives outside the DIMENSIONS sets above rather than being bent into their
---shape. It is also deliberately *not* persisted: unlike the three dropdowns,
---this one starts cleared on every login and /reload, so a week-narrowed view
---never outlives the session that asked for it. That means no SavedVariables
---field, and no schema change to MythicPlusTrackerDB.
local currentWeekOnly = false

---SavedVariables lazy-init for the Runs tab's filter selections. Each set is
---keyed by the filtered value (mapID / "timed"|"untimed" / bracket key) with
---value true; an empty set means "no filter applied, show everything".
---
---Called by every public function rather than once by the Runs page, because
---the Sidebar's breakdown reads the filter too and may render before that page
---ever ran.
---@return table runsFilter
local function ensureInitialized()
    local runsFilter = MythicPlusTrackerDB.runsFilter or {}
    MythicPlusTrackerDB.runsFilter = runsFilter

    runsFilter[DIMENSIONS.DUNGEONS]       = runsFilter[DIMENSIONS.DUNGEONS] or {}
    runsFilter[DIMENSIONS.TIMED_STATES]   = runsFilter[DIMENSIONS.TIMED_STATES] or {}
    runsFilter[DIMENSIONS.LEVEL_BRACKETS] = runsFilter[DIMENSIONS.LEVEL_BRACKETS] or {}

    return runsFilter
end

---@param level number|nil
---@return string|nil bracketKey nil if the level is missing or out of range
function addon.RunsFilterService:getLevelBracketKey(level)
    if not level then return nil end

    for _, bracket in ipairs(self.LEVEL_BRACKETS) do
        if level >= bracket.min and (not bracket.max or level <= bracket.max) then
            return bracket.key
        end
    end

    return nil
end

---How many values are selected in one dimension. Zero means that dimension
---does not filter at all.
---@param dimension string one of addon.RunsFilterService.DIMENSIONS
---@return number
function addon.RunsFilterService:countSelected(dimension)
    local count = 0
    for _ in pairs(ensureInitialized()[dimension]) do
        count = count + 1
    end
    return count
end

---@param dimension string one of addon.RunsFilterService.DIMENSIONS
---@param key string|number bracket key, timed state, or mapChallengeModeID
---@return boolean
function addon.RunsFilterService:isSelected(dimension, key)
    return ensureInitialized()[dimension][key] == true
end

---@param dimension string one of addon.RunsFilterService.DIMENSIONS
---@param key string|number bracket key, timed state, or mapChallengeModeID
function addon.RunsFilterService:toggle(dimension, key)
    local set = ensureInitialized()[dimension]
    if set[key] then
        set[key] = nil
    else
        set[key] = true
    end
end

---@return boolean whether the run list is limited to the current reset week
function addon.RunsFilterService:isCurrentWeekOnly()
    return currentWeekOnly
end

---@param enabled boolean
function addon.RunsFilterService:setCurrentWeekOnly(enabled)
    currentWeekOnly = enabled == true
end

---Whether any dimension currently narrows the run list. Consumers use this to
---label themselves as filtered.
---@return boolean
function addon.RunsFilterService:hasActiveFilter()
    if currentWeekOnly then
        return true
    end

    for _, dimension in pairs(DIMENSIONS) do
        if self:countSelected(dimension) > 0 then
            return true
        end
    end
    return false
end

---Whether a run survives the active filters. Dimensions combine with AND; a
---dimension with nothing selected does not filter.
---@param run table entry from addon.RunHistoryService:getRuns()
---@return boolean
function addon.RunsFilterService:isRunIncluded(run)
    local runsFilter = ensureInitialized()

    if currentWeekOnly then
        -- A run whose completionDate is missing or malformed can't be placed in
        -- a week, so it can't be shown as belonging to this one.
        local timestamp = addon.completionDateToTimestamp(run.completionDate)
        if not timestamp or timestamp < addon.getCurrentWeekStartTime() then
            return false
        end
    end

    if self:countSelected(DIMENSIONS.DUNGEONS) > 0
            and not runsFilter[DIMENSIONS.DUNGEONS][run.mapChallengeModeID] then
        return false
    end

    if self:countSelected(DIMENSIONS.TIMED_STATES) > 0 then
        local state = TIMED_STATES.UNTIMED
        if run.completed then
            state = TIMED_STATES.TIMED
        end
        if not runsFilter[DIMENSIONS.TIMED_STATES][state] then
            return false
        end
    end

    if self:countSelected(DIMENSIONS.LEVEL_BRACKETS) > 0 then
        local bracketKey = self:getLevelBracketKey(run.level)
        if not (bracketKey and runsFilter[DIMENSIONS.LEVEL_BRACKETS][bracketKey]) then
            return false
        end
    end

    return true
end

---@param runs table list of entries from addon.RunHistoryService:getRuns()
---@return table includedRuns a new list; the caller's table is never modified
function addon.RunsFilterService:filterRuns(runs)
    local includedRuns = {}

    for _, run in ipairs(runs) do
        if self:isRunIncluded(run) then
            table.insert(includedRuns, run)
        end
    end

    return includedRuns
end

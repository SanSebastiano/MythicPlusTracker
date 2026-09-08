local addonName, addon = ...

MythicPlusTrackerDB = MythicPlusTrackerDB or {}

local PADDING_X  = 8
local ROW_H      = 50   -- increased over HEADER_H's 30 for a full-height table
local HEADER_H   = 30
local COL_GAP    = 8
local ICON_SIZE  = 36
-- Reserved control-row height/margin above the table. Kept deliberately small
-- (rather than matching KeystonesPage's 26px dropdown row) because the
-- Dashboard frame's fixed height leaves this table only ~18px of slack below
-- its last row (8 dungeons at ROW_H=50) — anything bigger pushes the last row
-- out past the frame's bottom edge.
local WEEK_FILTER_ROW_H      = 14
local WEEK_FILTER_ROW_MARGIN = 2

local NAV_BOTTOM_MARGIN = MPT_Dashboard.LAYOUT.NAV_BOTTOM_MARGIN
local DASHBOARD_W       = MPT_Dashboard.LAYOUT.WIDTH
local CONTENT_INSET     = MPT_Dashboard.LAYOUT.CONTENT_INSET

-- Fixed column widths (name column is computed dynamically)
local COL_W = {
    icon      = 40,
    bestLevel = 60,
    score     = 70,
    runs      = 50,
    success   = 60,
    timeLimit = 65,
    bestTime  = 70,
}

local rowsContainer  = nil  -- recreated on each sort change

local HEADER_LOCALE = {
    name      = "DUNGEON_COL_DUNGEON",
    bestLevel = "DUNGEON_COL_BEST_LEVEL",
    score     = "DUNGEON_COL_SCORE",
    runs      = "DUNGEON_COL_RUNS",
    success   = "DUNGEON_COL_SUCCESS",
    timeLimit = "DUNGEON_COL_TIME_LIMIT",
    bestTime  = "DUNGEON_COL_BEST_TIME",
}

local DEFAULT_SORT_DIR = {
    name      = "asc",
    bestLevel = "desc",
    score     = "desc",
    runs      = "desc",
    success   = "desc",
    timeLimit = "asc",
    bestTime  = "asc",
}

-- This table always starts sorted by dungeon name; the Keystones table starts
-- unsorted instead, which is why the sort state is per-table.
local sortState = addon.TableSortService:new({
    initialColumn     = "name",
    defaultDirections = DEFAULT_SORT_DIR,
    headerLocaleKeys  = HEADER_LOCALE,
})

local ARTIFACT_R, ARTIFACT_G, ARTIFACT_B = addon.colorToRGB("ARTIFACT")

-- From this keystone level upwards a run only counts as the dungeon's best if
-- it was completed in time. Below it an over-time run still counts, because it
-- still awards score. Blizzard game rule — re-check it each season/patch.
local LEVEL_REQUIRING_TIMED_COMPLETION = 12

---Whether a run is eligible to be a dungeon's best run at all.
---run.completed is true only for in-time completions, which is also what drives
---the Runs tab's check/cross icon.
---@param run table entry from addon.RunHistoryService:getRuns()
---@return boolean
local function countsTowardBest(run)
    return run.level < LEVEL_REQUIRING_TIMED_COMPLETION or run.completed == true
end

---Per-dungeon totals plus the single run that counts as that dungeon's best.
---"Best" is the highest-scoring eligible run, so bestLevel/bestTime/bestScore
---always describe the same run — previously they could come from three
---different ones, which is how an over-time key ended up shown as the best
---level with its own (over the limit) duration next to it.
---@param runHistory table
---@return table lookup keyed by mapChallengeModeID
local function buildRunLookup(runHistory)
    local lookup = {}

    for _, run in ipairs(runHistory) do
        local id = run.mapChallengeModeID

        if not lookup[id] then
            lookup[id] = { bestLevel = 0, bestTime = 0, bestScore = 0, runs = 0, success = 0 }
        end

        local e = lookup[id]
        e.runs = e.runs + 1
        if run.completed then e.success = e.success + 1 end

        local runScore = run.runScore or 0
        if countsTowardBest(run) and runScore > e.bestScore then
            e.bestScore = runScore
            e.bestLevel = run.level
            e.bestTime  = run.durationSec or 0
        end
    end

    return lookup
end

---Runs whose completionDate falls within the current weekly-reset week, used
---to limit Läufe/Erfolge/Beste Zeit to what was completed since the last
---reset when the "current week" checkbox is active. Wertung stays unaffected
---since getDungeonScore prefers Blizzard's season-wide GetSeasonBestForMap
---over the locally aggregated score.
---@param runHistory table
---@return table
local function filterRunsSinceWeekStart(runHistory)
    local weekStart = addon.getCurrentWeekStartTime()
    local filtered = {}
    for _, run in ipairs(runHistory) do
        local timestamp = addon.completionDateToTimestamp(run.completionDate)
        if timestamp and timestamp >= weekStart then
            table.insert(filtered, run)
        end
    end
    return filtered
end

---Toggle for limiting Läufe/Erfolge/Beste Zeit to the current weekly-reset
---week, right-aligned above the table like the Keystones tab's mode dropdown.
---Persisted so it survives a UI reload; toggling re-renders the whole tab.
---@param frame Frame the tab's content panel
local function createWeekFilterCheckbox(frame)
    local checkbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    checkbox:SetSize(WEEK_FILTER_ROW_H, WEEK_FILTER_ROW_H)
    checkbox:SetPoint("TOPRIGHT", MPT_Dashboard.navFrame, "BOTTOMRIGHT", -CONTENT_INSET, -NAV_BOTTOM_MARGIN)
    checkbox:SetChecked(MythicPlusTrackerDB.overviewFilterCurrentWeek)

    local function applyFilterChange(checked)
        MythicPlusTrackerDB.overviewFilterCurrentWeek = checked
        MPT_Dashboard:refreshDungeonsView()
    end

    checkbox:SetScript("OnClick", function(self)
        applyFilterChange(self:GetChecked() == true)
    end)

    -- A plain FontString can't receive clicks, so the label is its own Button
    -- (sized to the rendered text) to the checkbox's left — clicking the text
    -- toggles the checkbox exactly like clicking the checkbox itself.
    local labelButton = CreateFrame("Button", nil, frame)
    labelButton:SetHeight(WEEK_FILTER_ROW_H)
    labelButton:SetPoint("RIGHT", checkbox, "LEFT", -4, 0)

    local labelText = labelButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    labelText:SetPoint("RIGHT", labelButton, "RIGHT", 0, 0)
    labelText:SetText(addon.colors.POOR .. addon.locale["DUNGEON_CURRENT_WEEK_ONLY"] .. addon.colors.RESET)

    labelButton:SetWidth(labelText:GetStringWidth())
    labelButton:SetScript("OnClick", function()
        local checked = not checkbox:GetChecked()
        checkbox:SetChecked(checked)
        applyFilterChange(checked)
    end)
end

local function getDungeonScore(mapID, ri)
    if C_MythicPlus.GetSeasonBestForMap then
        local info = C_MythicPlus.GetSeasonBestForMap(mapID)
        if info and info.dungeonScore and info.dungeonScore > 0 then
            return info.dungeonScore
        end
    end
    return ri and ri.bestScore or 0
end

local function formatLevel(level)
    if level and level > 0 then
        return addon.colorKeystoneLevel(level) .. "+" .. level .. addon.colors.RESET
    end
    return "–"
end

local function formatScore(score)
    if not score or score <= 0 then return "–" end
    return addon.colors.ARTIFACT .. score .. addon.colors.RESET
end

local function formatTimeMMSS(sec)
    if not sec or sec <= 0 then return "–" end
    return addon.formatMinutesSeconds(sec)
end

local function formatBestTime(sec, timeLimitSec)
    if not sec or sec <= 0 then return "–" end
    local s = sec
    local str = addon.formatMinutesSeconds(s)
    local color = s <= timeLimitSec and addon.colors.WHITE or addon.colors.POOR
    return color .. str .. addon.colors.RESET
end

local function formatCount(n)
    return (n and n > 0) and tostring(n) or "–"
end

local function createTableRow(child, mapID, colX, rowY, nameW, runLookup, isLast)
    local name, _, timeLimit, texture = C_ChallengeMode.GetMapUIInfo(mapID)
    if not name then return end

    local ri = runLookup[mapID]

    local icon = child:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("TOPLEFT", child, "TOPLEFT", colX["icon"] + 2, rowY - (ROW_H - ICON_SIZE) / 2)
    icon:SetTexture(texture)

    -- Clicking the dungeon icon teleports the player via the matching known
    -- "Path of ..." spell, if one is known (see Dashboard/DungeonTeleportCatalog.lua).
    addon.attachDungeonTeleportButton(child, icon, mapID, name,
        colX["icon"] + 2, rowY - (ROW_H - ICON_SIZE) / 2, ICON_SIZE)

    addon.createTableCell(child, colX["name"], rowY, nameW, ROW_H, name, "GameFontHighlight", "LEFT")

    addon.createTableCell(child, colX["bestLevel"], rowY, COL_W.bestLevel, ROW_H,
        formatLevel(ri and ri.bestLevel), "GameFontHighlight", "RIGHT")

    addon.createTableCell(child, colX["score"], rowY, COL_W.score, ROW_H,
        formatScore(getDungeonScore(mapID, ri)), "GameFontHighlight", "RIGHT")

    addon.createTableCell(child, colX["runs"], rowY, COL_W.runs, ROW_H,
        formatCount(ri and ri.runs), "GameFontHighlight", "RIGHT")

    addon.createTableCell(child, colX["success"], rowY, COL_W.success, ROW_H,
        formatCount(ri and ri.success), "GameFontHighlight", "RIGHT")

    addon.createTableCell(child, colX["timeLimit"], rowY, COL_W.timeLimit, ROW_H,
        formatTimeMMSS(timeLimit), "GameFontHighlight", "RIGHT")

    addon.createTableCell(child, colX["bestTime"], rowY, COL_W.bestTime, ROW_H,
        formatBestTime(ri and ri.bestTime, timeLimit), "GameFontHighlight", "RIGHT")

    if ri and ri.bestTime and ri.bestTime > 0 then
        local hitFrame = CreateFrame("Frame", nil, child)
        hitFrame:SetSize(COL_W.bestTime, ROW_H)
        hitFrame:SetPoint("TOPLEFT", child, "TOPLEFT", colX["bestTime"], rowY)
        hitFrame:EnableMouse(true)
        local capturedBestTime  = ri.bestTime
        local capturedTimeLimit = timeLimit
        hitFrame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(
                addon.locale["DUNGEON_TOOLTIP_TIME_LIMIT"] or "Time Limit",
                ARTIFACT_R, ARTIFACT_G, ARTIFACT_B, 1, true)
            local delta    = capturedTimeLimit - capturedBestTime
            local absDelta = math.abs(delta)
            local deltaStr = addon.formatMinutesSeconds(absDelta)
            if delta >= 0 then
                GameTooltip:AddLine("+" .. deltaStr, 0, 0.8, 0, 1)
            else
                GameTooltip:AddLine("-" .. deltaStr, 1, 0.2, 0.2, 1)
            end
            GameTooltip:Show()
        end)
        hitFrame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    if not isLast then
        addon.createRowDivider(child, rowY - ROW_H, 0.3)
    end
end

local function computeSortedEntries(dungeons, runLookup)
    local entries = {}
    for _, mapID in ipairs(dungeons) do
        local name, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapID)
        local ri = runLookup[mapID] or {}
        table.insert(entries, {
            mapID     = mapID,
            name      = name or "",
            bestLevel = ri.bestLevel or 0,
            score     = getDungeonScore(mapID, ri),
            runs      = ri.runs or 0,
            success   = ri.success or 0,
            bestTime  = ri.bestTime or 0,
            timeLimit = timeLimit or 0,
        })
    end

    local sortColumn = sortState:getColumn()
    local ascending  = sortState:isAscending()

    table.sort(entries, function(a, b)
        if sortColumn == "name" then
            if ascending then return a.name < b.name
            else              return a.name > b.name end
        else
            local va = a[sortColumn] or 0
            local vb = b[sortColumn] or 0
            -- Push zero/no-data entries to the bottom regardless of direction
            if (va == 0) ~= (vb == 0) then return va ~= 0 end
            if ascending then return va < vb
            else              return va > vb end
        end
    end)

    return entries
end

local function createTableHeader(child, colX, nameW, onSort)
    sortState:forgetHeaderCells()

    local headerDefs = {
        { key = "name",      w = nameW,           j = "LEFT"  },
        { key = "bestLevel", w = COL_W.bestLevel, j = "RIGHT" },
        { key = "score",     w = COL_W.score,     j = "RIGHT" },
        { key = "runs",      w = COL_W.runs,      j = "RIGHT" },
        { key = "success",   w = COL_W.success,   j = "RIGHT" },
        { key = "timeLimit", w = COL_W.timeLimit, j = "RIGHT" },
        { key = "bestTime",  w = COL_W.bestTime,  j = "RIGHT" },
    }

    for _, def in ipairs(headerDefs) do
        addon.createSortableHeaderButton(child, colX[def.key], def.w, HEADER_H, def.j, def.key, sortState, onSort)
    end

    sortState:updateIndicators()

    addon.createRowDivider(child, -HEADER_H, 0.5)
end

local function renderRows(tableFrame, dungeons, colX, nameW, runLookup)
    if rowsContainer then
        rowsContainer:Hide()
    end

    local entries = computeSortedEntries(dungeons, runLookup)

    rowsContainer = CreateFrame("Frame", nil, tableFrame)
    rowsContainer:SetPoint("TOPLEFT",  tableFrame, "TOPLEFT",  0, -(HEADER_H + 1))
    rowsContainer:SetPoint("TOPRIGHT", tableFrame, "TOPRIGHT", 0, -(HEADER_H + 1))
    rowsContainer:SetHeight(#entries * ROW_H)
    rowsContainer:Show()

    for i, entry in ipairs(entries) do
        local rowY   = -((i - 1) * ROW_H)
        local isLast = (i == #entries)
        createTableRow(rowsContainer, entry.mapID, colX, rowY, nameW, runLookup, isLast)
    end
end

function MPT_Dashboard:loadDungeons(frame)
    local dungeons = C_ChallengeMode.GetMapTable()
    if not dungeons then return end

    MythicPlusTrackerDB.overviewFilterCurrentWeek = MythicPlusTrackerDB.overviewFilterCurrentWeek or false

    local runHistory = addon.RunHistoryService:getRuns()
    if MythicPlusTrackerDB.overviewFilterCurrentWeek then
        runHistory = filterRunsSinceWeekStart(runHistory)
    end
    local runLookup = buildRunLookup(runHistory)

    createWeekFilterCheckbox(frame)

    local tableW = DASHBOARD_W - CONTENT_INSET * 2

    local fixedW = COL_W.icon + COL_W.bestLevel + COL_W.score
                 + COL_W.runs + COL_W.success + COL_W.timeLimit + COL_W.bestTime
    local numGaps = 7
    local nameW = tableW - PADDING_X * 2 - fixedW - numGaps * COL_GAP

    local colX = {}
    local cursor = PADDING_X
    for _, key in ipairs({ "icon", "name", "bestLevel", "score", "runs", "success", "timeLimit", "bestTime" }) do
        colX[key] = cursor
        local w = (key == "name") and nameW or COL_W[key]
        cursor = cursor + w + COL_GAP
    end

    local childHeight = HEADER_H + 1 + #dungeons * ROW_H + PADDING_X

    -- Drop the previous render's frames; createTableHeader re-registers the
    -- new header cells with the sort state.
    rowsContainer = nil

    local tableFrame = CreateFrame("Frame", nil, frame)
    tableFrame:SetSize(tableW, childHeight)
    tableFrame:SetPoint("TOP",  MPT_Dashboard.navFrame, "BOTTOM", 0,
        -(NAV_BOTTOM_MARGIN + WEEK_FILTER_ROW_H + WEEK_FILTER_ROW_MARGIN))
    tableFrame:SetPoint("LEFT", frame,                  "LEFT",   CONTENT_INSET, 0)

    createTableHeader(tableFrame, colX, nameW, function()
        renderRows(tableFrame, dungeons, colX, nameW, runLookup)
    end)

    renderRows(tableFrame, dungeons, colX, nameW, runLookup)
end

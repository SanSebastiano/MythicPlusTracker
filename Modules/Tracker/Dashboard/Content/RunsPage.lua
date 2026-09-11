local addonName, addon = ...

MythicPlusTrackerDB = MythicPlusTrackerDB or {}

local PADDING_X      = 8
local ROW_H          = 40
local HEADER_H       = 28
local COL_GAP        = 6
local ICON_SIZE      = 28
local DASHBOARD_W    = MPT_Dashboard.LAYOUT.WIDTH
local CONTENT_INSET  = MPT_Dashboard.LAYOUT.CONTENT_INSET
local NAV_BOTTOM_MARGIN = MPT_Dashboard.LAYOUT.NAV_BOTTOM_MARGIN
local SCROLL_BTN_SIZE = 10  -- gutter reserved for the scrollbar (MinimalScrollBar is 8px wide)
local FILTER_DROPDOWN_W      = 108
local FILTER_DROPDOWN_H      = 26  -- fixed height of WowStyle1DropdownTemplate
local FILTER_DROPDOWN_MARGIN = 6
local FILTER_DROPDOWN_GAP    = 8
-- Smaller than the dropdowns next to it: UICheckButtonTemplate draws a wide
-- frame around its box, so matching FILTER_DROPDOWN_H makes it tower over them.
local FILTER_CHECKBOX_SIZE   = 20

-- Fixed column widths sized to fit their header text (name column is computed dynamically)
local COL_W = {
    icon      = 34,
    level     = 60,
    completed = 36,
    score     = 65,
    duration  = 50,
    date      = 90,
    timeDelta = 55,
}

local RunsFilterService = addon.RunsFilterService
local DIMENSIONS        = RunsFilterService.DIMENSIONS
local TIMED_STATES      = RunsFilterService.TIMED_STATES
local LEVEL_BRACKETS    = RunsFilterService.LEVEL_BRACKETS

local ARTIFACT_R, ARTIFACT_G, ARTIFACT_B = addon.colorToRGB("ARTIFACT")

local rowsContainer = nil -- recreated on each filter change

local function formatLevel(level)
    if level and level > 0 then
        return addon.colorKeystoneLevel(level) .. "+" .. level .. addon.colors.RESET
    end
    return addon.colors.POOR .. "–" .. addon.colors.RESET
end

-- Delta: how much this run improved the score for its dungeon vs the
-- previous best.
local function formatScoreDelta(delta)
    if not delta or delta <= 0 then
        return addon.colors.POOR .. "–" .. addon.colors.RESET
    end
    return addon.colors.ARTIFACT .. "+" .. math.floor(delta) .. addon.colors.RESET
end

local function formatDuration(sec, timeLimit)
    if not sec or sec <= 0 then
        return addon.colors.POOR .. "–" .. addon.colors.RESET
    end
    local str = addon.formatMinutesSeconds(sec)
    if timeLimit and timeLimit > 0 and sec > timeLimit then
        return addon.colors.POOR .. str .. addon.colors.RESET
    end
    return addon.colors.WHITE .. str .. addon.colors.RESET
end

-- completionDate is a table: { year, month, monthDay, hour, minute, weekday }
local function dateToSortKey(d)
    if type(d) ~= "table" then return 0 end
    return (d.year     or 0) * 100000000
         + (d.month    or 0) * 1000000
         + (d.monthDay or 0) * 10000
         + (d.hour     or 0) * 100
         + (d.minute   or 0)
end

local function formatDate(d)
    if type(d) ~= "table" then
        return addon.colors.POOR .. "–" .. addon.colors.RESET
    end
    return string.format("%02d.%02d.%04d\n%02d:%02d",
        d.monthDay or 0, d.month or 0, d.year or 0,
        d.hour     or 0, d.minute or 0)
end

-- Delta between the dungeon's timer and how long the run actually took.
-- Positive (green) means time to spare; negative (red) means overtime.
local function formatTimeDelta(sec, timeLimit)
    if not sec or sec <= 0 or not timeLimit or timeLimit <= 0 then
        return addon.colors.POOR .. "–" .. addon.colors.RESET
    end
    local delta    = timeLimit - sec
    local absDelta = math.abs(delta)
    local str      = addon.formatMinutesSeconds(absDelta)
    if delta >= 0 then
        return addon.colors.TIMER_SUCCESS .. "+" .. str .. addon.colors.RESET
    end
    return addon.colors.TIMER_DANGER .. "-" .. str .. addon.colors.RESET
end

---@param bracket table one entry from addon.RunsFilterService.LEVEL_BRACKETS
---@return string
local function levelBracketLabel(bracket)
    if bracket.max then
        return "+" .. bracket.min .. "-" .. bracket.max
    end
    return "+" .. bracket.min .. "+"
end

local function addCellTooltip(parent, x, y, w, h, title, body)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(w, h)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(title, 1, 1, 1)
        if body then GameTooltip:AddLine(body, 0.8, 0.8, 0.8) end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function createHeader(parent, colX, nameW)
    local headerDefs = {
        { key = "icon",      localeKey = nil,               w = COL_W.icon,      j = "LEFT"  },
        { key = "name",      localeKey = "RUN_COL_DUNGEON", w = nameW,           j = "LEFT"  },
        { key = "level",     localeKey = "RUN_COL_LEVEL",   w = COL_W.level,     j = "RIGHT" },
        { key = "completed", localeKey = "RUN_COL_COMPLETED",w = COL_W.completed,j = "CENTER"},
        { key = "score",     localeKey = "RUN_COL_SCORE",   w = COL_W.score,     j = "RIGHT" },
        { key = "duration",  localeKey = "RUN_COL_DURATION",w = COL_W.duration,  j = "RIGHT" },
        { key = "timeDelta", localeKey = "RUN_COL_TIME_DELTA", w = COL_W.timeDelta, j = "RIGHT" },
        { key = "date",      localeKey = "RUN_COL_DATE",    w = COL_W.date,      j = "RIGHT" },
    }

    for _, def in ipairs(headerDefs) do
        if def.localeKey then
            local label = addon.locale[def.localeKey] or def.localeKey

            if def.key == "completed" then
                -- "Timed" translations vary wildly in length across locales
                -- (e.g. German "Im Zeitlimit"); an icon sidesteps the width
                -- problem entirely instead of sizing the column per-locale.
                local icon = parent:CreateTexture(nil, "ARTWORK")
                icon:SetAtlas(addon.theme.RUN_TIMED_HEADER_ICON, false)
                local iconSize = HEADER_H - 6
                icon:SetSize(iconSize, iconSize)
                icon:SetPoint("CENTER", parent, "TOPLEFT", colX[def.key] + def.w / 2, -HEADER_H / 2)
            else
                local fs = addon.createTableCell(parent, colX[def.key], 0, def.w, HEADER_H,
                                   label, "GameFontNormal", def.j)
                fs:SetTextColor(ARTIFACT_R, ARTIFACT_G, ARTIFACT_B, 1)
            end

            -- Column widths are narrow and headers don't wrap/ellipsize, so
            -- long labels can get visually clipped. A hover tooltip with the
            -- full label keeps the column meaning discoverable regardless.
            addCellTooltip(parent, colX[def.key], 0, def.w, HEADER_H, label)
        end
    end

    addon.createRowDivider(parent, -HEADER_H, 0.5)
end

local function createRow(parent, run, colX, nameW, rowY, isLast, scoreDeltas)
    local mapID = run.mapChallengeModeID
    local name, _, timeLimit, texture = C_ChallengeMode.GetMapUIInfo(mapID)
    name = name or ("Map " .. tostring(mapID))

    if texture then
        local icon = parent:CreateTexture(nil, "ARTWORK")
        icon:SetSize(ICON_SIZE, ICON_SIZE)
        icon:SetPoint("TOPLEFT", parent, "TOPLEFT",
            colX["icon"] + 2, rowY - (ROW_H - ICON_SIZE) / 2)
        icon:SetTexture(texture)
    end

    addon.createTableCell(parent, colX["name"], rowY, nameW, ROW_H, name, "GameFontHighlight", "LEFT")

    addon.createTableCell(parent, colX["level"], rowY, COL_W.level, ROW_H,
        formatLevel(run.level), "GameFontHighlight", "RIGHT")

    local cellX     = colX["completed"]
    local cellW     = COL_W.completed
    local MARK_SIZE = 16
    local markAtlas = run.completed and addon.theme.RUN_COMPLETED_ICON or addon.theme.RUN_FAILED_ICON
    local mark = parent:CreateTexture(nil, "ARTWORK")
    mark:SetAtlas(markAtlas, false)
    mark:SetSize(MARK_SIZE, MARK_SIZE)
    mark:SetPoint("TOPLEFT", parent, "TOPLEFT",
        cellX + (cellW - MARK_SIZE) / 2,
        rowY - (ROW_H - MARK_SIZE) / 2)

    local runKey     = run.mapChallengeModeID .. "_" .. dateToSortKey(run.completionDate)
    local runData    = scoreDeltas and scoreDeltas[runKey]
    local delta      = runData and runData.delta
    local scoreAfter = runData and runData.scoreAfter
    addon.createTableCell(parent, colX["score"], rowY, COL_W.score, ROW_H,
        formatScoreDelta(delta), "GameFontHighlight", "RIGHT")
    if scoreAfter and scoreAfter > 0 then
        addCellTooltip(parent, colX["score"], rowY, COL_W.score, ROW_H,
            addon.locale["RUN_TOOLTIP_DUNGEON_SCORE"],
            math.floor(scoreAfter) .. "")
    end

    addon.createTableCell(parent, colX["duration"], rowY, COL_W.duration, ROW_H,
        formatDuration(run.durationSec, timeLimit), "GameFontHighlight", "RIGHT")
    if timeLimit and timeLimit > 0 then
        local limitStr = addon.formatMinutesSeconds(timeLimit)
        addCellTooltip(parent, colX["duration"], rowY, COL_W.duration, ROW_H,
            addon.locale["RUN_TOOLTIP_TIME_LIMIT"], limitStr)
    end

    addon.createTableCell(parent, colX["date"], rowY, COL_W.date, ROW_H,
        formatDate(run.completionDate), "GameFontHighlight", "RIGHT", true)

    addon.createTableCell(parent, colX["timeDelta"], rowY, COL_W.timeDelta, ROW_H,
        formatTimeDelta(run.durationSec, timeLimit), "GameFontHighlight", "RIGHT")

    if not isLast then
        addon.createRowDivider(parent, rowY - ROW_H, 0.3)
    end
end

---Re-renders just the row list (and the "no runs" placeholder) for the
---current filter selection, without touching the header/dropdowns/scrollbar
---above it — so toggling a filter checkbox doesn't close the dropdown menu
---the player is still using, the way a full tab reload would.
---@param scrollFrame ScrollFrame
---@param scrollChild Frame
---@param scrollChildW number
---@param sortedRunHistory table full, unfiltered, date-descending run list
---@param colX table
---@param nameW number
---@param scoreDeltas table keyed by run, computed once from the unfiltered history
local function renderFilteredRows(scrollFrame, scrollChild, scrollChildW, sortedRunHistory, colX, nameW, scoreDeltas)
    if rowsContainer then
        rowsContainer:Hide()
    end

    local filteredRuns = RunsFilterService:filterRuns(sortedRunHistory)

    local totalRowsH = #filteredRuns * ROW_H + PADDING_X
    scrollChild:SetSize(scrollChildW, totalRowsH)

    rowsContainer = CreateFrame("Frame", nil, scrollChild)
    rowsContainer:SetPoint("TOPLEFT",  scrollChild, "TOPLEFT",  0, 0)
    rowsContainer:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, 0)
    rowsContainer:SetHeight(totalRowsH)
    rowsContainer:Show()

    for i, run in ipairs(filteredRuns) do
        local rowY   = -((i - 1) * ROW_H)
        local isLast = (i == #filteredRuns)
        createRow(rowsContainer, run, colX, nameW, rowY, isLast, scoreDeltas)
    end

    if #filteredRuns == 0 then
        -- Parented to rowsContainer so it disappears with it on the next
        -- render, but anchored to scrollFrame's centre (not rowsContainer's,
        -- which is only PADDING_X tall with zero rows) so it lands in the
        -- middle of the visible table area rather than pinned to its top.
        local noData = rowsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        noData:SetPoint("CENTER", scrollFrame, "CENTER")
        noData:SetTextColor(0.65, 0.65, 0.65, 1)
        noData:SetText(addon.colors.POOR .. addon.locale["RUN_TABLE_NO_RUNS"] .. addon.colors.RESET)
    end

    scrollFrame:UpdateScrollChildRect()
end

---Builds one right-aligned multi-select filter dropdown using Blizzard's
---modern Menu API (WowStyle1DropdownTemplate + CreateCheckbox) — the same
---widget KeystonesPage.lua uses for its single-select mode dropdown, here
---with checkboxes so several options can be picked without the menu closing.
---@param parent Frame the tab's content panel
---@param anchorFrame Frame MPT_Dashboard.navFrame (rightmost dropdown) or the previously built dropdown
---@param anchorToNav boolean true to anchor to navFrame's BOTTOMRIGHT, false to chain off anchorFrame's LEFT
---@param staticLabel string always-shown category label, e.g. "Dungeon"
---@param getSelectedCount function returns how many options are currently selected
---@param buildOptions function(rootDescription) adds this dropdown's CreateCheckbox entries
---@return Button
local function createFilterDropdown(parent, anchorFrame, anchorToNav, staticLabel, getSelectedCount, buildOptions)
    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(FILTER_DROPDOWN_W)

    if anchorToNav then
        dropdown:SetPoint("TOPRIGHT", anchorFrame, "BOTTOMRIGHT", -CONTENT_INSET, -NAV_BOTTOM_MARGIN)
    else
        dropdown:SetPoint("RIGHT", anchorFrame, "LEFT", -FILTER_DROPDOWN_GAP, 0)
    end

    -- WowStyle1DropdownTemplate manages its own displayed text: it scans the
    -- menu for a "selected" entry on every refresh and shows that, which
    -- silently overwrites a manually called SetText — and for a CreateCheckbox
    -- -only menu (no single exclusively-selected entry the way CreateRadio
    -- has one) it falls back to blank instead. SetDefaultText/SetSelectionText
    -- are the widget's own hooks for this, so they don't get clobbered.
    dropdown:SetDefaultText(staticLabel)
    dropdown:SetSelectionText(function()
        local count = getSelectedCount()
        if count > 0 then
            return string.format("%s (%d)", staticLabel, count)
        end
        return staticLabel
    end)

    dropdown:SetupMenu(function(_, rootDescription)
        buildOptions(rootDescription)
    end)

    return dropdown
end

---Creates the filter row above the table, right-aligned: the "current week
---only" checkbox, then the Dungeon / Timed / Stufen-Bracket dropdowns. All
---selections live in addon.RunsFilterService — the three dropdowns persist
---account-wide, the checkbox deliberately only for the session (see the
---service). onFilterChanged runs after every toggle and does a row-only
---re-render (see renderFilteredRows) plus a Sidebar refresh, since the
---Sidebar's Timed Runs breakdown mirrors the same filter — see
---Sidebar/Content/RunStatisticsCard.lua. Best Run there stays season-wide on
---purpose.
---@param frame Frame the tab's content panel
---@param dungeons table array of mapChallengeModeIDs, from C_ChallengeMode.GetMapTable()
---@param onFilterChanged function
local function createRunsFilters(frame, dungeons, onFilterChanged)
    local levelDropdown = createFilterDropdown(frame, MPT_Dashboard.navFrame, true,
        addon.locale["RUN_COL_LEVEL"],
        function() return RunsFilterService:countSelected(DIMENSIONS.LEVEL_BRACKETS) end,
        function(rootDescription)
            for _, bracket in ipairs(LEVEL_BRACKETS) do
                rootDescription:CreateCheckbox(levelBracketLabel(bracket),
                    function() return RunsFilterService:isSelected(DIMENSIONS.LEVEL_BRACKETS, bracket.key) end,
                    function()
                        RunsFilterService:toggle(DIMENSIONS.LEVEL_BRACKETS, bracket.key)
                        onFilterChanged()
                    end)
            end
        end)

    local timedDropdown = createFilterDropdown(frame, levelDropdown, false,
        addon.locale["RUNS_FILTER_TIMED_LABEL"],
        function() return RunsFilterService:countSelected(DIMENSIONS.TIMED_STATES) end,
        function(rootDescription)
            local options = {
                { key = TIMED_STATES.TIMED,   label = addon.locale["RUN_COL_COMPLETED"] },
                { key = TIMED_STATES.UNTIMED, label = addon.locale["RUNS_FILTER_UNTIMED"] },
            }
            for _, option in ipairs(options) do
                rootDescription:CreateCheckbox(option.label,
                    function() return RunsFilterService:isSelected(DIMENSIONS.TIMED_STATES, option.key) end,
                    function()
                        RunsFilterService:toggle(DIMENSIONS.TIMED_STATES, option.key)
                        onFilterChanged()
                    end)
            end
        end)

    local dungeonDropdown = createFilterDropdown(frame, timedDropdown, false,
        addon.locale["RUN_COL_DUNGEON"],
        function() return RunsFilterService:countSelected(DIMENSIONS.DUNGEONS) end,
        function(rootDescription)
            for _, mapID in ipairs(dungeons) do
                local name = C_ChallengeMode.GetMapUIInfo(mapID)
                rootDescription:CreateCheckbox(name or ("Map " .. tostring(mapID)),
                    function() return RunsFilterService:isSelected(DIMENSIONS.DUNGEONS, mapID) end,
                    function()
                        RunsFilterService:toggle(DIMENSIONS.DUNGEONS, mapID)
                        onFilterChanged()
                    end)
            end
        end)

    -- Initial state comes from the service, not from a local: loadRuns runs
    -- again on every tab reselect, and the checkbox has to come back checked
    -- for as long as the session's filter says so.
    local weekCheckbox = addon.createLabeledCheckbox(frame,
        addon.locale["FILTER_CURRENT_WEEK_ONLY"],
        FILTER_CHECKBOX_SIZE,
        RunsFilterService:isCurrentWeekOnly(),
        function(checked)
            RunsFilterService:setCurrentWeekOnly(checked)
            onFilterChanged()
        end)

    weekCheckbox:SetPoint("RIGHT", dungeonDropdown, "LEFT", -FILTER_DROPDOWN_GAP, 0)
end

function MPT_Dashboard:loadRuns(frame)
    local dungeons = C_ChallengeMode.GetMapTable() or {}

    -- Sort a shallow copy — addon.RunHistoryService:getRuns() returns a cached, shared
    -- reference, and sorting it in place would silently reorder it for
    -- other consumers (e.g. DungeonsPage.lua, RunStatisticsCard.lua) too.
    local runHistory = {}
    for i, run in ipairs(addon.RunHistoryService:getRuns()) do
        runHistory[i] = run
    end

    table.sort(runHistory, function(a, b)
        return dateToSortKey(a.completionDate) > dateToSortKey(b.completionDate)
    end)

    -- Build score-delta map: for each run, how much did it improve the score
    -- for its dungeon compared to the previous best? Walk chronologically so
    -- prevBest reflects only runs that happened before the current one. This
    -- always uses the full, unfiltered history — filtering only changes which
    -- rows are displayed, not what counted as each dungeon's previous best.
    local scoreDeltas = {}
    local prevBest    = {}
    for i = #runHistory, 1, -1 do
        local run   = runHistory[i]
        local id    = run.mapChallengeModeID
        local key   = id .. "_" .. dateToSortKey(run.completionDate)
        local score = run.runScore or 0
        local delta = math.max(0, score - (prevBest[id] or 0))
        scoreDeltas[key] = {
            delta      = delta,
            scoreAfter = math.max(prevBest[id] or 0, score),
        }
        if score > (prevBest[id] or 0) then
            prevBest[id] = score
        end
    end

    local tableW       = DASHBOARD_W - CONTENT_INSET * 2
    local scrollChildW = tableW - SCROLL_BTN_SIZE - 4
    local fixedW   = COL_W.icon + COL_W.level + COL_W.completed + COL_W.score
                   + COL_W.duration + COL_W.date + COL_W.timeDelta
    local numGaps  = 7
    local nameW    = scrollChildW - PADDING_X * 2 - fixedW - numGaps * COL_GAP

    local colX  = {}
    local cursor = PADDING_X
    for _, key in ipairs({ "icon", "name", "level", "completed", "score", "duration", "timeDelta", "date" }) do
        colX[key] = cursor
        local w = (key == "name") and nameW or COL_W[key]
        cursor = cursor + w + COL_GAP
    end

    -- Drop the previous render's rows frame; a fresh loadRuns() call (e.g. tab
    -- reselect) otherwise leaves the old one dangling under the new scrollChild.
    rowsContainer = nil

    local outerFrame = CreateFrame("Frame", nil, frame)
    outerFrame:SetPoint("TOPLEFT",  MPT_Dashboard.navFrame, "BOTTOMLEFT",
        CONTENT_INSET, -(NAV_BOTTOM_MARGIN + FILTER_DROPDOWN_H + FILTER_DROPDOWN_MARGIN))
    outerFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -CONTENT_INSET, CONTENT_INSET)

    local headerFrame = CreateFrame("Frame", nil, outerFrame)
    headerFrame:SetPoint("TOPLEFT",  outerFrame, "TOPLEFT",  0, 0)
    headerFrame:SetPoint("TOPRIGHT", outerFrame, "TOPRIGHT", -(SCROLL_BTN_SIZE + 4), 0)
    headerFrame:SetHeight(HEADER_H + 1)

    createHeader(headerFrame, colX, nameW)

    local scrollFrame = CreateFrame("ScrollFrame", nil, outerFrame)
    scrollFrame:SetPoint("TOPLEFT",  outerFrame, "TOPLEFT",  0, -(HEADER_H + 2))
    scrollFrame:SetPoint("BOTTOMRIGHT", outerFrame, "BOTTOMRIGHT", -(SCROLL_BTN_SIZE + 4), 0)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(scrollChild)

    -- Wired before the first render, not after: renderFilteredRows ends with
    -- UpdateScrollChildRect, and the scrollbar only ever learns its size from
    -- an OnScrollRangeChanged that fires *after* it was attached. Wiring it
    -- afterwards meant the initial render had already moved the range to its
    -- final value, so the scrollbar never heard about it and hid itself.
    addon.createTableScrollbar(outerFrame, scrollFrame, ROW_H)

    createRunsFilters(frame, dungeons, function()
        renderFilteredRows(scrollFrame, scrollChild, scrollChildW, runHistory, colX, nameW, scoreDeltas)

        -- Deliberately only the Sidebar, never a full tab reload: reloading the
        -- tab would hide the dropdown's own parent panel and close the menu
        -- mid-selection. The Sidebar is a sibling frame, so rebuilding it
        -- leaves the open menu alone.
        if MPT_Sidebar and MPT_Sidebar.showForTab then
            MPT_Sidebar:showForTab(MPT_Tracker.TABS.RUNS)
        end
    end)

    renderFilteredRows(scrollFrame, scrollChild, scrollChildW, runHistory, colX, nameW, scoreDeltas)
end

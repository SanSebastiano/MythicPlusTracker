local addonName, addon = ...

local PADDING_X      = 8
local ROW_H          = 40
local HEADER_H       = 28
local COL_GAP        = 6
local ICON_SIZE      = 28
local DASHBOARD_W    = 800  -- matches Frame.lua
local CONTENT_INSET  = 20   -- aligns with divider caps
local NAV_BOTTOM_MARGIN = 8
local SCROLL_BTN_SIZE = 10  -- gutter reserved for the scrollbar (MinimalScrollBar is 8px wide)

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

local ARTIFACT_R, ARTIFACT_G, ARTIFACT_B = addon.colorToRGB("ARTIFACT")

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
    local str = string.format("%d:%02d", math.floor(sec / 60), sec % 60)
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
    local str      = string.format("%d:%02d", math.floor(absDelta / 60), absDelta % 60)
    if delta >= 0 then
        return addon.colors.TIMER_SUCCESS .. "+" .. str .. addon.colors.RESET
    end
    return addon.colors.TIMER_DANGER .. "-" .. str .. addon.colors.RESET
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
        local limitStr = string.format("%d:%02d", math.floor(timeLimit / 60), timeLimit % 60)
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

function MPT_Dashboard:loadRuns(frame)
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
    -- prevBest reflects only runs that happened before the current one.
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

    local outerFrame = CreateFrame("Frame", nil, frame)
    outerFrame:SetPoint("TOPLEFT",  MPT_Dashboard.navFrame, "BOTTOMLEFT",  CONTENT_INSET, -NAV_BOTTOM_MARGIN)
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
    local totalRowsH  = #runHistory * ROW_H + PADDING_X
    scrollChild:SetSize(scrollChildW, totalRowsH)
    scrollFrame:SetScrollChild(scrollChild)

    for i, run in ipairs(runHistory) do
        local rowY   = -((i - 1) * ROW_H)
        local isLast = (i == #runHistory)
        createRow(scrollChild, run, colX, nameW, rowY, isLast, scoreDeltas)
    end

    addon.createTableScrollbar(outerFrame, scrollFrame, ROW_H)

    if #runHistory == 0 then
        local noData = scrollFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        noData:SetPoint("CENTER", scrollFrame, "CENTER")
        noData:SetTextColor(0.65, 0.65, 0.65, 1)
        noData:SetText(addon.colors.POOR .. addon.locale["RUN_TABLE_NO_RUNS"] .. addon.colors.RESET)
    end
end

local addonName, addon = ...

local PADDING_X      = 8    -- left/right padding inside the table frame
local ROW_H          = 40   -- height of each data row
local HEADER_H       = 28   -- height of the header row
local COL_GAP        = 6    -- horizontal gap between columns
local ICON_SIZE      = 28   -- dungeon icon dimensions
local SCROLL_STEP    = ROW_H * 3   -- pixels per mousewheel scroll
local DASHBOARD_W    = 800  -- matches Frame.lua
local CONTENT_INSET  = 20   -- aligns with divider caps
local SUMMARY_MARGIN = 8    -- vertical gap below navFrame
local SCROLL_BTN_SIZE = 22  -- gutter reserved for the scrollbar (added later)

-- Fixed column widths sized to fit their header text (name column is computed dynamically)
local COL_W = {
    icon      = 34,
    level     = 42,
    completed = 38,
    score     = 50,
    duration  = 50,
    date      = 90,
    season    = 50,
}

-- Parsed RGB from addon.colors.ARTIFACT |cFFe6cc80
local ARTIFACT_R = 0xe6 / 255
local ARTIFACT_G = 0xcc / 255
local ARTIFACT_B = 0x80 / 255

local function formatLevel(level)
    if level and level > 0 then
        return addon.colorKeystoneLevel(level) .. "+" .. level .. addon.colors.RESET
    end
    return addon.colors.POOR .. "–" .. addon.colors.RESET
end

-- Score delta: how much this run improved the score for its dungeon vs the
-- previous best. Positive gain shown in gold, no gain shown as a dash.
local function formatScoreDelta(delta)
    if not delta or delta <= 0 then
        return addon.colors.POOR .. "–" .. addon.colors.RESET
    end
    return addon.colors.ARTIFACT .. "+" .. math.floor(delta) .. addon.colors.RESET
end

-- Duration: poor if over the time limit, white if within
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

local function formatSeason(s)
    if not s or s <= 0 then
        return addon.colors.POOR .. "–" .. addon.colors.RESET
    end
    return tostring(s)
end

local function addCell(parent, x, y, w, h, text, font, justifyH, wordWrap)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    fs:SetSize(w, h)
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetJustifyH(justifyH or "LEFT")
    fs:SetJustifyV("MIDDLE")
    if wordWrap then fs:SetWordWrap(true) end
    fs:SetText(text)
    return fs
end

-- Transparent interactive frame that shows a two-line GameTooltip on hover.
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
        { key = "date",      localeKey = "RUN_COL_DATE",    w = COL_W.date,      j = "RIGHT" },
        { key = "season",    localeKey = "RUN_COL_SEASON",  w = COL_W.season,    j = "RIGHT" },
    }

    for _, def in ipairs(headerDefs) do
        if def.localeKey then
            local label = addon.locale[def.localeKey] or def.localeKey
            local fs = addCell(parent, colX[def.key], 0, def.w, HEADER_H,
                               label, "GameFontNormal", def.j)
            fs:SetTextColor(ARTIFACT_R, ARTIFACT_G, ARTIFACT_B, 1)
        end
    end

    local div = parent:CreateTexture(nil, "ARTWORK")
    div:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, -HEADER_H)
    div:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -HEADER_H)
    div:SetHeight(1)
    div:SetColorTexture(0.45, 0.45, 0.65, 0.5)
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

    addCell(parent, colX["name"], rowY, nameW, ROW_H, name, "GameFontHighlight", "LEFT")

    addCell(parent, colX["level"], rowY, COL_W.level, ROW_H,
        formatLevel(run.level), "GameFontHighlight", "RIGHT")

    local cellX     = colX["completed"]
    local cellW     = COL_W.completed
    local MARK_SIZE = 16
    local markAtlas = run.completed and "common-icon-checkmark" or "common-icon-redx"
    local mark = parent:CreateTexture(nil, "ARTWORK")
    mark:SetAtlas(markAtlas, false)
    mark:SetSize(MARK_SIZE, MARK_SIZE)
    mark:SetPoint("TOPLEFT", parent, "TOPLEFT",
        cellX + (cellW - MARK_SIZE) / 2,
        rowY - (ROW_H - MARK_SIZE) / 2)

    -- Score delta: how much this run improved the dungeon score vs previous best
    local runKey     = run.mapChallengeModeID .. "_" .. dateToSortKey(run.completionDate)
    local runData    = scoreDeltas and scoreDeltas[runKey]
    local delta      = runData and runData.delta
    local scoreAfter = runData and runData.scoreAfter
    addCell(parent, colX["score"], rowY, COL_W.score, ROW_H,
        formatScoreDelta(delta), "GameFontHighlight", "RIGHT")
    if scoreAfter and scoreAfter > 0 then
        addCellTooltip(parent, colX["score"], rowY, COL_W.score, ROW_H,
            addon.locale["RUN_TOOLTIP_DUNGEON_SCORE"],
            math.floor(scoreAfter) .. "")
    end

    addCell(parent, colX["duration"], rowY, COL_W.duration, ROW_H,
        formatDuration(run.durationSec, timeLimit), "GameFontHighlight", "RIGHT")
    if timeLimit and timeLimit > 0 then
        local limitStr = string.format("%d:%02d", math.floor(timeLimit / 60), timeLimit % 60)
        addCellTooltip(parent, colX["duration"], rowY, COL_W.duration, ROW_H,
            addon.locale["RUN_TOOLTIP_TIME_LIMIT"], limitStr)
    end

    addCell(parent, colX["date"], rowY, COL_W.date, ROW_H,
        formatDate(run.completionDate), "GameFontHighlight", "RIGHT", true)

    addCell(parent, colX["season"], rowY, COL_W.season, ROW_H,
        formatSeason(run.season), "GameFontHighlight", "RIGHT")

    if not isLast then
        local div = parent:CreateTexture(nil, "ARTWORK")
        div:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, rowY - ROW_H)
        div:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, rowY - ROW_H)
        div:SetHeight(1)
        div:SetColorTexture(0.45, 0.45, 0.65, 0.3)
    end
end

function MPT_Dashboard:loadRuns(frame, topOffset)
    topOffset = topOffset or 0

    local runHistory = C_MythicPlus.GetRunHistory(true, true, true) or {}

    -- Sort newest first by completionDate (display order)
    table.sort(runHistory, function(a, b)
        return dateToSortKey(a.completionDate) > dateToSortKey(b.completionDate)
    end)

    -- Build score-delta map: for each run, how much did it improve the score
    -- for its dungeon compared to the previous best? Walk chronologically so
    -- prevBest reflects only runs that happened before the current one.
    local scoreDeltas = {}
    local prevBest    = {}
    -- Iterate newest-first slice in reverse = oldest-first
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

    -- Column layout — reserve right gutter for the scrollbar
    local tableW       = DASHBOARD_W - CONTENT_INSET * 2
    local scrollChildW = tableW - SCROLL_BTN_SIZE - 4
    local fixedW   = COL_W.icon + COL_W.level + COL_W.completed + COL_W.score
                   + COL_W.duration + COL_W.date + COL_W.season
    local numGaps  = 7   -- gaps between 8 columns
    local nameW    = scrollChildW - PADDING_X * 2 - fixedW - numGaps * COL_GAP

    local colX  = {}
    local cursor = PADDING_X
    for _, key in ipairs({ "icon", "name", "level", "completed", "score", "duration", "date", "season" }) do
        colX[key] = cursor
        local w = (key == "name") and nameW or COL_W[key]
        cursor = cursor + w + COL_GAP
    end

    local outerFrame = CreateFrame("Frame", nil, frame)
    outerFrame:SetPoint("TOPLEFT",  MPT_Dashboard.navFrame, "BOTTOMLEFT",  CONTENT_INSET, -SUMMARY_MARGIN)
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

    -- Mousewheel scrolling + WoW default scrollbar (UIPanelScrollBarTemplate)
    local scrollBar = CreateFrame("Slider", nil, outerFrame, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("TOPLEFT",    scrollFrame, "TOPRIGHT",    2, -16)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 2,  16)
    scrollBar:SetMinMaxValues(0, 0)
    scrollBar:SetValueStep(ROW_H)
    scrollBar:SetValue(0)

    -- Keep scrollFrame and scrollBar in sync
    scrollFrame:SetScript("OnScrollRangeChanged", function(self, _, yRange)
        local current = self:GetVerticalScroll()
        scrollBar:SetMinMaxValues(0, math.max(0, yRange))
        scrollBar:SetValue(math.min(current, math.max(0, yRange)))
    end)

    scrollBar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local maxScr = self:GetVerticalScrollRange()
        local newVal = math.max(0, math.min(maxScr, self:GetVerticalScroll() - delta * SCROLL_STEP))
        scrollBar:SetValue(newVal)
    end)

    if #runHistory == 0 then
        local noData = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        noData:SetPoint("CENTER", scrollChild, "CENTER")
        noData:SetTextColor(0.65, 0.65, 0.65, 1)
        noData:SetText(addon.colors.POOR .. "No runs recorded yet." .. addon.colors.RESET)
    end
end

local addonName, addon = ...

local PADDING_X  = 8    -- left/right padding inside the table frame
local ROW_H      = 50   -- height of each data row (increased for full-height table)
local HEADER_H   = 30   -- height of the header row
local COL_GAP    = 8    -- horizontal gap between columns
local ICON_SIZE  = 36   -- dungeon icon dimensions

-- Summary box layout  (matches Weekly Vault slot dimensions)
local SUMMARY_BOX_W  = 70   -- same as WeeklyVault SLOT_WIDTH
local SUMMARY_BOX_H  = 45   -- same as WeeklyVault SLOT_HEIGHT
local SUMMARY_GAP    = 8    -- same as WeeklyVault SLOT_GAP
local SUMMARY_MARGIN = 8    -- vertical gap below navFrame
local DASHBOARD_W    = 800  -- dashboard frame width (fixed in Frame.lua)
local CONTENT_INSET  = 20   -- aligns with the divider bar left/right caps

-- Key level tier definitions for the second summary row
local TIERS = {
    { min =  2, max =  3, label = "+2-3"  },
    { min =  4, max =  6, label = "+4-6"  },
    { min =  7, max =  9, label = "+7-9"  },
    { min = 10, max = 11, label = "+10-11" },
    { min = 12, max = 14, label = "+12-14" },
    { min = 15, max = math.huge, label = "+15+" },
}

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

-- ---------------------------------------------------------------------------
-- Sort state
-- ---------------------------------------------------------------------------

local sortCol = "name"
local sortDir = "asc"
local headerCells    = {}   -- [colKey] = FontString, updated when sort changes
local rowsContainer  = nil  -- recreated on each sort change

-- Locale key for each sortable column
local HEADER_LOCALE = {
    name      = "DUNGEON_COL_DUNGEON",
    bestLevel = "DUNGEON_COL_BEST_LEVEL",
    score     = "DUNGEON_COL_SCORE",
    runs      = "DUNGEON_COL_RUNS",
    success   = "DUNGEON_COL_SUCCESS",
    timeLimit = "DUNGEON_COL_TIME_LIMIT",
    bestTime  = "DUNGEON_COL_BEST_TIME",
}

-- Default sort direction when a column is first clicked
local DEFAULT_SORT_DIR = {
    name      = "asc",
    bestLevel = "desc",
    score     = "desc",
    runs      = "desc",
    success   = "desc",
    timeLimit = "asc",
    bestTime  = "asc",
}

-- Parsed RGB for header text color (from addon.colors.ARTIFACT |cFFe6cc80)
local ARTIFACT_R = 0xe6 / 255
local ARTIFACT_G = 0xcc / 255
local ARTIFACT_B = 0x80 / 255

-- ---------------------------------------------------------------------------
-- Data helpers
-- ---------------------------------------------------------------------------

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

        if run.level > e.bestLevel then
            e.bestLevel = run.level
            e.bestTime  = run.durationSec or 0
        end

        if run.score and run.score > e.bestScore then
            e.bestScore = run.score
        end
    end

    return lookup
end

local function buildTierCounts(runHistory)
    local counts = {}
    for i = 1, #TIERS do counts[i] = 0 end

    for _, run in ipairs(runHistory) do
        for i, tier in ipairs(TIERS) do
            if run.level >= tier.min and run.level <= tier.max then
                counts[i] = counts[i] + 1
                break
            end
        end
    end

    return counts
end

local function buildSummaryData(runLookup, dungeons)
    local highestKey  = 0
    local totalRuns   = 0
    local totalSuccess = 0

    for _, mapID in ipairs(dungeons) do
        local ri = runLookup[mapID]
        if ri then
            if ri.bestLevel > highestKey then highestKey = ri.bestLevel end
            totalRuns    = totalRuns    + ri.runs
            totalSuccess = totalSuccess + ri.success
        end
    end

    return { highestKey = highestKey, totalRuns = totalRuns, totalSuccess = totalSuccess }
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
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

local function formatBestTime(sec, timeLimitSec)
    if not sec or sec <= 0 then return "–" end
    local s = sec
    local str = string.format("%d:%02d", math.floor(s / 60), s % 60)
    local color = s <= timeLimitSec and addon.colors.WHITE or addon.colors.POOR
    return color .. str .. addon.colors.RESET
end

local function formatCount(n)
    return (n and n > 0) and tostring(n) or "–"
end

-- ---------------------------------------------------------------------------
-- Summary boxes
-- ---------------------------------------------------------------------------

local function createSummaryBox(container, xOffset, boxW, labelKey, valueText, subText, rawLabel)
    local box = CreateFrame("Frame", nil, container)
    box:SetSize(boxW, SUMMARY_BOX_H)
    box:SetPoint("TOPLEFT", container, "TOPLEFT", xOffset, 0)

    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(box)
    bg:SetAtlas("ui-frame-midnight-portraitdisable", true)

    local value = box:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    value:SetPoint("CENTER", box, "CENTER", 0, subText and 5 or 0)
    value:SetJustifyH("CENTER")
    value:SetText(valueText)

    if subText then
        local sub = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        sub:SetPoint("TOP", value, "BOTTOM", 0, -2)
        sub:SetJustifyH("CENTER")
        sub:SetTextColor(0.65, 0.65, 0.65, 1)
        sub:SetText(subText)
    end

    -- Tooltip on hover: rawLabel takes priority over locale lookup
    local tooltipText = rawLabel or (labelKey and (addon.locale[labelKey] or labelKey))
    if tooltipText then
        box:EnableMouse(true)
        box:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(tooltipText, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        box:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
end

local function createSummaryBoxes(parent, summaryData)
    local totalBoxW = SUMMARY_BOX_W * 3 + SUMMARY_GAP * 2

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(totalBoxW, SUMMARY_BOX_H)

    if MPT_Dashboard.navFrame then
        container:SetPoint("TOPLEFT", MPT_Dashboard.navFrame, "BOTTOMLEFT", CONTENT_INSET, -SUMMARY_MARGIN)
    else
        container:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_INSET, -SUMMARY_MARGIN)
    end

    -- Box 1: Highest Keystone
    local highestKeyText = summaryData.highestKey > 0
        and (addon.colorKeystoneLevel(summaryData.highestKey) .. "+" .. summaryData.highestKey .. addon.colors.RESET)
        or addon.colors.POOR .. "–" .. addon.colors.RESET
    createSummaryBox(container, 0, SUMMARY_BOX_W, "DASHBOARD_SUMMARY_HIGHEST_KEY", highestKeyText, nil)

    -- Box 2: Total Runs
    local totalRunsText = summaryData.totalRuns > 0
        and (addon.colors.WHITE .. summaryData.totalRuns .. addon.colors.RESET)
        or addon.colors.POOR .. "–" .. addon.colors.RESET
    createSummaryBox(container, SUMMARY_BOX_W + SUMMARY_GAP, SUMMARY_BOX_W, "DASHBOARD_SUMMARY_TOTAL_RUNS", totalRunsText, nil)

    -- Box 3: Successful Runs (with percentage below)
    local successText = summaryData.totalSuccess > 0
        and (addon.colors.SUCCESS .. summaryData.totalSuccess .. addon.colors.RESET)
        or addon.colors.POOR .. "–" .. addon.colors.RESET
    local pctText = nil
    if summaryData.totalRuns > 0 then
        local pct = math.floor(summaryData.totalSuccess / summaryData.totalRuns * 100 + 0.5)
        pctText = addon.colors.POOR .. pct .. "%" .. addon.colors.RESET
    end
    createSummaryBox(container, (SUMMARY_BOX_W + SUMMARY_GAP) * 2, SUMMARY_BOX_W, "DASHBOARD_SUMMARY_SUCCESS_RUNS", successText, pctText)

    return container
end

local function createTierBoxes(parent, tierCounts, anchorBelow)
    local totalW = SUMMARY_BOX_W * #TIERS + SUMMARY_GAP * (#TIERS - 1)

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(totalW, SUMMARY_BOX_H)
    container:SetPoint("TOPLEFT", anchorBelow, "BOTTOMLEFT", 0, -SUMMARY_MARGIN)

    for i, tier in ipairs(TIERS) do
        local xOffset = (i - 1) * (SUMMARY_BOX_W + SUMMARY_GAP)
        local count   = tierCounts[i] or 0
        local countText = count > 0
            and (addon.colorKeystoneLevel(tier.min) .. count .. addon.colors.RESET)
            or  (addon.colors.POOR .. "–" .. addon.colors.RESET)
        createSummaryBox(container, xOffset, SUMMARY_BOX_W, nil, countText, nil, tier.label)
    end

    return container
end

local function addCell(parent, x, y, w, h, text, font, justifyH)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    fs:SetSize(w, h)
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetJustifyH(justifyH or "LEFT")
    fs:SetJustifyV("MIDDLE")
    fs:SetText(text)
    return fs
end

local function createTableRow(child, mapID, colX, rowY, nameW, runLookup, isLast)
    local name, _, timeLimit, texture = C_ChallengeMode.GetMapUIInfo(mapID)
    if not name then return end

    local ri = runLookup[mapID]

    -- 1) Icon (centred vertically)
    local icon = child:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("TOPLEFT", child, "TOPLEFT", colX["icon"] + 2, rowY - (ROW_H - ICON_SIZE) / 2)
    icon:SetTexture(texture)

    -- 2) Name
    addCell(child, colX["name"], rowY, nameW, ROW_H, name, "GameFontHighlight", "LEFT")

    -- 3) Best level
    addCell(child, colX["bestLevel"], rowY, COL_W.bestLevel, ROW_H,
        formatLevel(ri and ri.bestLevel), "GameFontHighlight", "RIGHT")

    -- 4) Score
    addCell(child, colX["score"], rowY, COL_W.score, ROW_H,
        formatScore(getDungeonScore(mapID, ri)), "GameFontHighlight", "RIGHT")

    -- 5) Runs
    addCell(child, colX["runs"], rowY, COL_W.runs, ROW_H,
        formatCount(ri and ri.runs), "GameFontHighlight", "RIGHT")

    -- 6) Success
    addCell(child, colX["success"], rowY, COL_W.success, ROW_H,
        formatCount(ri and ri.success), "GameFontHighlight", "RIGHT")

    -- 7) Time limit
    addCell(child, colX["timeLimit"], rowY, COL_W.timeLimit, ROW_H,
        formatTimeMMSS(timeLimit), "GameFontHighlight", "RIGHT")

    -- 8) Best time
    addCell(child, colX["bestTime"], rowY, COL_W.bestTime, ROW_H,
        formatBestTime(ri and ri.bestTime, timeLimit), "GameFontHighlight", "RIGHT")

    -- Tooltip on best time cell: title "Zeitlimit" + empty line + signed delta
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
            local deltaStr = string.format("%d:%02d", math.floor(absDelta / 60), absDelta % 60)
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

    -- 1px horizontal divider at the bottom of this row (skip for the last row)
    if not isLast then
        local rowDiv = child:CreateTexture(nil, "ARTWORK")
        rowDiv:SetPoint("TOPLEFT",  child, "TOPLEFT",  0, rowY - ROW_H)
        rowDiv:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, rowY - ROW_H)
        rowDiv:SetHeight(1)
        rowDiv:SetColorTexture(0.45, 0.45, 0.65, 0.3)
    end
end

-- ---------------------------------------------------------------------------
-- Sorting helpers
-- ---------------------------------------------------------------------------

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

    table.sort(entries, function(a, b)
        if sortCol == "name" then
            if sortDir == "asc" then return a.name < b.name
            else                     return a.name > b.name end
        else
            local va = a[sortCol] or 0
            local vb = b[sortCol] or 0
            -- Push zero/no-data entries to the bottom regardless of direction
            if (va == 0) ~= (vb == 0) then return va ~= 0 end
            if sortDir == "desc" then return va > vb
            else                      return va < vb end
        end
    end)

    return entries
end

-- ---------------------------------------------------------------------------
-- Header row (sortable)
-- ---------------------------------------------------------------------------

local function updateHeaderIndicators()
    for colKey, fs in pairs(headerCells) do
        local localeKey = HEADER_LOCALE[colKey]
        local label     = addon.locale[localeKey] or localeKey
        local indicator = (colKey == sortCol) and (sortDir == "asc" and " ^" or " v") or ""
        fs:SetText(label .. indicator)
        fs:SetTextColor(ARTIFACT_R, ARTIFACT_G, ARTIFACT_B, 1)
    end
end

local function createTableHeader(child, colX, nameW, onSort)
    wipe(headerCells)

    local function hdrBtn(x, w, colKey, justifyH)
        local btn = CreateFrame("Button", nil, child)
        btn:SetSize(w, HEADER_H)
        btn:SetPoint("TOPLEFT", child, "TOPLEFT", x, 0)

        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetSize(w, HEADER_H)
        fs:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        fs:SetJustifyH(justifyH or "LEFT")
        fs:SetJustifyV("MIDDLE")

        headerCells[colKey] = fs

        btn:SetScript("OnClick", function()
            if sortCol == colKey then
                sortDir = sortDir == "asc" and "desc" or "asc"
            else
                sortCol = colKey
                sortDir = DEFAULT_SORT_DIR[colKey] or "asc"
            end
            updateHeaderIndicators()
            onSort()
        end)

        -- Highlight on hover
        btn:SetScript("OnEnter", function()
            fs:SetTextColor(1, 1, 1, 1)
        end)
        btn:SetScript("OnLeave", function()
            fs:SetTextColor(ARTIFACT_R, ARTIFACT_G, ARTIFACT_B, 1)
        end)
    end

    -- Sortable column buttons
    hdrBtn(colX["name"],      nameW,           "name",      "LEFT")
    hdrBtn(colX["bestLevel"], COL_W.bestLevel, "bestLevel", "RIGHT")
    hdrBtn(colX["score"],     COL_W.score,     "score",     "RIGHT")
    hdrBtn(colX["runs"],      COL_W.runs,      "runs",      "RIGHT")
    hdrBtn(colX["success"],   COL_W.success,   "success",   "RIGHT")
    hdrBtn(colX["timeLimit"], COL_W.timeLimit, "timeLimit", "RIGHT")
    hdrBtn(colX["bestTime"],  COL_W.bestTime,  "bestTime",  "RIGHT")

    -- Set initial text with indicators
    updateHeaderIndicators()

    -- 1px horizontal divider below header
    local div = child:CreateTexture(nil, "ARTWORK")
    div:SetPoint("TOPLEFT",  child, "TOPLEFT",  0, -HEADER_H)
    div:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, -HEADER_H)
    div:SetHeight(1)
    div:SetColorTexture(0.45, 0.45, 0.65, 0.5)
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

-- ---------------------------------------------------------------------------
-- Entry point
-- ---------------------------------------------------------------------------

function MPT_Dashboard:loadDungeons(frame, topOffset)
    topOffset = topOffset or 0
    local dungeons = C_ChallengeMode.GetMapTable()
    if not dungeons then return end

    local runHistory = C_MythicPlus.GetRunHistory(true, true, true) or {}
    local runLookup  = buildRunLookup(runHistory)

    -- Stats boxes are intentionally disabled here — kept for future use elsewhere:
    -- local tierCounts      = buildTierCounts(runHistory)
    -- local summaryData     = buildSummaryData(runLookup, dungeons)
    -- local summaryContainer = createSummaryBoxes(frame, summaryData)
    -- local tierContainer   = createTierBoxes(frame, tierCounts, summaryContainer)

    local tableW = DASHBOARD_W - CONTENT_INSET * 2  -- align with divider caps

    -- Compute column x-positions dynamically; name column takes remaining space
    local fixedW = COL_W.icon + COL_W.bestLevel + COL_W.score
                 + COL_W.runs + COL_W.success + COL_W.timeLimit + COL_W.bestTime
    local numGaps = 7  -- gaps between 8 columns
    local nameW = tableW - PADDING_X * 2 - fixedW - numGaps * COL_GAP

    local colX = {}
    local cursor = PADDING_X
    for _, key in ipairs({ "icon", "name", "bestLevel", "score", "runs", "success", "timeLimit", "bestTime" }) do
        colX[key] = cursor
        local w = (key == "name") and nameW or COL_W[key]
        cursor = cursor + w + COL_GAP
    end

    local childHeight = HEADER_H + 1 + #dungeons * ROW_H + PADDING_X

    -- Reset sort state so the table starts fresh each time the panel opens
    rowsContainer = nil
    wipe(headerCells)

    local tableFrame = CreateFrame("Frame", nil, frame)
    tableFrame:SetSize(tableW, childHeight)
    -- Anchor directly below the nav bar — table fills the full remaining height
    tableFrame:SetPoint("TOP",  MPT_Dashboard.navFrame, "BOTTOM", 0, -SUMMARY_MARGIN)
    tableFrame:SetPoint("LEFT", frame,                  "LEFT",   CONTENT_INSET, 0)

    createTableHeader(tableFrame, colX, nameW, function()
        renderRows(tableFrame, dungeons, colX, nameW, runLookup)
    end)

    renderRows(tableFrame, dungeons, colX, nameW, runLookup)
end

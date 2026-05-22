local addonName, addon = ...

-- Layout constants
local PADDING_X  = 8    -- left/right padding inside the scroll child
local ROW_H      = 38   -- height of each data row
local HEADER_H   = 24   -- height of the header row
local COL_GAP    = 6    -- horizontal gap between columns
local ICON_SIZE  = 28   -- dungeon icon dimensions

-- Fixed column widths (name column is computed dynamically)
local COL_W = {
    icon      = 36,
    bestLevel = 60,
    score     = 72,
    runs      = 48,
    success   = 60,
    timeLimit = 65,
    bestTime  = 70,
}

-- Row / header background colours
local ROW_BG_ODD  = { 0.04, 0.06, 0.14, 0.75 }
local ROW_BG_EVEN = { 0.07, 0.09, 0.18, 0.70 }
local HDR_BG      = { 0.0,  0.0,  0.04, 0.90 }

-- ---------------------------------------------------------------------------
-- Data helpers
-- ---------------------------------------------------------------------------

local function buildRunLookup()
    local lookup = {}

    for _, run in ipairs(C_MythicPlus.GetRunHistory(true, true, true) or {}) do
        local id = run.mapChallengeModeID

        if not lookup[id] then
            lookup[id] = {
                bestLevel = 0, bestTime = 0,
                bestScore = 0,
                runs = 0,     success = 0,
            }
        end

        local e = lookup[id]
        e.runs = e.runs + 1
        if run.completed then e.success = e.success + 1 end

        if run.level > e.bestLevel then
            e.bestLevel = run.level
            e.bestTime  = run.completionMilliseconds or 0
        end

        if run.score and run.score > e.bestScore then
            e.bestScore = run.score
        end
    end

    return lookup
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

local function formatBestTime(ms, timeLimitSec)
    if not ms or ms <= 0 then return "–" end
    local s = math.floor(ms / 1000)
    local str = string.format("%d:%02d", math.floor(s / 60), s % 60)
    local color = s <= timeLimitSec and addon.colors.WHITE or addon.colors.POOR
    return color .. str .. addon.colors.RESET
end

local function formatCount(n)
    return (n and n > 0) and tostring(n) or "–"
end

-- ---------------------------------------------------------------------------
-- Row builder
-- ---------------------------------------------------------------------------

local function addCell(parent, x, y, w, h, text, font, justifyH)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    fs:SetSize(w, h)
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetJustifyH(justifyH or "LEFT")
    fs:SetJustifyV("MIDDLE")
    fs:SetText(text)
    return fs
end

local function createTableRow(child, mapID, colX, rowY, nameW, runLookup, isEven)
    local name, _, timeLimit, texture = C_ChallengeMode.GetMapUIInfo(mapID)
    if not name then return end

    local ri = runLookup[mapID]
    local bg = isEven and ROW_BG_EVEN or ROW_BG_ODD

    -- Row background
    local rowBg = child:CreateTexture(nil, "BACKGROUND")
    rowBg:SetPoint("TOPLEFT",     child, "TOPLEFT",     0, rowY)
    rowBg:SetPoint("TOPRIGHT",    child, "TOPRIGHT",    0, rowY)
    rowBg:SetHeight(ROW_H)
    rowBg:SetColorTexture(bg[1], bg[2], bg[3], bg[4])

    -- 1) Icon
    local icon = child:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("TOPLEFT", child, "TOPLEFT", colX["icon"] + 4, rowY - (ROW_H - ICON_SIZE) / 2)
    icon:SetTexture(texture)

    -- 2) Name
    addCell(child, colX["name"], rowY, nameW, ROW_H, name, "GameFontHighlightSmall", "LEFT")

    -- 3) Best level
    addCell(child, colX["bestLevel"], rowY, COL_W.bestLevel, ROW_H,
        formatLevel(ri and ri.bestLevel), "GameFontHighlightSmall", "RIGHT")

    -- 4) Score
    addCell(child, colX["score"], rowY, COL_W.score, ROW_H,
        formatScore(getDungeonScore(mapID, ri)), "GameFontHighlightSmall", "RIGHT")

    -- 5) Runs
    addCell(child, colX["runs"], rowY, COL_W.runs, ROW_H,
        formatCount(ri and ri.runs), "GameFontHighlightSmall", "RIGHT")

    -- 6) Success
    addCell(child, colX["success"], rowY, COL_W.success, ROW_H,
        formatCount(ri and ri.success), "GameFontHighlightSmall", "RIGHT")

    -- 7) Time limit
    addCell(child, colX["timeLimit"], rowY, COL_W.timeLimit, ROW_H,
        formatTimeMMSS(timeLimit), "GameFontHighlightSmall", "RIGHT")

    -- 8) Best time
    addCell(child, colX["bestTime"], rowY, COL_W.bestTime, ROW_H,
        formatBestTime(ri and ri.bestTime, timeLimit), "GameFontHighlightSmall", "RIGHT")
end

-- ---------------------------------------------------------------------------
-- Header row
-- ---------------------------------------------------------------------------

local function createTableHeader(child, colX, nameW)
    local hdrBg = child:CreateTexture(nil, "BACKGROUND")
    hdrBg:SetPoint("TOPLEFT",  child, "TOPLEFT",  0, 0)
    hdrBg:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, 0)
    hdrBg:SetHeight(HEADER_H)
    hdrBg:SetColorTexture(HDR_BG[1], HDR_BG[2], HDR_BG[3], HDR_BG[4])

    local function hdrCell(x, w, localeKey, justifyH)
        local fs = child:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetSize(w, HEADER_H)
        fs:SetPoint("TOPLEFT", child, "TOPLEFT", x, 0)
        fs:SetJustifyH(justifyH or "LEFT")
        fs:SetJustifyV("MIDDLE")
        fs:SetText(addon.colors.ARTIFACT .. (addon.locale[localeKey] or localeKey) .. addon.colors.RESET)
    end

    hdrCell(colX["name"],      nameW,            "DUNGEON_COL_DUNGEON",    "LEFT")
    hdrCell(colX["bestLevel"], COL_W.bestLevel,  "DUNGEON_COL_BEST_LEVEL", "RIGHT")
    hdrCell(colX["score"],     COL_W.score,      "DUNGEON_COL_SCORE",      "RIGHT")
    hdrCell(colX["runs"],      COL_W.runs,       "DUNGEON_COL_RUNS",       "RIGHT")
    hdrCell(colX["success"],   COL_W.success,    "DUNGEON_COL_SUCCESS",    "RIGHT")
    hdrCell(colX["timeLimit"], COL_W.timeLimit,  "DUNGEON_COL_TIME_LIMIT", "RIGHT")
    hdrCell(colX["bestTime"],  COL_W.bestTime,   "DUNGEON_COL_BEST_TIME",  "RIGHT")

    -- 1px divider below header
    local div = child:CreateTexture(nil, "ARTWORK")
    div:SetPoint("TOPLEFT",  child, "TOPLEFT",  0, -HEADER_H)
    div:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, -HEADER_H)
    div:SetHeight(1)
    div:SetColorTexture(0.45, 0.45, 0.65, 0.8)
end

-- ---------------------------------------------------------------------------
-- Entry point
-- ---------------------------------------------------------------------------

function MPT_Dashboard:loadDungeons(frame, topOffset)
    topOffset = topOffset or 0
    local dungeons = C_ChallengeMode.GetMapTable()
    if not dungeons then return end

    local runLookup = buildRunLookup()

    local tableW = frame:GetWidth() - 20  -- 10px outer padding each side

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

    local tableFrame = CreateFrame("Frame", nil, frame)
    tableFrame:SetSize(tableW, childHeight)

    if MPT_Dashboard.navFrame then
        tableFrame:SetPoint("TOPLEFT", MPT_Dashboard.navFrame, "BOTTOMLEFT", 10, -34)
    else
        tableFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -(topOffset + 10))
    end

    createTableHeader(tableFrame, colX, nameW)

    for i, mapID in ipairs(dungeons) do
        local rowY = -(HEADER_H + 1 + (i - 1) * ROW_H)
        createTableRow(tableFrame, mapID, colX, rowY, nameW, runLookup, (i % 2 == 0))
    end
end

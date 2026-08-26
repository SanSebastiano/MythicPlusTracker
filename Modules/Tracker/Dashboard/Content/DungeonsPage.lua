local addonName, addon = ...

local PADDING_X  = 8
local ROW_H      = 50   -- increased over HEADER_H's 30 for a full-height table
local HEADER_H   = 30
local COL_GAP    = 8
local ICON_SIZE  = 36

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

    -- Soft blue pulse shown on hover when the teleport below is actually
    -- usable — a portal-shimmer cue on top of the plain brightening, so a
    -- clickable icon reads as different from a merely-brightened one.
    -- Plain color texture (no external asset) blended additively.
    local glow = child:CreateTexture(nil, "OVERLAY")
    glow:SetAllPoints(icon)
    glow:SetColorTexture(0.3, 0.6, 1, 1)
    glow:SetBlendMode("ADD")
    glow:Hide()

    local glowAnim = glow:CreateAnimationGroup()
    glowAnim:SetLooping("BOUNCE")
    local glowFade = glowAnim:CreateAnimation("Alpha")
    glowFade:SetFromAlpha(0.15)
    glowFade:SetToAlpha(0.55)
    glowFade:SetDuration(0.6)
    glowFade:SetSmoothing("IN_OUT")

    -- Clicking the dungeon icon teleports the player via the matching known
    -- "Path of ..." spell, if one is known (see Dashboard/DungeonTeleportCatalog.lua).
    -- Uses a SecureActionButtonTemplate so the protected spell cast is
    -- allowed to run directly from the click.
    local teleport = addon.getDungeonTeleport(mapID)
    local hasTeleport = teleport and C_SpellBook.IsSpellKnown(teleport.spellID)
    local teleportBtn = CreateFrame("Button", nil, child, "SecureActionButtonTemplate")
    teleportBtn:SetSize(ICON_SIZE, ICON_SIZE)
    -- Anchored with the same coordinates as `icon`, relative to `child` (a
    -- Frame) rather than `icon` itself (a Texture/region) — secure/protected
    -- frames cannot be anchored to regions, only to other frames.
    teleportBtn:SetPoint("TOPLEFT", child, "TOPLEFT", colX["icon"] + 2, rowY - (ROW_H - ICON_SIZE) / 2)
    teleportBtn:RegisterForClicks("AnyUp", "AnyDown")
    if hasTeleport then
        teleportBtn:SetAttribute("type", "spell")
        teleportBtn:SetAttribute("spell", teleport.spellID)
    end
    teleportBtn:SetScript("OnEnter", function(self)
        icon:SetVertexColor(1.15, 1.15, 1.15)
        if hasTeleport then
            glow:Show()
            glowAnim:Play()
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if hasTeleport then
            GameTooltip:SetSpellByID(teleport.spellID)
            GameTooltip:AddLine(addon.locale["DUNGEON_TELEPORT_TOOLTIP"], 0, 1, 0, true)
        else
            GameTooltip:AddLine(name, ARTIFACT_R, ARTIFACT_G, ARTIFACT_B)
            GameTooltip:AddLine(addon.locale["DUNGEON_TELEPORT_NOT_OWNED"], 1, 0.2, 0.2, true)
        end
        GameTooltip:Show()
    end)
    teleportBtn:SetScript("OnLeave", function()
        icon:SetVertexColor(1, 1, 1)
        glowAnim:Stop()
        glow:Hide()
        GameTooltip:Hide()
    end)

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

    local runHistory = addon.RunHistoryService:getRuns()
    local runLookup  = buildRunLookup(runHistory)

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
    tableFrame:SetPoint("TOP",  MPT_Dashboard.navFrame, "BOTTOM", 0, -NAV_BOTTOM_MARGIN)
    tableFrame:SetPoint("LEFT", frame,                  "LEFT",   CONTENT_INSET, 0)

    createTableHeader(tableFrame, colX, nameW, function()
        renderRows(tableFrame, dungeons, colX, nameW, runLookup)
    end)

    renderRows(tableFrame, dungeons, colX, nameW, runLookup)
end

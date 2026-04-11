local addonName, addon = ...

local CARD_WIDTH = 182
local CARD_HEIGHT = 240
local GAP = 10
local PADDING_X = 20
local PADDING_Y = 30
local COLS = 4

local function buildScoreLookup()
    local lookup = {}
    for _, info in ipairs(C_ChallengeMode.GetMapScoreInfo() or {}) do
        lookup[info.mapChallengeModeID] = info
    end
    return lookup
end

local function buildRunLookup()
    local lookup = {}
    for _, run in ipairs(C_MythicPlus.GetRunHistory(true, false, true) or {}) do
        local id = run.mapChallengeModeID
        if not lookup[id] then
            lookup[id] = { weeklyBest = 0, runs = 0, success = 0, weeklyRuns = 0, weeklySuccess = 0 }
        end
        local entry = lookup[id]
        entry.runs = entry.runs + 1
        if run.completed then entry.success = entry.success + 1 end
        if run.thisWeek then
            entry.weeklyRuns = entry.weeklyRuns + 1
            if run.completed then entry.weeklySuccess = entry.weeklySuccess + 1 end
            if run.level > entry.weeklyBest then entry.weeklyBest = run.level end
        end
    end
    return lookup
end

local function formatLevel(level)
    if level and level > 0 then
        return addon.colorKeystoneLevel(level) .. level .. addon.colors.RESET
    end
    return "–"
end

local function formatCount(n)
    return (n and n > 0) and tostring(n) or "–"
end

local function addInfoRow(card, label, value, yOff, rowH)
    local lbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", card, "TOPLEFT", 8, yOff)
    lbl:SetSize(CARD_WIDTH / 2 - 12, rowH)
    lbl:SetJustifyH("LEFT")
    lbl:SetJustifyV("MIDDLE")
    lbl:SetText(label)

    local val = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    val:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, yOff)
    val:SetSize(CARD_WIDTH / 2 - 12, rowH)
    val:SetJustifyH("RIGHT")
    val:SetJustifyV("MIDDLE")
    val:SetText(value)
end

local function createDungeonCard(parent, mapID, col, row, scoreLookup, runLookup)
    local name, _, timeLimit, texture = C_ChallengeMode.GetMapUIInfo(mapID)
    if not name then return end

    local scoreInfo = scoreLookup[mapID]
    local runInfo   = runLookup[mapID]

    local card = CreateFrame("Frame", nil, parent)
    card:SetSize(CARD_WIDTH, CARD_HEIGHT)
    card:SetPoint(
        "TOPLEFT", parent, "TOPLEFT",
        PADDING_X + col * (CARD_WIDTH + GAP),
        -(PADDING_Y + row * (CARD_HEIGHT + GAP))
    )

    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -8)
    icon:SetTexture(texture)

    local nameText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, 0)
    nameText:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, 0)
    nameText:SetHeight(28)
    nameText:SetJustifyH("LEFT")
    nameText:SetJustifyV("TOP")
    nameText:SetText(name)

    local timeText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
    timeText:SetText(math.floor(timeLimit / 60) .. " Min")
    timeText:SetJustifyH("LEFT")

    local ROW_H = 15
    local ROW_GAP = 2
    local HEADER_H = 13
    local SECTION_GAP = 6
    local yOff = -(8 + 28 + 2 + 12 + 10)

    -- Overall section
    local overallHeader = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    overallHeader:SetPoint("TOPLEFT", card, "TOPLEFT", 8, yOff)
    overallHeader:SetSize(CARD_WIDTH - 16, HEADER_H)
    overallHeader:SetJustifyH("LEFT")
    overallHeader:SetText(addon.colors.INFO .. addon.locale["DASHBOARD_OVERALL"] .. addon.colors.RESET)
    yOff = yOff - HEADER_H - ROW_GAP

    addInfoRow(card, addon.locale["DASHBOARD_BEST"],    formatLevel(scoreInfo and scoreInfo.level),        yOff, ROW_H) yOff = yOff - ROW_H - ROW_GAP
    addInfoRow(card, addon.locale["DASHBOARD_RUNS"],    formatCount(runInfo and runInfo.runs),             yOff, ROW_H) yOff = yOff - ROW_H - ROW_GAP
    addInfoRow(card, addon.locale["DASHBOARD_SUCCESS"], formatCount(runInfo and runInfo.success),          yOff, ROW_H) yOff = yOff - ROW_H - SECTION_GAP

    -- Weekly section
    local weeklyHeader = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    weeklyHeader:SetPoint("TOPLEFT", card, "TOPLEFT", 8, yOff)
    weeklyHeader:SetSize(CARD_WIDTH - 16, HEADER_H)
    weeklyHeader:SetJustifyH("LEFT")
    weeklyHeader:SetText(addon.colors.INFO .. addon.locale["DASHBOARD_WEEKLY"] .. addon.colors.RESET)
    yOff = yOff - HEADER_H - ROW_GAP

    addInfoRow(card, addon.locale["DASHBOARD_BEST"],    formatLevel(runInfo and runInfo.weeklyBest),       yOff, ROW_H) yOff = yOff - ROW_H - ROW_GAP
    addInfoRow(card, addon.locale["DASHBOARD_RUNS"],    formatCount(runInfo and runInfo.weeklyRuns),       yOff, ROW_H) yOff = yOff - ROW_H - ROW_GAP
    addInfoRow(card, addon.locale["DASHBOARD_SUCCESS"], formatCount(runInfo and runInfo.weeklySuccess),    yOff, ROW_H)
end

function MPT_Dashboard:loadDungeons(frame)
    local dungeons = C_ChallengeMode.GetMapTable()
    if not dungeons then return end

    local scoreLookup = buildScoreLookup()
    local runLookup = buildRunLookup()

    for i, mapID in ipairs(dungeons) do
        local col = (i - 1) % COLS
        local row = math.floor((i - 1) / COLS)
        createDungeonCard(frame, mapID, col, row, scoreLookup, runLookup)
    end
end

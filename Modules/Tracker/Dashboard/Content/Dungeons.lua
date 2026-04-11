local addonName, addon = ...

local CARD_WIDTH = 182
local CARD_HEIGHT = 240
local GAP = 10
local PADDING_X = 20
local PADDING_Y = 30
local COLS = 4

local INFO_LABELS = {"Best", "Weekly", "Runs", "Success"}

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
            lookup[id] = { weeklyBest = 0, runs = 0, success = 0 }
        end
        local entry = lookup[id]
        entry.runs = entry.runs + 1
        if run.completed then
            entry.success = entry.success + 1
        end
        if run.thisWeek and run.level > entry.weeklyBest then
            entry.weeklyBest = run.level
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

local function createDungeonCard(parent, mapID, col, row, scoreLookup, runLookup)
    local name, _, timeLimit, texture = C_ChallengeMode.GetMapUIInfo(mapID)
    if not name then return end

    local scoreInfo = scoreLookup[mapID]
    local runInfo = runLookup[mapID]

    local bestLevel = formatLevel(scoreInfo and scoreInfo.level)
    local weeklyBest = formatLevel(runInfo and runInfo.weeklyBest)
    local runs = runInfo and runInfo.runs > 0 and tostring(runInfo.runs) or "–"
    local success = runInfo and runInfo.success > 0 and tostring(runInfo.success) or "–"

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

    local infoStartY = -(8 + 28 + 2 + 12 + 8)
    local availableHeight = CARD_HEIGHT + infoStartY - 8
    local rowHeight = math.floor((availableHeight - 3 * 4) / 4)

    local infoValues = {bestLevel, weeklyBest, runs, success}

    for j, label in ipairs(INFO_LABELS) do
        local y = infoStartY - (j - 1) * (rowHeight + 4)

        local labelText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        labelText:SetPoint("TOPLEFT", card, "TOPLEFT", 8, y)
        labelText:SetSize(CARD_WIDTH / 2 - 12, rowHeight)
        labelText:SetJustifyH("LEFT")
        labelText:SetJustifyV("MIDDLE")
        labelText:SetText(label)

        local valueText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        valueText:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, y)
        valueText:SetSize(CARD_WIDTH / 2 - 12, rowHeight)
        valueText:SetJustifyH("RIGHT")
        valueText:SetJustifyV("MIDDLE")
        valueText:SetText(infoValues[j])
    end
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

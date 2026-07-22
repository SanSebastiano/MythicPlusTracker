local addonName, addon = ...

-- Header uses the same width/position convention as the Score card and the
-- RunsStats section headers.
local CONTENT_X = 23
local CONTENT_W = 254
local HEADER_Y  = -118

local INSET = 10   -- left/right inset inside content rows
local ROW_H = 24

local ARTIFACT_R = 0xe6 / 255
local ARTIFACT_G = 0xcc / 255
local ARTIFACT_B = 0x80 / 255

---Returns the score-tier color for a given overall Mythic+ score, matching
---the coloring used for the local player's own score card.
---@param score number
---@return string colorCode
local function colorForScore(score)
    if score <= 999 then
        return addon.colors.POOR
    elseif score <= 1499 then
        return addon.colors.UNCOMMON
    elseif score <= 1999 then
        return addon.colors.RARE
    elseif score <= 2499 then
        return addon.colors.EPIC
    elseif score <= 2999 then
        return addon.colors.LEGENDARY
    end
    return addon.colors.ARTIFACT
end

local function createHeader(sidebar)
    local headerFrame = CreateFrame("Frame", nil, sidebar)
    headerFrame:SetSize(CONTENT_W, 46)
    headerFrame:SetPoint("TOPLEFT", sidebar, "TOPLEFT", CONTENT_X, HEADER_Y)

    local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints(headerFrame)
    headerBg:SetAtlas(addon.theme.CARD_TITLE_BACKGROUND, false)

    local headerLabel = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerLabel:SetPoint("CENTER", headerFrame, "CENTER", 0, 0)
    headerLabel:SetTextColor(ARTIFACT_R, ARTIFACT_G, ARTIFACT_B, 1)
    headerLabel:SetText(addon.locale["SIDEBAR_GROUP_HEADER"])
end

---Renders a single group member row: class-colored name on the left, score
---(or a fallback message) right-aligned.
---@param sidebar Frame
---@param unitToken string
---@param rowY number
local function createRow(sidebar, unitToken, rowY)
    if not UnitExists(unitToken) then
        return
    end

    local unitName = UnitName(unitToken) or "?"
    local _, englishClass = UnitClass(unitToken)

    local nameText = sidebar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetPoint("TOPLEFT", sidebar, "TOPLEFT", CONTENT_X + INSET, rowY)
    nameText:SetSize(CONTENT_W - INSET * 2 - 70, ROW_H)
    nameText:SetJustifyH("LEFT")
    nameText:SetJustifyV("MIDDLE")
    nameText:SetText(unitName)
    local classColor = englishClass and RAID_CLASS_COLORS[englishClass]
    if classColor then
        nameText:SetTextColor(classColor.r, classColor.g, classColor.b)
    end

    local fullPlayerName = addon.Communication:GetFullPlayerName(unitToken)
    local groupData = fullPlayerName and addon.groupKeystones[fullPlayerName]

    local scoreText = sidebar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    scoreText:SetPoint("TOPRIGHT", sidebar, "TOPLEFT", CONTENT_X + CONTENT_W - INSET, rowY)
    scoreText:SetSize(60, ROW_H)
    scoreText:SetJustifyH("RIGHT")
    scoreText:SetJustifyV("MIDDLE")

    if groupData and groupData.hasAddon and groupData.score then
        scoreText:SetText(colorForScore(groupData.score) .. groupData.score .. addon.colors.RESET)
    else
        scoreText:SetText(addon.colors.POOR .. "-" .. addon.colors.RESET)
    end
end

local function loadGroupScores(sidebar)
    addon.debugMessage("Loading sidebar: group scores...")

    createHeader(sidebar)

    if addon.Communication then
        addon.Communication:RequestGroupKeystones()
    end

    local unitTokens = addon.Communication and addon.Communication:GetGroupUnitTokens() or { "player" }

    -- Exclude the local player: their own score is already shown in the
    -- Score card above this section.
    local otherUnitTokens = {}
    for _, unitToken in ipairs(unitTokens) do
        if unitToken ~= "player" then
            table.insert(otherUnitTokens, unitToken)
        end
    end

    local rowY = HEADER_Y - 46 - 8

    if #otherUnitTokens == 0 then
        local noMembers = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        noMembers:SetPoint("TOPLEFT", sidebar, "TOPLEFT", CONTENT_X, rowY)
        noMembers:SetSize(CONTENT_W, ROW_H * 2)
        noMembers:SetJustifyH("CENTER")
        noMembers:SetJustifyV("MIDDLE")
        noMembers:SetWordWrap(true)
        noMembers:SetText(addon.colors.POOR .. addon.locale["SIDEBAR_GROUP_NO_MEMBERS"] .. addon.colors.RESET)
        return
    end

    for index, unitToken in ipairs(otherUnitTokens) do
        if index > 1 then
            local divider = sidebar:CreateTexture(nil, "ARTWORK")
            divider:SetPoint("TOPLEFT",  sidebar, "TOPLEFT", CONTENT_X + INSET, rowY)
            divider:SetPoint("TOPRIGHT", sidebar, "TOPLEFT", CONTENT_X + CONTENT_W - INSET, rowY)
            divider:SetHeight(1)
            divider:SetColorTexture(0.45, 0.45, 0.65, 0.3)
        end

        createRow(sidebar, unitToken, rowY)
        rowY = rowY - ROW_H
    end
end

if MPT_Sidebar then
    MPT_Sidebar.loadGroupScores = loadGroupScores
end

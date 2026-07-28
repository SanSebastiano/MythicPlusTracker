local addonName, addon = ...

local SCORE_HEIGHT = 80

local function loadScore(sidebar, cursor)
    addon.debugMessage("Loading sidebar: score...")

    local y = cursor:current()
    cursor:advance(SCORE_HEIGHT)

    local frame = CreateFrame(
        "Frame",
        nil,
        sidebar
    )

    frame:SetSize(254, SCORE_HEIGHT)
    frame:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 23, y)

    local background = frame:CreateTexture(nil, "OVERLAY")
    background:SetAllPoints()
    background:SetAtlas(addon.theme.CARD_TITLE_BACKGROUND, false)

    local score = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    score:SetPoint("CENTER", background, "CENTER", 0, 0)
    score:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")

    local overallDungeonScore = C_ChallengeMode.GetOverallDungeonScore()
    local color
    if not overallDungeonScore then
        color = addon.colors.WARNING
        score:SetText(color .. "ERROR" .. addon.colors.RESET)
    else
        color = addon.colorForScore(overallDungeonScore)
        score:SetText(color .. overallDungeonScore .. addon.colors.RESET)
    end
end

MPT_Sidebar.getScore = loadScore

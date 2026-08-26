local addonName, addon = ...

local CONTENT_W = MPT_Sidebar.LAYOUT.CONTENT_W
local SCORE_HEIGHT = 80

function MPT_Sidebar:loadScore(sidebar, cursor)
    addon.debugMessage("Loading sidebar: score...")

    local y = cursor:current()
    cursor:advance(SCORE_HEIGHT)

    local frame = CreateFrame(
        "Frame",
        nil,
        sidebar
    )

    frame:SetSize(CONTENT_W, SCORE_HEIGHT)
    frame:SetPoint("TOPLEFT", sidebar, "TOPLEFT", MPT_Sidebar.LAYOUT.CONTENT_X, y)

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

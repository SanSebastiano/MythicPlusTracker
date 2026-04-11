local addonName, addon = ...

local function loadScore(sidebar)
    addon.debugMessage("Loading sidebar: score...")

    local frame = CreateFrame(
        "Frame",
        nil,
        sidebar
    )

    frame:SetSize(254, 80)
    frame:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 23, -30)

    local background = frame:CreateTexture(nil, "OVERLAY")
    background:SetAllPoints()
    background:SetAtlas("ui-frame-midnight-border-title-bg", false)

    local score = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    score:SetPoint("CENTER", background, "CENTER", 0, 0)
    score:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")

    overallDungeonScore = C_ChallengeMode.GetOverallDungeonScore()
    if not overallDungeonScore then
        color = addon.colors.WARNING
        score:SetText(color .. "ERROR" .. addon.colors.RESET)
    else
        if overallDungeonScore <= 999 then
            color = addon.colors.POOR
        elseif overallDungeonScore <= 1499 then
            color = addon.colors.UNCOMMON
        elseif overallDungeonScore <= 1999 then
            color = addon.colors.RARE
        elseif overallDungeonScore <= 2499 then
            color = addon.colors.EPIC
        elseif overallDungeonScore <= 2999 then
            color = addon.colors.LEGENDARY
        else
            color = addon.colors.ARTIFACT
        end

        score:SetText(color .. overallDungeonScore .. addon.colors.RESET)
    end
end

if MPT_Sidebar then
    MPT_Sidebar.getScore = loadScore
end

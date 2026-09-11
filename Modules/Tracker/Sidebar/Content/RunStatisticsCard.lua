local addonName, addon = ...

-- Both the title banner and the tier header use the full Score-card width (see MPT_Sidebar.LAYOUT)
local CONTENT_X = MPT_Sidebar.LAYOUT.CONTENT_X
local CONTENT_W = MPT_Sidebar.LAYOUT.CONTENT_W

local ICON_SIZE = 22
local INSET     = 10

local ARTIFACT_R, ARTIFACT_G, ARTIFACT_B = addon.colorToRGB("ARTIFACT")
local RUNSSTATS_GAP = 8   -- gap after the previous card (Score)

-- Shared with the Runs tab's level filter so the two can't disagree about a
-- boundary — the rows below are that filter's own buckets. Ascending there,
-- rendered descending here.
local LEVEL_BRACKETS = addon.RunsFilterService.LEVEL_BRACKETS

local BRACKET_RANGE_SEPARATOR = " – "

---@param bracket table one entry from addon.RunsFilterService.LEVEL_BRACKETS
---@return string
local function bracketLabel(bracket)
    if bracket.max then
        return bracket.min .. BRACKET_RANGE_SEPARATOR .. bracket.max
    end
    return bracket.min .. "+"
end

function MPT_Sidebar:loadRunStatistics(sidebar, cursor)
    addon.debugMessage("Loading sidebar: runs stats...")

    local runHistory = addon.RunHistoryService:getRuns()

    -- Best Run intentionally ignores the Runs tab's filter: it is the season's
    -- best and stays a fixed reference next to the filtered breakdown below.
    -- Don't "fix" this to match.
    local bestRun = nil
    for _, run in ipairs(runHistory) do
        if not bestRun or (run.runScore or 0) > (bestRun.runScore or 0) then
            bestRun = run
        end
    end

    -- -----------------------------------------------------------------------
    -- "Best Run" title banner. Matches the Score card's width and height
    -- proportions exactly. All Y positions below are relative to titleY.
    -- -----------------------------------------------------------------------
    local titleY = cursor:current() - RUNSSTATS_GAP

    local titleFrame = CreateFrame("Frame", nil, sidebar)
    titleFrame:SetSize(CONTENT_W, 46)
    titleFrame:SetPoint("TOPLEFT", sidebar, "TOPLEFT", CONTENT_X, titleY)

    local titleBg = titleFrame:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints(titleFrame)
    titleBg:SetAtlas(addon.theme.CARD_TITLE_BACKGROUND, false)

    local titleLabel = titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleLabel:SetPoint("CENTER", titleFrame, "CENTER", 0, 0)
    titleLabel:SetTextColor(ARTIFACT_R, ARTIFACT_G, ARTIFACT_B, 1)
    titleLabel:SetText(addon.locale["SIDEBAR_RUNS_BEST_RUN"])

    -- -----------------------------------------------------------------------
    -- Best run content  (title bottom: titleY-46, 8px gap → titleY-54)
    -- Tier header fixed at titleY-108 (covers both run and no-run content heights).
    -- -----------------------------------------------------------------------
    local bestRunY = titleY - 54
    if bestRun then
        local mapID = bestRun.mapChallengeModeID
        local name, _, _, texture = C_ChallengeMode.GetMapUIInfo(mapID)
        name = name or ("Map " .. tostring(mapID))

        if texture then
            local icon = sidebar:CreateTexture(nil, "ARTWORK")
            icon:SetSize(ICON_SIZE, ICON_SIZE)
            icon:SetPoint("TOPLEFT", sidebar, "TOPLEFT", CONTENT_X + INSET, bestRunY)
            icon:SetTexture(texture)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end

        local nameLabel = sidebar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        nameLabel:SetPoint("TOPLEFT",  sidebar, "TOPLEFT",  CONTENT_X + INSET + ICON_SIZE + 5, bestRunY)
        nameLabel:SetPoint("TOPRIGHT", sidebar, "TOPLEFT",  CONTENT_X + CONTENT_W - INSET - 40, bestRunY)
        nameLabel:SetHeight(ICON_SIZE)
        nameLabel:SetJustifyH("LEFT")
        nameLabel:SetJustifyV("MIDDLE")
        nameLabel:SetText(name)

        local levelLabel = sidebar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        levelLabel:SetPoint("TOPRIGHT", sidebar, "TOPLEFT", CONTENT_X + CONTENT_W - INSET, bestRunY)
        levelLabel:SetSize(38, ICON_SIZE)
        levelLabel:SetJustifyH("RIGHT")
        levelLabel:SetJustifyV("MIDDLE")
        levelLabel:SetText(addon.colorKeystoneLevel(bestRun.level) .. "+" .. bestRun.level .. addon.colors.RESET)
    else
        local noRun = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        noRun:SetSize(CONTENT_W, 44)
        noRun:SetPoint("TOPLEFT", sidebar, "TOPLEFT", CONTENT_X, bestRunY)
        noRun:SetJustifyH("CENTER")
        noRun:SetJustifyV("MIDDLE")
        noRun:SetWordWrap(true)
        noRun:SetText(addon.colors.POOR .. addon.locale["SIDEBAR_RUNS_NO_RUNS"] .. addon.colors.RESET)
    end

    -- Resolved before any frame code: only this header is filtered, so only it
    -- says so. The Best Run banner above must keep its plain title.
    local headerText = addon.locale["SIDEBAR_RUNS_TIER_HEADER"]
    if addon.RunsFilterService:hasActiveFilter() then
        headerText = string.format(addon.locale["SIDEBAR_RUNS_TIER_HEADER_FILTERED"], headerText)
    end

    -- -----------------------------------------------------------------------
    -- "Timed Runs" section header  (fixed at titleY-108)
    -- Height 46 so the text has breathing room and the atlas isn't over-scaled.
    -- -----------------------------------------------------------------------
    local headerY = titleY - 108
    local headerFrame = CreateFrame("Frame", nil, sidebar)
    headerFrame:SetSize(CONTENT_W, 46)
    headerFrame:SetPoint("TOPLEFT", sidebar, "TOPLEFT", CONTENT_X, headerY)

    local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints(headerFrame)
    headerBg:SetAtlas(addon.theme.CARD_TITLE_BACKGROUND, false)

    local headerLabel = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerLabel:SetPoint("CENTER", headerFrame, "CENTER", 0, 0)
    headerLabel:SetTextColor(ARTIFACT_R, ARTIFACT_G, ARTIFACT_B, 1)
    headerLabel:SetText(headerText)

    -- -----------------------------------------------------------------------
    -- Tier breakdown  (header bottom: headerY-46, 8px gap → titleY-162)
    -- Two columns: total (POOR) | successful/completed (ARTIFACT if >0, POOR if 0)
    -- Column layout: label | total right-aligned at -48 | success right-aligned at 0
    -- -----------------------------------------------------------------------
    local COL_SUCCESS = CONTENT_X + CONTENT_W - INSET
    local COL_TOTAL   = CONTENT_X + CONTENT_W - INSET - 48

    -- One pass, bucketed by the filter service's own bracket lookup, so the
    -- boundaries can't drift from the Runs tab's dropdown. runHistory is the
    -- shared cached table and is only read here — never sorted or mutated.
    local counts  = {}
    local success = {}
    for _, run in ipairs(runHistory) do
        if addon.RunsFilterService:isRunIncluded(run) then
            local bracketKey = addon.RunsFilterService:getLevelBracketKey(run.level)
            if bracketKey then
                counts[bracketKey] = (counts[bracketKey] or 0) + 1
                if run.completed then
                    success[bracketKey] = (success[bracketKey] or 0) + 1
                end
            end
        end
    end

    local sectionY = titleY - 162
    local ROW_H    = 22

    local LABEL_W = COL_TOTAL - (CONTENT_X + INSET) - 6

    local hLevel = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hLevel:SetPoint("TOPLEFT", sidebar, "TOPLEFT", CONTENT_X + INSET, sectionY)
    hLevel:SetSize(LABEL_W, ROW_H)
    hLevel:SetJustifyH("LEFT")
    hLevel:SetJustifyV("MIDDLE")
    hLevel:SetTextColor(ARTIFACT_R, ARTIFACT_G, ARTIFACT_B, 1)
    hLevel:SetText(addon.locale["DUNGEON_COL_BEST_LEVEL"])

    local hTotal = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hTotal:SetPoint("TOPRIGHT", sidebar, "TOPLEFT", COL_TOTAL, sectionY)
    hTotal:SetSize(40, ROW_H)
    hTotal:SetJustifyH("RIGHT")
    hTotal:SetJustifyV("MIDDLE")
    hTotal:SetTextColor(ARTIFACT_R, ARTIFACT_G, ARTIFACT_B, 1)
    hTotal:SetText(addon.locale["DUNGEON_COL_RUNS"])

    local hSuccess = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hSuccess:SetPoint("TOPRIGHT", sidebar, "TOPLEFT", COL_SUCCESS, sectionY)
    hSuccess:SetSize(40, ROW_H)
    hSuccess:SetJustifyH("RIGHT")
    hSuccess:SetJustifyV("MIDDLE")
    hSuccess:SetTextColor(ARTIFACT_R, ARTIFACT_G, ARTIFACT_B, 1)
    hSuccess:SetText(addon.locale["DUNGEON_COL_SUCCESS"])

    local hDiv = sidebar:CreateTexture(nil, "ARTWORK")
    hDiv:SetPoint("TOPLEFT",  sidebar, "TOPLEFT",  CONTENT_X + INSET, sectionY - ROW_H)
    hDiv:SetPoint("TOPRIGHT", sidebar, "TOPLEFT",  CONTENT_X + CONTENT_W - INSET, sectionY - ROW_H)
    hDiv:SetHeight(1)
    hDiv:SetColorTexture(0.45, 0.45, 0.65, 0.5)

    sectionY = sectionY - ROW_H - 2

    -- Iterated backwards: LEVEL_BRACKETS is ascending (it is the filter's own
    -- order), this table reads highest-first. The divider therefore sits above
    -- every row except the first rendered one, which is the *last* index.
    for i = #LEVEL_BRACKETS, 1, -1 do
        local bracket = LEVEL_BRACKETS[i]

        if i < #LEVEL_BRACKETS then
            local div = sidebar:CreateTexture(nil, "ARTWORK")
            div:SetPoint("TOPLEFT",  sidebar, "TOPLEFT",  CONTENT_X + INSET, sectionY)
            div:SetPoint("TOPRIGHT", sidebar, "TOPLEFT",  CONTENT_X + CONTENT_W - INSET, sectionY)
            div:SetHeight(1)
            div:SetColorTexture(0.45, 0.45, 0.65, 0.3)
        end

        local labelFS = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        labelFS:SetPoint("TOPLEFT", sidebar, "TOPLEFT", CONTENT_X + INSET, sectionY)
        labelFS:SetSize(LABEL_W, ROW_H)
        labelFS:SetJustifyH("LEFT")
        labelFS:SetJustifyV("MIDDLE")
        labelFS:SetText(bracketLabel(bracket))
        labelFS:SetTextColor(0.85, 0.85, 0.85, 1)

        local totalFS = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        totalFS:SetPoint("TOPRIGHT", sidebar, "TOPLEFT", COL_TOTAL, sectionY)
        totalFS:SetSize(40, ROW_H)
        totalFS:SetJustifyH("RIGHT")
        totalFS:SetJustifyV("MIDDLE")
        totalFS:SetText(addon.colors.POOR .. tostring(counts[bracket.key] or 0) .. addon.colors.RESET)

        local won        = success[bracket.key] or 0
        local wonColor   = won > 0 and addon.colors.ARTIFACT or addon.colors.POOR
        local successFS  = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        successFS:SetPoint("TOPRIGHT", sidebar, "TOPLEFT", COL_SUCCESS, sectionY)
        successFS:SetSize(40, ROW_H)
        successFS:SetJustifyH("RIGHT")
        successFS:SetJustifyV("MIDDLE")
        successFS:SetText(wonColor .. tostring(won) .. addon.colors.RESET)

        sectionY = sectionY - ROW_H
    end
end

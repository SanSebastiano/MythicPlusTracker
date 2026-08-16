local addonName, addon = ...

MythicPlusTrackerDB = MythicPlusTrackerDB or {}

-- Same left/width convention as the Score card and the other Sidebar cards.
local CONTENT_X = 23
local CONTENT_W = 254
local INSET     = 10   -- left/right inset inside content rows, matches RunsStats.lua

local SECTION_GAP           = 8  -- gap before the section's header
local HEADER_TO_CONTENT_GAP = 4  -- gap between header banner and its rows (matches WeeklyVault.lua)

local ROW_H       = 22  -- matches RunsStats.lua's tier rows
local VALUE_W     = 90  -- wide enough for the "Best" row's "<Name> +<Level>" value
local VALUE_RIGHT = CONTENT_X + CONTENT_W - INSET
local LABEL_W     = CONTENT_W - INSET * 2 - VALUE_W - 6

local EMPTY_TEXT_H = 54

---@return boolean
local function isAltsMode()
    return MythicPlusTrackerDB.keystonesTabMode == "alts"
end

---A thin 1px divider spanning the same inset content width as the rows
---themselves (CONTENT_X+INSET .. CONTENT_X+CONTENT_W-INSET) — same
---convention as the hand-built dividers in RunsStats.lua, not the full-width
---addon.createRowDivider (that one spans the whole 300px sidebar frame).
---@param sidebar Frame
---@param y number
---@param alpha number
local function sectionDivider(sidebar, y, alpha)
    local div = sidebar:CreateTexture(nil, "ARTWORK")
    div:SetPoint("TOPLEFT",  sidebar, "TOPLEFT", CONTENT_X + INSET, y)
    div:SetPoint("TOPRIGHT", sidebar, "TOPLEFT", CONTENT_X + CONTENT_W - INSET, y)
    div:SetHeight(1)
    div:SetColorTexture(0.45, 0.45, 0.65, alpha)
end

---One label/value table row, styled like RunsStats.lua's tier rows.
---@param sidebar Frame
---@param y number
---@param label string
---@param valueText string already color-coded, ready to SetText
local function renderRow(sidebar, y, label, valueText)
    local labelFS = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelFS:SetPoint("TOPLEFT", sidebar, "TOPLEFT", CONTENT_X + INSET, y)
    labelFS:SetSize(LABEL_W, ROW_H)
    labelFS:SetJustifyH("LEFT")
    labelFS:SetJustifyV("MIDDLE")
    labelFS:SetTextColor(0.85, 0.85, 0.85, 1)
    labelFS:SetText(label)

    local valueFS = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valueFS:SetPoint("TOPRIGHT", sidebar, "TOPLEFT", VALUE_RIGHT, y)
    valueFS:SetSize(VALUE_W, ROW_H)
    valueFS:SetJustifyH("RIGHT")
    valueFS:SetJustifyV("MIDDLE")
    valueFS:SetText(valueText)
end

---Builds the "Best" row's value text: class-colored name + keystone-level-
---colored "+level", or a plain "–" fallback when nobody currently holds a
---key. Kept as its own value string (not a special full-width row) so it
---renders through the same renderRow() as every other stat, keeping the
---section a single consistent table.
---@param stats table from computeStats
---@return string
local function formatBestValue(stats)
    if not stats.best then
        return addon.colors.POOR .. "–" .. addon.colors.RESET
    end

    local classColor = stats.best.class and RAID_CLASS_COLORS[stats.best.class]
    local coloredName = classColor and classColor:WrapTextInColorCode(stats.best.name) or stats.best.name
    return coloredName .. " " .. addon.colorKeystoneLevel(stats.best.level) .. "+" .. stats.best.level .. addon.colors.RESET
end

---Aggregates a list of normalized {name, class, mapID, level, score} entries
---(the shared shape produced by buildGroupStatEntries() and, already,
---addon.AltKeystones:GetEntries()) into the numbers this panel shows.
---Averages only ever consider entries with a known value, so a member
---without the addon (nil score) can't drag the average toward zero.
---"Best" ranks by level first, score as the tiebreaker.
---@param entries table
---@return table stats { avgScore, avgLevel, withKey, total, best }
local function computeStats(entries)
    local scoreSum, scoreCount = 0, 0
    local levelSum, levelCount = 0, 0
    local best

    for _, e in ipairs(entries) do
        if e.score then
            scoreSum = scoreSum + e.score
            scoreCount = scoreCount + 1
        end
        if e.mapID and e.level then
            levelSum = levelSum + e.level
            levelCount = levelCount + 1
            if not best or e.level > best.level or (e.level == best.level and (e.score or 0) > (best.score or 0)) then
                best = { name = e.name, class = e.class, level = e.level, score = e.score }
            end
        end
    end

    return {
        avgScore = scoreCount > 0 and (scoreSum / scoreCount) or nil,
        avgLevel = levelCount > 0 and (levelSum / levelCount) or nil,
        withKey  = levelCount,
        total    = #entries,
        best     = best,
    }
end

---Builds the Group's normalized entry list from the live roster. The local
---player's own keystone/score is always known (read directly via the API,
---like Modules/Tracker/Dashboard/Content/Keystones.lua's getKnownKeystoneForUnit),
---so the Group section always has at least one entry — no "not in a group"
---fallback is needed here, unlike the old GroupScores.lua which excluded
---the player entirely.
---@return table entries
local function buildGroupStatEntries()
    local entries = {}
    local unitTokens = addon.Communication and addon.Communication:GetGroupUnitTokens() or { "player" }

    for _, unitToken in ipairs(unitTokens) do
        if UnitExists(unitToken) then
            local name = UnitName(unitToken)
            local _, englishClass = UnitClass(unitToken)
            local mapID, level, score

            if unitToken == "player" then
                mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
                level = C_MythicPlus.GetOwnedKeystoneLevel()
                score = C_ChallengeMode.GetOverallDungeonScore()
            else
                local fullPlayerName = addon.Communication:GetFullPlayerName(unitToken)
                local data = fullPlayerName and addon.groupKeystones[fullPlayerName]
                if data and data.hasAddon then
                    mapID, level, score = data.mapID, data.level, data.score
                end
            end

            table.insert(entries, { name = name, class = englishClass, mapID = mapID, level = level, score = score })
        end
    end

    return entries
end

---Renders the single "Gruppe"/"Twinks" section matching whichever mode is
---currently active in the Keystones tab's dropdown: header banner, then
---either the empty-state fallback text or the three stat rows + "Best" row,
---styled like RunsStats.lua's tier table rather than the old tile boxes.
---@param sidebar Frame
---@param cursor table addon.createLayoutCursor
---@param headerText string
---@param entries table
---@param emptyText string|nil shown instead of rows when entries is empty
local function renderStatsSection(sidebar, cursor, headerText, entries, emptyText)
    local headerY  = cursor:current() - SECTION_GAP
    local contentY = headerY - addon.SIDEBAR_SECTION_HEADER_HEIGHT - HEADER_TO_CONTENT_GAP

    addon.createSidebarSectionHeader(sidebar, headerY, CONTENT_W, headerText)

    if #entries == 0 then
        local fs = sidebar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", sidebar, "TOPLEFT", CONTENT_X, contentY)
        fs:SetSize(CONTENT_W, EMPTY_TEXT_H)
        fs:SetJustifyH("CENTER")
        fs:SetJustifyV("MIDDLE")
        fs:SetWordWrap(true)
        fs:SetText(addon.colors.POOR .. emptyText .. addon.colors.RESET)

        cursor:advance(SECTION_GAP + addon.SIDEBAR_SECTION_HEADER_HEIGHT + HEADER_TO_CONTENT_GAP + EMPTY_TEXT_H)
        return
    end

    local stats = computeStats(entries)

    local avgScoreText
    if stats.avgScore then
        local rounded = math.floor(stats.avgScore + 0.5)
        avgScoreText = addon.colorForScore(rounded) .. rounded .. addon.colors.RESET
    else
        avgScoreText = addon.colors.POOR .. "–" .. addon.colors.RESET
    end

    local avgLevelText
    if stats.avgLevel then
        local displayLevel = string.format("%.1f", stats.avgLevel)
        avgLevelText = addon.colorKeystoneLevel(math.floor(stats.avgLevel + 0.5)) .. displayLevel .. addon.colors.RESET
    else
        avgLevelText = addon.colors.POOR .. "–" .. addon.colors.RESET
    end

    -- Same "colored if any, POOR dash-tier if none" convention as the
    -- Success column in RunsStats.lua (wonColor = won > 0 and ARTIFACT or POOR).
    local withKeyColor = stats.withKey > 0 and addon.colors.ARTIFACT or addon.colors.POOR
    local withKeyText = withKeyColor .. stats.withKey .. "/" .. stats.total .. addon.colors.RESET

    local rows = {
        { label = addon.locale["SIDEBAR_STATS_AVG_SCORE"], value = avgScoreText },
        { label = addon.locale["SIDEBAR_STATS_AVG_LEVEL"], value = avgLevelText },
        { label = addon.locale["SIDEBAR_STATS_WITH_KEY"],  value = withKeyText },
        { label = addon.locale["SIDEBAR_STATS_BEST"],      value = formatBestValue(stats) },
    }

    local rowY = contentY
    for i, row in ipairs(rows) do
        renderRow(sidebar, rowY, row.label, row.value)
        rowY = rowY - ROW_H
        if i < #rows then
            sectionDivider(sidebar, rowY, 0.3)
        end
    end

    cursor:advance(SECTION_GAP + addon.SIDEBAR_SECTION_HEADER_HEIGHT + HEADER_TO_CONTENT_GAP + (#rows * ROW_H))
end

local function loadStatistics(sidebar, cursor)
    addon.debugMessage("Loading sidebar: statistics...")

    if isAltsMode() then
        renderStatsSection(sidebar, cursor, addon.locale["KEYSTONES_MODE_ALTS"],
            addon.AltKeystones:GetEntries(), addon.locale["KEYSTONES_ALTS_EMPTY"])
    else
        if addon.Communication then
            addon.Communication:RequestGroupKeystones()
        end
        renderStatsSection(sidebar, cursor, addon.locale["SIDEBAR_GROUP_HEADER"], buildGroupStatEntries(), nil)
    end
end

MPT_Sidebar.loadStatistics = loadStatistics

local addonName, addon = ...

MythicPlusTrackerDB = MythicPlusTrackerDB or {}

local ROW_H           = 40
local HEADER_H        = 28
local COL_GAP         = 6
local PORTRAIT_SIZE   = 28
local ROLE_SIZE        = 18
local DUNGEON_ICON_SIZE = 24
local DASHBOARD_W     = 800  -- matches Frame.lua
local CONTENT_INSET   = 20   -- aligns with divider caps
local NAV_BOTTOM_MARGIN = 8
local SCROLL_BTN_SIZE = 10   -- gutter reserved for the scrollbar (MinimalScrollBar is 8px wide)
local ROW_PADDING_X   = 5
local ARTIFACT_R, ARTIFACT_G, ARTIFACT_B = addon.colorToRGB("ARTIFACT")
local POOR_R, POOR_G, POOR_B = addon.colorToRGB("POOR")
local REFRESH_ICON_SIZE = 20
local REFRESH_ICON_PRESS_OFFSET = -2 -- pixels the icon shifts down while the button is held, like the nav tabs
local REFRESH_COOLDOWN_SECONDS = 2 -- minimum time between refreshes, not shown to the player
local GUILD_REFRESH_COOLDOWN_SECONDS = 30 -- longer than Group's: a guild is much bigger than a party/raid
local MODE_DROPDOWN_W = 150
local MODE_DROPDOWN_H = 26   -- fixed height of WowStyle1DropdownTemplate
local MODE_DROPDOWN_MARGIN = 6

-- Timestamp (GetTime()) of the last time the refresh button actually
-- triggered a refresh. Clicks within REFRESH_COOLDOWN_SECONDS (or, for
-- Guild, GUILD_REFRESH_COOLDOWN_SECONDS) of this are silently ignored, with
-- no visible feedback to the player.
local lastRefreshTime = 0
local lastGuildRefreshTime = 0

local MODE_GROUP = "group"
local MODE_ALTS  = "alts"
local MODE_GUILD = "guild"

local MODE_OPTIONS = {
    { mode = MODE_GROUP, localeKey = "KEYSTONES_MODE_GROUP" },
    { mode = MODE_ALTS,  localeKey = "KEYSTONES_MODE_ALTS" },
    { mode = MODE_GUILD, localeKey = "KEYSTONES_MODE_GUILD" },
}

-- Sort state for the clickable column headers, shared across both Group and
-- Alts/Guild modes (same table layout, same header row). nil sortCol means
-- "no explicit sort yet": Group keeps roster order, Alts/Guild keep their
-- own default (level desc, then name — see Modules/Tracker/Services/AltKeystoneService.lua and
-- GuildKeystoneService:getEntries()). Plain
-- module-level locals, like DungeonsPage.lua's sortCol/sortDir — persists across
-- re-renders within the session, reset only by /reload.
local sortCol = nil
local sortDir = "asc"
local headerCells = {} -- [colKey] = FontString, updated when sort changes

local HEADER_LOCALE = {
    name    = "KEYSTONES_COL_PLAYER",
    dungeon = "KEYSTONES_COL_DUNGEON",
    level   = "KEYSTONES_COL_LEVEL",
    score   = "KEYSTONES_COL_SCORE",
}

local SORT_DEFAULT_DIR = {
    name    = "asc",
    dungeon = "asc",
    level   = "desc",
    score   = "desc",
}

-- Fixed column widths sized to fit their content (name/dungeon columns are dynamic)
local COL_W = {
    portrait  = 34,
    classIcon = 22,
    role      = 30,
    level     = 50,
    score     = 80,
}

local ROLE_ATLAS_BY_ROLE = {
    TANK    = "UI-LFG-RoleIcon-Tank",
    HEALER  = "UI-LFG-RoleIcon-Healer",
    DAMAGER = "UI-LFG-RoleIcon-DPS",
}

local CLASS_ICON_ATLAS_BY_ENGLISH_CLASS = {
    DEATHKNIGHT = "UI-HUD-UnitFrame-Player-Portrait-ClassIcon-DeathKnight",
    DEMONHUNTER = "UI-HUD-UnitFrame-Player-Portrait-ClassIcon-DemonHunter",
    DRUID       = "UI-HUD-UnitFrame-Player-Portrait-ClassIcon-Druid",
    EVOKER      = "UI-HUD-UnitFrame-Player-Portrait-ClassIcon-Evoker",
    HUNTER      = "UI-HUD-UnitFrame-Player-Portrait-ClassIcon-Hunter",
    MAGE        = "UI-HUD-UnitFrame-Player-Portrait-ClassIcon-Mage",
    MONK        = "UI-HUD-UnitFrame-Player-Portrait-ClassIcon-Monk",
    PALADIN     = "UI-HUD-UnitFrame-Player-Portrait-ClassIcon-Paladin",
    PRIEST      = "UI-HUD-UnitFrame-Player-Portrait-ClassIcon-Priest",
    ROGUE       = "UI-HUD-UnitFrame-Player-Portrait-ClassIcon-Rogue",
    SHAMAN      = "UI-HUD-UnitFrame-Player-Portrait-ClassIcon-Shaman",
    WARLOCK     = "UI-HUD-UnitFrame-Player-Portrait-ClassIcon-Warlock",
    WARRIOR     = "UI-HUD-UnitFrame-Player-Portrait-ClassIcon-Warrior",
}

---@return string
local function getMode()
    if MythicPlusTrackerDB.keystonesTabMode == MODE_ALTS then
        return MODE_ALTS
    elseif MythicPlusTrackerDB.keystonesTabMode == MODE_GUILD then
        return MODE_GUILD
    end
    return MODE_GROUP
end

---@param mode string
local function setMode(mode)
    MythicPlusTrackerDB.keystonesTabMode = mode
end

---Resolves the keystone (mapID + level) known for the given unit token, as
---well as whether that member is known to run MythicPlusTracker at all.
---For the local player this is read directly from the owned keystone item;
---for other group members it is looked up from data received via
---addon.GroupKeystoneService (see Modules/Tracker/Services/GroupKeystoneService.lua).
---@param unitToken string
---@param fullPlayerName string|nil
---@return number|nil mapID
---@return number|nil level
---@return boolean hasAddon
---@return number|nil score
local function getKnownKeystoneForUnit(unitToken, fullPlayerName)
    if unitToken == "player" then
        return C_MythicPlus.GetOwnedKeystoneChallengeMapID(), C_MythicPlus.GetOwnedKeystoneLevel(), true,
            C_ChallengeMode.GetOverallDungeonScore()
    end

    local groupKeystoneData = fullPlayerName and addon.groupKeystones[fullPlayerName]
    if not groupKeystoneData then
        return nil, nil, false, nil
    end

    return groupKeystoneData.mapID, groupKeystoneData.level, groupKeystoneData.hasAddon == true, groupKeystoneData.score
end

---Determines the effective role ("TANK"/"HEALER"/"DAMAGER") for a unit.
---For the local player, falls back to the active specialization's role when
---no group role is assigned (e.g. when not in a group, where
---UnitGroupRolesAssigned always returns "NONE").
---@param unitToken string
---@return string|nil role
local function getEffectiveRole(unitToken)
    local role = UnitGroupRolesAssigned(unitToken)
    if role and role ~= "NONE" then
        return role
    end

    if unitToken == "player" then
        local specIndex = GetSpecialization()
        if specIndex then
            return GetSpecializationRole(specIndex)
        end
    end

    return nil
end

---Requests fresh group keystone data and re-renders both the Keystones tab
---and the Sidebar group scores view (which always mirrors this tab). Both
---MPT_Dashboard:refreshKeystonesView() and MPT_Sidebar:showForTab(MPT_Tracker.TABS.KEYSTONES) trigger
---their own addon.GroupKeystoneService:requestKeystones() call as part of
---their normal render path, so no separate request is issued here.
---Calls within REFRESH_COOLDOWN_SECONDS of the previous refresh are silently
---ignored — no visible feedback is given to the player.
local function refreshGroupView()
    local now = GetTime()
    if now - lastRefreshTime < REFRESH_COOLDOWN_SECONDS then
        return
    end
    lastRefreshTime = now

    if MPT_Dashboard and MPT_Dashboard.refreshKeystonesView then
        MPT_Dashboard:refreshKeystonesView()
    end

    if MPT_Sidebar and MPT_Sidebar.showForTab then
        MPT_Sidebar:showForTab(MPT_Tracker.TABS.KEYSTONES)
    end
end

---Same as refreshGroupView, but for the Guild mode's refresh button — see
---the comment above createRefreshButton. Guild's own
---addon.GuildKeystoneService:requestKeystones() call happens as part of the normal
---render path (see the MODE_GUILD branch below), just like Group's, so it
---isn't repeated here either.
local function refreshGuildView()
    local now = GetTime()
    if now - lastGuildRefreshTime < GUILD_REFRESH_COOLDOWN_SECONDS then
        return
    end
    lastGuildRefreshTime = now

    if MPT_Dashboard and MPT_Dashboard.refreshKeystonesView then
        MPT_Dashboard:refreshKeystonesView()
    end

    if MPT_Sidebar and MPT_Sidebar.showForTab then
        MPT_Sidebar:showForTab(MPT_Tracker.TABS.KEYSTONES)
    end
end

---Adds a tooltip line whose "<Label>:" prefix (up to and including the first
---colon) is colored POOR-gray, with the rest of the line left in the
---default tooltip color. Used for the secondary "last updated"/"next
---update" lines so only the label reads as muted, not the actual value.
---@param text string
local function addPoorLabelLine(text)
    local prefix, rest = text:match("^([^:]+:)(.*)$")
    if prefix then
        GameTooltip:AddLine(addon.colors.POOR .. prefix .. addon.colors.RESET .. rest, 1, 1, 1, true)
    else
        GameTooltip:AddLine(text, POOR_R, POOR_G, POOR_B, true)
    end
end

---Creates the icon-only refresh button, anchored directly to the left of the
---Group/Alts/Guild mode dropdown (in the row above the table). The scrollbar
---gutter (Dashboard/TableWidgets.lua) is only 14px wide — too narrow for a 20px
---icon now that it hosts the slim MinimalScrollBar instead of the old, wider
---UIPanelScrollBarTemplate — so this button no longer lives there. Used by
---both Group and Guild mode (each with their own onClick/cooldown and
---tooltip text); Alts has nothing to actively request and uses
---createInfoButton below instead.
---@param dropdown Frame the mode dropdown returned by createModeDropdown
---@param onClick function called on click (expected to do its own cooldown check)
---@param getLastRefreshedAt function returns the server timestamp of the last successful
---request (or nil), called fresh on every OnEnter so the tooltip is always current
local function createRefreshButton(dropdown, onClick, getLastRefreshedAt)
    local button = CreateFrame("Button", nil, dropdown)
    button:SetSize(REFRESH_ICON_SIZE, REFRESH_ICON_SIZE)
    button:SetPoint("RIGHT", dropdown, "LEFT", -8, 0)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(REFRESH_ICON_SIZE, REFRESH_ICON_SIZE)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetAtlas(addon.theme.GROUP_REFRESH_ICON, false)

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button)
    highlight:SetAtlas(addon.theme.GROUP_REFRESH_ICON, false)
    highlight:SetBlendMode("ADD")
    highlight:SetAlpha(0.5)
    button:SetHighlightTexture(highlight)

    button:SetScript("OnClick", onClick)

    -- Nudges the icon down while the button is held, mirroring the pushed
    -- look of the Dashboard nav tabs (whose SetFontString label shifts down
    -- automatically). Textures don't get that behavior for free, so it's
    -- reproduced manually here and reverted on release/leave.
    button:SetScript("OnMouseDown", function(self)
        icon:SetPoint("CENTER", self, "CENTER", 0, REFRESH_ICON_PRESS_OFFSET)
    end)
    button:SetScript("OnMouseUp", function(self)
        icon:SetPoint("CENTER", self, "CENTER", 0, 0)
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(addon.locale["KEYSTONES_REFRESH_TITLE"], ARTIFACT_R, ARTIFACT_G, ARTIFACT_B, 1)
        addPoorLabelLine(string.format(addon.locale["KEYSTONES_LAST_UPDATED"],
            addon.formatRelativeTime(getLastRefreshedAt())))
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        -- Safety net: reset the icon in case the mouse leaves the button
        -- while still held down, which would otherwise skip OnMouseUp.
        icon:SetPoint("CENTER", button, "CENTER", 0, 0)
        GameTooltip:Hide()
    end)
end

---Creates a static info icon in the same spot as createRefreshButton, for
---modes where there's nothing to actively request (Alts — see the comment
---above createRefreshButton). Unlike that button, this is a plain Frame (no
---OnClick, no press animation, no highlight texture) so it doesn't visually
---invite a click that would do nothing. getTooltipLines is called fresh on
---every OnEnter so the displayed "last updated" timestamp is always current,
---not just what it was when the tab was opened.
---@param dropdown Frame the mode dropdown returned by createModeDropdown
---@param getTooltipLines function returns an array of strings to show in the tooltip
local function createInfoButton(dropdown, getTooltipLines)
    local button = CreateFrame("Frame", nil, dropdown)
    button:SetSize(REFRESH_ICON_SIZE, REFRESH_ICON_SIZE)
    button:SetPoint("RIGHT", dropdown, "LEFT", -8, 0)
    button:EnableMouse(true)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(button)
    icon:SetAtlas(addon.theme.KEYSTONES_INFO_ICON, false)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(addon.locale["KEYSTONES_REFRESH_TITLE"], ARTIFACT_R, ARTIFACT_G, ARTIFACT_B, 1)
        for i, line in ipairs(getTooltipLines()) do
            if i > 1 then
                GameTooltip:AddLine(" ")
            end
            addPoorLabelLine(line)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

---Creates the Group/Alts/Guild mode dropdown, right-aligned above the table.
---Selecting an option persists it to MythicPlusTrackerDB.keystonesTabMode
---and re-renders both the Dashboard tab and the Sidebar (which mirrors the
---same mode, see Modules/Tracker/Sidebar/Content/KeystoneStatisticsCard.lua) in place.
---@param frame Frame the tab's content panel
local function createModeDropdown(frame)
    local function labelFor(mode)
        for _, option in ipairs(MODE_OPTIONS) do
            if option.mode == mode then
                return addon.locale[option.localeKey] or option.localeKey
            end
        end
    end

    local dropdown = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(MODE_DROPDOWN_W)
    dropdown:SetPoint("TOPRIGHT", MPT_Dashboard.navFrame, "BOTTOMRIGHT", -CONTENT_INSET, -NAV_BOTTOM_MARGIN)
    dropdown:SetText(labelFor(getMode()))

    dropdown:SetupMenu(function(_, rootDescription)
        for _, option in ipairs(MODE_OPTIONS) do
            local mode = option.mode
            local label = addon.locale[option.localeKey] or option.localeKey
            rootDescription:CreateRadio(label,
                function() return getMode() == mode end,
                function()
                    setMode(mode)
                    dropdown:SetText(label)
                    MPT_Dashboard:refreshKeystonesView()
                    if MPT_Sidebar and MPT_Sidebar.showForTab then
                        MPT_Sidebar:showForTab(MPT_Tracker.TABS.KEYSTONES)
                    end
                end)
        end
    end)

    return dropdown
end

local function updateHeaderIndicators()
    for colKey, fs in pairs(headerCells) do
        local localeKey = HEADER_LOCALE[colKey]
        local label = addon.locale[localeKey] or localeKey
        local indicator = (colKey == sortCol) and (sortDir == "asc" and " ^" or " v") or ""
        fs:SetText(label .. indicator)
        fs:SetTextColor(ARTIFACT_R, ARTIFACT_G, ARTIFACT_B, 1)
    end
end

---Resolves the dungeon name for a normalized row entry, used only for
---sorting by the "Dungeon" column. Group entries (see buildGroupEntries)
---already carry a cached dungeonName; Alts entries (from
---Modules/Tracker/Services/AltKeystoneService.lua) don't, so it's resolved here on demand instead of
---changing that module's saved data shape.
---@param entry table
---@return string|nil
local function resolveDungeonName(entry)
    if entry.dungeonName ~= nil then
        return entry.dungeonName
    end
    return entry.mapID and (C_ChallengeMode.GetMapUIInfo(entry.mapID))
end

---Sorts a row-entry array in place by the active header column, if any.
---Shared by Group, Alts, and Guild modes since all feed the same table layout
---(both entry shapes expose .name/.mapID/.level/.score). No-op when no
---column has been clicked yet, preserving each mode's own default order.
---@param entries table
---@return table entries
local function sortEntries(entries)
    if not sortCol or #entries == 0 then
        return entries
    end

    table.sort(entries, function(a, b)
        if sortCol == "name" then
            local an, bn = a.name or "", b.name or ""
            if sortDir == "asc" then return an < bn end
            return an > bn
        elseif sortCol == "dungeon" then
            local ad, bd = resolveDungeonName(a), resolveDungeonName(b)
            if (ad == nil) ~= (bd == nil) then return ad ~= nil end
            ad, bd = ad or "", bd or ""
            if sortDir == "asc" then return ad < bd end
            return ad > bd
        else -- "level" or "score": numeric, push unknown (nil/0) entries last regardless of direction
            local va = a[sortCol] or 0
            local vb = b[sortCol] or 0
            if (va == 0) ~= (vb == 0) then return va ~= 0 end
            if sortDir == "desc" then return va > vb end
            return va < vb
        end
    end)

    return entries
end

---Builds a normalized row-entry array for the Group mode's live unit
---tokens, resolving each unit's name/class/keystone/score once up front so
---sortEntries() can sort them like any other column data. entry.unitToken
---is kept around for the bits that still need a live unit (portrait, role).
---@param unitTokens table
---@return table entries
local function buildGroupEntries(unitTokens)
    local entries = {}
    for _, unitToken in ipairs(unitTokens) do
        if UnitExists(unitToken) then
            local fullPlayerName = addon.GroupKeystoneService:getFullPlayerName(unitToken)
            local unitName = UnitName(unitToken) or fullPlayerName or "?"
            local _, englishClass = UnitClass(unitToken)
            local mapID, level, hasAddon, score = getKnownKeystoneForUnit(unitToken, fullPlayerName)
            local dungeonName = mapID and (C_ChallengeMode.GetMapUIInfo(mapID))

            table.insert(entries, {
                unitToken   = unitToken,
                name        = unitName,
                class       = englishClass,
                mapID       = mapID,
                level       = level,
                hasAddon    = hasAddon,
                score       = score,
                dungeonName = dungeonName,
            })
        end
    end
    return entries
end

local function createHeader(parent, colX, nameW, dungeonW, onSort)
    wipe(headerCells)

    local headerDefs = {
        { key = "name",    w = nameW,        j = "LEFT"  },
        { key = "dungeon", w = dungeonW,     j = "LEFT"  },
        { key = "level",   w = COL_W.level,  j = "RIGHT" },
        { key = "score",   w = COL_W.score,  j = "RIGHT" },
    }

    for _, def in ipairs(headerDefs) do
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(def.w, HEADER_H)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", colX[def.key], 0)

        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetSize(def.w, HEADER_H)
        fs:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        fs:SetJustifyH(def.j)
        fs:SetJustifyV("MIDDLE")
        fs:SetWordWrap(false)

        headerCells[def.key] = fs

        btn:SetScript("OnClick", function()
            if sortCol == def.key then
                sortDir = sortDir == "asc" and "desc" or "asc"
            else
                sortCol = def.key
                sortDir = SORT_DEFAULT_DIR[def.key] or "asc"
            end
            updateHeaderIndicators()
            onSort()
        end)

        btn:SetScript("OnEnter", function()
            fs:SetTextColor(1, 1, 1, 1)
        end)
        btn:SetScript("OnLeave", function()
            fs:SetTextColor(ARTIFACT_R, ARTIFACT_G, ARTIFACT_B, 1)
        end)
    end

    updateHeaderIndicators()
    addon.createRowDivider(parent, -HEADER_H, 0.5)
end

---Shared by both the Group row (live unit) and the Alts row (saved entry).
---@param parent Frame
---@param colX table
---@param nameW number
---@param rowY number
---@param name string|nil
---@param englishClass string|nil
local function createNameAndClassCell(parent, colX, nameW, rowY, name, englishClass)
    local nameText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetSize(nameW, ROW_H)
    nameText:SetPoint("TOPLEFT", parent, "TOPLEFT", colX["name"], rowY)
    nameText:SetJustifyH("LEFT")
    nameText:SetJustifyV("MIDDLE")
    nameText:SetText(name or "?")
    local classColor = englishClass and RAID_CLASS_COLORS[englishClass]
    if classColor then
        nameText:SetTextColor(classColor.r, classColor.g, classColor.b)
    end

    local classIconAtlas = englishClass and CLASS_ICON_ATLAS_BY_ENGLISH_CLASS[englishClass]
    if classIconAtlas then
        local classIcon = parent:CreateTexture(nil, "ARTWORK")
        classIcon:SetAtlas(classIconAtlas, false)
        classIcon:SetSize(COL_W.classIcon, COL_W.classIcon)
        classIcon:SetPoint("TOPLEFT", parent, "TOPLEFT",
            colX["classIcon"], rowY - (ROW_H - COL_W.classIcon) / 2)
    end
end

---Alts rows always "have the addon" (it's the local account's own saved
---data), so noKeyText there means the character genuinely has no key.
---@param parent Frame
---@param colX table
---@param dungeonW number
---@param rowY number
---@param mapID number|nil
---@param level number|nil
---@param noKeyText string
local function createDungeonAndLevelCell(parent, colX, dungeonW, rowY, mapID, level, noKeyText)
    if mapID and level then
        local dungeonName, _, _, texture = C_ChallengeMode.GetMapUIInfo(mapID)
        dungeonName = dungeonName or ("Map " .. tostring(mapID))

        if texture then
            local dungeonIcon = parent:CreateTexture(nil, "ARTWORK")
            dungeonIcon:SetSize(DUNGEON_ICON_SIZE, DUNGEON_ICON_SIZE)
            dungeonIcon:SetPoint("TOPLEFT", parent, "TOPLEFT",
                colX["dungeon"], rowY - (ROW_H - DUNGEON_ICON_SIZE) / 2)
            dungeonIcon:SetTexture(texture)
        end

        local dungeonText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        dungeonText:SetSize(dungeonW - DUNGEON_ICON_SIZE - COL_GAP, ROW_H)
        dungeonText:SetPoint("TOPLEFT", parent, "TOPLEFT",
            colX["dungeon"] + DUNGEON_ICON_SIZE + COL_GAP, rowY)
        dungeonText:SetJustifyH("LEFT")
        dungeonText:SetJustifyV("MIDDLE")
        dungeonText:SetText(addon.colors.ARTIFACT .. dungeonName .. addon.colors.RESET)

        local levelText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        levelText:SetSize(COL_W.level, ROW_H)
        levelText:SetPoint("TOPLEFT", parent, "TOPLEFT", colX["level"], rowY)
        levelText:SetJustifyH("RIGHT")
        levelText:SetJustifyV("MIDDLE")
        levelText:SetText(addon.colorKeystoneLevel(level) .. level .. addon.colors.RESET)
    else
        local fallbackText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fallbackText:SetSize(dungeonW + COL_GAP + COL_W.level, ROW_H)
        fallbackText:SetPoint("TOPLEFT", parent, "TOPLEFT", colX["dungeon"], rowY)
        fallbackText:SetJustifyH("LEFT")
        fallbackText:SetJustifyV("MIDDLE")
        fallbackText:SetText(noKeyText)
    end
end

---Renders the M+ score column, right-justified, or a "–" fallback when the
---score isn't known (e.g. a Group member without the addon). Independent of
---whether a keystone is currently owned — score reflects overall rating, not
---the currently-held key.
---@param parent Frame
---@param colX table
---@param rowY number
---@param score number|nil
local function createScoreCell(parent, colX, rowY, score)
    local scoreText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    scoreText:SetSize(COL_W.score, ROW_H)
    scoreText:SetPoint("TOPLEFT", parent, "TOPLEFT", colX["score"], rowY)
    scoreText:SetJustifyH("RIGHT")
    scoreText:SetJustifyV("MIDDLE")
    if score and score > 0 then
        scoreText:SetText(addon.colors.ARTIFACT .. score .. addon.colors.RESET)
    else
        scoreText:SetText(addon.colors.POOR .. "–" .. addon.colors.RESET)
    end
end

---Renders a POOR-colored fallback message spanning the dungeon+level
---columns.
---@param parent Frame
---@param colX table
---@param dungeonW number
---@param rowY number
---@param text string message to show (e.g. "Kein Addon")
local function createNoAddonCell(parent, colX, dungeonW, rowY, text)
    local noAddonText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    noAddonText:SetSize(dungeonW + COL_GAP + COL_W.level, ROW_H)
    noAddonText:SetPoint("TOPLEFT", parent, "TOPLEFT", colX["dungeon"], rowY)
    noAddonText:SetJustifyH("LEFT")
    noAddonText:SetJustifyV("MIDDLE")
    noAddonText:SetText(addon.colors.POOR .. "– " .. text .. " –" .. addon.colors.RESET)
end

---entry.unitToken is still needed for the portrait render and the live role
---lookup — neither is precomputed since they don't factor into sorting.
---@param parent Frame
---@param entry table entry from buildGroupEntries
local function createRow(parent, entry, colX, nameW, dungeonW, rowY, isLast)
    local unitToken = entry.unitToken

    local portrait = parent:CreateTexture(nil, "ARTWORK")
    portrait:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
    portrait:SetPoint("TOPLEFT", parent, "TOPLEFT",
        colX["portrait"], rowY - (ROW_H - PORTRAIT_SIZE) / 2)
    SetPortraitTexture(portrait, unitToken)

    createNameAndClassCell(parent, colX, nameW, rowY, entry.name, entry.class)

    local role = getEffectiveRole(unitToken)
    local roleAtlas = role and ROLE_ATLAS_BY_ROLE[role]
    if roleAtlas then
        local roleIcon = parent:CreateTexture(nil, "ARTWORK")
        roleIcon:SetAtlas(roleAtlas, false)
        roleIcon:SetSize(ROLE_SIZE, ROLE_SIZE)
        roleIcon:SetPoint("TOPLEFT", parent, "TOPLEFT",
            colX["role"], rowY - (ROW_H - ROLE_SIZE) / 2)
    end

    if entry.hasAddon then
        createDungeonAndLevelCell(parent, colX, dungeonW, rowY, entry.mapID, entry.level, addon.locale["KEYSTONES_NO_KEY"])
    else
        -- No response received at all: member likely does not run MythicPlusTracker.
        createNoAddonCell(parent, colX, dungeonW, rowY, addon.locale["KEYSTONES_NO_ADDON"])
    end
    createScoreCell(parent, colX, rowY, entry.score)

    if not isLast then
        addon.createRowDivider(parent, rowY - ROW_H, 0.3)
    end
end

---Renders one saved Alts/Twinks or Guild row. There's no live unit token
---here, so no portrait or role icon. altEntry.hasAddon == false renders
---"Kein Addon" instead of a keystone.
---@param parent Frame
---@param altEntry table entry from addon.AltKeystoneService:getEntries() or addon.GuildKeystoneService:getEntries()
local function createAltRow(parent, altEntry, colX, nameW, dungeonW, rowY, isLast)
    createNameAndClassCell(parent, colX, nameW, rowY, altEntry.name, altEntry.class)
    if altEntry.hasAddon == false then
        createNoAddonCell(parent, colX, dungeonW, rowY, addon.locale["KEYSTONES_NO_ADDON"])
    else
        createDungeonAndLevelCell(parent, colX, dungeonW, rowY, altEntry.mapID, altEntry.level, addon.locale["KEYSTONES_NO_KEY"])
    end
    createScoreCell(parent, colX, rowY, altEntry.score)

    if not isLast then
        addon.createRowDivider(parent, rowY - ROW_H, 0.3)
    end
end

---Computes column X-offsets and the dynamic dungeon column width for the
---given mode. Alts mode drops the portrait/role columns (neither is
---available for a character that isn't a live unit), giving that width back
---to the name/dungeon columns.
---@param mode string
---@param scrollChildW number
---@param nameW number
---@return table colX
---@return number dungeonW
local function buildColumnLayout(mode, scrollChildW, nameW)
    local colX = {}
    local cursor = ROW_PADDING_X
    local dungeonW

    if mode == MODE_GROUP then
        dungeonW = scrollChildW - COL_W.portrait - COL_W.classIcon - COL_W.role - nameW - COL_W.level - COL_W.score
            - 6 * COL_GAP - (2 * ROW_PADDING_X)

        colX["portrait"]  = cursor; cursor = cursor + COL_W.portrait + COL_GAP
        colX["classIcon"] = cursor; cursor = cursor + COL_W.classIcon + COL_GAP
        colX["name"]      = cursor; cursor = cursor + nameW + COL_GAP
        colX["role"]      = cursor; cursor = cursor + COL_W.role + COL_GAP
        colX["dungeon"]   = cursor; cursor = cursor + dungeonW + COL_GAP
        colX["level"]     = cursor; cursor = cursor + COL_W.level + COL_GAP
        colX["score"]     = cursor
    else
        dungeonW = scrollChildW - COL_W.classIcon - nameW - COL_W.level - COL_W.score
            - 4 * COL_GAP - (2 * ROW_PADDING_X)

        colX["classIcon"] = cursor; cursor = cursor + COL_W.classIcon + COL_GAP
        colX["name"]      = cursor; cursor = cursor + nameW + COL_GAP
        colX["dungeon"]   = cursor; cursor = cursor + dungeonW + COL_GAP
        colX["level"]     = cursor; cursor = cursor + COL_W.level + COL_GAP
        colX["score"]     = cursor
    end

    return colX, dungeonW
end

function MPT_Dashboard:loadKeystones(frame)
    local mode = getMode()

    local dropdown = createModeDropdown(frame)

    local tableW       = DASHBOARD_W - CONTENT_INSET * 2
    local scrollChildW = tableW - SCROLL_BTN_SIZE - 4
    local nameW  = 140

    local colX, dungeonW = buildColumnLayout(mode, scrollChildW, nameW)

    local outerFrame = CreateFrame("Frame", nil, frame)
    outerFrame:SetPoint("TOPLEFT",  MPT_Dashboard.navFrame, "BOTTOMLEFT",
        CONTENT_INSET, -(NAV_BOTTOM_MARGIN + MODE_DROPDOWN_H + MODE_DROPDOWN_MARGIN))
    outerFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -CONTENT_INSET, CONTENT_INSET)

    local headerFrame = CreateFrame("Frame", nil, outerFrame)
    headerFrame:SetPoint("TOPLEFT",  outerFrame, "TOPLEFT",  0, 0)
    headerFrame:SetPoint("TOPRIGHT", outerFrame, "TOPRIGHT", -(SCROLL_BTN_SIZE + 4), 0)
    headerFrame:SetHeight(HEADER_H + 1)

    createHeader(headerFrame, colX, nameW, dungeonW, function()
        MPT_Dashboard:refreshKeystonesView()
    end)

    if mode == MODE_GROUP then
        createRefreshButton(dropdown, refreshGroupView,
            function() return addon.GroupKeystoneService and addon.GroupKeystoneService:getLastRefreshedAt() end)
    elseif mode == MODE_ALTS then
        createInfoButton(dropdown, function()
            return {
                string.format(addon.locale["KEYSTONES_LAST_UPDATED"],
                    addon.formatRelativeTime(addon.AltKeystoneService:getLastRefreshedAt())),
                addon.locale["KEYSTONES_ALTS_NEXT_UPDATE"],
            }
        end)
    elseif mode == MODE_GUILD then
        createRefreshButton(dropdown, refreshGuildView,
            function() return addon.GuildKeystoneService and addon.GuildKeystoneService:getLastRefreshedAt() end)
    end

    local scrollFrame = CreateFrame("ScrollFrame", nil, outerFrame)
    scrollFrame:SetPoint("TOPLEFT",  outerFrame, "TOPLEFT",  0, -(HEADER_H + 2))
    scrollFrame:SetPoint("BOTTOMRIGHT", outerFrame, "BOTTOMRIGHT", -(SCROLL_BTN_SIZE + 4), 0)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(scrollChild)

    if mode == MODE_GROUP then
        if addon.GroupKeystoneService then
            addon.GroupKeystoneService:requestKeystones()
        end

        local unitTokens = addon.GroupKeystoneService:getGroupUnitTokens()
        local entries = sortEntries(buildGroupEntries(unitTokens))
        scrollChild:SetSize(scrollChildW, #entries * ROW_H)

        for rowIndex, entry in ipairs(entries) do
            local rowY   = -((rowIndex - 1) * ROW_H)
            local isLast = (rowIndex == #entries)
            createRow(scrollChild, entry, colX, nameW, dungeonW, rowY, isLast)
        end
    elseif mode == MODE_ALTS then
        local altEntries = sortEntries(addon.AltKeystoneService:getEntries())
        scrollChild:SetSize(scrollChildW, math.max(#altEntries, 1) * ROW_H)

        if #altEntries == 0 then
            local emptyText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            emptyText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
            emptyText:SetSize(scrollChildW, ROW_H)
            emptyText:SetJustifyH("CENTER")
            emptyText:SetJustifyV("MIDDLE")
            emptyText:SetText(addon.locale["KEYSTONES_ALTS_EMPTY"])
        else
            for rowIndex, altEntry in ipairs(altEntries) do
                local rowY   = -((rowIndex - 1) * ROW_H)
                local isLast = (rowIndex == #altEntries)
                createAltRow(scrollChild, altEntry, colX, nameW, dungeonW, rowY, isLast)
            end
        end
    else -- MODE_GUILD
        if addon.GuildKeystoneService then
            addon.GuildKeystoneService:requestKeystones()
        end

        -- Reuses createAltRow: guild entries have the same shape (no live
        -- unit token, so no portrait/role column) as Alts entries.
        local guildEntries = sortEntries(addon.GuildKeystoneService:getEntries())
        scrollChild:SetSize(scrollChildW, math.max(#guildEntries, 1) * ROW_H)

        if #guildEntries == 0 then
            local emptyText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            emptyText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
            emptyText:SetSize(scrollChildW, ROW_H)
            emptyText:SetJustifyH("CENTER")
            emptyText:SetJustifyV("MIDDLE")
            emptyText:SetText(addon.locale["KEYSTONES_GUILD_EMPTY"])
        else
            for rowIndex, guildEntry in ipairs(guildEntries) do
                local rowY   = -((rowIndex - 1) * ROW_H)
                local isLast = (rowIndex == #guildEntries)
                createAltRow(scrollChild, guildEntry, colX, nameW, dungeonW, rowY, isLast)
            end
        end
    end

    addon.createTableScrollbar(outerFrame, scrollFrame, ROW_H)
end

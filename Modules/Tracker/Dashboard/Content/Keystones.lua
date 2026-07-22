local addonName, addon = ...

local ROW_H           = 40   -- height of each member row
local HEADER_H        = 28   -- height of the header row
local COL_GAP         = 6    -- horizontal gap between columns
local PORTRAIT_SIZE   = 28   -- player portrait dimensions
local ROLE_SIZE        = 18  -- role icon dimensions
local DUNGEON_ICON_SIZE = 24 -- dungeon icon dimensions
local SCROLL_STEP     = ROW_H * 3   -- pixels per mousewheel scroll
local DASHBOARD_W     = 800  -- matches Frame.lua
local CONTENT_INSET   = 20   -- aligns with divider caps
local SUMMARY_MARGIN  = 8    -- vertical gap below navFrame
local SCROLL_BTN_SIZE = 22   -- gutter reserved for the scrollbar
local ROW_PADDING_X   = 5    -- inset of row content from the left/right table edges
local REFRESH_ICON_SIZE = 20 -- refresh button dimensions
local REFRESH_ICON_PRESS_OFFSET = -2 -- pixels the icon shifts down while the button is held, like the nav tabs
local REFRESH_COOLDOWN_SECONDS = 2 -- minimum time between refreshes, not shown to the player

-- Timestamp (GetTime()) of the last time the refresh button actually
-- triggered a refresh. Clicks within REFRESH_COOLDOWN_SECONDS of this are
-- silently ignored, with no visible feedback to the player.
local lastRefreshTime = 0

-- Fixed column widths sized to fit their content (name/dungeon columns are dynamic)
local COL_W = {
    portrait  = 34,
    classIcon = 22,
    role      = 30,
    level     = 50,
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

---Resolves the keystone (mapID + level) known for the given unit token, as
---well as whether that member is known to run MythicPlusTracker at all.
---For the local player this is read directly from the owned keystone item;
---for other group members it is looked up from data received via
---addon.Communication (see Utils/Communication.lua).
---@param unitToken string
---@param fullPlayerName string|nil
---@return number|nil mapID
---@return number|nil level
---@return boolean hasAddon
local function getKnownKeystoneForUnit(unitToken, fullPlayerName)
    if unitToken == "player" then
        return C_MythicPlus.GetOwnedKeystoneChallengeMapID(), C_MythicPlus.GetOwnedKeystoneLevel(), true
    end

    local groupKeystoneData = fullPlayerName and addon.groupKeystones[fullPlayerName]
    if not groupKeystoneData then
        return nil, nil, false
    end

    return groupKeystoneData.mapID, groupKeystoneData.level, groupKeystoneData.hasAddon == true
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
---MPT_Dashboard:refreshKeystonesView() and MPT_Sidebar:showForTab(3) trigger
---their own addon.Communication:RequestGroupKeystones() call as part of
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
        MPT_Sidebar:showForTab(3)
    end
end

---Creates the icon-only refresh button, placed in the scrollbar gutter
---directly to the right of (and vertically centered on) the column header
---row, so it never overlaps the "Level" header text.
---@param outerFrame Frame
local function createRefreshButton(outerFrame)
    local gutterWidth = SCROLL_BTN_SIZE + 4
    local button = CreateFrame("Button", nil, outerFrame)
    button:SetSize(REFRESH_ICON_SIZE, REFRESH_ICON_SIZE)
    button:SetPoint("TOPRIGHT", outerFrame, "TOPRIGHT",
        -(gutterWidth - REFRESH_ICON_SIZE) / 2, -(HEADER_H - REFRESH_ICON_SIZE) / 2)

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

    button:SetScript("OnClick", refreshGroupView)

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
        GameTooltip:SetText(addon.locale["KEYSTONES_REFRESH_TOOLTIP"])
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        -- Safety net: reset the icon in case the mouse leaves the button
        -- while still held down, which would otherwise skip OnMouseUp.
        icon:SetPoint("CENTER", button, "CENTER", 0, 0)
        GameTooltip:Hide()
    end)
end

local function createHeader(parent, colX, nameW, dungeonW)
    local headerDefs = {
        { key = "name",    localeKey = "KEYSTONES_COL_PLAYER",  w = nameW,    j = "LEFT"  },
        { key = "dungeon", localeKey = "KEYSTONES_COL_DUNGEON", w = dungeonW, j = "LEFT"  },
        { key = "level",   localeKey = "KEYSTONES_COL_LEVEL",   w = COL_W.level, j = "RIGHT" },
    }

    for _, def in ipairs(headerDefs) do
        local label = addon.locale[def.localeKey] or def.localeKey
        local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetSize(def.w, HEADER_H)
        fs:SetPoint("TOPLEFT", parent, "TOPLEFT", colX[def.key], 0)
        fs:SetJustifyH(def.j)
        fs:SetJustifyV("MIDDLE")
        fs:SetText(label)
        fs:SetTextColor(0xe6 / 255, 0xcc / 255, 0x80 / 255, 1)
    end

    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, -HEADER_H)
    divider:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -HEADER_H)
    divider:SetHeight(1)
    divider:SetColorTexture(0.45, 0.45, 0.65, 0.5)
end

local function createRow(parent, unitToken, colX, nameW, dungeonW, rowY, isLast)
    if not UnitExists(unitToken) then
        return
    end

    local fullPlayerName = addon.Communication:GetFullPlayerName(unitToken)
    local unitName = UnitName(unitToken) or fullPlayerName or "?"
    local _, englishClass = UnitClass(unitToken)

    local portrait = parent:CreateTexture(nil, "ARTWORK")
    portrait:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
    portrait:SetPoint("TOPLEFT", parent, "TOPLEFT",
        colX["portrait"], rowY - (ROW_H - PORTRAIT_SIZE) / 2)
    SetPortraitTexture(portrait, unitToken)

    local nameText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetSize(nameW, ROW_H)
    nameText:SetPoint("TOPLEFT", parent, "TOPLEFT", colX["name"], rowY)
    nameText:SetJustifyH("LEFT")
    nameText:SetJustifyV("MIDDLE")
    nameText:SetText(unitName)
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

    local role = getEffectiveRole(unitToken)
    local roleAtlas = role and ROLE_ATLAS_BY_ROLE[role]
    if roleAtlas then
        local roleIcon = parent:CreateTexture(nil, "ARTWORK")
        roleIcon:SetAtlas(roleAtlas, false)
        roleIcon:SetSize(ROLE_SIZE, ROLE_SIZE)
        roleIcon:SetPoint("TOPLEFT", parent, "TOPLEFT",
            colX["role"], rowY - (ROW_H - ROLE_SIZE) / 2)
    end

    -- Dungeon + level, or a fallback message describing why no key is known
    local mapID, level, hasAddon = getKnownKeystoneForUnit(unitToken, fullPlayerName)
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
    elseif hasAddon then
        -- Member runs MythicPlusTracker and responded, but currently owns no keystone.
        local noKeyText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noKeyText:SetSize(dungeonW + COL_GAP + COL_W.level, ROW_H)
        noKeyText:SetPoint("TOPLEFT", parent, "TOPLEFT", colX["dungeon"], rowY)
        noKeyText:SetJustifyH("LEFT")
        noKeyText:SetJustifyV("MIDDLE")
        noKeyText:SetText(addon.locale["KEYSTONES_NO_KEY"])
    else
        -- No response received at all: member likely does not run MythicPlusTracker.
        local noAddonText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noAddonText:SetSize(dungeonW + COL_GAP + COL_W.level, ROW_H)
        noAddonText:SetPoint("TOPLEFT", parent, "TOPLEFT", colX["dungeon"], rowY)
        noAddonText:SetJustifyH("LEFT")
        noAddonText:SetJustifyV("MIDDLE")
        noAddonText:SetText(addon.colors.POOR .. "– " .. addon.locale["KEYSTONES_NO_ADDON"] .. " –" .. addon.colors.RESET)
    end

    if not isLast then
        local divider = parent:CreateTexture(nil, "ARTWORK")
        divider:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, rowY - ROW_H)
        divider:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, rowY - ROW_H)
        divider:SetHeight(1)
        divider:SetColorTexture(0.45, 0.45, 0.65, 0.3)
    end
end

function MPT_Dashboard:loadKeystones(frame, topOffset)
    topOffset = topOffset or 0

    -- Make sure we have the freshest possible data before rendering.
    if addon.Communication then
        addon.Communication:RequestGroupKeystones()
    end

    local unitTokens = addon.Communication:GetGroupUnitTokens()

    local tableW       = DASHBOARD_W - CONTENT_INSET * 2
    local scrollChildW = tableW - SCROLL_BTN_SIZE - 4
    local nameW  = 140
    local numGaps = 5
    local dungeonW = scrollChildW - COL_W.portrait - COL_W.classIcon - COL_W.role - nameW - COL_W.level - numGaps * COL_GAP - (2 * ROW_PADDING_X)

    local colX = {}
    local cursor = ROW_PADDING_X
    colX["portrait"]  = cursor; cursor = cursor + COL_W.portrait + COL_GAP
    colX["classIcon"] = cursor; cursor = cursor + COL_W.classIcon + COL_GAP
    colX["name"]      = cursor; cursor = cursor + nameW + COL_GAP
    colX["role"]      = cursor; cursor = cursor + COL_W.role + COL_GAP
    colX["dungeon"]   = cursor; cursor = cursor + dungeonW + COL_GAP
    colX["level"]     = cursor

    local outerFrame = CreateFrame("Frame", nil, frame)
    outerFrame:SetPoint("TOPLEFT",  MPT_Dashboard.navFrame, "BOTTOMLEFT",  CONTENT_INSET, -SUMMARY_MARGIN)
    outerFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -CONTENT_INSET, CONTENT_INSET)

    local headerFrame = CreateFrame("Frame", nil, outerFrame)
    headerFrame:SetPoint("TOPLEFT",  outerFrame, "TOPLEFT",  0, 0)
    headerFrame:SetPoint("TOPRIGHT", outerFrame, "TOPRIGHT", -(SCROLL_BTN_SIZE + 4), 0)
    headerFrame:SetHeight(HEADER_H + 1)

    createHeader(headerFrame, colX, nameW, dungeonW)
    createRefreshButton(outerFrame)

    local scrollFrame = CreateFrame("ScrollFrame", nil, outerFrame)
    scrollFrame:SetPoint("TOPLEFT",  outerFrame, "TOPLEFT",  0, -(HEADER_H + 2))
    scrollFrame:SetPoint("BOTTOMRIGHT", outerFrame, "BOTTOMRIGHT", -(SCROLL_BTN_SIZE + 4), 0)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    local totalRowsH = #unitTokens * ROW_H
    scrollChild:SetSize(scrollChildW, totalRowsH)
    scrollFrame:SetScrollChild(scrollChild)

    for rowIndex, unitToken in ipairs(unitTokens) do
        local rowY   = -((rowIndex - 1) * ROW_H)
        local isLast = (rowIndex == #unitTokens)
        createRow(scrollChild, unitToken, colX, nameW, dungeonW, rowY, isLast)
    end

    local scrollBar = CreateFrame("Slider", nil, outerFrame, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("TOPLEFT",    scrollFrame, "TOPRIGHT",    2, -16)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 2,  16)
    scrollBar:SetMinMaxValues(0, 0)
    scrollBar:SetValueStep(ROW_H)

    -- Attach our own OnValueChanged before the first SetValue() call — otherwise
    -- the template's built-in default handler fires first and tries to call
    -- SetVerticalScroll on outerFrame (not a ScrollFrame), causing a nil-call error.
    scrollBar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)

    scrollBar:SetValue(0)

    scrollFrame:SetScript("OnScrollRangeChanged", function(self, _, yRange)
        local current = self:GetVerticalScroll()
        scrollBar:SetMinMaxValues(0, math.max(0, yRange))
        scrollBar:SetValue(math.min(current, math.max(0, yRange)))
    end)

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = self:GetVerticalScrollRange()
        local newValue = math.max(0, math.min(maxScroll, self:GetVerticalScroll() - delta * SCROLL_STEP))
        scrollBar:SetValue(newValue)
    end)
end

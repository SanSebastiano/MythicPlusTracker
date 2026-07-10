local addonName, addon = ...

-- Omnium Folio / Runes of Power trait system (Midnight, system ID 48)
local TRAIT_SYSTEM_ID = 48

local BUTTON_SIZE  = 40
local BUTTON_GAP   = 8
local DIVIDER_Y    = -295
local FRAME_Y      = -320

local POPUP_W      = 190
local POPUP_ROW_H  = 28
local POPUP_PAD    = 6
local POPUP_ICON   = 22

-- Parsed ARTIFACT color
local ARTIFACT_R = 0xe6 / 255
local ARTIFACT_G = 0xcc / 255
local ARTIFACT_B = 0x80 / 255

-- ---------------------------------------------------------------------------
-- C_Traits helpers
-- ---------------------------------------------------------------------------

local function getConfigAndTree()
    if not (C_Traits and C_Traits.GetConfigIDBySystemID) then return nil, nil end
    local configID = C_Traits.GetConfigIDBySystemID(TRAIT_SYSTEM_ID)
    if not configID then return nil, nil end
    local configInfo = C_Traits.GetConfigInfo(configID)
    if not configInfo or not configInfo.treeIDs or not configInfo.treeIDs[1] then
        return nil, nil
    end
    return configID, configInfo.treeIDs[1]
end

local function getEntrySpellInfo(configID, entryID)
    local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
    if not entryInfo or not entryInfo.definitionID then return nil, nil end
    local defInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
    if not defInfo then return nil, nil end
    local spellID = defInfo.spellID
    local icon    = spellID and C_Spell.GetSpellTexture(spellID)
    local name    = spellID and C_Spell.GetSpellName(spellID)
    return spellID, icon, name
end

local function getFirstEntrySpellID(configID, nodeInfo)
    if not nodeInfo.entryIDs or #nodeInfo.entryIDs == 0 then return nil end
    local spellID = select(1, getEntrySpellInfo(configID, nodeInfo.entryIDs[1]))
    return spellID
end

local function getSortedNodeIDs(configID, treeID)
    local treeNodes = C_Traits.GetTreeNodes(treeID)
    if not treeNodes then return {} end

    local nodeIDs = {}
    local nodePos = {}
    for _, nodeID in ipairs(treeNodes) do
        local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
        if nodeInfo then
            nodePos[nodeID] = { nodeInfo.posX, nodeInfo.posY }
            table.insert(nodeIDs, nodeID)
        end
    end

    table.sort(nodeIDs, function(a, b)
        if nodePos[a][2] ~= nodePos[b][2] then return nodePos[a][2] < nodePos[b][2] end
        if nodePos[a][1] ~= nodePos[b][1] then return nodePos[a][1] < nodePos[b][1] end
        return a < b
    end)

    return nodeIDs
end

local function getActiveEntryID(nodeInfo)
    if nodeInfo.entryIDsWithCommittedRanks and #nodeInfo.entryIDsWithCommittedRanks > 0 then
        return nodeInfo.entryIDsWithCommittedRanks[1]
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Visual state
-- ---------------------------------------------------------------------------

local function getVisualState(configID, nodeID)
    local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
    if not nodeInfo then return 0 end
    if (nodeInfo.currentRank or 0) > 0 then return 1 end
    if nodeInfo.entryIDs then
        for _, entryID in ipairs(nodeInfo.entryIDs) do
            if C_Traits.CanPurchaseRank and C_Traits.CanPurchaseRank(configID, nodeID, entryID) then
                return 2
            end
        end
    end
    return 0
end

local function applyVisualState(btn, state, currentRank)
    if state == 0 then
        btn.icon:SetDesaturated(true)
        btn.icon:SetAlpha(0.4)
        btn.icon:SetVertexColor(1, 1, 1)
        btn.rankText:SetText("")
    elseif state == 1 then
        btn.icon:SetDesaturated(false)
        btn.icon:SetAlpha(1.0)
        btn.icon:SetVertexColor(1, 1, 1)
        btn.rankText:SetText(addon.colors.ARTIFACT .. currentRank .. addon.colors.RESET)
    elseif state == 2 then
        btn.icon:SetDesaturated(false)
        btn.icon:SetAlpha(1.0)
        btn.icon:SetVertexColor(0.5, 1.0, 0.5)
        btn.rankText:SetText("")
    end
end

-- ---------------------------------------------------------------------------
-- Selection popup (shared, lazy-created)
-- ---------------------------------------------------------------------------

local popup      = nil
local hideTimer  = nil

local function cancelHideTimer()
    if hideTimer then hideTimer:Cancel(); hideTimer = nil end
end

local function scheduleHidePopup()
    cancelHideTimer()
    hideTimer = C_Timer.NewTimer(0.15, function()
        if popup then popup:Hide() end
        hideTimer = nil
    end)
end

local function createPopupIfNeeded()
    if popup then return end

    popup = CreateFrame("Frame", "MPT_TraitSelectionPopup", UIParent)
    popup:SetFrameStrata("TOOLTIP")
    popup:SetFrameLevel(200)
    popup:Hide()

    local bg = popup:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(popup)
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.92)

    local border = popup:CreateTexture(nil, "BORDER")
    border:SetAllPoints(popup)
    border:SetAtlas("ui-frame-midnight-portraitdisable", false)
    border:SetAlpha(0.5)

    popup._rows = {}

    popup:SetScript("OnEnter", cancelHideTimer)
    popup:SetScript("OnLeave", scheduleHidePopup)
    popup:EnableMouse(true)
end

local function showSelectionPopup(ownerBtn, configID, nodeID)
    createPopupIfNeeded()
    cancelHideTimer()

    local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
    if not nodeInfo or not nodeInfo.entryIDs then return end

    local activeEntryID = getActiveEntryID(nodeInfo)
    local numEntries    = #nodeInfo.entryIDs
    local nodeState     = getVisualState(configID, nodeID)
    local popupH        = numEntries * POPUP_ROW_H + POPUP_PAD * 2

    popup:SetSize(POPUP_W, popupH)

    -- Recycle or create entry-only row buttons (refund row is separate)
    for i = #popup._rows + 1, numEntries do
        local row = CreateFrame("Button", nil, popup)
        row:SetSize(POPUP_W - POPUP_PAD * 2, POPUP_ROW_H)
        row:EnableMouse(true)
        row:RegisterForClicks("LeftButtonUp")

        local rowBg = row:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints(row)
        rowBg:SetColorTexture(1, 1, 1, 0)
        row._bg = rowBg

        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(row)
        hl:SetColorTexture(1, 1, 1, 0.12)

        local ico = row:CreateTexture(nil, "ARTWORK")
        ico:SetSize(POPUP_ICON, POPUP_ICON)
        ico:SetPoint("LEFT", row, "LEFT", 0, 0)
        ico:SetTexCoord(5/64, 59/64, 5/64, 59/64)
        row._ico = ico

        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lbl:SetPoint("LEFT", ico, "RIGHT", 6, 0)
        lbl:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetMaxLines(1)
        row._lbl = lbl

        row:SetScript("OnEnter", function(self)
            cancelHideTimer()
            if self._spellID then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(self._spellID)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function()
            scheduleHidePopup()
            GameTooltip:Hide()
        end)

        table.insert(popup._rows, row)
    end

    for i, entryID in ipairs(nodeInfo.entryIDs) do
        local row = popup._rows[i]
        local spellID, icon, name = getEntrySpellInfo(configID, entryID)

        row._spellID = spellID
        row._ico:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        local isActive = (entryID == activeEntryID)

        if nodeState == 0 then
            -- Locked: everything greyed out
            row._ico:SetDesaturated(true)
            row._ico:SetAlpha(0.4)
            row._ico:SetVertexColor(1, 1, 1)
            row._lbl:SetTextColor(0.5, 0.5, 0.5)
            row._lbl:SetText(name or "?")
        elseif nodeState == 1 then
            -- Active: highlight chosen entry, dim others
            if isActive then
                row._ico:SetDesaturated(false)
                row._ico:SetAlpha(1.0)
                row._ico:SetVertexColor(1, 1, 1)
                row._lbl:SetTextColor(ARTIFACT_R, ARTIFACT_G, ARTIFACT_B)
                row._lbl:SetText((name or "?") .. " *")
            else
                row._ico:SetDesaturated(true)
                row._ico:SetAlpha(0.55)
                row._ico:SetVertexColor(1, 1, 1)
                row._lbl:SetTextColor(1, 1, 1)
                row._lbl:SetText(name or "?")
            end
        else
            -- Purchasable: all full color
            row._ico:SetDesaturated(false)
            row._ico:SetAlpha(1.0)
            row._ico:SetVertexColor(0.5, 1.0, 0.5)
            row._lbl:SetTextColor(1, 1, 1)
            row._lbl:SetText(name or "?")
        end

        row:SetPoint("TOPLEFT", popup, "TOPLEFT", POPUP_PAD, -(POPUP_PAD + (i - 1) * POPUP_ROW_H))
        row:Show()

        local capturedEntryID = entryID
        row:SetScript("OnClick", function()
            if InCombatLockdown() then return end
            C_Traits.SetSelection(configID, nodeID, capturedEntryID)
            C_Traits.CommitConfig(configID)
            popup:Hide()
        end)
    end

    -- Hide excess entry rows
    for i = numEntries + 1, #popup._rows do
        popup._rows[i]:Hide()
    end

    popup:ClearAllPoints()
    popup:SetPoint("BOTTOM", ownerBtn, "TOP", 0, 4)
    popup:Show()
end

-- ---------------------------------------------------------------------------
-- Node button creation
-- ---------------------------------------------------------------------------

local function createNodeButton(parent, configID, nodeID, xOffset)
    local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
    if not nodeInfo then return end

    local activeEntryID = getActiveEntryID(nodeInfo)
    local iconEntryID   = activeEntryID or (nodeInfo.entryIDs and nodeInfo.entryIDs[1])
    local spellID, iconTex
    if iconEntryID then
        spellID, iconTex = getEntrySpellInfo(configID, iconEntryID)
    end
    iconTex  = iconTex or "Interface\\Icons\\INV_Misc_QuestionMark"
    local isChoice = nodeInfo.entryIDs and #nodeInfo.entryIDs > 1

    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    btn:SetPoint("LEFT", parent, "LEFT", xOffset, 0)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(btn)
    bg:SetAtlas("ui-frame-midnight-portraitdisable", true)
    bg:SetAlpha(0.6)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(30, 30)
    icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
    icon:SetTexture(iconTex)
    icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
    btn.icon = icon

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(btn)
    hl:SetColorTexture(1, 1, 1, 0.15)

    local rankText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rankText:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
    rankText:SetJustifyH("RIGHT")
    btn.rankText = rankText

    local state       = getVisualState(configID, nodeID)
    local currentRank = nodeInfo.currentRank or 0
    applyVisualState(btn, state, currentRank)

    btn._configID = configID
    btn._nodeID   = nodeID
    btn._isChoice = isChoice

    if isChoice then
        -- Selection node: hover shows popup, right-click refunds
        btn:SetScript("OnEnter", function(self)
            cancelHideTimer()
            showSelectionPopup(self, self._configID, self._nodeID)
        end)
        btn:SetScript("OnLeave", scheduleHidePopup)
        btn:SetScript("OnClick", function(self, mouseButton)
            if InCombatLockdown() then return end
            if mouseButton == "RightButton" then
                local ni = C_Traits.GetNodeInfo(self._configID, self._nodeID)
                if ni and (ni.currentRank or 0) > 0 then
                    C_Traits.RefundRank(self._configID, self._nodeID)
                    C_Traits.CommitConfig(self._configID)
                end
            end
        end)
    else
        -- Simple / ranked node
        btn:SetScript("OnEnter", function(self)
            if spellID then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(spellID)
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        btn:SetScript("OnClick", function(self, mouseButton)
            if InCombatLockdown() then return end
            local ni = C_Traits.GetNodeInfo(self._configID, self._nodeID)
            if not ni then return end
            if mouseButton == "LeftButton" then
                C_Traits.PurchaseRank(self._configID, self._nodeID)
                C_Traits.CommitConfig(self._configID)
            elseif mouseButton == "RightButton" and (ni.currentRank or 0) > 0 then
                C_Traits.RefundRank(self._configID, self._nodeID)
                C_Traits.CommitConfig(self._configID)
            end
        end)
    end

    return btn
end

-- ---------------------------------------------------------------------------
-- Refresh all buttons
-- ---------------------------------------------------------------------------

local nodeButtons = {}

local function refreshButtons()
    for _, btn in ipairs(nodeButtons) do
        local nodeInfo = C_Traits.GetNodeInfo(btn._configID, btn._nodeID)
        if nodeInfo then
            local state       = getVisualState(btn._configID, btn._nodeID)
            local currentRank = nodeInfo.currentRank or 0
            applyVisualState(btn, state, currentRank)

            -- For choice nodes, update the icon to reflect the active entry
            if btn._isChoice then
                local activeEntryID = getActiveEntryID(nodeInfo)
                local entryID = activeEntryID or (nodeInfo.entryIDs and nodeInfo.entryIDs[1])
                if entryID then
                    local _, icon = getEntrySpellInfo(btn._configID, entryID)
                    if icon then btn.icon:SetTexture(icon) end
                end
            end
        end
    end
    if popup and popup:IsShown() then
        popup:Hide()
    end
end

-- ---------------------------------------------------------------------------
-- Entry point
-- ---------------------------------------------------------------------------

local function loadTraitNodes(sidebar)
    addon.debugMessage("Loading sidebar: trait nodes...")

    local configID, treeID = getConfigAndTree()
    if not configID or not treeID then
        addon.debugMessage("TraitNodes: trait system not available (system ID " .. TRAIT_SYSTEM_ID .. ")")
        return
    end

    local nodeIDs = getSortedNodeIDs(configID, treeID)
    if #nodeIDs == 0 then return end

    addon.createDivider(sidebar, 23, DIVIDER_Y)

    local totalW = #nodeIDs * BUTTON_SIZE + (#nodeIDs - 1) * BUTTON_GAP

    local frame = CreateFrame("Frame", nil, sidebar)
    frame:SetSize(totalW, BUTTON_SIZE)
    frame:SetPoint("TOP", sidebar, "TOP", 0, FRAME_Y)

    wipe(nodeButtons)
    for i, nodeID in ipairs(nodeIDs) do
        local xOffset = (i - 1) * (BUTTON_SIZE + BUTTON_GAP)
        local btn = createNodeButton(frame, configID, nodeID, xOffset)
        if btn then table.insert(nodeButtons, btn) end
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
    eventFrame:RegisterEvent("TRAIT_TREE_CURRENCY_INFO_UPDATED")
    eventFrame:SetScript("OnEvent", function() refreshButtons() end)
end

if MPT_Sidebar then
    MPT_Sidebar.getTraitNodes = loadTraitNodes
end


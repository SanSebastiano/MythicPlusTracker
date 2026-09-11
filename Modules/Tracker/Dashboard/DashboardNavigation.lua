local addonName, addon = ...

MythicPlusTrackerDB = MythicPlusTrackerDB or {}

local TAB_ROW_TOP = 25   -- distance from the nav frame's top edge to the tab buttons
local TAB_ROW_H   = 30
local TAB_HEIGHT  = 26
local TAB_PADDING = 20
local TAB_SPACING = 8
local NAV_HEIGHT  = 85   -- TAB_ROW_H (30) + bar offset (30) + bar height (~18) + buffer (7)

local BONUS_EVENT_ICON_SIZE = 32

-- The pulse only ever shrinks the icon and lets it return, so
-- BONUS_EVENT_ICON_SIZE stays its maximum. The scale factor is derived from
-- both values, so changing one cannot silently contradict the other.
local BONUS_EVENT_PULSE_MIN_SIZE = 26
local BONUS_EVENT_PULSE_DURATION = 0.7

-- Right edge of the bonus event icon. The window's close button (MainFrame.lua,
-- 32px anchored at -5,-5) covers x -37..-5 down to y -37, and this icon's top
-- edge sits at y -22, so it has to pass the button horizontally instead of
-- fitting underneath it. That is why it stops short of the divider bar's right
-- cap at -20 rather than lining up with it.
local BONUS_EVENT_ICON_RIGHT_INSET = 42

-- navFrame inherits the Dashboard's frame level + 2, while addon.createFramedWindow
-- draws the Dashboard's border art at Dashboard level + 100 — the icon has to beat
-- that to stay visible in the window's top-right corner.
local BONUS_EVENT_ICON_FRAME_LEVEL_OFFSET = 200

local ARTIFACT_R, ARTIFACT_G, ARTIFACT_B = addon.colorToRGB("ARTIFACT")
local POOR_R,     POOR_G,     POOR_B     = addon.colorToRGB("POOR")
local GOLD_R,     GOLD_G,     GOLD_B     = addon.colorToRGB("GOLD")
local UNCOMMON_R, UNCOMMON_G, UNCOMMON_B = addon.colorToRGB("UNCOMMON")

-- Module-level state (reset on each createNavigation call)
local tabFontStrings = {}
local activeTabIndex = 1

local bonusEventIcon
local bonusEventRefreshFrame
local isBonusEventPulseWanted = false
local isBonusEventIconHovered = false

local function setActiveTab(idx)
    activeTabIndex = idx
    for i, fs in ipairs(tabFontStrings) do
        if i == activeTabIndex then
            fs:SetTextColor(ARTIFACT_R, ARTIFACT_G, ARTIFACT_B)
        else
            fs:SetTextColor(POOR_R, POOR_G, POOR_B)
        end
    end
end

-- Exposed so callers outside this file (e.g. Frame.lua on reshow) can
-- reset the highlighted tab without simulating a click.
function MPT_Dashboard:setActiveNavTab(idx)
    setActiveTab(idx)
end

local function showBonusEventTooltip(iconFrame)
    local status = addon.DungeonBonusEvent:getStatus()
    local questStatus = addon.DungeonBonusEvent.QUEST_STATUS

    GameTooltip:SetOwner(iconFrame, "ANCHOR_LEFT")
    GameTooltip:SetText(addon.locale["BONUS_EVENT_TOOLTIP_TITLE"], ARTIFACT_R, ARTIFACT_G, ARTIFACT_B, 1)
    GameTooltip:AddLine(addon.locale["BONUS_EVENT_ACTIVE"], 1, 1, 1, true)

    -- An UNKNOWN quest means this client knows nothing about the tracked quest
    -- ID, so the tooltip says nothing about the quest rather than claiming it
    -- can be picked up. See addon.DungeonBonusEvent:getStatus.
    if status.questStatus ~= questStatus.UNKNOWN then
        local questTitle = status.questTitle or addon.locale["BONUS_EVENT_QUEST_LOADING"]
        addon.addTooltipLabelLine(string.format(addon.locale["BONUS_EVENT_QUEST_LABEL"], questTitle), "ARTIFACT")
    end

    -- The status lines below go through AddLine with resolved RGB instead of
    -- addon.addTooltipLabelLine, because that helper derives its colour from
    -- whether the text happens to contain a colon — and these strings come from
    -- five translations plus Blizzard's own objective text. Their colour carries
    -- meaning (gold = something left to do, white = in progress, green = done),
    -- so it must not depend on punctuation.
    if status.progressText then
        GameTooltip:AddLine(status.progressText, 1, 1, 1, true)
    end

    if status.questStatus == questStatus.AVAILABLE then
        GameTooltip:AddLine(addon.locale["BONUS_EVENT_QUEST_AVAILABLE"], GOLD_R, GOLD_G, GOLD_B, true)
    elseif status.questStatus == questStatus.READY_FOR_TURN_IN then
        GameTooltip:AddLine(addon.locale["BONUS_EVENT_QUEST_TURN_IN"], GOLD_R, GOLD_G, GOLD_B, true)
    elseif status.questStatus == questStatus.COMPLETED then
        GameTooltip:AddLine(addon.locale["BONUS_EVENT_QUEST_COMPLETED"], UNCOMMON_R, UNCOMMON_G, UNCOMMON_B, true)
    end

    GameTooltip:Show()
end

---The icon carries the quest state itself: "!" while there is something to do,
---"?" once the objectives are done, and a greyed-out "!" after turn-in. No
---SetDesaturated needed — the done atlas is already greyed.
---@param questStatus string one of addon.DungeonBonusEvent.QUEST_STATUS
---@return string atlasName
local function bonusEventAtlasForStatus(questStatus)
    local QUEST_STATUS = addon.DungeonBonusEvent.QUEST_STATUS

    if questStatus == QUEST_STATUS.COMPLETED then
        return addon.theme.DUNGEON_BONUS_EVENT_DONE_ICON
    end
    if questStatus == QUEST_STATUS.READY_FOR_TURN_IN then
        return addon.theme.DUNGEON_BONUS_EVENT_TURN_IN_ICON
    end
    return addon.theme.DUNGEON_BONUS_EVENT_ICON
end

---Runs the pulse only while it is actually wanted and the mouse is elsewhere,
---so it never animates a hidden icon and holds still at full size while its
---tooltip is being read.
local function updateBonusEventPulse()
    if not bonusEventIcon then return end

    if isBonusEventPulseWanted and not isBonusEventIconHovered then
        if not bonusEventIcon.pulse:IsPlaying() then
            bonusEventIcon.pulse:Play()
        end
        return
    end

    bonusEventIcon.pulse:Stop()
end

---Applies the current bonus event state to the header icon: hidden unless the
---event week is running and the character could actually do the quest, and
---showing the glyph for the quest's state. The tooltip is not touched here —
---it is rebuilt on every hover, so objective progress stays current without an
---event listener for it.
local function refreshBonusEventIcon()
    if not bonusEventIcon then return end

    if MythicPlusTrackerDB.bonusEventIconHidden or not addon.Player:isMaxLevel() then
        isBonusEventPulseWanted = false
        updateBonusEventPulse()
        bonusEventIcon:Hide()
        return
    end

    local status = addon.DungeonBonusEvent:getStatus()
    if not status.isEventActive then
        isBonusEventPulseWanted = false
        updateBonusEventPulse()
        bonusEventIcon:Hide()
        return
    end

    bonusEventIcon.icon:SetAtlas(bonusEventAtlasForStatus(status.questStatus), false)
    bonusEventIcon:Show()

    -- A quest that is already turned in needs no more attention; every other
    -- state still has something left to do.
    isBonusEventPulseWanted = status.questStatus ~= addon.DungeonBonusEvent.QUEST_STATUS.COMPLETED
    updateBonusEventPulse()
end

---Hover-only, and deliberately a Frame rather than a Button: no API can accept
---a quest an NPC is not currently offering, so a click would have nothing to do
---and should not be invited. Same reasoning as createInfoButton in
---Dashboard/Content/KeystonesPage.lua.
---
---Sits at the right end of the tab row, vertically centred on the tab buttons.
---@param navFrame Frame the tab row frame it is anchored into
---@return Frame iconFrame
local function createBonusEventIcon(navFrame)
    local iconFrame = CreateFrame("Frame", nil, navFrame)
    iconFrame:SetSize(BONUS_EVENT_ICON_SIZE, BONUS_EVENT_ICON_SIZE)
    iconFrame:SetPoint("RIGHT", navFrame, "TOPRIGHT",
            -BONUS_EVENT_ICON_RIGHT_INSET, -(TAB_ROW_TOP + TAB_HEIGHT / 2))
    iconFrame:SetFrameLevel(navFrame:GetFrameLevel() + BONUS_EVENT_ICON_FRAME_LEVEL_OFFSET)
    iconFrame:EnableMouse(true)
    iconFrame:Hide()

    -- Centred with an explicit size rather than SetAllPoints, so the pulse's
    -- Scale animation has a well-defined centre. Only the texture is animated,
    -- never the frame, which keeps the mouse target a constant
    -- BONUS_EVENT_ICON_SIZE square wherever in the pulse it currently is.
    iconFrame.icon = iconFrame:CreateTexture(nil, "ARTWORK")
    iconFrame.icon:SetSize(BONUS_EVENT_ICON_SIZE, BONUS_EVENT_ICON_SIZE)
    iconFrame.icon:SetPoint("CENTER", iconFrame, "CENTER")
    iconFrame.icon:SetAtlas(addon.theme.DUNGEON_BONUS_EVENT_ICON, false)

    -- One shrink animation on BOUNCE loop gives the full breathe cycle, from
    -- full size down to BONUS_EVENT_PULSE_MIN_SIZE and back.
    iconFrame.pulse = iconFrame.icon:CreateAnimationGroup()
    iconFrame.pulse:SetLooping("BOUNCE")

    local pulseScale = BONUS_EVENT_PULSE_MIN_SIZE / BONUS_EVENT_ICON_SIZE
    local shrink = iconFrame.pulse:CreateAnimation("Scale")
    shrink:SetOrigin("CENTER", 0, 0)
    shrink:SetScaleFrom(1, 1)
    shrink:SetScaleTo(pulseScale, pulseScale)
    shrink:SetDuration(BONUS_EVENT_PULSE_DURATION)
    shrink:SetSmoothing("IN_OUT")

    iconFrame:SetScript("OnEnter", function(self)
        isBonusEventIconHovered = true
        updateBonusEventPulse()
        showBonusEventTooltip(self)
    end)
    iconFrame:SetScript("OnLeave", function()
        isBonusEventIconHovered = false
        updateBonusEventPulse()
        GameTooltip:Hide()
    end)

    return iconFrame
end

---@param parent Frame
---@param callbacks table|nil maps tab index -> function, called on click; a
---callback returning exactly `false` blocks the tab switch (activeTabIndex
---and the highlight stay on the previous tab)
---@return number navHeight so the caller can offset content below it
function MPT_Dashboard:createNavigation(parent, callbacks)
    wipe(tabFontStrings)
    activeTabIndex = 1

    local navFrame = CreateFrame("Frame", nil, parent)
    navFrame:SetPoint("TOPLEFT",  parent, "TOPLEFT")
    navFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT")
    navFrame:SetHeight(NAV_HEIGHT)
    MPT_Dashboard.navFrame = navFrame  -- expose for content anchoring

    local tabDefs = {
        addon.locale["DASHBOARD_TAB_OVERVIEW"],
        addon.locale["DASHBOARD_TAB_RUNS"],
        addon.locale["DASHBOARD_TAB_KEYSTONES"],
    }

    local prevBtn = nil
    for i, label in ipairs(tabDefs) do
        local btn = CreateFrame("Button", nil, navFrame)
        btn:SetHeight(TAB_HEIGHT)

        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        fs:SetText(label)
        fs:SetPoint("CENTER", btn, "CENTER")
        btn:SetFontString(fs)

        local textW = fs:GetStringWidth()
        if textW <= 0 then textW = 80 end
        btn:SetWidth(textW + TAB_PADDING)

        if prevBtn == nil then
            btn:SetPoint("TOPLEFT", navFrame, "TOPLEFT", 48, -TAB_ROW_TOP)
        else
            btn:SetPoint("TOPLEFT", prevBtn,  "TOPRIGHT", TAB_SPACING, 0)
        end

        tabFontStrings[i] = fs

        local capturedIdx = i
        btn:SetScript("OnClick", function()
            if callbacks and callbacks[capturedIdx] then
                local allowed = callbacks[capturedIdx]()
                if allowed == false then return end
            end
            setActiveTab(capturedIdx)
        end)

        prevBtn = btn
    end

    setActiveTab(1)

    local barLeft = navFrame:CreateTexture(nil, "ARTWORK")
    barLeft:SetAtlas(addon.theme.TAB_BAR_LEFT, true)
    barLeft:SetPoint("TOPLEFT", navFrame, "TOPLEFT", 20, -(TAB_ROW_H + 30))

    local barRight = navFrame:CreateTexture(nil, "ARTWORK")
    barRight:SetAtlas(addon.theme.TAB_BAR_RIGHT, true)
    barRight:SetPoint("TOPRIGHT", navFrame, "TOPRIGHT", -20, -(TAB_ROW_H + 30))

    local barCenter = navFrame:CreateTexture(nil, "ARTWORK")
    barCenter:SetAtlas(addon.theme.TAB_BAR_CENTER, false)
    barCenter:SetPoint("TOPLEFT",  barLeft,  "TOPRIGHT", 0, 0)
    barCenter:SetPoint("TOPRIGHT", barRight, "TOPLEFT",  0, 0)
    barCenter:SetPoint("BOTTOM",   barLeft,  "BOTTOM",   0, 0)

    local barFill = navFrame:CreateTexture(nil, "BACKGROUND")
    barFill:SetAtlas(addon.theme.TAB_BAR_FILL, false)
    barFill:SetPoint("TOPLEFT",  barLeft,  "TOPLEFT",   15, -5)
    barFill:SetPoint("TOPRIGHT", barRight, "TOPRIGHT", -15, -5)
    barFill:SetPoint("BOTTOM",   barLeft,  "BOTTOM",     0,  6)

    bonusEventIcon = createBonusEventIcon(navFrame)

    -- Registered on the first navigation build rather than at file load, so
    -- players who never open the window never register these events. They are
    -- the only bonus event state changes that can happen while the window is
    -- open, and are filtered down to the one tracked quest; the event aura
    -- itself only changes at the weekly reset and is read on demand instead.
    -- Guarded so a repeated createNavigation call cannot register them twice.
    if not bonusEventRefreshFrame then
        bonusEventRefreshFrame = CreateFrame("Frame")
        bonusEventRefreshFrame:RegisterEvent("QUEST_ACCEPTED")
        bonusEventRefreshFrame:RegisterEvent("QUEST_TURNED_IN")
        bonusEventRefreshFrame:SetScript("OnEvent", function(_, event, questID)
            if event ~= "QUEST_ACCEPTED" and event ~= "QUEST_TURNED_IN" then return end
            if not addon.DungeonBonusEvent:isTrackedQuest(questID) then return end
            refreshBonusEventIcon()
        end)
    end

    return NAV_HEIGHT
end

---Re-applies the header icon's visibility and desaturation. Public so the
---Dashboard's OnShow and the Settings checkbox can drive it; a no-op while the
---navigation has never been built.
function MPT_Dashboard:refreshBonusEventIcon()
    refreshBonusEventIcon()
end

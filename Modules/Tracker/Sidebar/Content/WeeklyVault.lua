local addonName, addon = ...

local SLOT_COUNT   = 3
local SLOT_WIDTH   = 70
local SLOT_HEIGHT  = 45
local SLOT_GAP     = 8
local CONTAINER_W  = SLOT_COUNT * SLOT_WIDTH + (SLOT_COUNT - 1) * SLOT_GAP  -- 226
local CONTAINER_H  = SLOT_HEIGHT
local ANCHOR_X     = 23
local CONTAINER_X  = ANCHOR_X + math.floor((254 - CONTAINER_W) / 2)  -- centres slots (=37)
local ANCHOR_Y     = -235

local M_PLUS_TYPE  = Enum.WeeklyRewardChestThresholdType and
                     Enum.WeeklyRewardChestThresholdType.Activities or 3

-- Methods borrowed from WeeklyRewardsActivityMixin for the Blizzard tooltip chain
local INHERIT_METHODS = {
    "ShowTooltip",
    "ShowPreviewItemTooltip",
    "ShowIncompleteTooltip",
    "IsCompletedAtHeroicLevel",
    "AddTopRunsToTooltip",
    "HandlePreviewMythicRewardTooltip",
    "HandlePreviewPvPRewardTooltip",
    "GetRaidName",
    "AddRaidCompletionInfoToGameTooltip",
}

local function getActivityItemLevel(activity)
    if not activity then return nil end
    local itemLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(activity.id)
    if itemLink and itemLink ~= "" and itemLink ~= "[]" then
        return C_Item.GetDetailedItemLevelInfo(itemLink)
    end
    return nil
end

local function buildSlot(container, activity, slotIndex, BlizzardMixin)
    local xOff = (slotIndex - 1) * (SLOT_WIDTH + SLOT_GAP)

    local slot = CreateFrame("Frame", nil, container)
    slot:SetSize(SLOT_WIDTH, SLOT_HEIGHT)
    slot:SetPoint("TOPLEFT", container, "TOPLEFT", xOff, 0)

    local background = slot:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(slot)
    background:SetAtlas("ui-frame-midnight-portraitdisable", true)

    local unlocked = activity and (activity.progress >= activity.threshold)
    local itemLevel     = getActivityItemLevel(activity)

    local centerText = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    centerText:SetPoint("CENTER", slot, "CENTER", 0, 0)
    centerText:SetJustifyH("CENTER")
    if unlocked then
        if itemLevel then
            centerText:SetText(addon.colors.ARTIFACT .. itemLevel .. addon.colors.RESET)
        else
            centerText:SetText(addon.colors.ARTIFACT .. "?" .. addon.colors.RESET)
        end
    elseif activity then
        centerText:SetText(addon.colors.POOR .. activity.progress .. " / " .. activity.threshold .. addon.colors.RESET)
    else
        centerText:SetText(addon.colors.POOR .. "-" .. addon.colors.RESET)
    end

    local button = CreateFrame("Button", nil, slot)
    button:SetAllPoints(slot)

    if BlizzardMixin then
        for _, method in ipairs(INHERIT_METHODS) do
            if BlizzardMixin[method] then
                button[method] = BlizzardMixin[method]
            end
        end
        button.info          = activity
        button.unlocked      = unlocked
        button.progressDelta = activity and math.max(0, activity.threshold - activity.progress) or 0
        button.CanShowPreviewItemTooltip = function(self) return self.unlocked end
    end

    button:SetScript("OnEnter", function(self)
        if BlizzardMixin and self.info then
            WeeklyRewardsActivityMixin.OnEnter(self)
            local tt = GameTooltip
            if tt:IsShown() and tt:GetOwner() == self then
                tt:ClearAllPoints()
                tt:SetPoint("BOTTOMLEFT", self, "TOPRIGHT", -4, 0)
            end
        end
    end)

    button:SetScript("OnClick", function()
        WeeklyRewards_ShowUI()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function loadWeeklyVault(sidebar)
    addon.debugMessage("Loading sidebar: weekly vault...")

    addon.createDivider(sidebar, ANCHOR_X, -210)

    local container = CreateFrame("Frame", nil, sidebar)
    container:SetSize(CONTAINER_W, CONTAINER_H)
    container:SetPoint("TOPLEFT", sidebar, "TOPLEFT", CONTAINER_X, ANCHOR_Y)

    C_AddOns.LoadAddOn("Blizzard_WeeklyRewards")
    local BlizzardMixin = WeeklyRewardsActivityMixin

    local all = C_WeeklyRewards.GetActivities() or {}
    local bySlot = {}
    for _, act in ipairs(all) do
        if act.type == M_PLUS_TYPE then
            bySlot[act.index] = act
        end
    end

    for i = 1, SLOT_COUNT do
        buildSlot(container, bySlot[i], i, BlizzardMixin)
    end
end

if MPT_Sidebar then
    MPT_Sidebar.getWeeklyVault = loadWeeklyVault
end
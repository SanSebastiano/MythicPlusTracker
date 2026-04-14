local addonName, addon = ...

local SLOT_COUNT   = 3
local SLOT_WIDTH   = 79
local SLOT_HEIGHT  = 55
local SLOT_GAP     = 8
local CONTAINER_W  = SLOT_COUNT * SLOT_WIDTH + (SLOT_COUNT - 1) * SLOT_GAP  -- 253
local CONTAINER_H  = SLOT_HEIGHT
local ANCHOR_X     = 23
local ANCHOR_Y     = -200

local M_PLUS_TYPE  = Enum.WeeklyRewardChestThresholdType and
                     Enum.WeeklyRewardChestThresholdType.Activities or 3

local function getActivityIlvl(activity)
    -- Rewards table is populated when the vault is open (after weekly reset)
    if activity.rewards and #activity.rewards > 0 then
        local reward = activity.rewards[1]
        if reward and reward.id and reward.id > 0 then
            local ilvl = select(4, GetItemInfo(reward.id))
            if ilvl and ilvl > 0 then return ilvl end
        end
    end
    return nil
end

local function buildSlot(container, activity, slotIndex)
    local xOff = (slotIndex - 1) * (SLOT_WIDTH + SLOT_GAP)

    local slot = CreateFrame("Frame", nil, container)
    slot:SetSize(SLOT_WIDTH, SLOT_HEIGHT)
    slot:SetPoint("TOPLEFT", container, "TOPLEFT", xOff, 0)

    local bg = slot:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(slot)
    bg:SetColorTexture(0, 0, 0, 0.25)

    local unlocked = activity and activity.progress >= activity.threshold
    local ilvl     = activity and getActivityIlvl(activity)

    local centerText = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    centerText:SetPoint("CENTER", slot, "CENTER", 0, 0)
    centerText:SetJustifyH("CENTER")
    if unlocked and ilvl then
        centerText:SetText(addon.colors.SUCCESS .. ilvl .. addon.colors.RESET)
    elseif activity then
        centerText:SetText(addon.colors.WARNING .. activity.progress .. " / " .. activity.threshold .. addon.colors.RESET)
    else
        centerText:SetText(addon.colors.POOR .. "–" .. addon.colors.RESET)
    end

    local btn = CreateFrame("Button", nil, slot)
    btn:SetAllPoints(slot)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(string.format(addon.locale["SIDEBAR_VAULT_SLOT"], slotIndex), 1, 1, 1)

        if not activity then
            GameTooltip:AddLine(addon.colors.POOR .. "–" .. addon.colors.RESET)
        elseif unlocked then
            if ilvl then
                GameTooltip:AddLine(string.format(addon.locale["SIDEBAR_VAULT_REWARD_ILVL"], ilvl), 0, 1, 0)
            end
        else
            GameTooltip:AddLine(
                string.format(addon.locale["SIDEBAR_VAULT_PROGRESS"], activity.progress, activity.threshold),
                1, 0.5, 0
            )
        end

        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function loadWeeklyVault(sidebar)
    addon.debugMessage("Loading sidebar: weekly vault...")

    addon.createDivider(sidebar, ANCHOR_X, -175)

    local container = CreateFrame("Frame", nil, sidebar)
    container:SetSize(CONTAINER_W, CONTAINER_H)
    container:SetPoint("TOPLEFT", sidebar, "TOPLEFT", ANCHOR_X, ANCHOR_Y)

    -- GetActivities returns all types regardless of the parameter; filter manually
    local all = C_WeeklyRewards.GetActivities() or {}
    local bySlot = {}
    for _, act in ipairs(all) do
        if act.type == M_PLUS_TYPE then
            bySlot[act.index] = act
        end
    end

    for i = 1, SLOT_COUNT do
        buildSlot(container, bySlot[i], i)
    end
end

if MPT_Sidebar then
    MPT_Sidebar.getWeeklyVault = loadWeeklyVault
end


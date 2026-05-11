local addonName, addon = ...

local KEYSTONE_ITEM_ID = 180653

local function findKeystoneInBags()
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            if C_Container.GetContainerItemID(bag, slot) == KEYSTONE_ITEM_ID then
                return bag, slot
            end
        end
    end
end

local function loadKeystone(sidebar)
    addon.debugMessage("Loading sidebar: keystone...")

    local frame = CreateFrame("Frame", nil, sidebar)
    frame:SetSize(254, 50)
    frame:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 23, -155)

    local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local level = C_MythicPlus.GetOwnedKeystoneLevel()

    if not mapID or not level then
        local noKeyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        noKeyText:SetAllPoints(frame)
        noKeyText:SetJustifyH("CENTER")
        noKeyText:SetJustifyV("MIDDLE")
        noKeyText:SetText(addon.colors.POOR .. addon.locale["SIDEBAR_NO_KEYSTONE"] .. addon.colors.RESET)
        return
    end

    local name, _, _, texture = C_ChallengeMode.GetMapUIInfo(mapID)
    if not name then return end

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("LEFT", frame, "LEFT", 5, 0)
    icon:SetTexture(texture)

    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    nameText:SetPoint("RIGHT", frame, "RIGHT", 40, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetText(addon.colors.ARTIFACT .. name .. addon.colors.RESET)

    local levelText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    levelText:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
    levelText:SetJustifyH("RIGHT")
    levelText:SetText(addon.colorKeystoneLevel(level) .. level .. addon.colors.RESET)

    local tooltipButton = CreateFrame("Button", nil, frame)
    tooltipButton:SetSize(frame:GetWidth() - 32, 32)
    tooltipButton:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    tooltipButton:SetScript("OnEnter", function(self)
        local bag, slot = findKeystoneInBags()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if bag then
            GameTooltip:SetBagItem(bag, slot)
        else
            GameTooltip:AddLine(name, 1, 1, 1)
            GameTooltip:AddLine(addon.locale["SIDEBAR_KEYSTONE_LEVEL"] .. ": " .. addon.colorKeystoneLevel(level) .. level .. addon.colors.RESET)
            GameTooltip:Show()
        end
    end)
    tooltipButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

if MPT_Sidebar then
    MPT_Sidebar.getKeystone = loadKeystone
end

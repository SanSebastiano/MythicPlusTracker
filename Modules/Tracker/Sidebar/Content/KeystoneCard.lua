local addonName, addon = ...

local CONTENT_W = MPT_Sidebar.LAYOUT.CONTENT_W
local KEYSTONE_HEIGHT = 50
local KEYSTONE_GAP = 7   -- gap after the previous card (Affixes)

function MPT_Sidebar:loadKeystone(sidebar, cursor)
    addon.debugMessage("Loading sidebar: keystone...")

    local y = cursor:current() - KEYSTONE_GAP
    cursor:advance(KEYSTONE_GAP + KEYSTONE_HEIGHT)

    local frame = CreateFrame("Frame", nil, sidebar)
    frame:SetSize(CONTENT_W, KEYSTONE_HEIGHT)
    frame:SetPoint("TOPLEFT", sidebar, "TOPLEFT", MPT_Sidebar.LAYOUT.CONTENT_X, y)

    local mapID, level, name, texture = addon.KeystoneService:getOwned()

    if not mapID then
        local noKeyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        noKeyText:SetAllPoints(frame)
        noKeyText:SetJustifyH("CENTER")
        noKeyText:SetJustifyV("MIDDLE")
        noKeyText:SetText(addon.colors.POOR .. addon.locale["SIDEBAR_NO_KEYSTONE"] .. addon.colors.RESET)
        return
    end

    if not name then return end

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("LEFT", frame, "LEFT", 10, 0)
    icon:SetTexture(texture)

    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    nameText:SetPoint("RIGHT", frame, "RIGHT", 45, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetText(addon.colors.ARTIFACT .. name .. addon.colors.RESET)

    local levelText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    levelText:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
    levelText:SetJustifyH("RIGHT")
    levelText:SetText(addon.colorKeystoneLevel(level) .. level .. addon.colors.RESET)

    local tooltipButton = CreateFrame("Button", nil, frame)
    tooltipButton:SetSize(frame:GetWidth() - 37, 32)
    tooltipButton:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    tooltipButton:SetScript("OnEnter", function(self)
        local bag, slot = addon.KeystoneService:findInBags()
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

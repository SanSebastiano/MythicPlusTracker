local addonName, addon = ...

local CURRENCY_IDS = {
    3442,
    3443,
    3444,
    3445,
    3446,
}

local SLOT_W    = 34
local SLOT_GAP  = 4
local ICON_SIZE = 22
local SLOT_H    = ICON_SIZE + 4 + 16  -- icon + gap + amount text
local CURRENCY_GAP = 20   -- gap after the previous card (TraitNodes)
local HEADER_TO_CONTENT_GAP = 4

local function loadCurrency(frame, currencyId, index)
    local currency = C_CurrencyInfo.GetCurrencyInfo(currencyId)
    if not currency then return end

    local xOffset = (index - 1) * (SLOT_W + SLOT_GAP)

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset + (SLOT_W - ICON_SIZE) / 2, 0)
    icon:SetTexture(currency.iconFileID)

    local amount = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    amount:SetSize(SLOT_W, 16)
    amount:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, -ICON_SIZE - 4)
    amount:SetJustifyH("CENTER")

    local weeklyCapReached = false
    if currency.maxWeeklyQuantity and currency.maxWeeklyQuantity > 0 then
        local earned = currency.quantityEarnedThisWeek or 0
        weeklyCapReached = earned >= currency.maxWeeklyQuantity
    end
    if weeklyCapReached then
        amount:SetText(addon.colors.SUCCESS .. currency.quantity .. addon.colors.RESET)
    else
        amount:SetText(addon.colors.WHITE .. currency.quantity .. addon.colors.RESET)
    end

    local tooltipButton = CreateFrame("Button", nil, frame)
    tooltipButton:SetSize(SLOT_W, SLOT_H)
    tooltipButton:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, 0)
    tooltipButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetCurrencyByID(currencyId)
        GameTooltip:Show()
    end)
    tooltipButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

function MPT_Sidebar:loadCurrencies(sidebar, cursor)
    addon.debugMessage("Loading sidebar: currencies...")

    local headerY = cursor:current() - CURRENCY_GAP
    local contentY = headerY - addon.SIDEBAR_SECTION_HEADER_HEIGHT - HEADER_TO_CONTENT_GAP
    cursor:advance(CURRENCY_GAP + addon.SIDEBAR_SECTION_HEADER_HEIGHT + HEADER_TO_CONTENT_GAP + SLOT_H)

    addon.createSidebarSectionHeader(sidebar, headerY, 254, addon.locale["SIDEBAR_CURRENCY_HEADER"])

    local totalW = #CURRENCY_IDS * SLOT_W + (#CURRENCY_IDS - 1) * SLOT_GAP

    local frame = CreateFrame("Frame", nil, sidebar)
    frame:SetSize(totalW, SLOT_H)
    frame:SetPoint("TOP", sidebar, "TOP", 0, contentY)

    for index, currencyId in ipairs(CURRENCY_IDS) do
        loadCurrency(frame, currencyId, index)
    end
end

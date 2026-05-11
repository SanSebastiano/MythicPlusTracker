local addonName, addon = ...

local CURRENCY_IDS = {
    3347,
    3345,
    3343,
    3341,
    3383,
}

local function loadCurrency(frame, currencyId, index)
    local currency = C_CurrencyInfo.GetCurrencyInfo(currencyId)

    if not currency then return end

    local yOffset = -10 - ((index - 1) * 30)

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, yOffset)
    icon:SetTexture(currency.iconFileID)

    local name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    name:SetWidth(170)
    name:SetMaxLines(1)
    name:SetJustifyH("LEFT")
    name:SetText(addon.colors.ARTIFACT .. currency.name .. addon.colors.RESET)

    local amount = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    amount:SetPoint("RIGHT", frame, "TOPRIGHT", -5, yOffset - 10)
    amount:SetJustifyH("RIGHT")

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
    tooltipButton:SetSize(frame:GetWidth() - 10, 25)
    tooltipButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, yOffset + 2)
    tooltipButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetCurrencyByID(currencyId)
        GameTooltip:Show()
    end)
    tooltipButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function loadBar(sidebar)
    addon.debugMessage("Loading sidebar: currencies...")

    addon.createDivider(sidebar, 23, -295)

    local frame = CreateFrame(
        "Frame",
        nil,
        sidebar
    )

    frame:SetSize(254, 20 + (#CURRENCY_IDS * 30))
    frame:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 23, -320)

    for index, currencyId in ipairs(CURRENCY_IDS) do
        loadCurrency(frame, currencyId, index)
    end
end

if MPT_Sidebar then
    MPT_Sidebar.getCurrencies = loadBar
end

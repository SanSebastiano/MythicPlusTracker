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
    name:SetJustifyH("LEFT")
    name:SetText(currency.name)
    name:SetTextColor(1, 1, 1, 1)

    local amount = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    amount:SetPoint("RIGHT", frame, "TOPRIGHT", -5, yOffset - 10)
    amount:SetJustifyH("RIGHT")
    amount:SetText(currency.quantity)

    local weeklyCapReached = currency.maxWeeklyQuantity and currency.maxWeeklyQuantity > 0
        and currency.quantityEarnedThisWeek and currency.quantityEarnedThisWeek >= currency.maxWeeklyQuantity
    if weeklyCapReached then
        amount:SetTextColor(0, 1, 0, 1)
    else
        amount:SetTextColor(1, 1, 1, 1)
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

    local dividerFrame = sidebar:CreateTexture(nil, "ARTWORK")
    dividerFrame:SetSize(254, 20)
    dividerFrame:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 23, -175)
    dividerFrame:SetAtlas("midnight-scenario-bar-frame", false)

    local dividerFill = sidebar:CreateTexture(nil, "BACKGROUND")
    dividerFill:SetSize(220, 12)
    dividerFill:SetPoint("CENTER", sidebar, "TOPLEFT", 23 + 127, -175 - 10)
    dividerFill:SetAtlas("midnight-scenario-barfill", false)

    local frame = CreateFrame(
        "Frame",
        nil,
        sidebar
    )

    frame:SetSize(254, 20 + (#CURRENCY_IDS * 30))
    frame:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 23, -200)

    for index, currencyId in ipairs(CURRENCY_IDS) do
        loadCurrency(frame, currencyId, index)
    end
end

if MPT_Sidebar then
    MPT_Sidebar.getCurrencies = loadBar
end

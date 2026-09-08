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
local HEADER_TO_CONTENT_GAP = MPT_Sidebar.LAYOUT.HEADER_TO_CONTENT_GAP

---Whether a currency has hit its cap (weekly or season-total, whichever
---applies) — verified against how the Plumber addon does this
---(CurrencyButtonMixin:Refresh in its Currency.lua): the season-earned
---formula and the official Blizzard queries are independent signals, OR'd
---together, not one a fallback for the other. That distinction matters for
---crests specifically: `quantity` (currently held) drops as crests get spent
---on upgrades, while `totalEarned` (this season's progress toward the cap,
---the same number the game's own tooltip shows) does not — a currency can
---read as season-capped in the tooltip while quantity is well below
---maxQuantity, which C_CurrencyInfo.PlayerHasMaxQuantity alone doesn't catch.
---@param currency table result of C_CurrencyInfo.GetCurrencyInfo
---@param currencyId number
---@return boolean
local function isCurrencyCapped(currency, currencyId)
    local quantity    = currency.quantity or 0
    local totalEarned = currency.totalEarned or 0
    local maxQuantity = currency.maxQuantity or 0

    local formulaCapped = quantity > 0 and maxQuantity > 0
        and ((maxQuantity - totalEarned == 0) or quantity >= maxQuantity)

    local apiCapped = false
    if C_CurrencyInfo.PlayerHasMaxWeeklyQuantity and C_CurrencyInfo.PlayerHasMaxQuantity then
        apiCapped = C_CurrencyInfo.PlayerHasMaxWeeklyQuantity(currencyId) or C_CurrencyInfo.PlayerHasMaxQuantity(currencyId)
    end

    return formulaCapped or apiCapped
end

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

    if isCurrencyCapped(currency, currencyId) then
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

    addon.createSidebarSectionHeader(sidebar, headerY, MPT_Sidebar.LAYOUT.CONTENT_W, addon.locale["SIDEBAR_CURRENCY_HEADER"])

    local totalW = #CURRENCY_IDS * SLOT_W + (#CURRENCY_IDS - 1) * SLOT_GAP

    local frame = CreateFrame("Frame", nil, sidebar)
    frame:SetSize(totalW, SLOT_H)
    frame:SetPoint("TOP", sidebar, "TOP", 0, contentY)

    for index, currencyId in ipairs(CURRENCY_IDS) do
        loadCurrency(frame, currencyId, index)
    end
end

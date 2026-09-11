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

---The progress value a currency's cap is measured against, paired with that
---cap — the same pairing the game's own tooltip shows. `useTotalEarnedForMaxQty`
---marks `maxQuantity` as a season-earned cap, which is what every crest uses:
---progress is `totalEarned`, never `quantity`. The two drift apart in both
---directions — `quantity` falls as crests get spent on upgrades, and it rises
---above `totalEarned` for crests from sources that don't count toward the cap
---(the crest exchange, for one) — so `quantity` is no measure of cap progress.
---@param currency table result of C_CurrencyInfo.GetCurrencyInfo
---@return number|nil earned, number|nil cap
local function getEarnedAndCap(currency)
    if currency.useTotalEarnedForMaxQty and (currency.maxQuantity or 0) > 0 then
        return currency.totalEarned or 0, currency.maxQuantity
    end
    if (currency.maxWeeklyQuantity or 0) > 0 then
        return currency.quantityEarnedThisWeek or 0, currency.maxWeeklyQuantity
    end
    if (currency.maxQuantity or 0) > 0 then
        return currency.quantity or 0, currency.maxQuantity
    end
end

---@param currency table result of C_CurrencyInfo.GetCurrencyInfo
---@param currencyId number
---@return boolean
local function isCurrencyCapped(currency, currencyId)
    local earned, cap = getEarnedAndCap(currency)
    if earned and cap then
        return earned >= cap
    end

    -- No usable cap on the info table: let Blizzard answer. These queries are
    -- an alternative to the comparison above, not an additional signal — the
    -- Plumber addon treats them the same way (API.IsCurrencyFullyEarned) — so
    -- OR-ing them in would only risk reintroducing a cap the tooltip denies.
    if C_CurrencyInfo.PlayerHasMaxWeeklyQuantity and C_CurrencyInfo.PlayerHasMaxQuantity then
        return C_CurrencyInfo.PlayerHasMaxWeeklyQuantity(currencyId) or C_CurrencyInfo.PlayerHasMaxQuantity(currencyId)
    end

    return false
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

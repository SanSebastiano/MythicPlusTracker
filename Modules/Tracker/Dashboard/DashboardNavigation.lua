local addonName, addon = ...

local TAB_ROW_H   = 30
local TAB_HEIGHT  = 26
local TAB_PADDING = 20
local TAB_SPACING = 8
local NAV_HEIGHT  = 85   -- TAB_ROW_H (30) + bar offset (30) + bar height (~18) + buffer (7)

local ARTIFACT_R, ARTIFACT_G, ARTIFACT_B = addon.colorToRGB("ARTIFACT")
local POOR_R,     POOR_G,     POOR_B     = addon.colorToRGB("POOR")

-- Module-level state (reset on each createNavigation call)
local tabFontStrings = {}
local activeTabIndex = 1

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
            btn:SetPoint("TOPLEFT", navFrame, "TOPLEFT", 48, -25)
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

    return NAV_HEIGHT
end

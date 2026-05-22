local addonName, addon = ...

local TAB_ROW_H   = 30   -- height reserved for the tab button row
local TAB_HEIGHT  = 26   -- individual button height
local TAB_PADDING = 20   -- horizontal padding inside each tab button
local TAB_SPACING = 8    -- gap between consecutive tabs
local NAV_HEIGHT  = 52   -- TAB_ROW_H (30) + bar (~18) + small buffer (4)

-- Parsed RGB for SetTextColor (from addon.colors escape codes)
local ARTIFACT_R, ARTIFACT_G, ARTIFACT_B = 0xe6 / 255, 0xcc / 255, 0x80 / 255  -- |cFFe6cc80
local POOR_R,     POOR_G,     POOR_B     = 0x9d / 255, 0x9d / 255, 0x9d / 255  -- |cFF9d9d9d

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

-- Creates the navigation bar and returns NAV_HEIGHT so the caller can
-- offset the content below it.
function MPT_Dashboard:createNavigation(parent)
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

    -- Vertically centre the buttons within the tab row
    local tabY = -(TAB_ROW_H - TAB_HEIGHT) / 2

    local prevBtn = nil
    for i, label in ipairs(tabDefs) do
        local btn = CreateFrame("Button", nil, navFrame)
        btn:SetHeight(TAB_HEIGHT)

        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        fs:SetText(label)
        fs:SetPoint("CENTER", btn, "CENTER")
        btn:SetFontString(fs)

        -- Width based on text content
        local textW = fs:GetStringWidth()
        if textW <= 0 then textW = 80 end
        btn:SetWidth(textW + TAB_PADDING)

        if prevBtn == nil then
            btn:SetPoint("LEFT", navFrame, "LEFT", 48, tabY - 10)
        else
            btn:SetPoint("LEFT", prevBtn,  "RIGHT", TAB_SPACING, 0)
        end

        tabFontStrings[i] = fs

        local capturedIdx = i
        btn:SetScript("OnClick", function()
            setActiveTab(capturedIdx)
        end)

        prevBtn = btn
    end

    -- Apply initial colours
    setActiveTab(1)

    -- 3-part decorative bar placed directly below the tab row.
    -- Left / right caps use their atlas-native size so they are not distorted.
    -- The center piece stretches horizontally to fill the space between them.
    local barLeft = navFrame:CreateTexture(nil, "ARTWORK")
    barLeft:SetAtlas("midnight-scenario-barframe-borderleft", true)
    barLeft:SetPoint("TOPLEFT", navFrame, "TOPLEFT", 20, -(TAB_ROW_H + 30))

    local barRight = navFrame:CreateTexture(nil, "ARTWORK")
    barRight:SetAtlas("midnight-scenario-barframe-borderright", true)
    barRight:SetPoint("TOPRIGHT", navFrame, "TOPRIGHT", -20, -(TAB_ROW_H + 30))

    local barCenter = navFrame:CreateTexture(nil, "ARTWORK")
    barCenter:SetAtlas("midnight-scenario-barframe-bordercenter", false)
    barCenter:SetPoint("TOPLEFT",  barLeft,  "TOPRIGHT", 0, 0)
    barCenter:SetPoint("TOPRIGHT", barRight, "TOPLEFT",  0, 0)
    barCenter:SetPoint("BOTTOM",   barLeft,  "BOTTOM",   0, 0)

    local barFill = navFrame:CreateTexture(nil, "BACKGROUND")
    barFill:SetAtlas("midnight-scenario-barfill", false)
    barFill:SetPoint("TOPLEFT",  barLeft,  "TOPLEFT",   15, -5)
    barFill:SetPoint("TOPRIGHT", barRight, "TOPRIGHT", -15, -5)
    barFill:SetPoint("BOTTOM",   barLeft,  "BOTTOM",     0,  6)

    return NAV_HEIGHT
end

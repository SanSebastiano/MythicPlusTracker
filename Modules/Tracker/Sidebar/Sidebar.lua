local addonName, addon = ...

MPT_Sidebar = {}

local frame
local contentWrapper

-- Starting Y for the first card (Score). Every subsequent card reads its own
-- anchor from the cursor and advances it by its own gap + height, so no card
-- needs to know any other card's size (see Sidebar/CardWidgets.lua).
local FIRST_CARD_Y = -30

local function renderDefaultContent(wrapper, cursor)
    MPT_Sidebar:loadScore(wrapper, cursor)
    MPT_Sidebar:loadAffixes(wrapper, cursor)
    MPT_Sidebar:loadKeystone(wrapper, cursor)
    MPT_Sidebar:loadWeeklyVault(wrapper, cursor)
    MPT_Sidebar:loadTraitNodes(wrapper, cursor)
    MPT_Sidebar:loadCurrencies(wrapper, cursor)
end

local function renderRunsContent(wrapper, cursor)
    MPT_Sidebar:loadScore(wrapper, cursor)
    MPT_Sidebar:loadRunsStats(wrapper, cursor)
end

local function renderKeystonesContent(wrapper, cursor)
    MPT_Sidebar:loadScore(wrapper, cursor)
    MPT_Sidebar:loadStatistics(wrapper, cursor)
end

local function rebuildContent(renderFn)
    if contentWrapper then contentWrapper:Hide() end
    contentWrapper = CreateFrame("Frame", nil, frame)
    contentWrapper:SetAllPoints(frame)
    local cursor = addon.createLayoutCursor(FIRST_CARD_Y)
    renderFn(contentWrapper, cursor)
end

local function create(mainFrame)
    if frame then return frame end

    frame = CreateFrame("Frame", nil, mainFrame)

    frame:SetSize(300, 550)
    frame:SetPoint("TOPLEFT", mainFrame)

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(frame)
    background:SetAtlas(addon.theme.FRAME_BACKGROUND, false)

    local borderFrame = CreateFrame("Frame", nil, frame)
    borderFrame:SetAllPoints(frame)
    -- The border atlas is oversized relative to the frame; scaling this
    -- wrapper down makes the texture's edges align with the panel's edges.
    borderFrame:SetScale(0.75)

    local border = borderFrame:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints(borderFrame)
    border:SetAtlas(addon.theme.FRAME_BORDER, false)

    frame:SetScript("OnShow", function()
        rebuildContent(renderDefaultContent)
    end)

    return frame
end

function MPT_Sidebar:getFrame(mainFrame)
    return create(mainFrame)
end

function MPT_Sidebar:showForTab(tabIndex)
    if not frame then return end
    if tabIndex == MPT_Tracker.TABS.RUNS then
        rebuildContent(renderRunsContent)
    elseif tabIndex == MPT_Tracker.TABS.KEYSTONES then
        rebuildContent(renderKeystonesContent)
    else
        rebuildContent(renderDefaultContent)
    end
end

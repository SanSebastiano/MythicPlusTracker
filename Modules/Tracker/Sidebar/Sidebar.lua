local addonName, addon = ...

MPT_Sidebar = {}

-- Geometry every card has to agree with. FIRST_CARD_Y is the anchor for the
-- first card (Score); every subsequent card reads its own anchor from the
-- layout cursor and advances it by its own gap + height, so no card needs to
-- know any other card's size (see Sidebar/CardWidgets.lua). The per-card gaps
-- deliberately stay local to each card — that is the point of the cursor.
MPT_Sidebar.LAYOUT = {
    WIDTH                 = 300,
    HEIGHT                = 550,
    CONTENT_X             = 23,
    CONTENT_W             = 254,
    HEADER_TO_CONTENT_GAP = 4,   -- between a section's header banner and its rows
    FIRST_CARD_Y          = -30,
}

local frame
local contentWrapper

local FIRST_CARD_Y = MPT_Sidebar.LAYOUT.FIRST_CARD_Y

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
    MPT_Sidebar:loadRunStatistics(wrapper, cursor)
end

local function renderKeystonesContent(wrapper, cursor)
    MPT_Sidebar:loadScore(wrapper, cursor)
    MPT_Sidebar:loadKeystoneStatistics(wrapper, cursor)
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

    frame:SetSize(MPT_Sidebar.LAYOUT.WIDTH, MPT_Sidebar.LAYOUT.HEIGHT)
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

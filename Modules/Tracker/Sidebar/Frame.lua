local addonName, addon = ...

local frame
local contentWrapper

local function renderDefaultContent(wrapper)
    MPT_Sidebar.getScore(wrapper)
    MPT_Sidebar.getAffixes(wrapper)
    MPT_Sidebar.getKeystone(wrapper)
    MPT_Sidebar.getWeeklyVault(wrapper)
    MPT_Sidebar.getTraitNodes(wrapper)
    MPT_Sidebar.getCurrencies(wrapper)
end

local function renderRunsContent(wrapper)
    MPT_Sidebar.getScore(wrapper)
    MPT_Sidebar.loadRunsStats(wrapper)
end

local function renderKeystonesContent(wrapper)
    MPT_Sidebar.getScore(wrapper)
    MPT_Sidebar.loadGroupScores(wrapper)
end

local function rebuildContent(renderFn)
    if contentWrapper then contentWrapper:Hide() end
    contentWrapper = CreateFrame("Frame", nil, frame)
    contentWrapper:SetAllPoints(frame)
    renderFn(contentWrapper)
end

local function create(mainFrame)
    if frame then return frame end

    frame = CreateFrame("Frame", nil, mainFrame)

    frame:SetSize(300, 550)
    frame:SetPoint("TOPLEFT", mainFrame)

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(frame)
    background:SetAtlas("ui-frame-midnight-cardparchmentwider", false)

    local borderFrame = CreateFrame("Frame", nil, frame)
    borderFrame:SetAllPoints(frame)
    borderFrame:SetScale(0.75)

    local border = borderFrame:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints(borderFrame)
    border:SetAtlas("ui-frame-midnight-border", false)

    frame:SetScript("OnShow", function()
        rebuildContent(renderDefaultContent)
    end)

    return frame
end

if MPT_Sidebar then
    function MPT_Sidebar:getFrame(mainFrame)
        return create(mainFrame)
    end

    function MPT_Sidebar:showForTab(tabIndex)
        if not frame then return end
        if tabIndex == 2 then
            rebuildContent(renderRunsContent)
        elseif tabIndex == 3 then
            rebuildContent(renderKeystonesContent)
        else
            rebuildContent(renderDefaultContent)
        end
    end
end

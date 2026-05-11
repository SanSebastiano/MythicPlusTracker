local addonName, addon = ...

local frame

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
        if frame.contentLoaded then return end
        frame.contentLoaded = true
        MPT_Sidebar.getScore(frame)
        MPT_Sidebar.getAffixes(frame)
        MPT_Sidebar.getKeystone(frame)
        MPT_Sidebar.getWeeklyVault(frame)
        MPT_Sidebar.getCurrencies(frame)
    end)

    return frame
end

if MPT_Sidebar then
    function MPT_Sidebar:getFrame(mainFrame)
        return create(mainFrame)
    end
end

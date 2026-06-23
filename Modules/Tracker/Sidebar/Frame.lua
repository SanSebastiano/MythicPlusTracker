local addonName, addon = ...

local frame
local contentWrapper

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
        if contentWrapper then contentWrapper:Hide() end

        contentWrapper = CreateFrame("Frame", nil, frame)
        contentWrapper:SetAllPoints(frame)

        MPT_Sidebar.getScore(contentWrapper)
        MPT_Sidebar.getAffixes(contentWrapper)
        MPT_Sidebar.getKeystone(contentWrapper)
        MPT_Sidebar.getWeeklyVault(contentWrapper)
        MPT_Sidebar.getCurrencies(contentWrapper)
    end)

    return frame
end

if MPT_Sidebar then
    function MPT_Sidebar:getFrame(mainFrame)
        return create(mainFrame)
    end
end

local addonName, addon = ...

local frame
local navHeight = 0

local function create(mainFrame)
    if frame then return frame end

    frame = CreateFrame("Frame", nil, mainFrame)

    frame:SetSize(800, 550)
    frame:SetPoint("TOPRIGHT", mainFrame)

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetAtlas("ui-frame-midnight-cardparchmentwider", false)

    local borderFrame = CreateFrame("Frame", nil, frame)
    borderFrame:SetAllPoints(frame)
    borderFrame:SetScale(0.5)

    local border = borderFrame:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints(borderFrame)
    border:SetAtlas("ui-frame-midnight-border", false)

    navHeight = MPT_Dashboard:createNavigation(frame)

    frame:SetScript("OnShow", function()
        if frame.dungeonsLoaded then return end
        frame.dungeonsLoaded = true
        addon.debugMessage("Dashboard Frame OnShow")

        if UnitLevel("player") < GetMaxPlayerLevel() then
            MPT_Dashboard:loadNotMaxLevel(frame)
            return
        end

        MPT_Dashboard:loadDungeons(frame, navHeight)
    end)

    return frame
end

function MPT_Dashboard:getFrame(mainFrame)
    return create(mainFrame)
end

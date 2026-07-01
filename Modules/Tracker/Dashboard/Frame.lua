local addonName, addon = ...

local frame
local contentWrapper
local navHeight = 0

-- Tracks the active content panel so we can hide it before showing a new one
local activeContent = nil

local function showContent(loader, ...)
    if activeContent then
        activeContent:Hide()
        activeContent = nil
    end

    local panel = CreateFrame("Frame", nil, contentWrapper)
    panel:SetAllPoints(contentWrapper)
    activeContent = panel

    loader(MPT_Dashboard, panel, navHeight, ...)
end

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

    local tabCallbacks = {
        [1] = function() showContent(MPT_Dashboard.loadDungeons); MPT_Sidebar:showForTab(1) end,
        [2] = function() showContent(MPT_Dashboard.loadRuns);     MPT_Sidebar:showForTab(2) end,
        [3] = function() MPT_Sidebar:showForTab(3) end,   -- Keystones: stub
    }

    navHeight = MPT_Dashboard:createNavigation(frame, tabCallbacks)

    frame:SetScript("OnShow", function()
        if contentWrapper then contentWrapper:Hide() end
        activeContent = nil

        contentWrapper = CreateFrame("Frame", nil, frame)
        contentWrapper:SetAllPoints(frame)

        addon.debugMessage("Dashboard Frame OnShow")

        if UnitLevel("player") < GetMaxPlayerLevel() then
            MPT_Dashboard:loadNotMaxLevel(contentWrapper)
            return
        end

        -- Default to tab 1 (Dungeons)
        showContent(MPT_Dashboard.loadDungeons)
    end)

    return frame
end

function MPT_Dashboard:getFrame(mainFrame)
    return create(mainFrame)
end

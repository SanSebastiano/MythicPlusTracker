local addonName, addon = ...

MPT_MAIN = {}

MythicPlusTrackerDB = MythicPlusTrackerDB or {}

local frame

local function applySavedPosition(f)
    local saved = MythicPlusTrackerDB.mainFrame
    f:ClearAllPoints()
    if saved and saved.point then
        f:SetPoint(saved.point, UIParent, saved.relativePoint or saved.point, saved.x or 0, saved.y or 0)
    else
        f:SetPoint("CENTER")
    end
end

local function saveFramePosition(f)
    local point, _, relativePoint, x, y = f:GetPoint(1)
    if not point then return end
    MythicPlusTrackerDB.mainFrame = { point = point, relativePoint = relativePoint, x = x, y = y }
end

local function create()
    if frame then return frame end

    frame = CreateFrame(
            "Frame",
            "MPTMainFrame",
            UIParent,
            "BackdropTemplate"
    )
    frame:SetSize(1100, 550)
    applySavedPosition(frame)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:Hide()

    tinsert(UISpecialFrames, "MPTMainFrame")

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        saveFramePosition(self)
    end)

    return frame
end

function MPT_MAIN:getFrame()
    return create()
end

function MPT_MAIN:Show()
    if addon.showTracker == true then
        return
    end

    local mainFrame = self:getFrame()
    MPT_Dashboard:getFrame(mainFrame)
    MPT_Sidebar:getFrame(mainFrame)

    mainFrame:Show()
    addon.showTracker = true

    mainFrame:SetScript("OnHide", function()
        addon.showTracker = false
    end)
end

function MPT_MAIN:Hide()
    if frame then
        frame:Hide()
    end
end

function MPT_MAIN:Toggle()
    if addon.showTracker == true then
        self:Hide()
    else
        self:Show()
    end
end

local addonName, addon = ...

MPT_MAIN = {}

local frame

local function create()
    if frame then return frame end

    frame = CreateFrame(
            "Frame",
            "MPTMainFrame",
            UIParent,
            "BackdropTemplate"
    )
    frame:SetSize(1100, 550)
    frame:SetPoint("CENTER")
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
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

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

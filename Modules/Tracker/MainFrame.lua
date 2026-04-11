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

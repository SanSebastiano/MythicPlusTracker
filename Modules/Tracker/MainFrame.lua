local addonName, addon = ...

MPT_MAIN = {}

local function create()
    frame = CreateFrame(
            "Frame",
            nil,
            UIParent,
            "BackdropTemplate"
    )
    frame:SetSize(1100, 550)
    frame:SetPoint("CENTER")
    frame:Hide()

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

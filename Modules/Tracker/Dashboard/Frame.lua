local addonName, addon = ...

local function create(mainFrame)
    local frame = CreateFrame(
            "Frame",
            nil,
            UIParent,
            "BackdropTemplate"
    )

    frame:SetSize(800, 550)
    frame:SetPoint("TOPRIGHT", mainFrame)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileEdge = true,
        tileSize = 32,
        edgeSize = 20,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    frame:Hide()

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)

    frame:SetScript("OnShow", function()
        addon.successMessage("open")
    end)

    return frame
end

function MPT_Dashboard:getFrame(mainFrame)
    return create(mainFrame)
end

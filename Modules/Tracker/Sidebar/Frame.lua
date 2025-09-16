local addonName, addon = ...

local function create(mainFrame)
    local frame = CreateFrame(
        "Frame",
        nil,
        mainFrame,
        "BackdropTemplate"
    )

    frame:SetSize(300, 550)
    frame:SetPoint("TOPLEFT", mainFrame)

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileEdge = true,
        tileSize = 32,
        edgeSize = 20,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })

    frame:SetScript("OnShow", function()
        MPT_Sidebar.getScore(frame)
    end)

    return frame
end

if MPT_Sidebar then
    function MPT_Sidebar:getFrame(mainFrame)
        return create(mainFrame)
    end
end

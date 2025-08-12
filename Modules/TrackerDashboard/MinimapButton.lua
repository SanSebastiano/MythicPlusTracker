local addonName, addon = ...

MPT_MinimapButton = {}

local function create()
    local button = CreateFrame("Button", "MPTMinimapButton", Minimap)
    button:SetSize(64, 64)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAtlas("mythicplus-greatvault-collect")
    icon:SetAllPoints()

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetAtlas("Minimap-TrackingBorder")
    border:SetAllPoints()

    button:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)

    return button
end

function MPT_MinimapButton:load()
    local button = create()

    button:SetScript("OnClick", function(self, clickedButton)
        if clickedButton == "LeftButton" then
            addon.trackerDashboard.frame:Show()
        end
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Mythic Plus Tracker Dashboard")
        GameTooltip:AddLine("Click to toggle the dashboard.", 1, 1, 1)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return button
end

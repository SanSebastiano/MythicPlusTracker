local addonName, addon = ...

MPT_GreatVaultButton = {}

local function create(frame)
    local button = CreateFrame("Button", nil, frame)
    button:SetSize(54.62, 48)
    button:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -5)

    button:SetNormalAtlas("gficon-chest-evergreen-greatvault-collect")
    button:SetHighlightAtlas("gficon-chest-evergreen-greatvault-collect")
    button:SetPushedAtlas("gficon-chest-evergreen-greatvault-collect")

    return button
end

function MPT_GreatVaultButton:load(frame)
    local button = create(frame)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Große Truhe öffnen")
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("OnClick", function()
        if WeeklyRewardsFrame then
            WeeklyRewardsFrame:Show()
        else
            if PVEFrame then
                PVEFrame_ToggleFrame("ChallengesFrame")
            end
        end
    end)
end

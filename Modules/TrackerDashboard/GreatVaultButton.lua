local addonName, addon = ...

MPT_GreatVaultButton = {}

function MPT_GreatVaultButton:load(frame)
    local greatVaultButton = CreateFrame("Button", nil, frame)
    greatVaultButton:SetSize(54.62, 48)
    greatVaultButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -5)

    greatVaultButton:SetNormalAtlas("gficon-chest-evergreen-greatvault-collect")
    greatVaultButton:SetHighlightAtlas("gficon-chest-evergreen-greatvault-collect")
    greatVaultButton:SetPushedAtlas("gficon-chest-evergreen-greatvault-collect")

    greatVaultButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Große Truhe öffnen")
        GameTooltip:Show()
    end)
    greatVaultButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    greatVaultButton:SetScript("OnClick", function()
        if WeeklyRewardsFrame then
            WeeklyRewardsFrame:Show()
        else
            if PVEFrame then
                PVEFrame_ToggleFrame("ChallengesFrame")
            end
        end
    end)
end

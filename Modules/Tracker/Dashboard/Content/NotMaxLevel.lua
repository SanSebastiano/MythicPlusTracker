local addonName, addon = ...

function MPT_Dashboard:loadNotMaxLevel(frame)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(63, 76)
    icon:SetPoint("CENTER", frame, "CENTER", 0, 36)
    icon:SetAtlas("Bags-padlock-authenticator", false)

    local msg = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    msg:SetPoint("TOP", icon, "BOTTOM", 0, -12)
    msg:SetJustifyH("CENTER")
    msg:SetText(addon.locale["DASHBOARD_NOT_MAX_LEVEL"])
end

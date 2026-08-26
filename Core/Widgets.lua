local addonName, addon = ...

function addon.createRowDivider(parent, y, alpha)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, y)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, y)
    line:SetHeight(1)
    line:SetColorTexture(0.45, 0.45, 0.65, alpha or 0.3)
    return line
end

local addonName, addon = ...

function addon.createDivider(parent, xOffset, yOffset)
    local bar = parent:CreateTexture(nil, "ARTWORK")
    bar:SetSize(254, 20)
    bar:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)
    bar:SetAtlas("midnight-scenario-bar-frame", false)

    local fill = parent:CreateTexture(nil, "BACKGROUND")
    fill:SetSize(220, 12)
    fill:SetPoint("CENTER", parent, "TOPLEFT", xOffset + 127, yOffset - 10)
    fill:SetAtlas("midnight-scenario-barfill", false)
end

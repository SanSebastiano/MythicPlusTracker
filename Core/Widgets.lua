local addonName, addon = ...

---Adds a GameTooltip line whose "<Label>:" prefix (up to and including the
---first colon) is tinted, with the value after it left in the default tooltip
---colour — so only the label reads as a label. Lines without a colon have no
---label to separate, so the whole line takes fallbackColorKey instead.
---@param text string
---@param prefixColorKey string key into addon.colors, e.g. "POOR" or "ARTIFACT"
---@param fallbackColorKey string|nil colour for colon-less lines, default white
function addon.addTooltipLabelLine(text, prefixColorKey, fallbackColorKey)
    local prefix, rest = text:match("^([^:]+:)(.*)$")
    if prefix then
        GameTooltip:AddLine(addon.colors[prefixColorKey] .. prefix .. addon.colors.RESET .. rest, 1, 1, 1, true)
        return
    end

    if not fallbackColorKey then
        GameTooltip:AddLine(text, 1, 1, 1, true)
        return
    end

    local r, g, b = addon.colorToRGB(fallbackColorKey)
    GameTooltip:AddLine(text, r, g, b, true)
end

function addon.createRowDivider(parent, y, alpha)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, y)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, y)
    line:SetHeight(1)
    line:SetColorTexture(0.45, 0.45, 0.65, alpha or 0.3)
    return line
end

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

---Creates a themed background + border pair for a top-level addon window
---(Dashboard, Sidebar), with the border guaranteed to render above ALL of the
---frame's content regardless of how deeply that content is nested. Plain
---FrameLevel inheritance isn't enough here — content can nest many frames
---deep (e.g. a table row's icon inside a rows container inside a table frame
---inside a tab panel) and would otherwise end up with a higher effective
---FrameLevel than a same-strata border frame, drawing on top of it. Raising
---the border's FrameLevel by a large constant beats any realistic nesting
---depth without needing to change its FrameStrata.
---@param frame Frame the top-level window frame (already sized/positioned)
---@param borderScale number the border atlas is oversized relative to the frame; this scales it down to align edges
---@return Texture background
---@return Texture border
function addon.createFramedWindow(frame, borderScale)
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(frame)
    background:SetAtlas(addon.theme.FRAME_BACKGROUND, false)

    local borderFrame = CreateFrame("Frame", nil, frame)
    borderFrame:SetAllPoints(frame)
    borderFrame:SetScale(borderScale)
    borderFrame:SetFrameStrata(frame:GetFrameStrata())
    borderFrame:SetFrameLevel(frame:GetFrameLevel() + 100)

    local border = borderFrame:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints(borderFrame)
    border:SetAtlas(addon.theme.FRAME_BORDER, false)

    return background, border
end

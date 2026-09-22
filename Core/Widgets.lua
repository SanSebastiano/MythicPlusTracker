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

---How wide a click area over a text label should be: as wide as the rendered
---text, never wider than the cell it sits in.
---
---Sizing it to the cell instead would put the tooltip's ANCHOR_RIGHT at the
---column edge — far from the name it describes and on top of the neighbouring
---columns — and would light the hover highlight up over empty space next to
---short names. GetStringWidth reports the full text width even when the label
---itself truncates it, hence the clamp.
---@param label FontString already carrying its final text
---@param maxWidth number the cell width
---@return number
function addon.textHotspotWidth(label, maxWidth)
    return math.min(label:GetStringWidth(), maxWidth)
end

---Creates an invisible, clickable button over a rectangle of `parent`. A
---FontString can't receive mouse events on its own, and the table views lay
---their cells out directly on the scroll child without per-row frames, so a
---clickable label always needs an overlay like this.
---
---The click-area twin of addon.createTableCellHoverArea (Dashboard/TableWidgets.lua),
---which only does hover. It lives here rather than next to that one because a
---Sidebar card uses it too, and Core loads before every module.
---
---Only the mechanics are shared: the caller owns what the click does and what
---the tooltip says. onLeave defaults to hiding the tooltip, which is what a
---caller that only shows one wants.
---@param parent Frame the frame the label was laid out in
---@param x number top-left X offset within parent
---@param y number top-left Y offset within parent
---@param w number
---@param h number
---@param onClick function receives the button frame
---@param onEnter function|nil receives the button frame, expected to show GameTooltip
---@param onLeave function|nil defaults to hiding GameTooltip
---@return Button
function addon.createClickArea(parent, x, y, w, h, onClick, onEnter, onLeave)
    local clickArea = CreateFrame("Button", nil, parent)
    clickArea:SetSize(w, h)
    clickArea:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    clickArea:RegisterForClicks("LeftButtonUp")
    clickArea:SetScript("OnClick", onClick)

    if onEnter then
        clickArea:SetScript("OnEnter", onEnter)
    end

    clickArea:SetScript("OnLeave", onLeave or function()
        GameTooltip:Hide()
    end)

    return clickArea
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

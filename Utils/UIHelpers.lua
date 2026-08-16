local addonName, addon = ...

---Creates a single FontString table cell, shared by the Dashboard table views
---(Dungeons/Runs/Keystones) to avoid re-implementing the same cell layout per file.
function addon.createTableCell(parent, x, y, w, h, text, font, justifyH, wordWrap)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    fs:SetSize(w, h)
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetJustifyH(justifyH or "LEFT")
    fs:SetJustifyV("MIDDLE")
    if wordWrap then fs:SetWordWrap(true) end
    fs:SetText(text)
    return fs
end

---Draws a thin 4-sided border exactly along a frame's own edges, anchored
---(not size-based), so it stays pixel-accurate even if the frame is resized
---later. Use for floating panels/popups whose size varies at runtime, where
---stretching a fixed-aspect atlas texture (like CARD_ICON_BACKGROUND) would
---visibly misalign against the frame's true edges.
function addon.createThinBorder(frame, thickness, r, g, b, a)
    local top = frame:CreateTexture(nil, "OVERLAY")
    top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    top:SetHeight(thickness)
    top:SetColorTexture(r, g, b, a)

    local bottom = frame:CreateTexture(nil, "OVERLAY")
    bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(thickness)
    bottom:SetColorTexture(r, g, b, a)

    local left = frame:CreateTexture(nil, "OVERLAY")
    left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    left:SetWidth(thickness)
    left:SetColorTexture(r, g, b, a)

    local right = frame:CreateTexture(nil, "OVERLAY")
    right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(thickness)
    right:SetColorTexture(r, g, b, a)
end

---A plain 1px horizontal separator line for table/list rows.
function addon.createRowDivider(parent, y, alpha)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, y)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, y)
    line:SetHeight(1)
    line:SetColorTexture(0.45, 0.45, 0.65, alpha or 0.3)
    return line
end

---Wires a modern MinimalScrollBar (the same Track/Thumb + Back/Forward-stepper
---style as the Encounter Journal's "Journeys" tab) + mousewheel scrolling to a
---ScrollFrame. ScrollUtil.InitScrollFrameWithScrollBar works directly with a
---plain ScrollFrame/scrollChild (no WowScrollBoxList migration needed) and
---installs OnVerticalScroll/OnScrollRangeChanged/OnMouseWheel itself.
function addon.createTableScrollbar(outerFrame, scrollFrame, rowHeight)
    local scrollBar = CreateFrame("EventFrame", nil, outerFrame, "MinimalScrollBar")
    scrollBar:SetPoint("TOPRIGHT",    outerFrame, "TOPRIGHT",    0, 0)
    scrollBar:SetPoint("BOTTOMRIGHT", outerFrame, "BOTTOMRIGHT", 0, 0)
    scrollBar:SetHideIfUnscrollable(true)

    scrollFrame:EnableMouseWheel(true)
    ScrollUtil.InitScrollFrameWithScrollBar(scrollFrame, scrollBar)

    -- Preserve the previous "3 rows per wheel notch" scroll feel (Init
    -- defaults the pan extent to 30px, independent of this table's row height).
    scrollFrame:SetPanExtent(rowHeight * 3)

    -- scrollChild is already sized/populated by the caller before this runs,
    -- so force one range recalculation now — otherwise OnScrollRangeChanged
    -- never fires and the thumb stays full-size.
    scrollFrame:UpdateScrollChildRect()

    return scrollBar
end

---Minimal vertical layout cursor for stacking Sidebar cards. Each content
---loader only needs to know its own leading gap and height; it reads its
---anchor Y from cursor:current() (minus its own gap) and calls cursor:advance()
---with gap+height once placed, so later cards never need to know earlier
---cards' sizes.
function addon.createLayoutCursor(startY)
    local y = startY
    return {
        current = function(self) return y end,
        advance = function(self, amount) y = y - amount; return y end,
    }
end

-- Section-header banner height for the Overview tab's Sidebar sections
-- (WeeklyVault/TraitNodes/Currency). Matches the 46px title banners already
-- used in RunsStats.lua/GroupScores.lua — with headers now on only 3 of the
-- 6 Overview sections (Affixes/Keystone stay header-less), the Sidebar's
-- fixed 550px height has enough room for the full-size banner look.
addon.SIDEBAR_SECTION_HEADER_HEIGHT = 46

---Section-header banner for the Sidebar's Overview tab: same visual language
---(CARD_TITLE_BACKGROUND + centered ARTIFACT-colored label) and size as the
---title banners in RunsStats.lua/GroupScores.lua.
---@param parent Frame
---@param y number top-left Y offset within parent
---@param width number
---@param text string
function addon.createSidebarSectionHeader(parent, y, width, text)
    local header = CreateFrame("Frame", nil, parent)
    header:SetSize(width, addon.SIDEBAR_SECTION_HEADER_HEIGHT)
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 23, y)

    local bg = header:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(header)
    bg:SetAtlas(addon.theme.CARD_TITLE_BACKGROUND, false)

    local label = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER", header, "CENTER", 0, 0)
    local r, g, b = addon.colorToRGB("ARTIFACT")
    label:SetTextColor(r, g, b, 1)
    label:SetText(text)

    return header
end

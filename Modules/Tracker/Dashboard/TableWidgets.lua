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

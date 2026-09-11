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

---Creates one clickable column header for a sortable Dashboard table: the
---button, its label, the hover highlight, and the wiring that flips the sort
---state and re-renders. The label text itself is written by
---sortState:updateIndicators(), which the caller runs once after building all
---headers.
---@param parent Frame
---@param x number top-left X offset within parent
---@param width number
---@param height number
---@param justifyH string|nil defaults to "LEFT"
---@param columnKey string key into the sort state's direction/locale tables
---@param sortState table an addon.TableSortService instance
---@param onSort function called after the sort state changed
---@return Button
function addon.createSortableHeaderButton(parent, x, width, height, justifyH, columnKey, sortState, onSort)
    local artifactR, artifactG, artifactB = addon.colorToRGB("ARTIFACT")

    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, 0)

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetSize(width, height)
    label:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    label:SetJustifyH(justifyH or "LEFT")
    label:SetJustifyV("MIDDLE")
    label:SetWordWrap(false)

    sortState:registerHeaderCell(columnKey, label)

    button:SetScript("OnClick", function()
        sortState:toggleColumn(columnKey)
        onSort()
    end)

    button:SetScript("OnEnter", function()
        label:SetTextColor(1, 1, 1, 1)
    end)
    button:SetScript("OnLeave", function()
        label:SetTextColor(artifactR, artifactG, artifactB, 1)
    end)

    return button
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

    -- The scrollbar learns its size exclusively from OnScrollRangeChanged, and
    -- that only fires when the range actually changes. So the first range
    -- change has to happen at or after this point: either the caller has
    -- already sized scrollChild and this recalculation produces it, or the
    -- caller sizes it afterwards and produces it then. What breaks is a caller
    -- that calls UpdateScrollChildRect itself *before* wiring — the range is
    -- then already final, the recalculation below is a no-op, no event fires,
    -- and SetHideIfUnscrollable above hides the bar for good.
    scrollFrame:UpdateScrollChildRect()

    return scrollBar
end

---Creates a checkbox with a clickable text label to its left, for the filter
---rows above the Dashboard tables. A plain FontString can't receive clicks, so
---the label is its own Button (sized to the rendered text) — clicking the text
---toggles the checkbox exactly like clicking the checkbox itself.
---
---The caller anchors the returned checkbox: the Overview and Runs tabs place
---their filter rows differently. The size is a parameter for the same reason —
---the Overview tab's row is deliberately squeezed (see the comment on its
---WEEK_FILTER_ROW_H), the Runs tab's row has a dropdown's worth of height.
---@param parent Frame
---@param labelText string plain text; the coloring is applied here so both tabs match
---@param size number edge length of the square checkbox, also the label's height
---@param initialChecked boolean
---@param onChanged function(checked) runs after every toggle, from either half
---@return CheckButton
function addon.createLabeledCheckbox(parent, labelText, size, initialChecked, onChanged)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetSize(size, size)
    checkbox:SetChecked(initialChecked)

    checkbox:SetScript("OnClick", function(self)
        onChanged(self:GetChecked() == true)
    end)

    local labelButton = CreateFrame("Button", nil, parent)
    labelButton:SetHeight(size)
    labelButton:SetPoint("RIGHT", checkbox, "LEFT", -4, 0)

    local label = labelButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("RIGHT", labelButton, "RIGHT", 0, 0)
    label:SetText(addon.colors.POOR .. labelText .. addon.colors.RESET)

    labelButton:SetWidth(label:GetStringWidth())
    labelButton:SetScript("OnClick", function()
        local checked = not checkbox:GetChecked()
        checkbox:SetChecked(checked)
        onChanged(checked)
    end)

    return checkbox
end

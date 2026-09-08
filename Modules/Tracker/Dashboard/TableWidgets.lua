local addonName, addon = ...

local TELEPORT_ARTIFACT_R, TELEPORT_ARTIFACT_G, TELEPORT_ARTIFACT_B = addon.colorToRGB("ARTIFACT")

---Attaches a hover-glow + click-to-teleport button on top of a dungeon icon,
---using the season's known "Path of ..." spell for mapID (see
---Dashboard/DungeonTeleportCatalog.lua). Uses a SecureActionButtonTemplate so
---the protected spell cast is allowed to run directly from the click. Shared
---by DungeonsPage.lua and KeystonesPage.lua so both tabs behave identically.
---@param parent Frame the row/table frame the icon texture belongs to
---@param icon Texture the dungeon icon to brighten/glow on hover — secure
---frames can't anchor to a Texture, so the button is anchored to `parent`
---using the same x/y/size instead of to `icon` itself
---@param mapID number
---@param name string dungeon name, shown in the tooltip when no spell is known
---@param x number
---@param y number
---@param size number
---@return Button
function addon.attachDungeonTeleportButton(parent, icon, mapID, name, x, y, size)
    local glow = parent:CreateTexture(nil, "OVERLAY")
    glow:SetAllPoints(icon)
    glow:SetColorTexture(0.3, 0.6, 1, 1)
    glow:SetBlendMode("ADD")
    glow:Hide()

    local glowAnim = glow:CreateAnimationGroup()
    glowAnim:SetLooping("BOUNCE")
    local glowFade = glowAnim:CreateAnimation("Alpha")
    glowFade:SetFromAlpha(0.15)
    glowFade:SetToAlpha(0.55)
    glowFade:SetDuration(0.6)
    glowFade:SetSmoothing("IN_OUT")

    local teleport = addon.getDungeonTeleport(mapID)
    local hasTeleport = teleport and C_SpellBook.IsSpellKnown(teleport.spellID)
    local teleportBtn = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
    teleportBtn:SetSize(size, size)
    teleportBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    teleportBtn:RegisterForClicks("AnyUp", "AnyDown")
    if hasTeleport then
        teleportBtn:SetAttribute("type", "spell")
        teleportBtn:SetAttribute("spell", teleport.spellID)
    end
    teleportBtn:SetScript("OnEnter", function(self)
        icon:SetVertexColor(1.15, 1.15, 1.15)
        if hasTeleport then
            glow:Show()
            glowAnim:Play()
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if hasTeleport then
            GameTooltip:SetSpellByID(teleport.spellID)
            GameTooltip:AddLine(addon.locale["DUNGEON_TELEPORT_TOOLTIP"], 0, 1, 0, true)
        else
            GameTooltip:AddLine(name, TELEPORT_ARTIFACT_R, TELEPORT_ARTIFACT_G, TELEPORT_ARTIFACT_B)
            GameTooltip:AddLine(addon.locale["DUNGEON_TELEPORT_NOT_OWNED"], 1, 0.2, 0.2, true)
        end
        GameTooltip:Show()
    end)
    teleportBtn:SetScript("OnLeave", function()
        icon:SetVertexColor(1, 1, 1)
        glowAnim:Stop()
        glow:Hide()
        GameTooltip:Hide()
    end)

    return teleportBtn
end

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

    -- scrollChild is already sized/populated by the caller before this runs,
    -- so force one range recalculation now — otherwise OnScrollRangeChanged
    -- never fires and the thumb stays full-size.
    scrollFrame:UpdateScrollChildRect()

    return scrollBar
end

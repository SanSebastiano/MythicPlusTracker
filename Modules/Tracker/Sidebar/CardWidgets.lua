local addonName, addon = ...

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
-- used in RunsStats.lua/Statistics.lua — with headers now on only 3 of the
-- 6 Overview sections (Affixes/Keystone stay header-less), the Sidebar's
-- fixed 550px height has enough room for the full-size banner look.
addon.SIDEBAR_SECTION_HEADER_HEIGHT = 46

---Section-header banner for the Sidebar's Overview tab: same visual language
---(CARD_TITLE_BACKGROUND + centered ARTIFACT-colored label) and size as the
---title banners in RunsStats.lua/Statistics.lua.
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

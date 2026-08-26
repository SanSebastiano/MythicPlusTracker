local addonName, addon = ...

MPT_MinimapButton = {}

local button
local icon
local border

local MINIMAP_BUTTON_EDGE_INSET = 5
local DEFAULT_MINIMAP_BUTTON_ANGLE = -45
local DEFAULT_MINIMAP_BUTTON_STYLE = "large"

local LARGE_BUTTON_SIZE = 64

-- "Normal" style mimics the classic LibDBIcon look (small round icon behind
-- a fixed border texture). Size/offset were tuned by eye so the icon fully
-- fills the border's round cutout with no visible gaps on any side.
local NORMAL_BUTTON_SIZE = 31
local NORMAL_BORDER_SIZE = 53
local NORMAL_ICON_SIZE = 24
local NORMAL_ICON_OFFSET_X = 5
local NORMAL_ICON_OFFSET_Y = -5

local function create()
    local newButton = CreateFrame("Button", "MPTMinimapButton", Minimap)
    newButton:SetFrameStrata("MEDIUM")
    newButton:SetFrameLevel(8)

    local newIcon = newButton:CreateTexture(nil, "ARTWORK")
    local newBorder = newButton:CreateTexture(nil, "OVERLAY")

    return newButton, newIcon, newBorder
end

local function applyStyle(style)
    if style == "normal" then
        button:SetSize(NORMAL_BUTTON_SIZE, NORMAL_BUTTON_SIZE)

        icon:ClearAllPoints()
        icon:SetSize(NORMAL_ICON_SIZE, NORMAL_ICON_SIZE)
        icon:SetPoint("TOPLEFT", NORMAL_ICON_OFFSET_X, NORMAL_ICON_OFFSET_Y)
        icon:SetTexture(addon.theme.MINIMAP_BUTTON_NORMAL_ICON)

        border:ClearAllPoints()
        border:SetSize(NORMAL_BORDER_SIZE, NORMAL_BORDER_SIZE)
        border:SetPoint("TOPLEFT", 0, 0)
        border:SetTexture(addon.theme.MINIMAP_BUTTON_NORMAL_BORDER)
        border:Show()
    else
        button:SetSize(LARGE_BUTTON_SIZE, LARGE_BUTTON_SIZE)

        icon:ClearAllPoints()
        icon:SetAllPoints()
        icon:SetAtlas(addon.theme.MINIMAP_BUTTON_ICON)

        border:Hide()
    end
end

local function ensureMinimapButtonState()
    MythicPlusTrackerDB = MythicPlusTrackerDB or {}
    MythicPlusTrackerDB.minimapButton = MythicPlusTrackerDB.minimapButton or {
        angle = DEFAULT_MINIMAP_BUTTON_ANGLE,
        style = DEFAULT_MINIMAP_BUTTON_STYLE,
    }
    MythicPlusTrackerDB.minimapButton.style = MythicPlusTrackerDB.minimapButton.style or DEFAULT_MINIMAP_BUTTON_STYLE

    return MythicPlusTrackerDB.minimapButton
end

local function getMinimapRadius()
    -- Derived from the minimap's actual current size (rather than a fixed
    -- constant) so the button sits at the true outer edge regardless of the
    -- player's minimap size/scale setting.
    local width = Minimap:GetWidth() or 140
    return (width / 2) + MINIMAP_BUTTON_EDGE_INSET
end

local function updatePosition()
    local state = ensureMinimapButtonState()

    button:ClearAllPoints()

    if state.free then
        button:SetPoint("CENTER", UIParent, "BOTTOMLEFT", state.x or 0, state.y or 0)
    else
        local angle = math.rad(state.angle or DEFAULT_MINIMAP_BUTTON_ANGLE)
        local radius = getMinimapRadius()
        local x = radius * math.cos(angle)
        local y = radius * math.sin(angle)
        button:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end
end

local function onEdgeDragUpdate()
    -- Keeps the button pinned to the minimap's edge: converts the cursor
    -- position into an angle around the minimap's center and stores that
    -- angle, rather than storing free-form screen coordinates.
    local minimapX, minimapY = Minimap:GetCenter()
    if not minimapX then
        return
    end

    local scale = Minimap:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    cursorX, cursorY = cursorX / scale, cursorY / scale

    local angle = math.deg(math.atan2(cursorY - minimapY, cursorX - minimapX))

    local state = ensureMinimapButtonState()
    state.angle = angle
    state.free = false

    updatePosition()
end

local function onFreeDragUpdate()
    -- "Large" style only: lets the button be dropped anywhere on screen,
    -- clamped to the screen bounds, storing absolute coordinates instead of
    -- an angle around the minimap.
    local scale = UIParent:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    cursorX, cursorY = cursorX / scale, cursorY / scale

    local screenWidth = UIParent:GetRight() or cursorX
    local screenHeight = UIParent:GetTop() or cursorY

    cursorX = math.max(0, math.min(screenWidth, cursorX))
    cursorY = math.max(0, math.min(screenHeight, cursorY))

    local state = ensureMinimapButtonState()
    state.free = true
    state.x = cursorX
    state.y = cursorY

    updatePosition()
end

function MPT_MinimapButton:setHidden(hidden)
    if not button then
        return
    end

    if hidden then
        button:Hide()
    else
        button:Show()
    end
end

function MPT_MinimapButton:setStyle(style)
    if style ~= "large" and style ~= "normal" then
        return
    end

    local state = ensureMinimapButtonState()
    if state.style == style then
        return
    end

    state.style = style

    if style == "normal" then
        state.free = false
    end

    if button then
        applyStyle(style)
        updatePosition()
    end
end

local function applySavedState()
    if not button then
        return
    end

    local state = ensureMinimapButtonState()
    applyStyle(state.style)
    updatePosition()
    MPT_MinimapButton:setHidden(MythicPlusTrackerDB.minimapButtonHidden)
end

local stateFrame = CreateFrame("Frame")
stateFrame:RegisterEvent("ADDON_LOADED")
stateFrame:RegisterEvent("PLAYER_LOGIN")
stateFrame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if event == "ADDON_LOADED" and loadedAddonName == addonName then
        applySavedState()
    elseif event == "PLAYER_LOGIN" then
        applySavedState()
        stateFrame:UnregisterAllEvents()
    end
end)

function MPT_MinimapButton:load()
    button, icon, border = create()

    applySavedState()

    button:RegisterForClicks("AnyUp")
    button:RegisterForDrag("LeftButton")

    button:SetScript("OnDragStart", function(self)
        self:LockHighlight()

        -- "Normal" style is always edge-locked (matches other addons'
        -- minimap buttons); "Large" style defaults to edge-locked too,
        -- unless Shift is held for a free, anywhere-on-screen drag.
        local state = ensureMinimapButtonState()
        if state.style == "normal" then
            self:SetScript("OnUpdate", onEdgeDragUpdate)
        elseif IsShiftKeyDown() then
            self:SetScript("OnUpdate", onFreeDragUpdate)
        else
            self:SetScript("OnUpdate", onEdgeDragUpdate)
        end
    end)

    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self:UnlockHighlight()
    end)

    button:SetScript("OnClick", function(self, clickedButton, down)
        addon.debugMessage("Pressed " ..  clickedButton .. (down and " down" or " up"))

        if clickedButton == "LeftButton" then
            MPT_Tracker:show()

        elseif clickedButton == "RightButton" then
            if WeeklyRewardsFrame then
                WeeklyRewardsFrame:Show()
            else
                if PVEFrame then
                    PVEFrame_ToggleFrame("ChallengesFrame")
                end
            end
        end
    end)

    -- Colors the "<Label>:" prefix (before the first colon) in the addon's
    -- gold accent, leaving the rest of the line white, and wraps long lines
    -- instead of letting them stretch the tooltip's width.

    button:SetScript("OnEnter", function(self)
        local state = ensureMinimapButtonState()

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        -- Matches the two-tone addon name from the .toc title.
        GameTooltip:SetText(addon.colors.EPIC .. "Mythic" .. addon.colors.RESET
            .. " " .. addon.colors.LEGENDARY .. "Plus Tracker" .. addon.colors.RESET)
        addon.addTooltipLabelLine(addon.locale['MINIMAP_BUTTON_CLICK_LEFT'], "ARTIFACT")
        addon.addTooltipLabelLine(addon.locale['MINIMAP_BUTTON_CLICK_RIGHT'], "ARTIFACT")

        if state.style == "normal" then
            addon.addTooltipLabelLine(addon.locale['MINIMAP_BUTTON_DRAG_NORMAL'], "ARTIFACT")
        else
            addon.addTooltipLabelLine(addon.locale['MINIMAP_BUTTON_DRAG'], "ARTIFACT")
        end

        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

MPT_MinimapButton:load()

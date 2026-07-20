local addonName, addon = ...

MPT_MinimapButton = {}

local button

local MINIMAP_BUTTON_RADIUS = 80
local DEFAULT_MINIMAP_BUTTON_ANGLE = -45

local function create()
    local button = CreateFrame("Button", "MPTMinimapButton", Minimap)
    button:SetSize(64, 64)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAtlas("mythicplus-greatvault-collect")
    icon:SetAllPoints()

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetAtlas("Minimap-TrackingBorder")
    border:SetAllPoints()

    return button
end

local function ensureMinimapButtonState()
    MythicPlusTrackerDB = MythicPlusTrackerDB or {}
    MythicPlusTrackerDB.minimapButton = MythicPlusTrackerDB.minimapButton or { angle = DEFAULT_MINIMAP_BUTTON_ANGLE }

    return MythicPlusTrackerDB.minimapButton
end

local function updatePosition()
    local state = ensureMinimapButtonState()

    button:ClearAllPoints()

    if state.free then
        button:SetPoint("CENTER", UIParent, "BOTTOMLEFT", state.x or 0, state.y or 0)
    else
        local angle = math.rad(state.angle or DEFAULT_MINIMAP_BUTTON_ANGLE)
        local x = MINIMAP_BUTTON_RADIUS * math.cos(angle)
        local y = MINIMAP_BUTTON_RADIUS * math.sin(angle)
        button:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end
end

local function onEdgeDragUpdate()
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

function MPT_MinimapButton:SetHidden(hidden)
    if not button then
        return
    end

    if hidden then
        button:Hide()
    else
        button:Show()
    end
end

local function applySavedState()
    if not button then
        return
    end

    ensureMinimapButtonState()
    updatePosition()
    MPT_MinimapButton:SetHidden(MythicPlusTrackerDB.minimapButtonHidden)
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
    button = create()

    applySavedState()

    button:RegisterForClicks("AnyUp")
    button:RegisterForDrag("LeftButton")

    button:SetScript("OnDragStart", function(self)
        self:LockHighlight()

        if IsShiftKeyDown() then
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
        if addon.isDebugMode then
            addon.debugMessage("Pressed " ..  clickedButton .. (down and " down" or " up"))
        end

        if clickedButton == "LeftButton" then
            MPT_MAIN:Show()

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

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(addon.locale['MINIMAP_BUTTON_NAME'])
        GameTooltip:AddLine(addon.locale['MINIMAP_BUTTON_CLICK_LEFT'], 1, 1, 1)
        GameTooltip:AddLine(addon.locale['MINIMAP_BUTTON_CLICK_RIGHT'], 1, 1, 1)
        GameTooltip:AddLine(addon.locale['MINIMAP_BUTTON_DRAG'], 1, 1, 1)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

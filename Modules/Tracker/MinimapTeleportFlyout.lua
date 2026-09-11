local addonName, addon = ...

MPT_MinimapTeleportFlyout = {}

local ICON_SIZE = 32
local ICON_SPACING = 4
local FRAME_PADDING = 8
-- The strip is one icon thick across its short axis and grows along the other.
-- Which axis is which depends on the orientation setting, so the two are named
-- "thickness" and "length" rather than height and width.
local FRAME_THICKNESS = ICON_SIZE + (FRAME_PADDING * 2)
-- Flush against the button's *visible* edge, not its frame edge — see
-- anchorToButton(), which adds the button's own artwork inset on top. Kept as a
-- constant so the distance stays tunable from one place instead of hiding as
-- zeros in the SetPoint calls.
local BUTTON_GAP = 0

-- Slack for the geometric hover test at the button/strip seam, so UI-scale
-- rounding there isn't read as "cursor left both". Deliberately separate from
-- BUTTON_GAP: the visual distance and the hover tolerance are unrelated.
local HOVER_SEAM_TOLERANCE = 4
local COLLAPSED_LENGTH = 1

-- Persisted values, not display strings. "horizontal" keeps the original
-- behaviour and stays the default.
local ORIENTATIONS = {
    HORIZONTAL = "horizontal",
    VERTICAL   = "vertical",
}
local DEFAULT_ORIENTATION = ORIENTATIONS.HORIZONTAL

-- Which way the strip grows away from the button. Picked per open from where
-- the button sits, so it always unrolls towards the screen centre.
local GROWS = {
    LEFT  = "LEFT",
    RIGHT = "RIGHT",
    UP    = "UP",
    DOWN  = "DOWN",
}

local DEFAULT_HOVER_DELAY_SECONDS = 2
local MINIMUM_HOVER_DELAY_SECONDS = 0.5
local MAXIMUM_HOVER_DELAY_SECONDS = 3
local HOVER_DELAY_STEP_SECONDS = 0.25

-- Bridges the gap between the button's OnLeave and flyout:OnEnter (and back),
-- so crossing the seam with the cursor does not collapse the strip.
local CLOSE_GRACE_SECONDS = 0.25
local ANIMATION_DURATION_SECONDS = 0.18

-- SPELLS_CHANGED fires repeatedly while the spellbook settles after login;
-- collapse those into a single rebuild.
local REFRESH_DEBOUNCE_SECONDS = 1

local BACKGROUND_R, BACKGROUND_G, BACKGROUND_B, BACKGROUND_A = 0, 0, 0, 0.7
local BACKGROUND_INSET = 5

local FLYOUT_BORDER_LAYOUT = {
    TopLeftCorner     = { atlas = addon.theme.FLYOUT_BORDER_CORNER_TOP_LEFT },
    TopRightCorner    = { atlas = addon.theme.FLYOUT_BORDER_CORNER_TOP_RIGHT },
    BottomLeftCorner  = { atlas = addon.theme.FLYOUT_BORDER_CORNER_BOTTOM_LEFT },
    BottomRightCorner = { atlas = addon.theme.FLYOUT_BORDER_CORNER_BOTTOM_RIGHT },
    TopEdge           = { atlas = addon.theme.FLYOUT_BORDER_EDGE_TOP },
    BottomEdge        = { atlas = addon.theme.FLYOUT_BORDER_EDGE_BOTTOM },
    LeftEdge          = { atlas = addon.theme.FLYOUT_BORDER_EDGE_LEFT },
    RightEdge         = { atlas = addon.theme.FLYOUT_BORDER_EDGE_RIGHT },
}

local flyout
local combatGate
-- The addon's own minimap button: both the hover trigger and the anchor, so the
-- strip follows it even when it has been dragged free of the minimap.
local minimapButton
local slots = {}
local visibleSlotCount = 0
local targetLength = COLLAPSED_LENGTH
local laidOutGrows

local openTimer
local closeTimer
local refreshTimer
local pendingRefresh = false
local pendingCollapse = false
-- The strip stays shown while it rolls back up, so IsShown() alone can't tell
-- "open" from "on its way out".
local isClosing = false
-- True between the button's OnDragStart and OnDragStop. The strip is anchored
-- to the button and would be dragged along, pointing the wrong way the moment
-- the button crosses the screen centre — so it stays out of the way entirely.
local isDragging = false

-- Forward-declared: refresh() has to drop an open strip whose contents just
-- changed, but the animation helpers below it own the actual teardown.
local closeImmediately
-- Forward-declared for the same reason: ensureSlot() wires the icon buttons to
-- the hover timers, which are defined further down.
local cancelCloseTimer
local scheduleClose

local function ensureFlyoutState()
    MythicPlusTrackerDB = MythicPlusTrackerDB or {}
    if MythicPlusTrackerDB.minimapTeleportFlyoutDelay == nil then
        MythicPlusTrackerDB.minimapTeleportFlyoutDelay = DEFAULT_HOVER_DELAY_SECONDS
    end

    return MythicPlusTrackerDB
end

local function isEnabled()
    return not ensureFlyoutState().minimapTeleportFlyoutHidden
end

local function getHoverDelay()
    local delay = ensureFlyoutState().minimapTeleportFlyoutDelay or DEFAULT_HOVER_DELAY_SECONDS

    return math.max(MINIMUM_HOVER_DELAY_SECONDS, math.min(MAXIMUM_HOVER_DELAY_SECONDS, delay))
end

local function getOrientation()
    local orientation = ensureFlyoutState().minimapTeleportFlyoutOrientation

    if orientation ~= ORIENTATIONS.VERTICAL then
        return DEFAULT_ORIENTATION
    end

    return ORIENTATIONS.VERTICAL
end

local function isVertical()
    return getOrientation() == ORIENTATIONS.VERTICAL
end

---The strip's size along its growing axis. Which of width/height that is
---follows the orientation, so every caller says "length" and this pair decides.
---@param length number
local function setLength(length)
    if isVertical() then
        flyout:SetHeight(length)
    else
        flyout:SetWidth(length)
    end
end

---@return number
local function getLength()
    if isVertical() then
        return flyout:GetHeight()
    end

    return flyout:GetWidth()
end

---Pins the short axis, which never animates. Run at creation and again whenever
---the orientation changes, since the two axes swap roles.
local function applyThickness()
    if isVertical() then
        flyout:SetWidth(FRAME_THICKNESS)
    else
        flyout:SetHeight(FRAME_THICKNESS)
    end
end

---Tweens the strip's length. There is no AnimationGroup type for size, so this
---runs an OnUpdate — strictly for the length of the tween, cleared the moment
---it finishes (CODING_GUIDELINES 11.1.1).
local function animateLength(fromLength, toLength, onFinished)
    local elapsed = 0

    flyout:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta

        local progress = math.min(1, elapsed / ANIMATION_DURATION_SECONDS)
        setLength(fromLength + ((toLength - fromLength) * progress))

        if progress >= 1 then
            self:SetScript("OnUpdate", nil)
            if onFinished then
                onFinished()
            end
        end
    end)
end

local function stopAnimation()
    flyout:SetScript("OnUpdate", nil)
end

---Anchors the strip to whichever side of the button faces the screen centre, so
---it always unrolls inwards no matter where the button has been dragged. The
---anchor is the button frame itself, so the strip follows it while it moves.
---
---The button's frame is a square bounding box its artwork doesn't fill, so
---anchoring to the frame edge leaves a gap the code never names. Pulling the
---strip back in by that inset puts it against the circle the player sees. It is
---read per call, so switching the button's style takes effect on the next open.
---@return string|nil grows one of GROWS; nil while the button has no resolvable position
local function anchorToButton()
    local buttonX, buttonY = minimapButton:GetCenter()
    if not buttonX then
        return nil
    end

    -- The button is square, so one inset covers both axes.
    local offset = MPT_MinimapButton:getArtworkInset() - BUTTON_GAP
    local grows

    flyout:ClearAllPoints()
    if isVertical() then
        grows = buttonY > (UIParent:GetHeight() / 2) and GROWS.DOWN or GROWS.UP

        if grows == GROWS.DOWN then
            flyout:SetPoint("TOP", minimapButton, "BOTTOM", 0, offset)
        else
            flyout:SetPoint("BOTTOM", minimapButton, "TOP", 0, -offset)
        end
    else
        grows = buttonX > (UIParent:GetWidth() / 2) and GROWS.LEFT or GROWS.RIGHT

        if grows == GROWS.LEFT then
            flyout:SetPoint("RIGHT", minimapButton, "LEFT", offset, 0)
        else
            flyout:SetPoint("LEFT", minimapButton, "RIGHT", -offset, 0)
        end
    end

    return grows
end

---Lines the icons up starting at the button-facing edge, so growing the strip
---uncovers them one by one instead of dragging them along.
---@param grows string one of GROWS
local function layoutSlots(grows)
    for index = 1, visibleSlotCount do
        local offset = FRAME_PADDING + ((index - 1) * (ICON_SIZE + ICON_SPACING))

        slots[index]:ClearAllPoints()
        if grows == GROWS.LEFT then
            slots[index]:SetPoint("TOPRIGHT", flyout, "TOPRIGHT", -offset, -FRAME_PADDING)
        elseif grows == GROWS.RIGHT then
            slots[index]:SetPoint("TOPLEFT", flyout, "TOPLEFT", offset, -FRAME_PADDING)
        elseif grows == GROWS.DOWN then
            slots[index]:SetPoint("TOPLEFT", flyout, "TOPLEFT", FRAME_PADDING, -offset)
        else
            slots[index]:SetPoint("BOTTOMLEFT", flyout, "BOTTOMLEFT", FRAME_PADDING, offset)
        end
    end
end

local function ensureSlot(index)
    if slots[index] then
        return slots[index]
    end

    local slot = CreateFrame("Frame", nil, flyout)
    slot:SetSize(ICON_SIZE, ICON_SIZE)

    slot.icon = slot:CreateTexture(nil, "ARTWORK")
    slot.icon:SetAllPoints(slot)

    slot.teleportButton = addon.createDungeonTeleportButton(slot, slot.icon, 0, 0, ICON_SIZE)

    -- The strip loses mouse focus the moment the cursor moves onto an icon, so
    -- it never fires OnLeave again when the cursor then exits to the outside.
    -- The icons have to report that leave on its behalf; scheduleClose's
    -- geometric check keeps the strip open while the cursor only hops icons.
    -- HookScript, not SetScript, so the glow and tooltip stay intact.
    slot.teleportButton:HookScript("OnEnter", cancelCloseTimer)
    slot.teleportButton:HookScript("OnLeave", scheduleClose)

    slots[index] = slot

    return slot
end

---@return table dungeons { mapID, name, texture } entries, name-sorted so the
---icon order stays stable between rebuilds
local function collectTeleportableDungeons()
    local dungeons = {}

    local mapIDs = C_ChallengeMode.GetMapTable()
    if not mapIDs then
        return dungeons
    end

    for _, mapID in ipairs(mapIDs) do
        if addon.getDungeonTeleport(mapID) then
            local name, _, _, texture = C_ChallengeMode.GetMapUIInfo(mapID)
            if name and texture then
                table.insert(dungeons, { mapID = mapID, name = name, texture = texture })
            end
        end
    end

    table.sort(dungeons, function(first, second)
        return first.name < second.name
    end)

    return dungeons
end

---Rebinds the slots to the dungeons the player currently owns a teleport for.
---Deferred while in combat, because binding writes SetAttribute on a protected
---frame.
local function refresh()
    if not flyout then
        return
    end

    if InCombatLockdown() then
        pendingRefresh = true
        return
    end
    pendingRefresh = false

    local dungeons = collectTeleportableDungeons()
    visibleSlotCount = #dungeons

    for index, dungeon in ipairs(dungeons) do
        local slot = ensureSlot(index)
        slot.icon:SetTexture(dungeon.texture)
        slot.teleportButton:bindDungeon(dungeon.mapID, dungeon.name)
        slot:Show()
    end

    for index = visibleSlotCount + 1, #slots do
        slots[index]:Hide()
    end

    targetLength = (FRAME_PADDING * 2)
        + (visibleSlotCount * ICON_SIZE)
        + (math.max(0, visibleSlotCount - 1) * ICON_SPACING)

    addon.debugMessage(("Teleport flyout: %d season dungeons, %d with a known teleport, length %d")
        :format(#(C_ChallengeMode.GetMapTable() or {}), visibleSlotCount, targetLength))

    -- The slot count may have changed, so the next open has to re-run the
    -- layout even when the unroll direction stayed the same.
    laidOutGrows = nil

    -- A strip that is currently unrolled still shows the old width and slot
    -- positions; drop it rather than reflow it mid-hover.
    closeImmediately()
end

local function requestRefresh()
    if refreshTimer then
        return
    end

    refreshTimer = C_Timer.NewTimer(REFRESH_DEBOUNCE_SECONDS, function()
        refreshTimer = nil
        refresh()
    end)
end

local function cancelOpenTimer()
    if openTimer then
        openTimer:Cancel()
        openTimer = nil
    end
end

function cancelCloseTimer()
    if closeTimer then
        closeTimer:Cancel()
        closeTimer = nil
    end
end

---True while the cursor is on the button or the strip. Purely geometric, so it
---stays true over the strip's icon buttons — unlike OnEnter/OnLeave, which
---those children steal from their parent.
local function isCursorInHoverArea()
    if minimapButton:IsMouseOver() then
        return true
    end

    if not flyout:IsShown() then
        return false
    end

    -- Widen the hit rect across the seam the strip shares with the button,
    -- which swaps axes with the orientation. IsMouseOver takes offsets in
    -- top/bottom/left/right order.
    if isVertical() then
        return flyout:IsMouseOver(HOVER_SEAM_TOLERANCE, -HOVER_SEAM_TOLERANCE, 0, 0)
    end

    return flyout:IsMouseOver(0, 0, -HOVER_SEAM_TOLERANCE, HOVER_SEAM_TOLERANCE)
end

local function open()
    openTimer = nil

    -- A timer started just before the drag began would otherwise fire mid-drag.
    if isDragging then
        addon.debugMessage("Teleport flyout: open skipped (button is being dragged)")
        return
    end

    -- The dwell survives OnLeave (see onButtonLeave), so confirm the cursor
    -- is genuinely still there before unrolling.
    if not isCursorInHoverArea() then
        addon.debugMessage("Teleport flyout: open skipped (cursor left)")
        return
    end

    if not flyout or not isEnabled() or visibleSlotCount == 0 then
        addon.debugMessage(("Teleport flyout: open skipped (frame %s, enabled %s, slots %d)")
            :format(tostring(flyout ~= nil), tostring(isEnabled()), visibleSlotCount))
        return
    end

    -- Silent: the cursor crosses the minimap constantly during a fight, so a
    -- warning here would spam the chat frame.
    if InCombatLockdown() then
        addon.debugMessage("Teleport flyout: open skipped (in combat)")
        return
    end

    local grows = anchorToButton()
    if grows == nil then
        addon.debugMessage("Teleport flyout: open skipped (minimap has no position)")
        return
    end

    if grows ~= laidOutGrows then
        layoutSlots(grows)
        laidOutGrows = grows
    end

    local fromLength = COLLAPSED_LENGTH
    if flyout:IsShown() then
        fromLength = getLength()
    end

    isClosing = false
    setLength(fromLength)
    flyout:Show()
    animateLength(fromLength, targetLength)

    addon.debugMessage(("Teleport flyout: opening grows=%s target=%d gateShown=%s visible=%s")
        :format(grows, targetLength, tostring(combatGate:IsShown()), tostring(flyout:IsVisible())))
end

local function close()
    if not flyout or not flyout:IsShown() then
        return
    end

    -- SecureActionButton children make the strip itself implicitly protected,
    -- so its size and visibility are frozen for the length of the fight. The
    -- secure gate already hides it on screen; collapse it for real once the
    -- lockdown lifts.
    if InCombatLockdown() then
        pendingCollapse = true
        return
    end

    isClosing = true
    animateLength(getLength(), COLLAPSED_LENGTH, function()
        isClosing = false
        flyout:Hide()
    end)
end

function closeImmediately()
    if not flyout then
        return
    end

    if InCombatLockdown() then
        pendingCollapse = true
        return
    end
    pendingCollapse = false

    stopAnimation()
    isClosing = false
    flyout:Hide()
    setLength(COLLAPSED_LENGTH)
end

function scheduleClose()
    cancelCloseTimer()

    closeTimer = C_Timer.NewTimer(CLOSE_GRACE_SECONDS, function()
        closeTimer = nil

        if isCursorInHoverArea() then
            return
        end

        close()
    end)
end

local function scheduleOpen()
    cancelCloseTimer()

    addon.debugMessage(("Teleport flyout: button hovered (enabled %s, shown %s, closing %s)")
        :format(tostring(isEnabled()), tostring(flyout:IsShown()), tostring(isClosing)))

    if not isEnabled() then
        return
    end

    -- An edge drag moves the button under the cursor, so the cursor can slip out
    -- of the frame and back in mid-drag — which arrives here as a fresh hover.
    if isDragging then
        return
    end

    -- Cursor came back from the strip while it is still open: cancelling the
    -- close timer above was the whole job, no second unroll needed.
    if flyout:IsShown() and not isClosing then
        return
    end

    -- OnEnter/OnLeave can fire in bursts as the cursor crosses neighbouring
    -- frames, so restarting the countdown on every OnEnter would keep it from
    -- ever completing. The dwell measures time since the cursor first reached
    -- the button, not since the last event.
    if openTimer then
        return
    end

    openTimer = C_Timer.NewTimer(getHoverDelay(), open)
end

local function onButtonLeave()
    addon.debugMessage("Teleport flyout: button left")

    -- Deliberately leaves the dwell timer running; open() re-checks the cursor
    -- position geometrically when the timer fires.
    scheduleClose()
end

local function onButtonDragStart()
    addon.debugMessage("Teleport flyout: button drag started")

    isDragging = true
    cancelOpenTimer()
    cancelCloseTimer()

    -- Not close(): the animated collapse would trail behind the button as it
    -- travels, and during a fight close() only marks the strip for later anyway.
    closeImmediately()
end

local function onButtonDragStop()
    addon.debugMessage("Teleport flyout: button drag stopped")

    isDragging = false

    -- The cursor never left the button, so no OnEnter will arrive to restart the
    -- dwell — without this the strip would stay rolled up until the player moves
    -- away and comes back.
    if isCursorInHoverArea() then
        scheduleOpen()
    end
end

---Combat lockdown is already in effect by the time PLAYER_REGEN_DISABLED
---arrives, so the strip can only be marked for collapse here — the secure
---visibility gate is what actually takes it off screen.
local function onCombatStart()
    cancelOpenTimer()
    cancelCloseTimer()
    pendingCollapse = true
end

local function onCombatEnd()
    if pendingCollapse then
        closeImmediately()
    end

    if pendingRefresh then
        refresh()
    end
end

function MPT_MinimapTeleportFlyout:isEnabled()
    return isEnabled()
end

function MPT_MinimapTeleportFlyout:setEnabled(enabled)
    ensureFlyoutState().minimapTeleportFlyoutHidden = not enabled

    if not enabled then
        cancelOpenTimer()
        cancelCloseTimer()
        closeImmediately()
    end
end

---@return string one of "horizontal" / "vertical"
function MPT_MinimapTeleportFlyout:getOrientation()
    return getOrientation()
end

---@param orientation string one of "horizontal" / "vertical"
function MPT_MinimapTeleportFlyout:setOrientation(orientation)
    if orientation ~= ORIENTATIONS.HORIZONTAL and orientation ~= ORIENTATIONS.VERTICAL then
        return
    end

    ensureFlyoutState().minimapTeleportFlyoutOrientation = orientation

    if not flyout then
        return
    end

    -- Same teardown as refresh(): an open strip still carries the old axis, and
    -- the slots are anchored for the old direction. Drop it, re-pin the short
    -- axis, and let the next hover build it fresh.
    cancelOpenTimer()
    closeImmediately()
    applyThickness()
    setLength(COLLAPSED_LENGTH)
    laidOutGrows = nil
end

function MPT_MinimapTeleportFlyout:getHoverDelay()
    return getHoverDelay()
end

function MPT_MinimapTeleportFlyout:setHoverDelay(seconds)
    ensureFlyoutState().minimapTeleportFlyoutDelay = seconds

    -- A timer already counting down still carries the old delay; drop it so
    -- the new value applies from the next hover on.
    cancelOpenTimer()
end

---Feeds the settings slider, so its range lives next to the clamp in
---getHoverDelay() instead of being repeated in Settings.lua.
---@return number minimum
---@return number maximum
---@return number step
---@return number default
function MPT_MinimapTeleportFlyout:getHoverDelayBounds()
    return MINIMUM_HOVER_DELAY_SECONDS, MAXIMUM_HOVER_DELAY_SECONDS, HOVER_DELAY_STEP_SECONDS, DEFAULT_HOVER_DELAY_SECONDS
end

---A full-screen, invisible parent whose only job is to disappear during
---combat. The strip inherits protection upwards from its SecureActionButton
---children, so insecure code may not hide it once the fight starts; a state
---driver runs in the restricted environment and is allowed to, and hiding the
---gate takes everything below it along.
local function createCombatGate()
    local gate = CreateFrame("Frame", "MPTMinimapTeleportFlyoutGate", UIParent)
    gate:SetAllPoints(UIParent)
    RegisterStateDriver(gate, "visibility", "[combat] hide; show")

    return gate
end

local function createFlyout(parent)
    -- Parented to the combat gate rather than to the button: the strip reaches
    -- well past it, and as its child it would inherit the button's own
    -- stacking order inside the minimap.
    local newFlyout = CreateFrame("Frame", "MPTMinimapTeleportFlyout", parent)
    newFlyout:SetSize(COLLAPSED_LENGTH, COLLAPSED_LENGTH)
    -- Above the action bars (MEDIUM), whose buttons would otherwise draw their
    -- item counts and keybind labels over the strip — frame level can't settle
    -- that inside a shared strata. Still below the tracker window (DIALOG), so
    -- opening that puts it on top, where it belongs.
    newFlyout:SetFrameStrata("HIGH")
    newFlyout:SetFrameLevel(minimapButton:GetFrameLevel() + 10)
    -- Lets the icons emerge from behind the growing edge instead of popping in.
    newFlyout:SetClipsChildren(true)
    newFlyout:EnableMouse(true)
    newFlyout:Hide()

    -- Stops short of the frame edge: the nine-slice draws its visible line
    -- inset, so a backdrop filling the whole rect peeks out past the border.
    local background = newFlyout:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("TOPLEFT", newFlyout, "TOPLEFT", BACKGROUND_INSET, -BACKGROUND_INSET)
    background:SetPoint("BOTTOMRIGHT", newFlyout, "BOTTOMRIGHT", -BACKGROUND_INSET, BACKGROUND_INSET)
    background:SetColorTexture(BACKGROUND_R, BACKGROUND_G, BACKGROUND_B, BACKGROUND_A)

    local border = CreateFrame("Frame", nil, newFlyout)
    border:SetAllPoints(newFlyout)
    border:SetFrameLevel(newFlyout:GetFrameLevel() + 5)
    NineSliceUtil.ApplyLayout(border, FLYOUT_BORDER_LAYOUT)

    return newFlyout
end

local function onEvent(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        onCombatStart()
    elseif event == "PLAYER_REGEN_ENABLED" then
        onCombatEnd()
    else
        requestRefresh()
    end
end

function MPT_MinimapTeleportFlyout:load()
    minimapButton = MPT_MinimapButton:getFrame()
    if not minimapButton then
        -- Only reachable if MinimapButton.lua stops creating its frame during
        -- load; without a button there is nothing to hover or anchor to.
        addon.debugMessage("Teleport flyout: no minimap button to attach to")
        return
    end

    combatGate = createCombatGate()
    flyout = createFlyout(combatGate)

    -- createFlyout can't size the axes itself: they depend on the orientation,
    -- and these helpers work on the module-level `flyout` that is only assigned
    -- on the line above.
    applyThickness()
    setLength(COLLAPSED_LENGTH)

    flyout:SetScript("OnEnter", cancelCloseTimer)
    flyout:SetScript("OnLeave", scheduleClose)

    minimapButton:HookScript("OnEnter", scheduleOpen)
    minimapButton:HookScript("OnLeave", onButtonLeave)
    -- Hooked rather than owned by MinimapButton.lua, like the two above: the
    -- button doesn't need to know the strip exists. MinimapButton.lua loads
    -- first (Modules/modules.xml) and sets its drag scripts at file scope, so
    -- they are there to hook by the time this runs.
    minimapButton:HookScript("OnDragStart", onButtonDragStart)
    minimapButton:HookScript("OnDragStop", onButtonDragStop)

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("SPELLS_CHANGED")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:SetScript("OnEvent", onEvent)
end

MPT_MinimapTeleportFlyout:load()

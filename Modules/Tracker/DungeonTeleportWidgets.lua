local addonName, addon = ...

local TELEPORT_ARTIFACT_R, TELEPORT_ARTIFACT_G, TELEPORT_ARTIFACT_B = addon.colorToRGB("ARTIFACT")

local GLOW_FROM_ALPHA = 0.15
local GLOW_TO_ALPHA = 0.55
local GLOW_DURATION_SECONDS = 0.6

---Binds (or rebinds) a dungeon to an existing teleport button, using the
---season's known "Path of ..." spell for mapID (see DungeonTeleportCatalog.lua).
---Calls SetAttribute on a protected frame, so callers MUST check
---InCombatLockdown() first.
---@param mapID number
---@param name string dungeon name, shown in the tooltip when no spell is known
---@return boolean hasTeleport
local function bindDungeon(self, mapID, name)
    local teleport = addon.getDungeonTeleport(mapID)

    self.teleport = teleport
    self.dungeonName = name

    if teleport then
        self:SetAttribute("type", "spell")
        self:SetAttribute("spell", teleport.spellID)
    else
        self:SetAttribute("type", nil)
        self:SetAttribute("spell", nil)
    end

    return teleport ~= nil
end

---Creates a hover-glow + click-to-teleport button on top of a dungeon icon,
---without binding a dungeon yet — call `button:bindDungeon(mapID, name)` for
---that. Split from attachDungeonTeleportButton so the minimap flyout can pool
---its buttons: secure frames can never be destroyed, so rebuilding a panel has
---to reuse them rather than create new ones.
---
---Uses a SecureActionButtonTemplate so the protected spell cast is allowed to
---run directly from the click.
---@param parent Frame the row/slot frame the icon texture belongs to
---@param icon Texture the dungeon icon to brighten/glow on hover — secure
---frames can't anchor to a Texture, so the button is anchored to `parent`
---using the same x/y/size instead of to `icon` itself
---@param x number
---@param y number
---@param size number
---@return Button
function addon.createDungeonTeleportButton(parent, icon, x, y, size)
    local glow = parent:CreateTexture(nil, "OVERLAY")
    glow:SetAllPoints(icon)
    glow:SetColorTexture(0.3, 0.6, 1, 1)
    glow:SetBlendMode("ADD")
    glow:Hide()

    local glowAnim = glow:CreateAnimationGroup()
    glowAnim:SetLooping("BOUNCE")
    local glowFade = glowAnim:CreateAnimation("Alpha")
    glowFade:SetFromAlpha(GLOW_FROM_ALPHA)
    glowFade:SetToAlpha(GLOW_TO_ALPHA)
    glowFade:SetDuration(GLOW_DURATION_SECONDS)
    glowFade:SetSmoothing("IN_OUT")

    local teleportBtn = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
    teleportBtn:SetSize(size, size)
    teleportBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    teleportBtn:RegisterForClicks("AnyUp", "AnyDown")
    teleportBtn.bindDungeon = bindDungeon

    teleportBtn:SetScript("OnEnter", function(self)
        icon:SetVertexColor(1.15, 1.15, 1.15)

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.teleport then
            glow:Show()
            glowAnim:Play()
            GameTooltip:SetSpellByID(self.teleport.spellID)
            GameTooltip:AddLine(addon.locale["DUNGEON_TELEPORT_TOOLTIP"], 0, 1, 0, true)
        else
            GameTooltip:AddLine(self.dungeonName, TELEPORT_ARTIFACT_R, TELEPORT_ARTIFACT_G, TELEPORT_ARTIFACT_B)
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

---Creates a teleport button and binds mapID to it in one call. Shared by
---DungeonsPage.lua and KeystonesPage.lua so both tabs behave identically —
---they rebuild their rows from scratch on every render, so there is nothing
---to rebind.
---@param parent Frame
---@param icon Texture
---@param mapID number
---@param name string
---@param x number
---@param y number
---@param size number
---@return Button
function addon.attachDungeonTeleportButton(parent, icon, mapID, name, x, y, size)
    local teleportBtn = addon.createDungeonTeleportButton(parent, icon, x, y, size)
    teleportBtn:bindDungeon(mapID, name)

    return teleportBtn
end

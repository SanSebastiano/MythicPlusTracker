local addonName, addon = ...

local JOURNAL_ARTIFACT_R, JOURNAL_ARTIFACT_G, JOURNAL_ARTIFACT_B = addon.colorToRGB("ARTIFACT")

-- The Adventure Guide is load-on-demand: its globals only exist once something
-- has pulled it in. Nothing here runs at login, only on an actual click.
local JOURNAL_ADDON = "Blizzard_EncounterJournal"

-- Mythic, not Mythic Keystone: EJ_IsValidInstanceDifficulty only accepts 1
-- (Normal), 2 (Heroic), 23 (Mythic) and 24 (Timewalking) for dungeons, so
-- passing DungeonChallenge leaves the journal with no difficulty selected at
-- all. Mythic shows the same bosses and loot a keystone run does.
local JOURNAL_DIFFICULTY_ID = DifficultyUtil.ID.DungeonMythic

-- mapChallengeModeID -> journalInstanceID, or false for a dungeon the journal
-- has no entry for. Both lookups below are static game data, so one answer per
-- dungeon per session is enough — and caching the misses as `false` keeps them
-- from being retried on every render.
local journalInstanceIDByMapID = {}

---The journal instance behind a Mythic+ dungeon, or nil when there is none.
---
---GetMapUIInfo's sixth return (added in 11.2.0) is the game map ID, which is
---exactly what GetInstanceForGameMap takes — "GameMap as opposed to UIMap since
---we use a mapID not a uiMapID", per its own documentation. That pairing is
---what makes a static per-season dungeon table unnecessary here, unlike
---DungeonTeleportCatalog.lua.
---@param mapID number mapChallengeModeID
---@return number|nil journalInstanceID
local function resolveJournalInstanceID(mapID)
    local cached = journalInstanceIDByMapID[mapID]
    if cached ~= nil then
        return cached or nil
    end

    local _, _, _, _, _, gameMapID = C_ChallengeMode.GetMapUIInfo(mapID)
    local journalInstanceID = gameMapID and C_EncounterJournal.GetInstanceForGameMap(gameMapID) or nil

    journalInstanceIDByMapID[mapID] = journalInstanceID or false

    return journalInstanceID
end

---Opens the Adventure Guide on one dungeon, at Mythic difficulty, and closes
---the tracker behind it — the journal is a full-size window and would otherwise
---come up half-hidden under it.
---@param journalInstanceID number
local function openJournal(journalInstanceID)
    -- The player can have the journal addon disabled entirely, in which case
    -- the load fails and its functions never appear.
    local loaded = C_AddOns.LoadAddOn(JOURNAL_ADDON)
    if not loaded or not EncounterJournal_OpenJournal then
        addon.debugMessage("DungeonJournalWidgets: " .. JOURNAL_ADDON .. " could not be loaded")
        return
    end

    -- Blizzard UI code, called straight from our click handler: a fault in it
    -- must not surface as an error in this addon (CODING_GUIDELINES 14.2.2).
    local succeeded, openError = pcall(EncounterJournal_OpenJournal, JOURNAL_DIFFICULTY_ID, journalInstanceID)
    if not succeeded then
        addon.debugMessage("DungeonJournalWidgets: opening the journal failed: " .. tostring(openError))
        return
    end

    -- OpenJournal swallows a difficulty the instance doesn't support without
    -- saying so, and the journal then keeps whatever it had. Setting it again
    -- is the only way to know the selection actually took.
    if EJ_GetDifficulty() ~= JOURNAL_DIFFICULTY_ID and EJ_IsValidInstanceDifficulty(JOURNAL_DIFFICULTY_ID) then
        EJ_SetDifficulty(JOURNAL_DIFFICULTY_ID)
    end

    MPT_Tracker:hide()
end

---Turns a dungeon-name label into a link that opens the Adventure Guide at that
---dungeon. Shared by every view that lists dungeons so they all behave alike.
---
---Attaches nothing when the dungeon has no journal entry, leaving no dead
---hotspot behind — callers can hand over any mapID without checking first.
---
---Hover brightens the label to white and restores the colour it had at attach
---time, the same feedback the sortable table headers give. That colour has to
---come from SetTextColor: an inline |cff escape in the label's text wins over
---SetTextColor and would make the highlight a no-op.
---
---The dungeon icon is deliberately left alone. In Group and Overview rows it
---already carries the secure teleport button, so the rule across all views is:
---icon teleports, name opens the journal.
---@param parent Frame the frame the label was laid out in
---@param label FontString the dungeon name label
---@param mapID number|nil mapChallengeModeID
---@param name string dungeon name, shown as the tooltip's title
---@param x number top-left X offset within parent, i.e. the label's offset
---@param y number top-left Y offset within parent, i.e. the row's offset
---@param w number
---@param h number
---@return Button|nil clickArea nil when the dungeon has no journal entry
function addon.attachDungeonJournalLink(parent, label, mapID, name, x, y, w, h)
    local journalInstanceID = mapID and resolveJournalInstanceID(mapID)
    if not journalInstanceID then
        return nil
    end

    local labelR, labelG, labelB, labelA = label:GetTextColor()

    return addon.createClickArea(parent, x, y, addon.textHotspotWidth(label, w), h,
        function()
            openJournal(journalInstanceID)
        end,
        function(self)
            label:SetTextColor(1, 1, 1, 1)

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(name, JOURNAL_ARTIFACT_R, JOURNAL_ARTIFACT_G, JOURNAL_ARTIFACT_B, 1)
            addon.addTooltipLabelLine(addon.locale["DUNGEON_JOURNAL_TOOLTIP"], "POOR", "POOR")
            GameTooltip:Show()
        end,
        function()
            label:SetTextColor(labelR, labelG, labelB, labelA)
            GameTooltip:Hide()
        end)
end

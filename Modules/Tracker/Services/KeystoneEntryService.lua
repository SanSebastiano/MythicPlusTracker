local addonName, addon = ...

MythicPlusTrackerDB = MythicPlusTrackerDB or {}

addon.KeystoneEntryService = addon.KeystoneEntryService or {}

-- Persisted as MythicPlusTrackerDB.keystonesTabMode. These string values are a
-- SavedVariables contract: renaming one would silently reset every existing
-- user's dropdown selection back to the default on their next login.
addon.KeystoneEntryService.MODES = {
    GROUP = "group",
    ALTS  = "alts",
    GUILD = "guild",
}

local MODES = addon.KeystoneEntryService.MODES

-- A view forced by the situation rather than chosen: the Dashboard sets this to
-- Group when it auto-opens on the Keystones tab because the player is in a
-- group. Deliberately not persisted — it describes where the player is right
-- now, not what they configured, and must not outlive the session.
local modeOverride

-- Set the moment someone uses the dropdown. From then on the automatic opening
-- stops forcing a view for the rest of the session, so a deliberate choice
-- can't be taken away again on the next open.
local modeChosenByUser = false

---The Keystones tab's active view, shared by the table, the dropdown and the
---Sidebar's statistics card so the three can't disagree. Anything unrecognised
---(including nil on a fresh install) resolves to Group.
---@return string mode one of MODES
function addon.KeystoneEntryService:getActiveMode()
    if modeOverride then
        return modeOverride
    end

    local storedMode = MythicPlusTrackerDB.keystonesTabMode
    if storedMode == MODES.ALTS or storedMode == MODES.GUILD then
        return storedMode
    end
    return MODES.GROUP
end

---Forces a view without storing it, for the Dashboard's automatic open in a
---group. Passing nil drops the override — the Dashboard does that on every
---open that isn't the group case, which is what keeps the forced view from
---outlasting the group.
---
---A view the player picked themselves wins: once that has happened, this is
---ignored for the rest of the session.
---@param mode string|nil one of MODES, or nil to drop the override
function addon.KeystoneEntryService:setModeOverride(mode)
    if modeChosenByUser then
        modeOverride = nil
        return
    end

    modeOverride = mode
end

---The dropdown's path. Stores the choice and stands down the override, so the
---selection takes effect immediately and isn't undone by the next auto-open.
---@param mode string one of MODES
function addon.KeystoneEntryService:setActiveMode(mode)
    MythicPlusTrackerDB.keystonesTabMode = mode
    modeChosenByUser = true
    modeOverride = nil
end

---Resolves the keystone known for one group unit, plus whether that member is
---known to run MythicPlusTracker at all. The local player is read straight
---from the API — own data is always known, no addon message needed.
---@param unitToken string
---@param fullPlayerName string|nil
---@return number|nil mapID
---@return number|nil level
---@return boolean hasAddon
---@return number|nil score
local function resolveKeystoneForUnit(unitToken, fullPlayerName)
    if unitToken == "player" then
        return C_MythicPlus.GetOwnedKeystoneChallengeMapID(), C_MythicPlus.GetOwnedKeystoneLevel(), true,
            C_ChallengeMode.GetOverallDungeonScore()
    end

    local receivedKeystone = fullPlayerName and addon.GroupKeystoneService:getKeystone(fullPlayerName)
    if not receivedKeystone then
        return nil, nil, false, nil
    end

    return receivedKeystone.mapID, receivedKeystone.level, receivedKeystone.hasAddon == true, receivedKeystone.score
end

---Normalized entry list for the live group roster, in the same shape the Alts
---and Guild providers return, so both the Keystones tab's table and the
---Sidebar's statistics card can consume all three modes identically.
---entry.unitToken is kept for the bits that still need a live unit (portrait,
---role) and is absent on Alts/Guild entries.
---@return table entries
function addon.KeystoneEntryService:getGroupEntries()
    local entries = {}

    for _, unitToken in ipairs(addon.GroupKeystoneService:getGroupUnitTokens()) do
        if UnitExists(unitToken) then
            local fullPlayerName = addon.GroupKeystoneService:getFullPlayerName(unitToken)
            local _, englishClass = UnitClass(unitToken)
            local mapID, level, hasAddon, score = resolveKeystoneForUnit(unitToken, fullPlayerName)

            table.insert(entries, {
                unitToken   = unitToken,
                name        = UnitName(unitToken) or fullPlayerName or "?",
                class       = englishClass,
                mapID       = mapID,
                level       = level,
                hasAddon    = hasAddon,
                score       = score,
                dungeonName = mapID and (C_ChallengeMode.GetMapUIInfo(mapID)),
            })
        end
    end

    return entries
end

---Entries for whichever mode the Keystones tab currently shows. Callers that
---render mode-specific columns want the individual providers instead; this is
---for callers that treat all three modes the same.
---@return table entries
function addon.KeystoneEntryService:getEntriesForActiveMode()
    local mode = self:getActiveMode()

    if mode == MODES.ALTS then
        return addon.AltKeystoneService:getEntries()
    elseif mode == MODES.GUILD then
        return addon.GuildKeystoneService:getEntries()
    end

    return self:getGroupEntries()
end

---Aggregates a normalized entry list into the numbers the Sidebar shows.
---Averages only ever consider entries with a known value, so a member without
---the addon (nil score) cannot drag the average toward zero. "Best" ranks by
---level first, score as the tiebreaker.
---@param entries table
---@return table statistics { averageScore, averageLevel, withKey, total, best }
function addon.KeystoneEntryService:computeStatistics(entries)
    local scoreSum, scoreCount = 0, 0
    local levelSum, levelCount = 0, 0
    local best

    for _, entry in ipairs(entries) do
        if entry.score then
            scoreSum = scoreSum + entry.score
            scoreCount = scoreCount + 1
        end
        if entry.mapID and entry.level then
            levelSum = levelSum + entry.level
            levelCount = levelCount + 1
            if not best or entry.level > best.level
                or (entry.level == best.level and (entry.score or 0) > (best.score or 0)) then
                best = { name = entry.name, class = entry.class, level = entry.level, score = entry.score }
            end
        end
    end

    return {
        averageScore = scoreCount > 0 and (scoreSum / scoreCount) or nil,
        averageLevel = levelCount > 0 and (levelSum / levelCount) or nil,
        withKey      = levelCount,
        total        = #entries,
        best         = best,
    }
end

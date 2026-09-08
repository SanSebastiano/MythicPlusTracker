local addonName, addon = ...

-- Account-wide store of each max-level character's last-known keystone,
-- keyed by "Name-Realm". Populated whenever the local character logs in or
-- finishes/enters an instance (see eventFrame below), so switching to a
-- different character still shows that character's last-known keystone in
-- the Dashboard Keystones tab's "Alts" view.
MythicPlusTrackerAltDB = MythicPlusTrackerAltDB or {}
MythicPlusTrackerDB = MythicPlusTrackerDB or {}

---Saves the local character's current keystone (or lack thereof) into
---MythicPlusTrackerAltDB, stamped with the current weekly reset epoch so a
---later read can tell whether the data is still from this reset week.
---Only max-level characters are persisted.
local function persistOwnKeystoneIfEligible()
    if not addon.Player:isMaxLevel() then
        return
    end

    local mapID, level = addon.KeystoneService:getOwned()
    local _, englishClass = UnitClass("player")

    MythicPlusTrackerAltDB[addon.Player:getCharacterKey()] = {
        name       = UnitName("player"),
        realm      = GetNormalizedRealmName(),
        class      = englishClass,
        mapID      = mapID,
        level      = level,
        score      = C_ChallengeMode.GetOverallDungeonScore() or 0,
        resetEpoch = C_DateAndTime.GetWeeklyResetStartTime(),
        savedAt    = GetServerTime(),
    }
    MythicPlusTrackerDB.altKeystonesLastRefreshedAt = GetServerTime()

    addon.debugMessage("AltKeystones: saved own keystone (mapID=" .. tostring(mapID)
        .. ", level=" .. tostring(level) .. ")")
end

addon.AltKeystoneService = addon.AltKeystoneService or {}

---Returns the server timestamp of the last time the local character's own
---keystone was checked and (re-)saved into MythicPlusTrackerAltDB, or nil if
---that hasn't happened yet (e.g. addon just installed, or character below
---max level). Used by the Alts view's info tooltip.
---@return number|nil
function addon.AltKeystoneService:getLastRefreshedAt()
    return MythicPlusTrackerDB.altKeystonesLastRefreshedAt
end

---Returns every saved alt entry, sorted by keystone level (highest first,
---no-key entries last) and then by name. Entries whose resetEpoch no longer
---matches the current weekly reset are stale (the keystone has reset since
---that character last logged in): their keystone fields are cleared so the
---character still appears in the list, showing the existing "no key"
---fallback, without the leftover pre-reset level being misleading.
---@return table entries
function addon.AltKeystoneService:getEntries()
    local currentResetEpoch = C_DateAndTime.GetWeeklyResetStartTime()

    local entries = {}
    for _, entry in pairs(MythicPlusTrackerAltDB) do
        if entry.resetEpoch ~= currentResetEpoch then
            entry.mapID = nil
            entry.level = nil
            entry.score = nil
            entry.resetEpoch = currentResetEpoch
        end
        table.insert(entries, entry)
    end

    table.sort(entries, function(a, b)
        if (a.level or 0) ~= (b.level or 0) then
            return (a.level or 0) > (b.level or 0)
        end
        return (a.name or "") < (b.name or "")
    end)

    return entries
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- Catches keystone changes that aren't a dungeon completion or a loading
-- screen, e.g. trading a timed-out key down at Lindormi.
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:SetScript("OnEvent", persistOwnKeystoneIfEligible)

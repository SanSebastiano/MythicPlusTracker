local addonName, addon = ...

-- Guild-wide store of every known guild member's last-known keystone, keyed
-- by "Name-Realm". Unlike MythicPlusTrackerAltDB (own account only), entries
-- here come from other players entirely, via Utils/GuildComm.lua's addon
-- messages on the GUILD channel — both the member's own broadcast and,
-- transitively, other online members relaying whatever they've learned.
MythicPlusTrackerGuildDB = MythicPlusTrackerGuildDB or {}

addon.GuildKeys = addon.GuildKeys or {}

---Splits a guild roster name into character name + realm. Same-realm guild
---members are returned by GetGuildRosterInfo without a realm suffix; cross-
---realm (connected-realm) guilds include one. Falls back to the local
---realm when none is present, matching the qualification pattern used for
---incoming addon-message senders (see Utils/Communication.lua:217-220).
---@param rawName string
---@return string name
---@return string realm
local function splitNameRealm(rawName)
    local name, realm = string.match(rawName, "^([^%-]+)%-(.+)$")
    if name then
        return name, realm
    end
    return rawName, GetNormalizedRealmName()
end

---Merges a single received entry into MythicPlusTrackerGuildDB, keeping
---whichever version of a given member's data has the newer savedAt — the
---timestamp the *source* character saved it with, not when it was relayed.
---This per-entry comparison (rather than replacing the whole table with
---some peer's "most complete" snapshot) is what lets data from members who
---were never online at the same time still reach each other transitively:
---no single online member's local knowledge necessarily has to be a superset
---of anyone else's.
---@param key string "Name-Realm" of the entry being merged
---@param entry table {name, realm, class, mapID, level, score, savedAt, resetEpoch}
---@return boolean changed true if this call actually added/updated something
function addon.GuildKeys:Merge(key, entry)
    local existing = MythicPlusTrackerGuildDB[key]
    if existing and (existing.savedAt or 0) >= (entry.savedAt or 0) then
        return false
    end

    MythicPlusTrackerGuildDB[key] = entry
    return true
end

---Returns every known guild entry, plus a synthetic "no addon" entry for
---every currently online guild member we've never heard a broadcast from,
---sorted by keystone level (highest first, no-key/no-addon entries last)
---and then by name.
---
---Entries whose resetEpoch no longer matches the current weekly reset are
---stale (the keystone has reset since that member's data was last saved):
---their keystone fields are cleared so the member still appears in the list
---as "known, no key this week" (hasAddon=true/no-mapID — same state the
---Group tab shows for a member who responded with NOKEY), rather than
---disappearing or showing a leftover pre-reset level.
---
---Members with no entry at all are otherwise indistinguishable from someone
---who simply hasn't broadcast yet, so a live guild-roster scan fills in
---"no addon" (hasAddon=false) for anyone currently online who still has no
---entry — mirroring the Group tab's fallback for unresponsive members.
---Offline members with no known entry are left out entirely: there's no way
---to tell "no addon" apart from "has the addon, just not logged in" for
---someone who isn't online to ask.
---@return table entries
function addon.GuildKeys:GetEntries()
    local currentResetEpoch = C_DateAndTime.GetWeeklyResetStartTime()

    local entries = {}
    local seenKeys = {}
    for key, entry in pairs(MythicPlusTrackerGuildDB) do
        if entry.resetEpoch ~= currentResetEpoch then
            entry.mapID = nil
            entry.level = nil
            entry.score = nil
            entry.resetEpoch = currentResetEpoch
        end
        entry.hasAddon = true
        table.insert(entries, entry)
        seenKeys[key] = true
    end

    if IsInGuild() then
        C_GuildInfo.GuildRoster()
        -- GetGuildRosterInfo return order (per the Blizzard UI code at the
        -- time of writing): name, rank, rankIndex, level, class, zone, note,
        -- officernote, isOnline, status, classFileName, ...
        for i = 1, GetNumGuildMembers() do
            local rawName, _, _, _, _, _, _, _, isOnline, _, classFileName = GetGuildRosterInfo(i)
            if isOnline and rawName and rawName ~= "" then
                local name, realm = splitNameRealm(rawName)
                local key = name .. "-" .. realm
                if not seenKeys[key] then
                    table.insert(entries, {
                        name     = name,
                        realm    = realm,
                        class    = classFileName,
                        hasAddon = false,
                    })
                    seenKeys[key] = true
                end
            end
        end
    end

    table.sort(entries, function(a, b)
        if (a.level or 0) ~= (b.level or 0) then
            return (a.level or 0) > (b.level or 0)
        end
        return (a.name or "") < (b.name or "")
    end)

    return entries
end

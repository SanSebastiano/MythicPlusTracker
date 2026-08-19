local addonName, addon = ...

-- Guild-wide store of every known guild member's last-known keystone, keyed
-- by "Name-Realm". Unlike MythicPlusTrackerAltDB (own account only), entries
-- here come from other players entirely, via Utils/GuildComm.lua's addon
-- messages on the GUILD channel — both the member's own broadcast and,
-- transitively, other online members relaying whatever they've learned.
MythicPlusTrackerGuildDB = MythicPlusTrackerGuildDB or {}
MythicPlusTrackerDB = MythicPlusTrackerDB or {}
MythicPlusTrackerAltDB = MythicPlusTrackerAltDB or {}

addon.GuildKeys = addon.GuildKeys or {}

---Splits a guild roster name into character name + realm. Same-realm guild
---members are returned by GetGuildRosterInfo without a realm suffix; cross-
---realm (connected-realm) guilds include one. Falls back to the local
---realm when none is present, matching the qualification pattern used for
---incoming addon-message senders in Utils/Communication.lua's CHAT_MSG_ADDON handler.
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
    MythicPlusTrackerDB.guildKeysLastRefreshedAt = GetServerTime()
    return true
end

---Returns the server timestamp of the last time MythicPlusTrackerGuildDB
---actually learned something new (own broadcast, an incoming KEY message, or
---an incoming BULK dump), or nil if that hasn't happened yet. Used by the
---Guild view's info tooltip.
---@return number|nil
function addon.GuildKeys:GetLastRefreshedAt()
    return MythicPlusTrackerDB.guildKeysLastRefreshedAt
end

---Returns every currently online guild member, sorted by keystone level
---(highest first, no-key/no-addon entries last) and then by name.
---
---Name/class/online-status come from a live roster scan
---(GetNumGuildMembers/GetGuildRosterInfo). Keystone/score come from our own
---broadcast protocol (MythicPlusTrackerGuildDB, see Utils/GuildComm.lua);
---hasAddon is false when no broadcast has been heard from that member.
---
---Members who are also the local account's own alts (MythicPlusTrackerAltDB)
---are excluded, since they already show in the Twinks tab — except the
---currently-played character, which stays in the list like any other member.
---@return table entries
function addon.GuildKeys:GetEntries()
    local currentResetEpoch = C_DateAndTime.GetWeeklyResetStartTime()
    local currentCharacterKey = UnitName("player") .. "-" .. GetNormalizedRealmName()

    local ownOtherAltKeys = {}
    for key in pairs(MythicPlusTrackerAltDB) do
        if key ~= currentCharacterKey then
            ownOtherAltKeys[key] = true
        end
    end

    local entries = {}
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
                if not ownOtherAltKeys[key] then
                    local broadcastEntry = MythicPlusTrackerGuildDB[key]
                    if broadcastEntry and broadcastEntry.resetEpoch ~= currentResetEpoch then
                        broadcastEntry.mapID = nil
                        broadcastEntry.level = nil
                        broadcastEntry.score = nil
                        broadcastEntry.resetEpoch = currentResetEpoch
                    end

                    table.insert(entries, {
                        name     = name,
                        realm    = realm,
                        class    = classFileName,
                        mapID    = broadcastEntry and broadcastEntry.mapID or nil,
                        level    = broadcastEntry and broadcastEntry.level or nil,
                        score    = broadcastEntry and broadcastEntry.score or nil,
                        hasAddon = broadcastEntry ~= nil,
                    })
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

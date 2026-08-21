local addonName, addon = ...

MythicPlusTrackerAltDB = MythicPlusTrackerAltDB or {}

addon.GuildKeys = addon.GuildKeys or {}

---Splits a guild roster name into character name + realm. Same-realm guild
---members are returned by GetGuildRosterInfo without a realm suffix; cross-
---realm (connected-realm) guilds include one. Falls back to the local
---realm when none is present, matching the qualification pattern used for
---incoming addon-message senders in Utils/GuildComm.lua's CHAT_MSG_ADDON handler.
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

---Returns every currently online guild member, sorted by keystone level
---(highest first, no-key/no-addon entries last) and then by name.
---
---Name/class/online-status come from a live roster scan
---(GetNumGuildMembers/GetGuildRosterInfo). Keystone/score come from
---addon.guildKeystones, which Utils/GuildComm.lua populates live over its
---REQUEST/KEYSTONE/NOKEY addon-message protocol — the same in-memory,
---per-session-only shape as addon.groupKeystones in Utils/Communication.lua.
---hasAddon is false when no response has been heard from that member yet.
---
---Members who are also the local account's own alts (MythicPlusTrackerAltDB)
---are excluded, since they already show in the Twinks tab — except the
---currently-played character, which stays in the list like any other member.
---@return table entries
function addon.GuildKeys:GetEntries()
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
                    local data = addon.guildKeystones[key]

                    table.insert(entries, {
                        name     = name,
                        realm    = realm,
                        class    = classFileName,
                        mapID    = data and data.mapID or nil,
                        level    = data and data.level or nil,
                        score    = data and data.score or nil,
                        hasAddon = data ~= nil,
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

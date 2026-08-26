local addonName, addon = ...

MythicPlusTrackerAltDB = MythicPlusTrackerAltDB or {}

addon.GuildKeystoneService = addon.GuildKeystoneService or {}

-- Addon message prefix used to exchange keystone information between
-- MythicPlusTracker installations across the whole guild (not just the
-- current group — see GroupKeystoneService.lua for that). Deliberately a
-- different prefix than "MPTrackerKeys" so the two protocols never collide.
-- Blizzard limits addon message prefixes to 16 characters (including the
-- null terminator, i.e. 15 visible characters).
local ADDON_MESSAGE_PREFIX = "MPTrackerGuild"

-- Versioned independently of GroupKeystoneService's protocol on purpose: the
-- guild message shape can grow without forcing a bump on the group one.
local PROTOCOL_VERSION = 1

-- Several call sites (Dashboard Keystones tab, Sidebar guild scores, the
-- manual refresh button, GUILD_ROSTER_UPDATE) each request fresh guild
-- keystone data on their own render path. Throttling here, once, protects
-- the addon-message channel from being spammed when several of those happen
-- to fire in quick succession — same reasoning as
-- GroupKeystoneService.lua:REQUEST_COOLDOWN_SECONDS.
local REQUEST_COOLDOWN_SECONDS = 2
local lastRequestTime = 0

-- Server timestamp of the last time a request actually went out (not
-- skipped by cooldown). Session-only, unlike AltKeystoneService.lua's
-- persisted timestamp — guild keystone data itself is just an in-memory
-- cache that's gone after /reload, so a timestamp surviving the reload
-- would be misleading. Used by the refresh button's tooltip.
local lastRefreshedAt = nil

-- Entries are only populated for online guild members who also run
-- MythicPlusTracker and have responded with their current keystone. Purely
-- in-memory, like addon.groupKeystones in GroupKeystoneService.lua — cleared
-- on /reload, never persisted.
addon.guildKeystones = addon.guildKeystones or {}

---@return boolean
local function isMaxLevel()
    return UnitLevel("player") >= GetMaxPlayerLevel()
end

---Splits a guild roster name into character name + realm. Same-realm guild
---members are returned by GetGuildRosterInfo without a realm suffix; cross-
---realm (connected-realm) guilds include one. Falls back to the local realm
---when none is present, matching the qualification pattern used for incoming
---addon-message senders in the CHAT_MSG_ADDON handler below.
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

---Broadcasts the local player's current keystone status and overall Mythic+
---score to the guild. Mirrors GroupKeystoneService's broadcastOwnKeystoneStatus
---exactly, just on the GUILD channel. Only max-level characters broadcast,
---matching AltKeystoneService.lua's rule for what counts as a meaningful
---keystone owner.
local function broadcastOwnKeystoneStatus()
    if not IsInGuild() or not isMaxLevel() then
        return
    end

    local mapID, level = addon.KeystoneService:getOwned()
    local score = C_ChallengeMode.GetOverallDungeonScore() or 0

    local message
    if mapID and level then
        message = PROTOCOL_VERSION .. ":KEYSTONE:" .. mapID .. ":" .. level .. ":" .. score
    else
        message = PROTOCOL_VERSION .. ":NOKEY:" .. score
    end

    addon.debugMessage("GuildKeystoneService: sending '" .. message .. "' on GUILD")
    C_ChatInfo.SendAddonMessage(ADDON_MESSAGE_PREFIX, message, "GUILD")
end

local function sendGuildKeystoneRequestMessage()
    if not IsInGuild() then
        addon.debugMessage("GuildKeystoneService: sendGuildKeystoneRequestMessage skipped (not in a guild)")
        return
    end
    addon.debugMessage("GuildKeystoneService: sending 'REQUEST' on GUILD")
    C_ChatInfo.SendAddonMessage(ADDON_MESSAGE_PREFIX, PROTOCOL_VERSION .. ":REQUEST", "GUILD")
end

---@param rawMessage string
---@param senderFullPlayerName string
local function handleIncomingMessage(rawMessage, senderFullPlayerName)
    local versionText, message = string.match(rawMessage, "^(%d+):(.+)$")
    local version = tonumber(versionText)
    if not version or version ~= PROTOCOL_VERSION then
        addon.debugMessage("GuildKeystoneService: ignoring message with unknown/mismatched protocol version: "
            .. tostring(rawMessage))
        return
    end

    if message == "REQUEST" then
        addon.debugMessage("GuildKeystoneService: received REQUEST from " .. tostring(senderFullPlayerName))
        broadcastOwnKeystoneStatus()
        return
    end

    local noKeyScoreText = string.match(message, "^NOKEY:(%d+)$")
    if noKeyScoreText then
        addon.debugMessage("GuildKeystoneService: received NOKEY from " .. tostring(senderFullPlayerName)
            .. " (score " .. noKeyScoreText .. ")")
        addon.guildKeystones[senderFullPlayerName] = {
            mapID     = nil,
            level     = nil,
            score     = tonumber(noKeyScoreText),
            hasAddon  = true,
            timestamp = GetServerTime(),
        }
        return
    end

    local mapIDText, levelText, scoreText = string.match(message, "^KEYSTONE:(%d+):(%d+):(%d+)$")
    if not mapIDText or not levelText then
        addon.debugMessage("GuildKeystoneService: received unrecognized message from "
            .. tostring(senderFullPlayerName) .. ": '" .. tostring(message) .. "'")
        return
    end

    addon.debugMessage("GuildKeystoneService: received KEYSTONE from " .. tostring(senderFullPlayerName)
        .. " (mapID " .. mapIDText .. ", level " .. levelText .. ", score " .. scoreText .. ")")

    addon.guildKeystones[senderFullPlayerName] = {
        mapID     = tonumber(mapIDText),
        level     = tonumber(levelText),
        score     = tonumber(scoreText),
        hasAddon  = true,
        timestamp = GetServerTime(),
    }
end

---Calls within REQUEST_COOLDOWN_SECONDS of the previous one are silently
---ignored.
function addon.GuildKeystoneService:requestKeystones()
    local now = GetTime()
    if now - lastRequestTime < REQUEST_COOLDOWN_SECONDS then
        addon.debugMessage("GuildKeystoneService: requestKeystones skipped (cooldown)")
        return
    end
    lastRequestTime = now
    lastRefreshedAt = GetServerTime()

    sendGuildKeystoneRequestMessage()
    broadcastOwnKeystoneStatus()
end

---Returns the server timestamp of the last time a guild keystone request
---actually went out this session, or nil if that hasn't happened yet.
---@return number|nil
function addon.GuildKeystoneService:getLastRefreshedAt()
    return lastRefreshedAt
end

---Returns every currently online guild member, sorted by keystone level
---(highest first, no-key/no-addon entries last) and then by name.
---
---Name/class/online-status come from a live roster scan
---(GetNumGuildMembers/GetGuildRosterInfo). Keystone/score come from
---addon.guildKeystones, which this service populates live over its
---REQUEST/KEYSTONE/NOKEY addon-message protocol — the same in-memory,
---per-session-only shape as addon.groupKeystones in GroupKeystoneService.lua.
---hasAddon is false when no response has been heard from that member yet.
---
---Members who are also the local account's own alts (MythicPlusTrackerAltDB)
---are excluded, since they already show in the Twinks tab — except the
---currently-played character, which stays in the list like any other member.
---@return table entries
function addon.GuildKeystoneService:getEntries()
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

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        C_ChatInfo.RegisterAddonMessagePrefix(ADDON_MESSAGE_PREFIX)
        local isRegistered = C_ChatInfo.IsAddonMessagePrefixRegistered(ADDON_MESSAGE_PREFIX)
        addon.debugMessage("GuildKeystoneService: registered addon message prefix '" .. ADDON_MESSAGE_PREFIX
            .. "' (confirmed: " .. tostring(isRegistered) .. ")")

    elseif event == "GUILD_ROSTER_UPDATE" then
        addon.debugMessage("GuildKeystoneService: guild roster changed, re-requesting keystones")
        addon.GuildKeystoneService:requestKeystones()

    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, _, senderName = ...

        if prefix ~= ADDON_MESSAGE_PREFIX then
            return
        end

        local senderFullPlayerName = senderName
        if senderFullPlayerName and not string.find(senderFullPlayerName, "-", 1, true) then
            senderFullPlayerName = senderFullPlayerName .. "-" .. GetNormalizedRealmName()
        end
        if senderFullPlayerName then
            handleIncomingMessage(message, senderFullPlayerName)
        end
    end
end)

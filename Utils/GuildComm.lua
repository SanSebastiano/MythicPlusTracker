local addonName, addon = ...

-- Addon message prefix used to exchange keystone information between
-- MythicPlusTracker installations across the whole guild (not just the
-- current group — see Modules/Tracker/Services/GroupKeystoneService.lua for that). Deliberately a
-- different prefix than "MPTrackerKeys" so the two protocols never collide.
-- Blizzard limits addon message prefixes to 16 characters (including the
-- null terminator, i.e. 15 visible characters).
local ADDON_MESSAGE_PREFIX = "MPTrackerGuild"

-- Leading version token on every message, matching the convention in
-- Modules/Tracker/Services/GroupKeystoneService.lua.
local PROTOCOL_VERSION = 1

-- Entries are only populated for online guild members who also run
-- MythicPlusTracker and have responded with their current keystone. Purely
-- in-memory, like addon.groupKeystones in Modules/Tracker/Services/GroupKeystoneService.lua — cleared
-- on /reload, never persisted.
addon.guildKeystones = addon.guildKeystones or {}

---@return boolean
local function isMaxLevel()
    return UnitLevel("player") >= GetMaxPlayerLevel()
end

---Broadcasts the local player's current keystone status and overall
---Mythic+ score to the guild. Mirrors Communication.lua's
---broadcastOwnKeystoneStatus exactly, just on the GUILD channel. Only
---max-level characters broadcast, matching Utils/AltKeystones.lua's rule for
---what counts as a meaningful keystone owner.
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

    addon.debugMessage("GuildComm: sending '" .. message .. "' on GUILD")
    C_ChatInfo.SendAddonMessage(ADDON_MESSAGE_PREFIX, message, "GUILD")
end

local function sendGuildKeystoneRequestMessage()
    if not IsInGuild() then
        addon.debugMessage("GuildComm: sendGuildKeystoneRequestMessage skipped (not in a guild)")
        return
    end
    addon.debugMessage("GuildComm: sending 'REQUEST' on GUILD")
    C_ChatInfo.SendAddonMessage(ADDON_MESSAGE_PREFIX, PROTOCOL_VERSION .. ":REQUEST", "GUILD")
end

---@param rawMessage string
---@param senderFullPlayerName string
local function handleIncomingMessage(rawMessage, senderFullPlayerName)
    local versionText, message = string.match(rawMessage, "^(%d+):(.+)$")
    local version = tonumber(versionText)
    if not version or version ~= PROTOCOL_VERSION then
        addon.debugMessage("GuildComm: ignoring message with unknown/mismatched protocol version: "
            .. tostring(rawMessage))
        return
    end

    if message == "REQUEST" then
        addon.debugMessage("GuildComm: received REQUEST from " .. tostring(senderFullPlayerName))
        broadcastOwnKeystoneStatus()
        return
    end

    local noKeyScoreText = string.match(message, "^NOKEY:(%d+)$")
    if noKeyScoreText then
        addon.debugMessage("GuildComm: received NOKEY from " .. tostring(senderFullPlayerName)
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
        addon.debugMessage("GuildComm: received unrecognized message from "
            .. tostring(senderFullPlayerName) .. ": '" .. tostring(message) .. "'")
        return
    end

    addon.debugMessage("GuildComm: received KEYSTONE from " .. tostring(senderFullPlayerName)
        .. " (mapID " .. mapIDText .. ", level " .. levelText .. ", score " .. scoreText .. ")")

    addon.guildKeystones[senderFullPlayerName] = {
        mapID     = tonumber(mapIDText),
        level     = tonumber(levelText),
        score     = tonumber(scoreText),
        hasAddon  = true,
        timestamp = GetServerTime(),
    }
end

addon.GuildComm = addon.GuildComm or {}

-- Several call sites (Dashboard Keystones tab, Sidebar guild scores, the
-- manual refresh button, GUILD_ROSTER_UPDATE) each request fresh guild
-- keystone data on their own render path. Throttling here, once, protects
-- the addon-message channel from being spammed when several of those happen
-- to fire in quick succession — same reasoning as
-- Communication.lua:REQUEST_COOLDOWN_SECONDS.
local REQUEST_COOLDOWN_SECONDS = 2
local lastRequestTime = 0

-- Server timestamp of the last time a request actually went out (not
-- skipped by cooldown). Session-only, unlike Utils/AltKeystones.lua's
-- persisted timestamp — guild keystone data itself is just an in-memory
-- cache that's gone after /reload, so a timestamp surviving the reload
-- would be misleading. Used by the refresh button's tooltip.
local lastRefreshedAt = nil

---Calls within REQUEST_COOLDOWN_SECONDS of the previous one are silently
---ignored.
function addon.GuildComm:RequestGuildKeystones()
    local now = GetTime()
    if now - lastRequestTime < REQUEST_COOLDOWN_SECONDS then
        addon.debugMessage("GuildComm: RequestGuildKeystones skipped (cooldown)")
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
function addon.GuildComm:GetLastRefreshedAt()
    return lastRefreshedAt
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        C_ChatInfo.RegisterAddonMessagePrefix(ADDON_MESSAGE_PREFIX)
        local isRegistered = C_ChatInfo.IsAddonMessagePrefixRegistered(ADDON_MESSAGE_PREFIX)
        addon.debugMessage("GuildComm: registered addon message prefix '" .. ADDON_MESSAGE_PREFIX
            .. "' (confirmed: " .. tostring(isRegistered) .. ")")

    elseif event == "GUILD_ROSTER_UPDATE" then
        addon.debugMessage("GuildComm: guild roster changed, re-requesting keystones")
        addon.GuildComm:RequestGuildKeystones()

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

local addonName, addon = ...

-- Addon message prefix used to exchange keystone information between
-- MythicPlusTracker installations within the same group.
-- Blizzard limits addon message prefixes to 16 characters (including the
-- null terminator, i.e. 15 visible characters); longer prefixes silently
-- fail to register, so messages never actually reach other clients.
local ADDON_MESSAGE_PREFIX = "MPTrackerKeys"

-- Leading version token on every message, so a future protocol change can be
-- detected and ignored gracefully instead of being mis-parsed as the old
-- (or new) shape. WoW addons auto-update, so there's no fleet of old clients
-- to keep working long-term — a mismatch is simply logged and dropped.
local PROTOCOL_VERSION = 1

-- Entries are only populated for other group members that also run
-- MythicPlusTracker and have responded with their current keystone.
local keystonesByPlayerName = {}

---@return string|nil channel
local function getGroupChannel()
    if IsInRaid() then
        return "RAID"
    elseif IsInGroup() then
        return "PARTY"
    end
    return nil
end

---@param unitToken string
---@return string|nil fullPlayerName
local function resolveFullPlayerName(unitToken)
    local name, realm = UnitFullName(unitToken)
    if not name or name == "" then
        return nil
    end
    if not realm or realm == "" then
        return addon.Player:qualifyRealm(name)
    end
    return name .. "-" .. realm
end

---Solo players get a single-entry list containing "player".
---@return table unitTokens
local function collectGroupUnitTokens()
    local unitTokens = {}

    if IsInRaid() then
        for memberIndex = 1, GetNumGroupMembers() do
            table.insert(unitTokens, "raid" .. memberIndex)
        end
    elseif IsInGroup() then
        table.insert(unitTokens, "player")
        for memberIndex = 1, GetNumGroupMembers() - 1 do
            table.insert(unitTokens, "party" .. memberIndex)
        end
    else
        table.insert(unitTokens, "player")
    end

    return unitTokens
end

---Broadcasts the local player's current keystone status and overall
---Mythic+ score to the group. Always sends a message when a group channel
---exists, even without an owned keystone, so other members can tell
---"has addon, no key" apart from "does not have the addon".
local function broadcastOwnKeystoneStatus()
    local channel = getGroupChannel()
    if not channel then
        addon.debugMessage("GroupKeystoneService: broadcastOwnKeystoneStatus skipped (not in a group)")
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

    addon.debugMessage("GroupKeystoneService: sending '" .. message .. "' on " .. channel)
    C_ChatInfo.SendAddonMessage(ADDON_MESSAGE_PREFIX, message, channel)
end

local function sendKeystoneRequestMessage()
    local channel = getGroupChannel()
    if not channel then
        addon.debugMessage("GroupKeystoneService: sendKeystoneRequestMessage skipped (not in a group)")
        return
    end
    addon.debugMessage("GroupKeystoneService: sending 'REQUEST' on " .. channel)
    C_ChatInfo.SendAddonMessage(ADDON_MESSAGE_PREFIX, PROTOCOL_VERSION .. ":REQUEST", channel)
end

local function handleIncomingMessage(rawMessage, senderFullPlayerName)
    local versionText, message = string.match(rawMessage, "^(%d+):(.+)$")
    local version = tonumber(versionText)
    if not version or version ~= PROTOCOL_VERSION then
        addon.debugMessage("GroupKeystoneService: ignoring message with unknown/mismatched protocol version: "
            .. tostring(rawMessage))
        return
    end

    if message == "REQUEST" then
        addon.debugMessage("GroupKeystoneService: received REQUEST from " .. tostring(senderFullPlayerName))
        broadcastOwnKeystoneStatus()
        return
    end

    local noKeyScoreText = string.match(message, "^NOKEY:(%d+)$")
    if noKeyScoreText then
        addon.debugMessage("GroupKeystoneService: received NOKEY from " .. tostring(senderFullPlayerName)
            .. " (score " .. noKeyScoreText .. ")")
        keystonesByPlayerName[senderFullPlayerName] = {
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
        addon.debugMessage("GroupKeystoneService: received unrecognized message from "
            .. tostring(senderFullPlayerName) .. ": '" .. tostring(message) .. "'")
        return
    end

    addon.debugMessage("GroupKeystoneService: received KEYSTONE from " .. tostring(senderFullPlayerName)
        .. " (mapID " .. mapIDText .. ", level " .. levelText .. ", score " .. scoreText .. ")")

    keystonesByPlayerName[senderFullPlayerName] = {
        mapID     = tonumber(mapIDText),
        level     = tonumber(levelText),
        score     = tonumber(scoreText),
        hasAddon  = true,
        timestamp = GetServerTime(),
    }
end

addon.GroupKeystoneService = addon.GroupKeystoneService or {}

-- Several call sites (Dashboard Keystones tab, Sidebar group scores, the
-- manual refresh button, GROUP_ROSTER_UPDATE) each request fresh group
-- keystone data on their own render path. Throttling here, once, protects
-- the addon-message channel from being spammed when several of those
-- happen to fire in quick succession (e.g. rapid tab switching).
local REQUEST_COOLDOWN_SECONDS = 2
local lastRequestTime = 0

-- Server timestamp of the last time a request actually went out (not
-- skipped by cooldown). Session-only, unlike Modules/Tracker/Services/AltKeystoneService.lua's
-- persisted timestamp — group keystone data itself is just an in-memory
-- cache that's gone after /reload, so a timestamp surviving the reload
-- would be misleading. Used by the refresh button's tooltip.
local lastRefreshedAt = nil

---Calls within REQUEST_COOLDOWN_SECONDS of the previous one are silently
---ignored.
function addon.GroupKeystoneService:requestKeystones()
    local now = GetTime()
    if now - lastRequestTime < REQUEST_COOLDOWN_SECONDS then
        addon.debugMessage("GroupKeystoneService: requestKeystones skipped (cooldown)")
        return
    end
    lastRequestTime = now
    lastRefreshedAt = GetServerTime()

    sendKeystoneRequestMessage()
    broadcastOwnKeystoneStatus()
end

---Returns the server timestamp of the last time a group keystone request
---actually went out this session, or nil if that hasn't happened yet.
---@return number|nil
function addon.GroupKeystoneService:getLastRefreshedAt()
    return lastRefreshedAt
end

---The keystone last received from one group member, or nil if that member has
---not responded this session — which means either they do not run the addon or
---the request is still in flight. Entries are only ever stored for responders,
---so a non-nil result always has hasAddon = true.
---@param fullPlayerName string realm-qualified, see addon.Player:getCharacterKey
---@return table|nil keystoneInfo { mapID, level, score, hasAddon, timestamp }
function addon.GroupKeystoneService:getKeystone(fullPlayerName)
    return keystonesByPlayerName[fullPlayerName]
end

---@param unitToken string
---@return string|nil fullPlayerName
function addon.GroupKeystoneService:getFullPlayerName(unitToken)
    return resolveFullPlayerName(unitToken)
end

---Solo players get a single-entry list containing "player".
---@return table unitTokens
function addon.GroupKeystoneService:getGroupUnitTokens()
    return collectGroupUnitTokens()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        C_ChatInfo.RegisterAddonMessagePrefix(ADDON_MESSAGE_PREFIX)
        local isRegistered = C_ChatInfo.IsAddonMessagePrefixRegistered(ADDON_MESSAGE_PREFIX)
        addon.debugMessage("GroupKeystoneService: registered addon message prefix '" .. ADDON_MESSAGE_PREFIX
            .. "' (confirmed: " .. tostring(isRegistered) .. ")")
    elseif event == "GROUP_ROSTER_UPDATE" then
        addon.debugMessage("GroupKeystoneService: group roster changed, re-requesting keystones")
        addon.GroupKeystoneService:requestKeystones()
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, _, senderName = ...

        if prefix ~= ADDON_MESSAGE_PREFIX then
            return
        end

        addon.debugMessage("GroupKeystoneService: CHAT_MSG_ADDON prefix='" .. tostring(prefix)
            .. "' message='" .. tostring(message) .. "' sender='" .. tostring(senderName) .. "'")

        local senderFullPlayerName = addon.Player:qualifyRealm(senderName)
        if senderFullPlayerName then
            handleIncomingMessage(message, senderFullPlayerName)
        end
    end
end)

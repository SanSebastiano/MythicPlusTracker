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

-- Table of received group keystone information, keyed by "Name-Realm".
-- Entries are only populated for other group members that also run
-- MythicPlusTracker and have responded with their current keystone.
addon.groupKeystones = addon.groupKeystones or {}

---Determines which chat channel to use for the current group, if any.
---@return string|nil channel
local function getGroupChannel()
    if IsInRaid() then
        return "RAID"
    elseif IsInGroup() then
        return "PARTY"
    end
    return nil
end

---Builds a realm-qualified player name for a given unit token.
---@param unitToken string
---@return string|nil fullPlayerName
local function getFullPlayerName(unitToken)
    local name, realm = UnitFullName(unitToken)
    if not name or name == "" then
        return nil
    end
    if not realm or realm == "" then
        realm = GetNormalizedRealmName()
    end
    return name .. "-" .. realm
end

---Returns the list of unit tokens for the current group, including the
---local player. Solo players get a single-entry list containing "player".
---@return table unitTokens
local function getGroupUnitTokens()
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
        addon.debugMessage("Communication: broadcastOwnKeystoneStatus skipped (not in a group)")
        return
    end

    local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    local score = C_ChallengeMode.GetOverallDungeonScore() or 0

    local message
    if mapID and level then
        message = PROTOCOL_VERSION .. ":KEYSTONE:" .. mapID .. ":" .. level .. ":" .. score
    else
        message = PROTOCOL_VERSION .. ":NOKEY:" .. score
    end

    addon.debugMessage("Communication: sending '" .. message .. "' on " .. channel)
    C_ChatInfo.SendAddonMessage(ADDON_MESSAGE_PREFIX, message, channel)
end

---Asks other group members running MythicPlusTracker to broadcast their
---current keystone back to the group.
local function sendKeystoneRequestMessage()
    local channel = getGroupChannel()
    if not channel then
        addon.debugMessage("Communication: sendKeystoneRequestMessage skipped (not in a group)")
        return
    end
    addon.debugMessage("Communication: sending 'REQUEST' on " .. channel)
    C_ChatInfo.SendAddonMessage(ADDON_MESSAGE_PREFIX, PROTOCOL_VERSION .. ":REQUEST", channel)
end

local function handleIncomingMessage(rawMessage, senderFullPlayerName)
    local versionText, message = string.match(rawMessage, "^(%d+):(.+)$")
    local version = tonumber(versionText)
    if not version or version ~= PROTOCOL_VERSION then
        addon.debugMessage("Communication: ignoring message with unknown/mismatched protocol version: "
            .. tostring(rawMessage))
        return
    end

    if message == "REQUEST" then
        addon.debugMessage("Communication: received REQUEST from " .. tostring(senderFullPlayerName))
        broadcastOwnKeystoneStatus()
        return
    end

    local noKeyScoreText = string.match(message, "^NOKEY:(%d+)$")
    if noKeyScoreText then
        addon.debugMessage("Communication: received NOKEY from " .. tostring(senderFullPlayerName)
            .. " (score " .. noKeyScoreText .. ")")
        addon.groupKeystones[senderFullPlayerName] = {
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
        addon.debugMessage("Communication: received unrecognized message from "
            .. tostring(senderFullPlayerName) .. ": '" .. tostring(message) .. "'")
        return
    end

    addon.debugMessage("Communication: received KEYSTONE from " .. tostring(senderFullPlayerName)
        .. " (mapID " .. mapIDText .. ", level " .. levelText .. ", score " .. scoreText .. ")")

    addon.groupKeystones[senderFullPlayerName] = {
        mapID     = tonumber(mapIDText),
        level     = tonumber(levelText),
        score     = tonumber(scoreText),
        hasAddon  = true,
        timestamp = GetServerTime(),
    }
end

addon.Communication = addon.Communication or {}

-- Several call sites (Dashboard Keystones tab, Sidebar group scores, the
-- manual refresh button, GROUP_ROSTER_UPDATE) each request fresh group
-- keystone data on their own render path. Throttling here, once, protects
-- the addon-message channel from being spammed when several of those
-- happen to fire in quick succession (e.g. rapid tab switching).
local REQUEST_COOLDOWN_SECONDS = 2
local lastRequestTime = 0

---Requests up-to-date keystone information from the current group and
---broadcasts the local player's own keystone status at the same time.
---Calls within REQUEST_COOLDOWN_SECONDS of the previous one are silently
---ignored.
function addon.Communication:RequestGroupKeystones()
    local now = GetTime()
    if now - lastRequestTime < REQUEST_COOLDOWN_SECONDS then
        addon.debugMessage("Communication: RequestGroupKeystones skipped (cooldown)")
        return
    end
    lastRequestTime = now

    sendKeystoneRequestMessage()
    broadcastOwnKeystoneStatus()
end

---Builds a realm-qualified player name for a given unit token.
---@param unitToken string
---@return string|nil fullPlayerName
function addon.Communication:GetFullPlayerName(unitToken)
    return getFullPlayerName(unitToken)
end

---Returns the list of unit tokens for the current group, including the
---local player. Solo players get a single-entry list containing "player".
---@return table unitTokens
function addon.Communication:GetGroupUnitTokens()
    return getGroupUnitTokens()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        C_ChatInfo.RegisterAddonMessagePrefix(ADDON_MESSAGE_PREFIX)
        local isRegistered = C_ChatInfo.IsAddonMessagePrefixRegistered(ADDON_MESSAGE_PREFIX)
        addon.debugMessage("Communication: registered addon message prefix '" .. ADDON_MESSAGE_PREFIX
            .. "' (confirmed: " .. tostring(isRegistered) .. ")")
    elseif event == "GROUP_ROSTER_UPDATE" then
        addon.debugMessage("Communication: group roster changed, re-requesting keystones")
        addon.Communication:RequestGroupKeystones()
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, _, senderName = ...

        if prefix ~= ADDON_MESSAGE_PREFIX then
            return
        end

        addon.debugMessage("Communication: CHAT_MSG_ADDON prefix='" .. tostring(prefix)
            .. "' message='" .. tostring(message) .. "' sender='" .. tostring(senderName) .. "'")

        local senderFullPlayerName = senderName
        if senderFullPlayerName and not string.find(senderFullPlayerName, "-", 1, true) then
            senderFullPlayerName = senderFullPlayerName .. "-" .. GetNormalizedRealmName()
        end
        if senderFullPlayerName then
            handleIncomingMessage(message, senderFullPlayerName)
        end
    end
end)

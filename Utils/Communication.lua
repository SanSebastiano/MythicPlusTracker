local addonName, addon = ...

-- Addon message prefix used to exchange keystone information between
-- MythicPlusTracker installations within the same group.
local ADDON_MESSAGE_PREFIX = "MythicPlusTrackerKeys"

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
        message = "KEYSTONE:" .. mapID .. ":" .. level .. ":" .. score
    else
        message = "NOKEY:" .. score
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
    C_ChatInfo.SendAddonMessage(ADDON_MESSAGE_PREFIX, "REQUEST", channel)
end

local function handleIncomingMessage(message, senderFullPlayerName)
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

---Requests up-to-date keystone information from the current group and
---broadcasts the local player's own keystone status at the same time.
function addon.Communication:RequestGroupKeystones()
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
        addon.debugMessage("Communication: registered addon message prefix '" .. ADDON_MESSAGE_PREFIX .. "'")
    elseif event == "GROUP_ROSTER_UPDATE" then
        addon.debugMessage("Communication: group roster changed, re-requesting keystones")
        addon.Communication:RequestGroupKeystones()
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, _, senderName = ...

        addon.debugMessage("Communication: CHAT_MSG_ADDON prefix='" .. tostring(prefix)
            .. "' message='" .. tostring(message) .. "' sender='" .. tostring(senderName) .. "'")

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

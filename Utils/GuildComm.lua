local addonName, addon = ...

-- Addon message prefix used to exchange keystone information between
-- MythicPlusTracker installations across the whole guild (not just the
-- current group — see Utils/Communication.lua for that). Deliberately a
-- different prefix than "MPTrackerKeys" so the two protocols never collide.
-- Blizzard limits addon message prefixes to 16 characters (including the
-- null terminator, i.e. 15 visible characters).
local ADDON_MESSAGE_PREFIX = "MPTrackerGuild"

-- Leading version token on every message, matching the convention in
-- Utils/Communication.lua.
local PROTOCOL_VERSION = 1

local FIELD_SEP = ","
local ENTRY_SEP = "|"

-- Raw payload characters per BULK chunk. Blizzard caps a single addon
-- message at 255 characters; this leaves headroom for the
-- "<ver>:BULK:<dumpId>:<idx>/<total>:" header in front of the payload.
local BULK_CHUNK_SIZE = 200

-- Delay between successive chunk sends of the same bulk dump, so a large
-- dump doesn't trip Blizzard's addon-message send-rate throttle.
local BULK_CHUNK_DELAY_SECONDS = 0.15

-- Minimum time between two bulk dumps *this client* sends, regardless of
-- what triggered it (own login or a merge that learned something new from
-- someone else). Without this, a burst of incoming KEY/BULK messages could
-- each trigger their own immediate re-share, cascading through the guild.
local BULK_COOLDOWN_SECONDS = 120
local lastBulkBroadcastTime = 0

-- Reassembly buffers for in-progress BULK dumps, keyed by sender full name.
-- {dumpId, total, chunks = {[chunkIndex] = payload}, receivedCount}
local bulkBuffers = {}

-- Last own-keystone state actually sent to the guild, so broadcastOwnKeystone
-- can no-op when triggered by BAG_UPDATE_DELAYED without anything having
-- changed (that event fires on every inventory shuffle, not just keystone
-- swaps).
local lastBroadcastMapID, lastBroadcastLevel, lastBroadcastScore = nil, nil, nil

---@return boolean
local function isMaxLevel()
    return UnitLevel("player") >= GetMaxPlayerLevel()
end

---Encodes one guild entry as a comma-separated field list. Player/realm
---names can't contain "," or "|", so no escaping is needed.
---@param entry table
---@return string
local function encodeEntry(entry)
    return table.concat({
        entry.name or "",
        entry.realm or "",
        entry.class or "",
        entry.mapID or "",
        entry.level or "",
        entry.score or 0,
        entry.savedAt or 0,
        entry.resetEpoch or 0,
    }, FIELD_SEP)
end

---@param str string
---@return table|nil entry nil if str doesn't match the expected shape
local function decodeEntry(str)
    local name, realm, class, mapIDText, levelText, scoreText, savedAtText, resetEpochText =
        string.match(str, "^([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*)$")
    if not name or name == "" or not realm or realm == "" then
        return nil
    end

    return {
        name       = name,
        realm      = realm,
        class      = class ~= "" and class or nil,
        mapID      = tonumber(mapIDText),
        level      = tonumber(levelText),
        score      = tonumber(scoreText) or 0,
        savedAt    = tonumber(savedAtText) or 0,
        resetEpoch = tonumber(resetEpochText) or 0,
    }
end

---Sends the full locally known guild DB as a sequence of chunked BULK
---messages, so that data one member learned about a third party can spread
---to guild members who were never online with that third party directly.
local function broadcastGuildBulkDump()
    if not IsInGuild() then
        return
    end

    local entryStrings = {}
    for _, entry in pairs(MythicPlusTrackerGuildDB) do
        table.insert(entryStrings, encodeEntry(entry))
    end
    if #entryStrings == 0 then
        return
    end

    local fullPayload = table.concat(entryStrings, ENTRY_SEP)
    local dumpId = tostring(math.random(100000, 999999))

    local chunks = {}
    for chunkStart = 1, #fullPayload, BULK_CHUNK_SIZE do
        table.insert(chunks, string.sub(fullPayload, chunkStart, chunkStart + BULK_CHUNK_SIZE - 1))
    end

    addon.debugMessage("GuildComm: broadcasting bulk dump (" .. #entryStrings .. " entries, "
        .. #chunks .. " chunks, dumpId=" .. dumpId .. ")")

    for chunkIndex, chunk in ipairs(chunks) do
        C_Timer.After((chunkIndex - 1) * BULK_CHUNK_DELAY_SECONDS, function()
            local message = PROTOCOL_VERSION .. ":BULK:" .. dumpId .. ":" .. chunkIndex .. "/" .. #chunks
                .. ":" .. chunk
            C_ChatInfo.SendAddonMessage(ADDON_MESSAGE_PREFIX, message, "GUILD")
        end)
    end
end

---Triggers a bulk dump unless one was already sent within
---BULK_COOLDOWN_SECONDS, in which case the call is silently ignored. This is
---the only entry point that actually broadcasts a bulk dump — every trigger
---(login jitter, or having just merged new data from someone else) funnels
---through here.
local function requestBulkBroadcastIfDue()
    local now = GetTime()
    if now - lastBulkBroadcastTime < BULK_COOLDOWN_SECONDS then
        addon.debugMessage("GuildComm: bulk dump skipped (cooldown)")
        return
    end
    lastBulkBroadcastTime = now
    broadcastGuildBulkDump()
end

---Broadcasts the local player's own current keystone to the guild and
---merges it into the local guild DB, so it's included in this client's own
---Guild tab view and in future bulk dumps. Only max-level characters are
---broadcast, matching Utils/AltKeystones.lua's rule for what counts as a
---meaningful keystone owner.
local function broadcastOwnKeystone()
    if not IsInGuild() or not isMaxLevel() then
        return
    end

    local mapID, level = addon.Keystone:GetOwned()
    local score = C_ChallengeMode.GetOverallDungeonScore() or 0

    if mapID == lastBroadcastMapID and level == lastBroadcastLevel and score == lastBroadcastScore then
        return
    end
    lastBroadcastMapID, lastBroadcastLevel, lastBroadcastScore = mapID, level, score

    local _, englishClass = UnitClass("player")

    local entry = {
        name       = UnitName("player"),
        realm      = GetNormalizedRealmName(),
        class      = englishClass,
        mapID      = mapID,
        level      = level,
        score      = score,
        savedAt    = GetServerTime(),
        resetEpoch = C_DateAndTime.GetWeeklyResetStartTime(),
    }

    local changed = addon.GuildKeys:Merge(entry.name .. "-" .. entry.realm, entry)

    local message = PROTOCOL_VERSION .. ":KEY:" .. encodeEntry(entry)
    addon.debugMessage("GuildComm: sending own KEY '" .. message .. "'")
    C_ChatInfo.SendAddonMessage(ADDON_MESSAGE_PREFIX, message, "GUILD")

    if changed then
        requestBulkBroadcastIfDue()
    end
end

---@param payload string the part of a "<ver>:KEY:<payload>" message after "KEY:"
---@param senderFullPlayerName string
local function handleIncomingKey(payload, senderFullPlayerName)
    local entry = decodeEntry(payload)
    if not entry then
        addon.debugMessage("GuildComm: failed to decode KEY payload from "
            .. tostring(senderFullPlayerName) .. ": '" .. tostring(payload) .. "'")
        return
    end

    local changed = addon.GuildKeys:Merge(entry.name .. "-" .. entry.realm, entry)
    addon.debugMessage("GuildComm: received KEY from " .. tostring(senderFullPlayerName)
        .. " (mapID=" .. tostring(entry.mapID) .. ", level=" .. tostring(entry.level)
        .. ", changed=" .. tostring(changed) .. ")")

    if changed then
        requestBulkBroadcastIfDue()
    end
end

---Buffers one chunk of an incoming BULK dump; once every chunk for a given
---dumpId has arrived, reassembles the full payload, merges every entry, and
---(if anything actually changed) re-shares via requestBulkBroadcastIfDue so
---the newly learned data keeps propagating to whoever else is online.
---@param dumpId string
---@param chunkIndexText string
---@param chunkTotalText string
---@param chunkPayload string
---@param senderFullPlayerName string
local function handleIncomingBulkChunk(dumpId, chunkIndexText, chunkTotalText, chunkPayload, senderFullPlayerName)
    local chunkIndex = tonumber(chunkIndexText)
    local chunkTotal = tonumber(chunkTotalText)
    if not chunkIndex or not chunkTotal then
        return
    end

    local buffer = bulkBuffers[senderFullPlayerName]
    if not buffer or buffer.dumpId ~= dumpId then
        if buffer and buffer.receivedCount < buffer.total then
            addon.debugMessage("GuildComm: discarding incomplete bulk dump from "
                .. tostring(senderFullPlayerName) .. " (superseded by a new dump)")
        end
        buffer = { dumpId = dumpId, total = chunkTotal, chunks = {}, receivedCount = 0 }
        bulkBuffers[senderFullPlayerName] = buffer
    end

    if not buffer.chunks[chunkIndex] then
        buffer.chunks[chunkIndex] = chunkPayload
        buffer.receivedCount = buffer.receivedCount + 1
    end

    if buffer.receivedCount < buffer.total then
        return
    end

    bulkBuffers[senderFullPlayerName] = nil

    local fullPayload = table.concat(buffer.chunks, "", 1, buffer.total)
    local anyChanged = false
    for entryStr in string.gmatch(fullPayload, "([^|]+)") do
        local entry = decodeEntry(entryStr)
        if entry then
            if addon.GuildKeys:Merge(entry.name .. "-" .. entry.realm, entry) then
                anyChanged = true
            end
        end
    end

    addon.debugMessage("GuildComm: reassembled bulk dump from " .. tostring(senderFullPlayerName)
        .. " (" .. buffer.total .. " chunks)")

    if anyChanged then
        requestBulkBroadcastIfDue()
    end
end

---@param rawMessage string
---@param senderFullPlayerName string
local function handleIncomingMessage(rawMessage, senderFullPlayerName)
    local versionText, rest = string.match(rawMessage, "^(%d+):(.+)$")
    local version = tonumber(versionText)
    if not version or version ~= PROTOCOL_VERSION then
        addon.debugMessage("GuildComm: ignoring message with unknown/mismatched protocol version: "
            .. tostring(rawMessage))
        return
    end

    local keyPayload = string.match(rest, "^KEY:(.+)$")
    if keyPayload then
        handleIncomingKey(keyPayload, senderFullPlayerName)
        return
    end

    local dumpId, chunkIndexText, chunkTotalText, chunkPayload =
        string.match(rest, "^BULK:([^:]+):(%d+)/(%d+):(.*)$")
    if dumpId then
        handleIncomingBulkChunk(dumpId, chunkIndexText, chunkTotalText, chunkPayload, senderFullPlayerName)
        return
    end

    addon.debugMessage("GuildComm: received unrecognized message from "
        .. tostring(senderFullPlayerName) .. ": '" .. tostring(rest) .. "'")
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
-- Catches keystone changes that aren't a dungeon completion or a loading
-- screen, e.g. trading a timed-out key down at Lindormi.
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        C_ChatInfo.RegisterAddonMessagePrefix(ADDON_MESSAGE_PREFIX)
        local isRegistered = C_ChatInfo.IsAddonMessagePrefixRegistered(ADDON_MESSAGE_PREFIX)
        addon.debugMessage("GuildComm: registered addon message prefix '" .. ADDON_MESSAGE_PREFIX
            .. "' (confirmed: " .. tostring(isRegistered) .. ")")

    elseif event == "PLAYER_ENTERING_WORLD" then
        broadcastOwnKeystone()
        -- Jittered so a mass-login (e.g. raid invite) doesn't have everyone
        -- send their full bulk dump in the same instant.
        C_Timer.After(math.random(2, 8), requestBulkBroadcastIfDue)

    elseif event == "CHALLENGE_MODE_COMPLETED" then
        broadcastOwnKeystone()

    elseif event == "BAG_UPDATE_DELAYED" then
        broadcastOwnKeystone()

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

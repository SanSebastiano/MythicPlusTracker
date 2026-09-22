local addonName, addon = ...

-- LibKeystone (https://github.com/BigWigsMods/LibKeystone) is the de-facto
-- standard keystone exchange in the addon ecosystem: DBM ships a copy, and it
-- is also published as a standalone addon. Reading it lets the Keystones tab
-- fill rows for players who run one of those addons but not this one.
--
-- It is deliberately NOT bundled with MythicPlusTracker. The library carries no
-- license file, and its intended embedding path is a packager build step this
-- addon doesn't have. It is therefore resolved at runtime only, declared as
-- "## OptionalDeps: LibKeystone" in the .toc, and every function below degrades
-- to a no-op when no provider is installed.
--
-- This is the only file in the addon that knows LibKeystone exists. The native
-- MPTrackerKeys/MPTrackerGuild protocols (GroupKeystoneService,
-- GuildKeystoneService) are untouched and always take precedence — they carry a
-- RAID channel and an explicit "has the addon but no key" signal that
-- LibKeystone has no equivalent for.
local LIBRARY_NAME = "LibKeystone"

-- The library throttles its own sends to 3 seconds per channel and queues a
-- catch-up timer for anything faster. Matching that here keeps our render paths
-- from stacking timers inside third-party code (CODING_GUIDELINES 11.2.1).
local REQUEST_COOLDOWN_SECONDS = 3

-- The only two channels the library accepts. Anything else makes its Request
-- function raise a Lua error rather than return a status.
local SUPPORTED_CHANNELS = {
    PARTY = true,
    GUILD = true,
}

-- The resolved library, or nil for the whole session when none is installed.
local library

-- Keyed by realm-qualified player name, the same key GroupKeystoneService and
-- GuildKeystoneService use, so the three stores join without translation.
-- In-memory only, like both native stores (see AGENTS.md, SavedVariables).
local keystonesByPlayerName = {}

local lastRequestTimeByChannel = {}

---Stores one incoming keystone report.
---
---The library reports 0 for "no key" and "no rating" where this addon uses nil.
---That distinction matters: KeystoneEntryService:computeStatistics skips nil
---scores but would average a 0 in, dragging the group average toward zero.
---
---Values arrive from other players, so they are treated as untrusted even
---though the library already pattern-matches them (CODING_GUIDELINES 13.2.1).
---@param keyLevel number
---@param challengeMapID number
---@param playerRating number
---@param senderName string short name on the same realm, "Name-Realm" otherwise
---@param channel string "PARTY" or "GUILD"
local function handleKeystoneReceived(keyLevel, challengeMapID, playerRating, senderName, channel)
    if type(keyLevel) ~= "number" or type(challengeMapID) ~= "number" or type(playerRating) ~= "number" then
        return
    end

    -- Ambiguate(name, "none") — what the library sends — drops the realm for
    -- same-realm players and keeps "Name-Realm" for everyone else. That is
    -- exactly what qualifyRealm expects.
    local fullPlayerName = type(senderName) == "string" and addon.Player:qualifyRealm(senderName)
    if not fullPlayerName then
        return
    end

    addon.debugMessage("ExternalKeystoneService: received keystone from " .. fullPlayerName
        .. " via " .. tostring(channel) .. " (mapID " .. challengeMapID
        .. ", level " .. keyLevel .. ", rating " .. playerRating .. ")")

    keystonesByPlayerName[fullPlayerName] = {
        mapID     = challengeMapID > 0 and challengeMapID or nil,
        level     = keyLevel > 0 and keyLevel or nil,
        score     = playerRating > 0 and playerRating or nil,
        hasAddon  = true,
        timestamp = GetServerTime(),
    }
end

addon.ExternalKeystoneService = addon.ExternalKeystoneService or {}

---Asks everyone on the channel to report their keystone. Responses arrive
---asynchronously and land in the store, so the caller renders whatever is
---already known and picks the rest up on the next render.
---
---Calls within REQUEST_COOLDOWN_SECONDS of the previous one for the same
---channel are silently ignored.
---@param channel string "PARTY" or "GUILD"
function addon.ExternalKeystoneService:requestKeystones(channel)
    if not library then
        return
    end

    if not SUPPORTED_CHANNELS[channel] then
        addon.debugMessage("ExternalKeystoneService: ignoring request for unsupported channel " .. tostring(channel))
        return
    end

    local now = GetTime()
    if now - (lastRequestTimeByChannel[channel] or 0) < REQUEST_COOLDOWN_SECONDS then
        addon.debugMessage("ExternalKeystoneService: requestKeystones skipped for " .. channel .. " (cooldown)")
        return
    end
    lastRequestTimeByChannel[channel] = now

    -- The library raises Lua errors instead of returning a status. A fault in
    -- third-party code must not take the render path down with it
    -- (CODING_GUIDELINES 14.2.2).
    local succeeded, requestError = pcall(library.Request, channel)
    if not succeeded then
        addon.debugMessage("ExternalKeystoneService: LibKeystone request failed: " .. tostring(requestError))
    end
end

---The keystone last reported by one player, or nil if nothing has been heard
---from them. Callers must prefer their native MythicPlusTracker data and only
---fall back to this.
---
---timestamp is what the Keystones tab uses to mark the value as external and to
---show when it arrived, so it must stay set for every stored entry.
---@param fullPlayerName string realm-qualified, see addon.Player:qualifyRealm
---@return table|nil keystoneInfo { mapID, level, score, hasAddon, timestamp }
function addon.ExternalKeystoneService:getKeystone(fullPlayerName)
    return keystonesByPlayerName[fullPlayerName]
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function()
    -- Resolved at login rather than at file load: "## OptionalDeps" only orders
    -- the standalone LibKeystone addon ahead of this one. A copy embedded in
    -- another addon (DBM ships one) is only reliably present once every addon
    -- has finished loading.
    if not LibStub then
        addon.debugMessage("ExternalKeystoneService: LibStub not present, LibKeystone interop disabled")
        return
    end

    -- The second argument silences LibStub's error when nothing provides it.
    library = LibStub:GetLibrary(LIBRARY_NAME, true)
    if not library then
        addon.debugMessage("ExternalKeystoneService: LibKeystone not installed, interop disabled")
        return
    end

    -- The library identifies callers by the table they pass in; the addon table
    -- is unique to this addon and is what an Unregister would key on.
    local succeeded, registrationError = pcall(library.Register, addon, handleKeystoneReceived)
    if not succeeded then
        library = nil
        addon.debugMessage("ExternalKeystoneService: LibKeystone registration failed: " .. tostring(registrationError))
        return
    end

    addon.debugMessage("ExternalKeystoneService: LibKeystone interop active")
end)

local addonName, addon = ...

-- Dynamically resolves the known teleport spell ("Path of ...") for each
-- current Mythic+ season dungeon, without maintaining a hardcoded
-- mapID -> spellID table per season. These teleports turned out to be
-- normal spellbook spells (not Toy Box toys), so this scans the player's
-- spellbook and matches each known spell against the dungeon.
--
-- Matching happens in two passes:
--   1. Icon match: Blizzard reuses the same dungeon icon (textureFileID
--      from C_ChallengeMode.GetMapUIInfo) as the teleport spell's icon
--      (C_Spell.GetSpellTexture). Icons are always available client-side
--      (no data-load wait needed), so this resolves most dungeons instantly.
--   2. Description match (fallback): matches a candidate spell's
--      description text against the localized dungeon name. Spell
--      descriptions are not always loaded client-side yet (especially for
--      obscure teleport spells nobody has ever hovered), so this pass
--      requests the missing data via C_Spell.RequestLoadSpellData and
--      waits for SPELL_DATA_LOAD_RESULT before matching.
--
-- Result table, keyed by mapChallengeModeID:
--   addon.dungeonTeleports[mapID] = { spellID = number }
addon.dungeonTeleports = addon.dungeonTeleports or {}

-- Bump whenever the cached teleport entry shape changes, or whenever the
-- matching logic changes in a way that could produce different results, to
-- invalidate any stale SavedVariables cache built by a previous version of
-- this scan.
local CACHE_FORMAT_VERSION = 3

local isScanning = false
local hasScanned = false

-- Callbacks waiting for addon.dungeonTeleports to be populated (e.g. UI
-- panels that rendered before the async spell-data load finished).
local readyCallbacks = {}

local pendingSpellIDs = {}
local pendingDungeons, pendingCandidates, pendingTeleports, pendingDungeonSetKey

---Realm-qualified key identifying the current character within the shared,
---account-wide MythicPlusTrackerDB.dungeonTeleportCache table. Teleport
---availability is character-specific (e.g. class-locked "Path of ..."
---spells), so each character caches its own scan result under its own key
---rather than sharing/overwriting a single account-wide entry.
---@return string
local function getCharacterKey()
    return UnitName("player") .. "-" .. GetNormalizedRealmName()
end

---@param callback function
function addon.onDungeonTeleportsReady(callback)
    if hasScanned then
        callback()
    else
        table.insert(readyCallbacks, callback)
    end
end

local function notifyReady()
    local callbacks = readyCallbacks
    readyCallbacks = {}
    for _, callback in ipairs(callbacks) do
        callback()
    end
end

---Builds a sorted, comma-joined key representing the current set of season
---dungeon mapIDs, used to detect season changes for cache invalidation.
---@param dungeons table array of mapChallengeModeID
---@return string
local function buildDungeonSetKey(dungeons)
    local ids = {}
    for i, mapID in ipairs(dungeons) do
        ids[i] = mapID
    end
    table.sort(ids)
    return table.concat(ids, ",")
end

---@param spellID number
---@param dungeonName string
---@return boolean
local function spellMatchesDungeon(spellID, dungeonName)
    local description = C_Spell.GetSpellDescription(spellID)
    if not description or description == "" then
        return false
    end
    return description:lower():find(dungeonName:lower(), 1, true) ~= nil
end

---Flyouts and future (not-yet-learned) spells are skipped.
---@return table candidates array of { spellID = number, icon = number }
local function collectSpellbookCandidates()
    local candidates = {}

    for skillLine = 1, C_SpellBook.GetNumSpellBookSkillLines() do
        local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(skillLine)
        if skillLineInfo then
            local offset, numSlots = skillLineInfo.itemIndexOffset, skillLineInfo.numSpellBookItems
            for slot = offset + 1, offset + numSlots do
                local itemInfo = C_SpellBook.GetSpellBookItemInfo(slot, Enum.SpellBookSpellBank.Player)
                if itemInfo and itemInfo.itemType == Enum.SpellBookItemType.Spell and itemInfo.actionID then
                    table.insert(candidates, {
                        spellID = itemInfo.actionID,
                        icon = C_Spell.GetSpellTexture(itemInfo.actionID),
                    })
                end
            end
        end
    end

    addon.debugMessage("DungeonTeleports: found " .. #candidates .. " spellbook candidates")
    return candidates
end

---Matches remaining candidates by description text (icon matches were
---already resolved by matchByIcon). Called once every remaining candidate
---spell's description data has finished loading.
---@param dungeons table
---@param candidates table array of { spellID, icon }
---@param teleports table teleports already resolved via icon matching
---@param dungeonSetKey string
local function finalizeCache(dungeons, candidates, teleports, dungeonSetKey)
    for _, mapID in ipairs(dungeons) do
        if not teleports[mapID] then
            local name = C_ChallengeMode.GetMapUIInfo(mapID)
            if name and name ~= "" then
                for _, candidate in ipairs(candidates) do
                    if spellMatchesDungeon(candidate.spellID, name) then
                        teleports[mapID] = { spellID = candidate.spellID }
                        addon.debugMessage("DungeonTeleports: matched " .. name .. " (mapID "
                            .. mapID .. ") to spell " .. candidate.spellID .. " by description")
                        break
                    end
                end
            end
            if not teleports[mapID] then
                addon.debugMessage("DungeonTeleports: no teleport found for " .. tostring(name)
                    .. " (mapID " .. mapID .. ")")
            end
        end
    end

    addon.dungeonTeleports = teleports

    -- Discard a pre-migration (flat, single account-wide entry) cache shape
    -- from an older addon version rather than trying to interpret it as
    -- per-character data — it gets rebuilt below, once per character.
    if not MythicPlusTrackerDB.dungeonTeleportCache or MythicPlusTrackerDB.dungeonTeleportCache.formatVersion then
        MythicPlusTrackerDB.dungeonTeleportCache = {}
    end
    MythicPlusTrackerDB.dungeonTeleportCache[getCharacterKey()] = {
        formatVersion = CACHE_FORMAT_VERSION,
        dungeonSetKey = dungeonSetKey,
        teleports = teleports,
    }

    hasScanned = true
    isScanning = false
    notifyReady()
end

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(_, event, spellID)
    if event ~= "SPELL_DATA_LOAD_RESULT" or not pendingSpellIDs[spellID] then
        return
    end

    pendingSpellIDs[spellID] = nil
    if next(pendingSpellIDs) == nil then
        eventFrame:UnregisterEvent("SPELL_DATA_LOAD_RESULT")
        finalizeCache(pendingDungeons, pendingCandidates, pendingTeleports, pendingDungeonSetKey)
    end
end)

---Matches candidate spell icons against dungeon icons. Blizzard reuses the
---same icon for a dungeon's Mythic+ UI entry and its "Path of ..." teleport
---spell, so this resolves most dungeons instantly without waiting on any
---spell data to load.
---@param dungeons table
---@param candidates table array of { spellID, icon }
---@return table teleports keyed by mapID
local function matchByIcon(dungeons, candidates)
    local teleports = {}
    for _, mapID in ipairs(dungeons) do
        local name, icon = C_ChallengeMode.GetMapUIInfo(mapID)
        if icon then
            for _, candidate in ipairs(candidates) do
                if candidate.icon == icon then
                    teleports[mapID] = { spellID = candidate.spellID }
                    addon.debugMessage("DungeonTeleports: matched " .. tostring(name) .. " (mapID "
                        .. mapID .. ") to spell " .. candidate.spellID .. " by icon")
                    break
                end
            end
        end
    end
    return teleports
end

---Builds addon.dungeonTeleports for the currently available season dungeons
---by matching known spellbook spells against each dungeon, first by shared
---icon (instant, no data-load wait needed), then by description text for
---any dungeon that couldn't be resolved that way. Caches the result in
---MythicPlusTrackerDB so the spellbook scan only runs again when the
---season's dungeon set changes.
function addon.buildDungeonTeleportCache()
    if isScanning or hasScanned then
        return
    end
    isScanning = true

    local dungeons = C_ChallengeMode.GetMapTable()
    if not dungeons or #dungeons == 0 then
        isScanning = false
        return
    end

    local dungeonSetKey = buildDungeonSetKey(dungeons)

    MythicPlusTrackerDB = MythicPlusTrackerDB or {}
    local allCaches = MythicPlusTrackerDB.dungeonTeleportCache
    -- A truthy formatVersion at this level means it's the old, pre-migration
    -- flat shape (not keyed by character) — ignore it and rescan instead.
    local cache = allCaches and not allCaches.formatVersion and allCaches[getCharacterKey()]
    if cache and cache.formatVersion == CACHE_FORMAT_VERSION
        and cache.dungeonSetKey == dungeonSetKey and cache.teleports then
        addon.dungeonTeleports = cache.teleports
        hasScanned = true
        isScanning = false
        return
    end

    local candidates = collectSpellbookCandidates()
    local teleports = matchByIcon(dungeons, candidates)

    local unresolvedCount = 0
    for _, mapID in ipairs(dungeons) do
        if not teleports[mapID] then
            unresolvedCount = unresolvedCount + 1
        end
    end

    if unresolvedCount == 0 then
        finalizeCache(dungeons, candidates, teleports, dungeonSetKey)
        return
    end

    local pending = {}
    for _, candidate in ipairs(candidates) do
        if not C_Spell.IsSpellDataCached(candidate.spellID) then
            pending[candidate.spellID] = true
            C_Spell.RequestLoadSpellData(candidate.spellID)
        end
    end

    if next(pending) == nil then
        finalizeCache(dungeons, candidates, teleports, dungeonSetKey)
        return
    end

    pendingSpellIDs      = pending
    pendingDungeons       = dungeons
    pendingCandidates     = candidates
    pendingTeleports      = teleports
    pendingDungeonSetKey  = dungeonSetKey
    eventFrame:RegisterEvent("SPELL_DATA_LOAD_RESULT")
end

---@param mapID number
---@return table|nil teleport { spellID }
function addon.getDungeonTeleport(mapID)
    if not hasScanned then
        addon.buildDungeonTeleportCache()
    end
    return addon.dungeonTeleports[mapID]
end

local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function()
    addon.buildDungeonTeleportCache()
    loginFrame:UnregisterEvent("PLAYER_LOGIN")
end)

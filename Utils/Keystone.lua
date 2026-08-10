local addonName, addon = ...

addon.Keystone = addon.Keystone or {}

---Returns the local player's currently owned keystone, or nils if none.
---@return number|nil mapID
---@return number|nil level
---@return string|nil dungeonName
---@return string|nil dungeonTexture
function addon.Keystone:GetOwned()
    local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    if not mapID or not level then
        return nil, nil, nil, nil
    end

    local name, _, _, texture = C_ChallengeMode.GetMapUIInfo(mapID)
    return mapID, level, name, texture
end

---Formats the owned keystone as "<Dungeon Name> +<Level>", or nil if none owned.
---@return string|nil
function addon.Keystone:FormatOwned()
    local mapID, level, name = self:GetOwned()
    if not mapID or not name then
        return nil
    end
    return string.format("%s +%d", name, level)
end

---Determines which SendChatMessage channel reaches the player's current
---group. Instance groups (e.g. Group Finder Mythic+ parties) restrict
---delivery to INSTANCE_CHAT instead of the normal PARTY/RAID channels.
---@return string|nil channel
local function getAnnounceChannel()
    local isInstanceGroup = IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
    if IsInRaid() then
        return isInstanceGroup and "INSTANCE_CHAT" or "RAID"
    elseif IsInGroup() then
        return isInstanceGroup and "INSTANCE_CHAT" or "PARTY"
    end
    return nil
end

---Posts the local player's current keystone into the group's chat channel.
---Prints a local error instead of doing nothing silently if solo or if no
---keystone is owned.
function addon.Keystone:AnnounceToGroup()
    local channel = getAnnounceChannel()
    if not channel then
        addon.errorMessage(addon.locale["KEYSTONE_ANNOUNCE_NOT_IN_GROUP"])
        return
    end

    local formatted = self:FormatOwned()
    if not formatted then
        addon.errorMessage(addon.locale["KEYSTONE_ANNOUNCE_NO_KEYSTONE"])
        return
    end

    SendChatMessage(string.format(addon.locale["KEYSTONE_ANNOUNCE_MESSAGE"], formatted), channel)
end

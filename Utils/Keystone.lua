local addonName, addon = ...

addon.Keystone = addon.Keystone or {}

local KEYSTONE_ITEM_ID = 180653

local function findInBags()
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            if C_Container.GetContainerItemID(bag, slot) == KEYSTONE_ITEM_ID then
                return bag, slot
            end
        end
    end
end

---Returns the bag/slot of the owned keystone item, or nil if it isn't a
---physical bag item (e.g. account-wide virtual keystone tracking).
---@return number|nil bag
---@return number|nil slot
function addon.Keystone:FindInBags()
    return findInBags()
end

---Returns a clickable item link for the owned keystone, or nil if it has
---no physical bag item to link.
---@return string|nil
function addon.Keystone:GetItemLink()
    local bag, slot = findInBags()
    if not bag then
        return nil
    end
    return C_Container.GetContainerItemLink(bag, slot)
end

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

    local link = self:GetItemLink()
    local announceText = link or formatted

    SendChatMessage(string.format(addon.locale["KEYSTONE_ANNOUNCE_MESSAGE"], announceText), channel)
end

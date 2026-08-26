local addonName, addon = ...

addon.Player = addon.Player or {}

---Realm-qualified key identifying the current character ("Name-Realm").
---
---This exact format is the join key between three otherwise unrelated data
---sources: the per-character snapshots in MythicPlusTrackerAltDB, the guild
---roster scan, and the sender names on incoming addon messages. If any of
---them built the key differently, alt filtering and keystone lookups would
---mismatch silently — no error, just missing or duplicated rows. Hence one
---implementation.
---@return string
function addon.Player:getCharacterKey()
    return UnitName("player") .. "-" .. GetNormalizedRealmName()
end

---Appends the local realm to a bare character name, leaving already-qualified
---names untouched. Same-realm addon-message senders and same-realm guild
---roster entries arrive without a realm suffix; cross-realm (connected-realm)
---ones already carry one.
---@param name string|nil
---@return string|nil qualifiedName nil in, nil out
function addon.Player:qualifyRealm(name)
    if not name then
        return nil
    end
    if string.find(name, "-", 1, true) then
        return name
    end
    return name .. "-" .. GetNormalizedRealmName()
end

---Whether the played character is at the current expansion's level cap. Gates
---both the Dashboard's tab content and what counts as a meaningful keystone
---owner for the Twinks and Guild views.
---@return boolean
function addon.Player:isMaxLevel()
    return UnitLevel("player") >= GetMaxPlayerLevel()
end

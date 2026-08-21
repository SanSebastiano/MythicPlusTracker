local addonName, addon = ...

-- mapChallengeModeID -> this season's "Path of ..." teleport spell.
-- Confirmed directly from Wowhead spell pages and cross-checked against a
-- running client's C_ChallengeMode.GetMapUIInfo() output. Bump each season.
-- Midnight Season 2 (patch 12.1):
local SEASON_TELEPORTS = {
    [249] = 1286831, -- Kings' Rest / Die Königsruh: Path of the Slumbering Conqueror
    [250] = 1286828, -- Temple of Sethraliss / Der Tempel von Sethraliss: Path of the Sacred Temple
    [399] = 393256,  -- Ruby Life Pools / Rubinlebensbecken: Path of the Clutch Defender
    [584] = 1286801, -- The Blinding Vale / Das blendende Tal: Path of the Blooming Verdure
    [585] = 1286804, -- Voidscar Arena / Arena der Leerennarbe: Path of the Brutal Combatant
    [586] = 1286807, -- Den of Nalorakk / Nalorakks Bau: Path of the Worthy Aspirant
    [587] = 1286809, -- Murder Row / Mördergasse: Path of the Devious Smuggler
    [588] = 1286812, -- Altar of Fangs / Altar der Fänge: Path of Venomous Evolution
}

---Returns the known teleport for mapID, but only if the player actually
---owns it — checked fresh on every call (no caching), since IsSpellKnown is
---already instant and this only ever runs while rendering a visible panel.
---@param mapID number
---@return table|nil teleport { spellID }
function addon.getDungeonTeleport(mapID)
    local spellID = SEASON_TELEPORTS[mapID]
    if spellID and C_SpellBook.IsSpellKnown(spellID) then
        return { spellID = spellID }
    end
    return nil
end

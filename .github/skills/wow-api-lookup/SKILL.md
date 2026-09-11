---
name: wow-api-lookup
description: Looks up WoW API documentation for a specific function, method, namespace, or event name. Use whenever you need the exact signature, parameters, return values, or usage notes for any World of Warcraft Lua API — for example C_MythicPlus, C_ChallengeMode, CreateFrame, or any game event.
---

# WoW API Lookup

**warcraft.wiki.gg** is the source: prose, examples, patch history, and community notes on quirks and deprecations.

## Steps

### Quick lookup

```bash
bash Tools/wow-api-lookup.sh <API_NAME>
```

```bash
bash Tools/wow-api-lookup.sh C_MythicPlus.GetRunHistory
bash Tools/wow-api-lookup.sh CHALLENGE_MODE_MAPS_UPDATE
bash Tools/wow-api-lookup.sh CreateFrame
```

The script resolves the page title itself. Worth knowing if you fetch by hand: the wiki puts API functions under an `API_` prefix (`API_C_ChallengeMode.GetMapTable`) but events under the bare name (`CHALLENGE_MODE_MAPS_UPDATE`).

### Browsing warcraft.wiki.gg

- **Full API index**: https://warcraft.wiki.gg/wiki/World_of_Warcraft_API
- **Events index**: https://warcraft.wiki.gg/wiki/Events
- **Widget API**: https://warcraft.wiki.gg/wiki/Widget_API

## Key Namespaces Used in This Addon

| Namespace | Purpose |
|-----------|---------|
| `C_MythicPlus` | Run history, season scores, key levels |
| `C_ChallengeMode` | Dungeon map info, time limits, affixes |
| `C_CurrencyInfo` | Currency IDs and amounts |
| `C_WeeklyRewards` | Weekly vault slots and progress |
| `C_PlayerInfo` | Player level, spec, class info |

## Important Notes

- This addon targets **Interface 120100** (patch 12.1.0, Midnight) — see `MythicPlusTracker.toc`.
- WoW uses **Lua 5.1** — standard library differences apply.
- Deprecated APIs may still work but should be replaced with current equivalents.

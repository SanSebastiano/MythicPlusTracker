---
name: wow-api-lookup
description: Looks up WoW API documentation for a specific function, method, namespace, or event name. Use whenever you need the exact signature, parameters, return values, or usage notes for any World of Warcraft Lua API — for example C_MythicPlus, C_ChallengeMode, CreateFrame, or any game event.
---

# WoW API Lookup

Fetches authoritative documentation from **warcraft.wiki.gg** for WoW Lua API functions, events, and namespaces.

## Steps

### Quick lookup (single item)

Use the `web_fetch` tool or the shell script:

```bash
bash Tools/wow-api-lookup.sh <API_NAME>
```

Examples:
```bash
bash Tools/wow-api-lookup.sh C_MythicPlus.GetRunHistory
bash Tools/wow-api-lookup.sh C_ChallengeMode.GetMapTable
bash Tools/wow-api-lookup.sh CHALLENGE_MODE_MAPS_UPDATE
bash Tools/wow-api-lookup.sh CreateFrame
```

URL pattern: `https://warcraft.wiki.gg/wiki/<API_NAME>`

### Browsing

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

- This addon targets **Interface 120001** (Midnight expansion)
- WoW uses **Lua 5.1** — standard library differences apply
- Always verify on warcraft.wiki.gg — some APIs change between expansions
- Deprecated APIs may still work but should be replaced with current equivalents

---
name: registration-validator
description: Validates that every .lua file in MythicPlusTracker is actually referenced from a .toc or .xml load-order manifest. Use after moving, renaming, or adding Lua files — an unregistered file produces no error in-game, it simply never runs.
allowed-tools: shell
---

# Registration Validator

The inverse of `toc-validator`. That one asks "does every referenced file exist?"; this one asks "is every existing file referenced?".

An unregistered `.lua` file is the quietest failure mode in this addon: the WoW client reports nothing, `luacheck` reports nothing, and `toc-validator` reports nothing. The file simply never executes, so whatever it defined is silently missing at runtime.

## Steps

Run the validator script from the repository root:

```bash
bash Tools/registration-validator.sh
```

## Output

- `All 43 .lua files are registered.` — nothing orphaned
- `UNREGISTERED  Modules/Tracker/NewFile.lua` — file exists but no manifest references it

Exit code `1` if any unregistered files are detected.

## Fixing Issues

Add a `<Script file='...'/>` line for the file in the `.xml` manifest that owns its directory, at the position its load order requires (see `AGENTS.md`). If the file is genuinely obsolete, delete it instead.

## Notes

- Paths are compared in full, not by basename — `Services/KeystoneService.lua` and `Sidebar/Content/KeystoneCard.lua` are distinct even where names are similar.
- `Locales/*.lua` are covered too; they are registered via `Locales/locales.xml`.
- `.git`, `.idea` and `.luarocks` are excluded.

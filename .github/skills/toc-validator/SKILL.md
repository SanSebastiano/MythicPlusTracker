---
name: toc-validator
description: Validates that every file referenced in MythicPlusTracker.toc and in all .xml files actually exists on disk. Use after adding, renaming, or deleting Lua files, when debugging WoW client load errors, or to verify the load order is consistent.
allowed-tools: shell
---

# TOC / XML Validator

Checks that every file listed in `MythicPlusTracker.toc` and every `<Include>` / `<Script>` tag in all `.xml` files points to a file that actually exists.

## Steps

Run the validator script from the repository root:

```bash
bash tools/toc-validator.sh
```

## Output

- `OK   init.lua` — file exists
- `MISSING  Modules/NewFile.lua` — file referenced but not found

Exit code `1` if any missing references are detected.

## Fixing Issues

**Missing in .toc** — either create the file or remove the line from `MythicPlusTracker.toc`.

**Missing in .xml** — either create the file or remove the `<Include file='...'/>` / `<Script file='...'/>` line from the relevant `.xml` file.

## Load Order Rules (Critical)

The WoW client loads files in the exact order they appear in `.toc` and `.xml`:

```
init.lua                → addon namespace
Locales/locales.xml     → addon.locale populated
Utils/utils.xml         → addon.colors, helpers
MythicPlusTracker.lua   → event registration
Command/comands.xml     → slash commands
Modules/modules.xml     → all UI modules
```

A file **must** be declared before any other file that references its globals. If you add a new file, register it at the correct position.

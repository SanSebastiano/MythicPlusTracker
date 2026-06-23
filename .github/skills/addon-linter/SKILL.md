---
name: addon-linter
description: Lints all Lua files in the MythicPlusTracker WoW addon using luacheck with WoW-specific globals configured in .luacheckrc. Use when asked to lint, check for errors, validate Lua code, run the addon linter, or check for undefined globals.
allowed-tools: shell
---

# Addon Linter — WoW Lua Static Analysis

Runs `luacheck` on all Lua files in the repository. The `.luacheckrc` at the repo root configures `std = "lua51"` and whitelists all WoW API globals so only genuine issues are reported.

## Steps

1. Ensure luacheck is installed:
   ```bash
   which luacheck || sudo luarocks install luacheck
   ```

2. Run from the repository root:
   ```bash
   luacheck .
   ```

3. Report findings grouped by file.

## Interpreting Results

- **W011 – unused variable**: Often the `addonName` in `local addonName, addon = ...` — safe to ignore or suppress with `---@diagnostic disable`
- **W111/W112 – undefined global**: If it's a real WoW API missing from the whitelist, add it to the `globals` list in `.luacheckrc`
- **E**: Syntax errors — must always be fixed

## Common WoW Globals Not Yet in .luacheckrc

If luacheck reports a global as undefined but you know it's a valid WoW API, add it to the `globals` table in `.luacheckrc` and document it with a comment.

## Reference

Full WoW API index: https://warcraft.wiki.gg/wiki/World_of_Warcraft_API

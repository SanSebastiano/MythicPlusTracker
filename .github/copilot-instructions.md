# MythicPlusTracker — Copilot Instructions

## What This Is

A World of Warcraft retail addon (Interface version 120001, Midnight) that tracks Mythic+ dungeon runs. Pure Lua, no build tools or test runners — loaded directly by the WoW client.

## Loading Order (Critical)

Files load in the exact order declared in `.toc` and `.xml` files. **Load order determines what globals exist when each file runs.**

```
init.lua                  → defines _G["MPT"] = addon, addon.locale = {}
Locales/locales.xml       → populates addon.locale
Utils/utils.xml           → defines addon.colors, addon.debugMessage, addon.addonMessage, etc.
MythicPlusTracker.lua     → main MPT namespace, registers ADDON_LOADED / PLAYER_LOGIN
Command/comands.xml       → registers /mpt and /mythicplustracker slash commands
Modules/modules.xml       → loads all UI modules (read the file for exact order)
```

The load order within `Modules/modules.xml` is critical for globals — read the file before adding new entries. If you add a new file, register it in the correct `.xml` or `.toc` file **at the right position**.

## Namespace & Global Pattern

Every `.lua` file starts with `local addonName, addon = ...`

- `addon` is the primary shared namespace (attach utilities and state to it).
- Module globals use `MPT_*` prefix (e.g., `MPT_MAIN`, `MPT_Dashboard`, `MPT_Sidebar`), initialized as empty tables in `init.lua` files and extended in subsequent files.
- `_G["MPT"] = addon` makes the table globally accessible as `MPT`.

## Saved Variables

`MythicPlusTrackerDB` is the single SavedVariables table (declared in `.toc`). All persistent state goes here.

## Messaging Utilities (`Utils/MessageHandler.lua`)

Never use `print()` directly. Use `addon.*Message()` helpers: `addonMessage`, `chatMessage`, `errorMessage`, `successMessage`, `warningMessage`, `infoMessage`, `debugMessage` (only prints when debug mode is on).

## Color System (`Utils/ColorHandler.lua`)

Colors are WoW UI escape codes in `addon.colors`. Never hardcode `|cFF...` strings. Key groups: item quality (`POOR`…`LEGENDARY`), keystone levels (`KEYSTONE_LEVEL_LOW/MID/HIGH/VERY_HIGH`), UI states (`ERROR`, `SUCCESS`, `WARNING`, `INFO`). Always close with `addon.colors.RESET` (`|r`).

## Debug Mode

Toggle with `/mpt debug [on|off]`. State persists via `MythicPlusTrackerDB.debugMode`. `addon.isDebugMode` is truthy when active.

## UI Architecture

Three frames anchored together: **MainFrame** (root, draggable), **Dashboard** (`TOPRIGHT`; dungeon grid), **Sidebar** (`TOPLEFT`; M+ score and currencies). Frames use `BackdropTemplate` with WoW's dark dialog background texture. See the source files for exact dimensions and atlas names.

## Localization

Strings live in `Locales/en-US.lua` (and `de-DE.lua`). Access via `addon.locale["KEY"]`. Add new strings to **all** locale files when introducing user-facing text.

## Slash Commands

Registered as `/mpt` and `/mythicplustracker`. Handler: `Command/MythicPlusTrackerCommand.lua`. Add new commands with `elseif command == "..."` and update the help text block.

## WoW API Reference

**https://warcraft.wiki.gg/wiki/World_of_Warcraft_API** — authoritative reference for all WoW addon APIs.

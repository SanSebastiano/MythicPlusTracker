# MythicPlusTracker — Copilot Instructions

## What This Is

A World of Warcraft retail addon (Interface version 120001, Midnight) that tracks Mythic+ dungeon runs. It adds a minimap button that opens a dashboard with dungeon stats and a sidebar showing the player's M+ score and currencies.

There are no build tools, package managers, or test runners — this is pure Lua loaded directly by the WoW client.

## Loading Order (Critical)

WoW addons load files in the exact order declared in `.toc` and `.xml` files. **Load order determines what globals exist when each file runs.**

```
init.lua                  → defines _G["MPT"] = addon, addon.locale = {}
Locales/locales.xml       → populates addon.locale
Utils/utils.xml           → defines addon.colors, addon.debugMessage, addon.addonMessage, etc.
MythicPlusTracker.lua     → main MPT namespace, registers ADDON_LOADED / PLAYER_LOGIN
Command/comands.xml       → registers /mpt and /mythicplustracker slash commands
Modules/modules.xml       → loads all UI modules (see below)
```

`Modules/modules.xml` load order matters for globals:

```
Tracker/MainFrame.lua         → defines MPT_MAIN global
Tracker/Dashboard/init.lua    → defines MPT_Dashboard global
Tracker/Dashboard/Frame.lua   → extends MPT_Dashboard
Tracker/Sidebar/init.lua      → defines MPT_Sidebar global
Tracker/Sidebar/Content/Currency.lua  → attaches MPT_Sidebar.getCurrencies
Tracker/Sidebar/Content/Score.lua     → attaches MPT_Sidebar.getScore
Tracker/Sidebar/Frame.lua     → extends MPT_Sidebar (calls getCurrencies/getScore)
Tracker/MinimapButton.lua     → defines MPT_MinimapButton; depends on MPT_MAIN, MPT_Dashboard, MPT_Sidebar
Tracker/init.lua              → calls MPT_MinimapButton:load()
WelcomeMessage/inti.lua       → [note: filename typo] shows welcome message on load
```

If you add a new file, register it in the correct `.xml` or `.toc` file **at the right position**.

## Namespace & Global Pattern

Every `.lua` file starts with:
```lua
local addonName, addon = ...
```

- `addon` is the shared addon table (the second vararg passed by WoW's loader). It is the primary namespace — attach utilities and state to it (e.g., `addon.colors`, `addon.debugMessage`).
- Module-level globals use the `MPT_*` prefix (e.g., `MPT_MAIN`, `MPT_Dashboard`, `MPT_Sidebar`). These are initialized as empty tables in `init.lua` files, then methods are attached in subsequent files — this is the split-init pattern used throughout.
- `_G["MPT"] = addon` is set in `init.lua`, making `addon` accessible globally as `MPT` from outside the addon.

## Saved Variables

`MythicPlusTrackerDB` is the single SavedVariables table declared in the `.toc`. All persistent state goes here. Currently used only by the debug system (`MythicPlusTrackerDB.debugMode`).

## Messaging Utilities (`Utils/MessageHandler.lua`)

Always use these instead of `print()` directly:

| Function | Use case |
|---|---|
| `addon.addonMessage(text, color)` | Prefixes message with colored addon title |
| `addon.chatMessage(text, color)` | Plain colored chat message |
| `addon.errorMessage(text)` | Red, with addon prefix |
| `addon.successMessage(text)` | Green, with addon prefix |
| `addon.warningMessage(text)` | Yellow, with addon prefix |
| `addon.infoMessage(text)` | Blue, with addon prefix |
| `addon.debugMessage(text, color)` | Only prints when debug mode is on |

## Color System (`Utils/ColorHandler.lua`)

Colors are WoW UI escape codes stored in `addon.colors`. Always use these constants rather than hardcoding `|cFF...` strings. Key ones:

- Item quality: `POOR`, `UNCOMMON`, `RARE`, `EPIC`, `LEGENDARY`, `ARTIFACT`
- Keystone levels: `KEYSTONE_LEVEL_LOW/MID/HIGH/VERY_HIGH`
- UI: `ERROR`, `SUCCESS`, `WARNING`, `INFO`
- Always close with `addon.colors.RESET` (`|r`)

## Debug Mode

Toggle with `/mpt debug`, `/mpt debug on`, `/mpt debug off`. State persists across sessions via `MythicPlusTrackerDB.debugMode`. When debug is on, `addon.isDebugMode` is truthy — used in Content.lua to show colored layout guides.

## UI Architecture

- **MainFrame** (1100×550): root draggable frame, created fresh each time the minimap button is left-clicked if not already shown (`addon.showTracker` flag).
- **Dashboard** (800×550): anchored `TOPRIGHT` of MainFrame; shows dungeon grid via `C_ChallengeMode.GetMapTable()`.
- **Sidebar** (300×550): anchored `TOPLEFT` of MainFrame; shows M+ score (`C_ChallengeMode.GetOverallDungeonScore()`) and currencies (`C_CurrencyInfo.GetCurrencyInfo(id)`).
- Frames use `BackdropTemplate` and WoW's built-in `Interface\\DialogFrame\\UI-DialogBox-Background-Dark` textures.
- Atlases used: `"mythicplus-greatvault-collect"`, `"UI-Frame-TheWarWithin-CardParchmentWider"`, `"thewarwithin-landingpage-renownbutton-locked"`.

## Localization

Strings live in `Locales/en-US.lua` (and `de-DE.lua`). Access via `addon.locale["KEY"]`. Add new strings to all locale files when introducing user-facing text.

## Slash Commands

Registered as `/mpt` and `/mythicplustracker`. Handler is in `Command/MythicPlusTrackerCommand.lua`. Add new commands there with a new `elseif command == "..."` branch, and update the help text block.

## WoW API Documentation

When searching for WoW API functions, events, widgets, or frame types, always refer to:
**https://warcraft.wiki.gg/wiki/World_of_Warcraft_API**

This is the authoritative reference for all WoW addon APIs (functions, events, widgets, constants).

## Key WoW APIs Used

- `C_ChallengeMode.GetMapTable()`, `GetMapUIInfo(mapID)`, `GetOverallDungeonScore()`, `GetMapScoreInfo()`
- `C_MythicPlus.GetCurrentSeason()`, `IsMythicPlusActive()`, `GetRunHistory()`
- `C_CurrencyInfo.GetCurrencyInfo(currencyId)`
- `C_AddOns.GetAddOnMetadata(addonName, field)`
- `C_Timer.After(delay, func)` for deferred execution

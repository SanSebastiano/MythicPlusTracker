# MythicPlusTracker — Agent Instructions

This is the single source of truth for any AI coding agent working in this repository (Claude Code, GitHub Copilot, Cursor, etc.). Tool-specific files (`CLAUDE.md`, `.github/copilot-instructions.md`) are thin pointers to this document — update this file, not those.

## What This Is

A World of Warcraft retail addon (Interface **120100**, patch 12.1.0) that tracks Mythic+ dungeon runs, group/guild keystones, and Weekly Vault progress. Pure Lua 5.1, no external libraries (no Ace3, no LibStub), no build step — loaded directly by the WoW client from source.

## Loading Order (Critical)

Files load in the exact order declared in `.toc` and `.xml` files. **Load order determines what globals exist when each file runs.**

```
init.lua                  → defines _G["MPT"] = addon, addon.locale = {}
Locales/locales.xml       → populates addon.locale (en-US, de-DE, fr-FR, es-ES, ru-RU)
Utils/utils.xml           → addon.colors, addon.*Message helpers, Theme, DebugSystem,
                             Keystone/AltKeystones/GuildKeys, Communication/GuildComm,
                             DungeonTeleports, RunHistoryCache, UIHelpers
Command/commands.xml      → registers /mpt and /mythicplustracker slash commands
Modules/modules.xml       → all UI modules (MainFrame → Dashboard → Sidebar →
                             MinimapButton → Tracker/init → Settings → WelcomeMessage)
```

Read `Modules/modules.xml` before adding a new UI file — its order is load-bearing. If you add a new file anywhere, register it in the correct `.xml`/`.toc` file **at the right position**.

## Namespace & Global Pattern

Every `.lua` file starts with `local addonName, addon = ...`

- `addon` is the shared namespace — attach utilities and state to it.
- Module globals use the `MPT_*` prefix (e.g. `MPT_MAIN`, `MPT_Dashboard`, `MPT_Sidebar`), pre-declared as empty tables in each module's `init.lua` and extended by subsequent files.
- `_G["MPT"] = addon` makes the shared table globally accessible as `MPT`.
- No abbreviations in file/variable/function names (e.g. `Communication.lua`/`addon.Communication`, not `Comm.lua`/`addon.Comm`).

## SavedVariables

Declared in `.toc`: `MythicPlusTrackerDB`, `MythicPlusTrackerAltDB`.

- **`MythicPlusTrackerDB`** — account-wide state: `debugMode`, `altKeystonesLastRefreshedAt`.
- **`MythicPlusTrackerAltDB`** — per-character keystone snapshots for the Twinks view, keyed by character.
- Guild Sync doesn't persist anything — it's a live request/response model, same as Group Sync (a previously-declared `MythicPlusTrackerGuildDB` was removed in 1.3.1 for this reason). Don't reintroduce a SavedVariable for guild data.

## Messaging Utilities (`Utils/MessageHandler.lua`)

Never use `print()` directly. Use `addon.*Message()` helpers: `addonMessage`, `chatMessage`, `errorMessage`, `successMessage`, `warningMessage`, `infoMessage`, `debugMessage` (only prints when debug mode is on, see `Utils/DebugSystem.lua`).

## Color System (`Utils/ColorHandler.lua`)

Colors are WoW UI escape codes in `addon.colors`. Never hardcode `|cFF...` strings. Key groups: item quality (`POOR`…`LEGENDARY`), keystone levels (`KEYSTONE_LEVEL_LOW/MID/HIGH/VERY_HIGH`), UI states (`ERROR`, `SUCCESS`, `WARNING`, `INFO`). Always close with `addon.colors.RESET` (`|r`).

## Theming (`Utils/Theme.lua`)

All decorative Atlas texture names (frame backgrounds/borders, card headers, icon backgrounds, tab-bar decorations, sidebar dividers, minimap icon/border) are cataloged here. Re-skinning means swapping values in this one file, not touching UI code — the same principle as translating a locale file.

## Debug Mode

Toggle with `/mpt debug [on|off]`. State persists via `MythicPlusTrackerDB.debugMode`. `addon.isDebugMode()` returns true when active — note it is a function, calling it without parentheses always yields a truthy reference.

## UI Architecture

- **Sidebar** (`MPT_Sidebar`, `Modules/Tracker/Sidebar/`, anchored `TOPLEFT` of MainFrame, 300×550): always visible, always shows the same content — M+ score, affixes, keystone, weekly vault, currencies, run stats. Does **not** change when switching Dashboard tabs.
- **MainFrame** (`MPT_MAIN`, `Modules/Tracker/MainFrame.lua`, root, 1100×550, draggable): outer container. Carries a border texture (`ui-frame-midnight-border`) that overlaps inward at the edges/corners — child content must respect this inset.
- **Dashboard** (`MPT_Dashboard`, `Modules/Tracker/Dashboard/`, anchored `TOPRIGHT` of MainFrame, 800×550): right-hand content region. On the three main pages (Overview/Runs/Keystones) it always shows a header tab row, a divider, and content inset from the border below that.
  > Future detail pages (Key detail, Run detail) will render inside the MainFrame area *without* the header nav/divider.

## Localization

Strings live in `Locales/*.lua` (`en-US` is the reference; `de-DE`, `fr-FR`, `es-ES`, `ru-RU` must match its keys exactly). Access via `addon.locale["KEY"]`. Add new keys to **all five** files when introducing user-facing text — validated by the `locale-validator` skill/script below.

## Slash Commands

Registered as `/mpt` and `/mythicplustracker`. Handler: `Command/MythicPlusTrackerCommand.lua`. Add new commands with `elseif command == "..."` and update the help text block.

## Validation Tooling

Don't hand-roll checks this repo already automates — use these (also wired into CI via `.github/workflows/lua-validation.yml`):

| Task | Command | Skill |
|---|---|---|
| Lint all Lua | `luacheck .` (config: `.luacheckrc`, Lua 5.1, `max_line_length = 160`, WoW globals whitelisted) | `.github/skills/addon-linter/SKILL.md` |
| Locale key consistency | `bash Tools/locale-validator.sh` | `.github/skills/locale-validator/SKILL.md` |
| `.toc`/`.xml` file references exist | `bash Tools/toc-validator.sh` | `.github/skills/toc-validator/SKILL.md` |
| Look up a WoW API signature | see skill | `.github/skills/wow-api-lookup/SKILL.md` (authoritative source: https://warcraft.wiki.gg/wiki/World_of_Warcraft_API) |

If `luacheck` flags a genuine WoW API global as undefined, add it to the `globals` table in `.luacheckrc` rather than suppressing the warning.

## Comment Discipline

Only comment non-obvious logic or WoW API quirks — not what the code already says. No banner comments, no dead/commented-out code.

## Git Workflow

- `develop` is the integration branch; PRs into `main` are only accepted from `develop` (enforced by `.github/workflows/enforce-main-source.yml`).
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat`, `fix`, `docs`, `style`, `refactor`, `chore`), header ≤50 chars.
- Releases are cut from `CHANGELOG.md` on push to `main` (`.github/workflows/release.yml`) — keep the `## [x.y.z] - Unreleased` section current when making user-facing changes.

## License

CC BY-NC-ND 4.0 — non-commercial, no derivatives, attribution required. Relevant if asked about redistribution, forks, or commercial use.

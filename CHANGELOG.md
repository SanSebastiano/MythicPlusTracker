# Changelog

All notable changes to MythicPlusTracker are documented here.

## [1.4.0] - Unreleased

### Added
- `Tools/registration-validator.sh`, wired into CI: it catches `.lua` files that exist but aren't referenced from any `.toc`/`.xml` manifest. That failure mode produces no error and no warning in-game — the file simply never runs, and whatever it defined is silently missing.
- `.gitattributes`, so line endings are normalized in the repository instead of depending on each contributor's local git configuration.
- `CODING_GUIDELINES.md` section 3.4 defines what earns a `Service` suffix, where a service belongs depending on who calls it, and which words are banned in file names.

### Changed
- **Large internal restructuring with no intended change in behavior.** Nothing about the UI, the saved data, or the group/guild sync protocols changed; this release exists to make the codebase navigable before the next round of features. Each step was verified in-game on its own. In detail:
  - The `Utils/` folder is gone. Code now sits in one of three layers: `Core/` for cross-cutting infrastructure (colors, theme, messages, debug mode, time formatting, shared widgets), `Services/` for domain services more than one module uses, and `Modules/<Module>/Services/` for services only one module uses. "Where does this file belong?" is now answered by looking at who calls it, not by taste.
  - Domain services carry a `Service` suffix and one consistent shape: `KeystoneService`, `GroupKeystoneService`, `GuildKeystoneService`, `AltKeystoneService`, `RunHistoryService`, `KeystoneEntryService`, `TableSortService`. `GuildComm.lua` and `GuildKeys.lua` turned out to be two halves of one job and are now a single `GuildKeystoneService`.
  - The Keystones tab and the Sidebar's statistics card each built the group's keystone list separately from the same source, so the two could disagree. Both now read one provider, and the in-memory keystone stores are no longer global variables.
  - The Overview and Keystones tables share one sorting implementation, each keeping its own state — sorting one can no longer reorder the other.
  - Consolidated duplicated logic: realm-qualified character names (7 places), max-level checks (3), `m:ss` duration formatting (6), tooltip label lines (2), and dashboard/sidebar layout constants (26, of which 9 were inline values rather than named constants).
  - The Sidebar's content files now expose module methods the way the Dashboard's already did, and every module table is declared in the file that shares its name. `init.lua` has a single meaning again — the addon's entry point — instead of three.
  - Every public method is `camelCase`, with no exceptions left.
- Removed dead code: the never-used `MythicPlusTracker.lua` core file, an always-true debug guard in the minimap button, and a window-visibility flag nothing ever read.

### Fixed
- **The Overview tab showed keys that weren't timed.** Runs at keystone level 12 or above were counted as a dungeon's best even when they weren't completed in time, along with their over-the-limit duration in the Best Time column. Those runs no longer count; below level 12 an over-time run still does, since it still awards score. Of the eligible runs the highest-scoring one wins, so Level, Score and Best Time always describe the same run instead of potentially three different ones.
- The minimap button's tooltip promised that left-clicking would *toggle* the dashboard, but a click only ever opened it — a second click never closed it. The tooltip now says "open", in all five languages.
- The developer-only `/mpt test` command printed straight to the chat frame instead of going through the addon's own message helpers, with its diagnostic logic inlined in the slash-command dispatch.
- `Tools/toc-validator.sh` reported 13 false "MISSING" entries on Windows checkouts because it didn't strip the CR from CRLF line endings, which left the repository's main structural check effectively unusable locally while passing in CI.

## [1.3.1] - 2026-08-21

### Added
- **Guild Sync refresh button.** The "Guild" dropdown option in the Keystones tab now has the same manual refresh button as the Group view, with a 30-second cooldown (silent, like the Group button).
- **Time +/- column in the Runs tab.** The Season column has been replaced with a Time +/- column showing how far each run finished under (green) or over (red) the dungeon's timer, reusing the same delta logic already shown as a tooltip on the Dungeons tab's Best Time column. Column order was also adjusted so the new column sits between Time and Date.
- **Dungeon teleport icons glow on hover** when the shown teleport is actually known, as an extra visual cue alongside the existing tooltip.

### Changed
- Reworked Guild Sync internally to match Group Sync's request/response model: guild keystones are requested live and no longer cached across sessions (the `MythicPlusTrackerGuildDB` SavedVariable has been removed) or relayed transitively between members who were never online together.
- The Group/Guild refresh button's tooltip in the Keystones tab now shows a gold "Refresh" title with a "Last updated: ..." line below it (reusing the Alts view's existing relative-time formatting), instead of a static one-line description.
- Replaced the Dungeons tab's unreliable dynamic teleport-spell discovery (spellbook scan + icon/description matching) with a fixed, verified per-season mapID → spell table — teleport icons now resolve correctly and instantly instead of intermittently failing to detect an owned teleport.
- Tidied up the minimap button's tooltip: the addon name is now shown in its usual two-tone colors, each click/drag instruction's label is highlighted, and long lines wrap instead of stretching the tooltip wide.
- Renamed the Sidebar Statistics "Best" row to "Highest Key" and widened its value column so a max-length (12-character) character name plus keystone level no longer wraps or looks misaligned.

## [1.3.0] - 2026-08-19

### Added
- **Twinks/Alts support in the Keystones tab.** A new dropdown above the table switches between the live Group view and a new Twinks view that lists every one of your other max-level characters' last-known keystone. Each max-level character saves its own keystone automatically on login and after finishing a dungeon; a Twink's keystone/level automatically resets to "no key" once the weekly reset has passed since it last logged in, so the list never shows stale data as current.
- **Guild-wide keystones in the Keystones tab.** A new "Guild" dropdown option lists every currently online guild member's last-known keystone and score, kept in sync automatically over guild-chat addon messages — the same online-only behavior as the Group view. Online guild members who've never responded show "No addon"; data can still reach members transitively through whoever else happens to be online at the time.
- New "Score" column in the Keystones tab table, shown in both the Group and Twinks views.
- The Keystones tab table's column headers (Player, Dungeon, Level, Score) are now clickable to sort the table, with an ascending/descending indicator — matching the Overview tab's existing sortable headers.
- New Sidebar Statistics section for the Keystones tab: average score, average keystone level, how many currently hold a key, and the best-performing member/twink — automatically follows whichever mode (Group or Twinks) is selected in the Dashboard dropdown.

### Changed
- The Runs and Keystones tabs now use the same modern scrollbar style as Blizzard's own panels (e.g. the Encounter Journal), which also hides itself automatically when there's nothing to scroll.
- The Sidebar's Keystones-tab section no longer shows a plain list of group members' scores — it's now the Statistics section described above.

## [1.2.1] - 2026-08-13

### Changed
- Updated the Sidebar Overview currencies section to track the new Season 2 crest currencies (Adventurer/Veteran/Champion/Hero/Myth Mistcrest, IDs 3442-3446) instead of the retired Season 1 Dawncrest currencies (IDs 3341, 3343, 3345, 3347, 3383).

### Fixed
- Fixed the tracker window getting permanently stuck in an "open" state if it was opened while in combat — subsequent attempts to open it silently did nothing until `/reload`. The window can no longer be opened during combat lockdown (a chat message explains why, throttled to once every 5 seconds), and its open/closed state now always reflects the actual window visibility.

## [1.2.0] - 2026-08-11

Tested and supported on World of Warcraft client version 12.1.0 (Interface `120100`).

### Added
- New slash command `/mpt announce` to post your current keystone (dungeon + level) directly to party, raid, or instance chat — posts a clickable item link when the keystone is a physical bag item, so group members can inspect it directly from chat.
- New setting (Options → AddOns → Mythic Plus Tracker → Dashboard) to open the Dashboard directly to the Keystones tab instead of Overview when you're in a party or raid.
- Added Russian (`ruRU`) translations - [@Hollicsh](https://github.com/Hollicsh) ([#40](https://github.com/SanSebastiano/MythicPlusTracker/pull/40)).

### Changed
- The main tracker window now remembers its position across relogs/reloads instead of always reopening centered on screen.
- The Dashboard Runs tab's "Timed" column now shows a clock icon instead of a text label (hover for the full description), since the translated label no longer fit the column in several locales.
- Increased the padding around the current-keystone icon and level number in the Sidebar Overview tab so they no longer sit flush against the card's edges.
- Shortened the Sidebar "Best Run" card's empty-state text in all locales so it no longer wraps onto two lines.

### Fixed
- Added the French (`frFR`) and Spanish (`esES`) addon description/category metadata to the `.toc` file, which had been missing since those translations were introduced.
- Fixed the Dashboard Runs tab's "Level" and "Score" column headers getting visually clipped or overflowing into neighboring columns in German, Spanish, and Russian, by widening those columns.
- Fixed the Runs tab's empty-state message ("No runs recorded yet.") being hardcoded in English regardless of the active locale, and visually overlapping the column header instead of appearing centered below it.
- Fixed the Sidebar's Affixes section showing a blank empty area instead of a message when no affixes are currently available.

## [1.1.1] - 2026-07-28

### Fixed
- Fixed a crash if the welcome message tried to warn about a locale not being loaded yet — it called a non-existent function (`addon.chatError`) instead of the real message helper.
- Fixed two global-variable leaks in the Sidebar score card that polluted `_G` on every render.
- Fixed a memory/event-leak in the Sidebar Trait Nodes section, which registered a new event listener every time the sidebar was shown instead of once.
- Removed a leftover empty `ADDON_LOADED` handler that was never unregistered and ran for the entire session without doing anything.
- Fixed the dungeon teleport cache being shared account-wide instead of per character, which could make an alt inherit or overwrite another character's teleport data.
- Fixed the Trait Nodes rune-selection popup truncating longer rune names — it now sizes itself to fit the widest entry instead of using a fixed width.
- Fixed the rune-selection popup's border not lining up with its actual edges (previously a stretched icon-slot texture); it's now drawn as a precise thin border that always matches the popup's size.

### Changed
- Centralized score-tier and keystone-level coloring logic in `Utils/ColorHandler.lua` instead of duplicating it across several files.
- Consolidated duplicated table-cell, row-divider, and scrollbar-wiring code from the Dashboard's Dungeons/Runs/Keystones tabs into shared helpers (`Utils/UIHelpers.lua`).
- Sidebar sections now use a shared vertical layout cursor instead of hardcoded pixel offsets, making future layout changes less error-prone.
- Mythic+ run history is now cached and only re-fetched on key completion or login, instead of being requested from the API on every tab switch.
- Group keystone requests are now centrally rate-limited (max once every 2 seconds) regardless of which UI action triggered them.
- The group keystone addon-message protocol now includes a version number so future protocol changes can be detected and ignored safely by old clients.
- Added section-header banners (matching the Runs/Keystones tab style) above the Sidebar Overview tab's Weekly Vault, Trait Nodes, and Currency sections for clearer visual separation, replacing the plain divider bars that used to sit there.
- Trait Nodes that are purchasable but not yet chosen now show a grayed-out icon with a clearly visible green background highlight, both in the rune row and in the selection popup, instead of a barely-noticeable green icon tint.
- Weekly Vault boxes now have a simpler border instead of the generic icon background texture.

### Removed
- Removed the unused, unwired Great Vault quick-access button module.

## [1.1.0] - 2026-07-22

### Added
- New slash command `/mpt show` to open the tracker window without using the minimap button.
- New settings panel (Options → AddOns → Mythic Plus Tracker, or `/mpt settings`) with toggles for Debug Mode and Show Minimap Button, now grouped into "General" and "Minimap" sections.
- The minimap button can now be dragged along the minimap's edge (left-click-drag) or moved freely anywhere on screen (Shift+left-click-drag); the position is remembered across logins.
- New "Minimap Button Style" setting to switch between the large, freely draggable button and a compact button matching the classic look of other addons' minimap icons, which can only be moved along the minimap edge.
- Custom addon icon, shown in the AddOns list and the AddOn Compartment button.
- Introduced a centralized theme catalog (`Utils/Theme.lua`) listing every decorative Atlas texture used across the UI, so the addon can be re-skinned by editing a single file.
- Added French (`frFR`) and Spanish (`esES`) translations.
- Added a refresh button to the Keystones tab's group overview to manually re-request and re-render group keystone data (also updates the Sidebar group scores) without needing to switch tabs or reopen the tracker.
- Added hover tooltips to the Runs tab's column headers so their full names are visible even when the header text is truncated.

### Changed
- Renamed the Runs tab's "Completed" column to "Timed" to better reflect that it shows whether the run finished within the time limit.

## [1.0.1] - 2026-07-15

### Fixed
- Fixed the dashboard tab highlight not resetting to Overview when reopening the tracker.
- Fixed a scrollbar error when switching to the Runs or Keystones tab (`SecureScrollTemplates.lua:24: attempt to call a nil value`).
- Fixed group communication not working due to an incorrect addon message prefix.

## [1.0.0] - 2026-07-10

### Added
- Initial release of MythicPlusTracker for World of Warcraft: Midnight

**Sidebar**
- M+ score card, color-coded by score tier
- Current keystone display (dungeon icon, name, level) with item tooltip on hover
- Weekly Vault section with 3 slots showing progress/reward, clickable to open the Great Vault window
- Trait Nodes section (Omnium Folio / Runes of Power) with interactive selection popup and refund support
- Currencies row with icons, amounts, and highlighted capped currencies
- Affixes row with name/description tooltips
- Run statistics: best run this week plus timed-run breakdown by key-level bracket
- Group scores section showing other group members' Mythic+ scores, with fallback text when unavailable

**Dashboard – Overview tab**
- Sortable dungeon table (icon, name, best key level, score, total runs, successful runs, time limit, best time)
- Sort direction indicator on the active column
- Best-time delta tooltip showing time above/below the limit
- Timer-based color coding for best times

**Dashboard – Runs tab**
- Scrollable run history (icon, dungeon, level, completed status, score delta, duration, date/time, season)
- Tooltips for resulting dungeon score and dungeon time limit
- Color coding for keystone level, overtime duration, and score gains
- Empty-state message when no runs are recorded yet

**Dashboard – Keystones tab**
- Live group keystone overview: portrait, class icon, role icon, name, and current dungeon + level per member
- Fallback messages for members without a keystone or without the addon
- Automatic refresh of group data when the tab is opened

**Minimap & Great Vault**
- Minimap button: left-click toggles the tracker window, right-click opens the Great Vault / Weekly Rewards window
- Dedicated Great Vault button with tooltip

**Slash commands (`/mpt`, `/mythicplustracker`)**
- `help` (or no argument): prints available commands
- `debug`, `debug on`, `debug off`: toggles debug mode

**Group communication**
- Addon-message sync of keystone and score data between MythicPlusTracker users in a party/raid
- Detection of which group members are running the addon

**Localization**
- Full support for en-US and de-DE

**Other**
- Welcome message on login, with an additional notice when debug mode is active
- Persistent debug mode setting (`MythicPlusTrackerDB`)
- Shared color system for UI states, item quality, keystone tiers, and timers
- Movable, closable main tracker window

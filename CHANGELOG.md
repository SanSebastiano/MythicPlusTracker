# Changelog

All notable changes to MythicPlusTracker are documented here.

## [1.2.0] - 2026-08-11

### Added
- New slash command `/mpt announce` to post your current keystone (dungeon + level) directly to party, raid, or instance chat — posts a clickable item link when the keystone is a physical bag item, so group members can inspect it directly from chat.
- New setting (Options → AddOns → Mythic Plus Tracker → Dashboard) to open the Dashboard directly to the Keystones tab instead of Overview when you're in a party or raid.
- Added Russian (`ruRU`) translations - [@Hollicsh](https://github.com/Hollicsh) ([#40](https://github.com/SanSebastiano/MythicPlusTracker/pull/40)).

### Changed
- The main tracker window now remembers its position across relogs/reloads instead of always reopening centered on screen.
- The Dashboard Runs tab's "Timed" column now shows a clock icon instead of a text label (hover for the full description), since the translated label no longer fit the column in several locales.
- Shortened the Sidebar "Best Run" card's empty-state text in all locales so it no longer wraps onto two lines.
- Increased the padding around the current-keystone icon and level number in the Sidebar Overview tab so they no longer sit flush against the card's edges.

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

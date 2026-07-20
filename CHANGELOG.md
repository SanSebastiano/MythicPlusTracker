# Changelog

All notable changes to MythicPlusTracker are documented here.

## [1.1.0-] unreleased

### Added
- New slash command `/mpt show` to open the tracker window without using the minimap button.
- New settings panel (Options → AddOns → Mythic Plus Tracker, or `/mpt settings`) with toggles for Debug Mode and Show Minimap Button.
- The minimap button can now be dragged along the minimap's edge (left-click-drag) or moved freely anywhere on screen (Shift+left-click-drag); the position is remembered across logins.
- Introduced a centralized theme catalog (`Utils/Theme.lua`) listing every decorative Atlas texture used across the UI, so the addon can be re-skinned by editing a single file.
- Added French (`frFR`) and Spanish (`esES`) translations.
- Added a refresh button to the Keystones tab's group overview to manually re-request and re-render group keystone data (also updates the Sidebar group scores) without needing to switch tabs or reopen the tracker.

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

<div align="center">
  
# Mythic Plus Tracker

![WoW Interface](https://img.shields.io/badge/WoW%20Interface-120007-blueviolet)
![Version](https://img.shields.io/badge/Version-1.0.0-blue)
[![License: CC BY-NC-ND 4.0](https://img.shields.io/badge/License-CC%20BY--NC--ND%204.0-lightgrey)](https://creativecommons.org/licenses/by-nc-nd/4.0/)

</div>

A World of Warcraft retail addon that gives you a clear, at-a-glance overview of your Mythic+ progress — dungeons, score, keystone, group, and Weekly Vault — all in one compact UI.

## Features

### Dashboard

The main window has three tabs:

- **Overview** — a sortable table of every dungeon available in the current Mythic+ season (icon, name, best key level, score, total runs, successful runs, time limit, best time), with a delta tooltip on the best-time column.
- **Runs** — a scrollable history of your past runs (dungeon, level, completed status, score gain, duration, date/time, season), color-coded by result.
- **Keystones** — a live overview of your group's keystones: each member's portrait, class, role, and current dungeon + level, with fallback messages for members without a key or without the addon.

### Sidebar
- **M+ Score** — your current overall Mythic+ score, color-coded by tier (Poor through Artifact quality).
- **Keystone** — the dungeon name, icon, and level of the keystone currently in your bags. Hovering shows the full item tooltip.
- **Weekly Vault** — three Mythic+ vault slots showing either the unlocked item level reward or your current run progress toward unlocking each slot.
- **Trait Nodes** — your Omnium Folio (Runes of Power) trait choices, with an interactive popup to select or refund ranks.
- **Currencies** — a live list of your relevant Mythic+ currencies with amounts, highlighted green when the weekly cap is reached.
- **Affixes** — this week's active affixes with name and description tooltips.
- **Run Statistics** — your best run this week, plus a breakdown of timed runs by key-level bracket.
- **Group Scores** — the Mythic+ scores of your current group members.

### Minimap Button
- **Left-click** — opens the Mythic Plus Tracker window.
- **Right-click** — opens the Great Vault (Weekly Rewards frame).

### Slash Commands
Available as `/mpt` or `/mythicplustracker`:
- (no argument) or `help` — prints the list of available commands.
- `debug`, `debug on`, `debug off` — toggles debug mode, which prints additional diagnostic messages.

### Group Communication
MythicPlusTracker automatically syncs keystone and score data between group/raid members who also run the addon, so the Keystones tab and Group Scores section stay up to date without any manual action.

---

## Localization

MythicPlusTracker ships with full support for:

| Locale | Language |
|--------|----------|
| `enUS` | English  |
| `deDE` | German   |

Want to add your language? See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on submitting pull requests, reporting bugs, and adding translations.

---

## License

This project is licensed under [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/) — see the [LICENSE](LICENSE) file for details. You may share this AddOn unmodified for free, with attribution, but not for commercial purposes or as a modified derivative. Pull requests to the official repository are always welcome.

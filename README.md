<div align="center">
  
# Mythic Plus Tracker

![WoW Interface](https://img.shields.io/badge/WoW%20Interface-120100-blueviolet)
![Version](https://img.shields.io/badge/Version-1.3.0-blue)
[![License: CC BY-NC-ND 4.0](https://img.shields.io/badge/License-CC%20BY--NC--ND%204.0-lightgrey)](https://creativecommons.org/licenses/by-nc-nd/4.0/)

</div>

A World of Warcraft retail addon that gives you a clear, at-a-glance overview of your Mythic+ progress — dungeons, score, keystone, group, and Weekly Vault — all in one compact UI.

## Features

### Dashboard
- 🗂️ **Overview** — sortable dungeon table for the season (level, score, runs, time limit, best time), with a best-time delta tooltip.
- 📜 **Runs** — full run history, color-coded by result.
- 🔑 **Keystones** — switch between Group, Alts, and Guild views via a dropdown; sortable columns (dungeon, level, score) with fallbacks for members missing a key or the addon. A refresh button (Group) or a "last updated" info tooltip (Alts/Guild) shows how fresh the data is.

### Sidebar
- 🏆 **M+ Score** — your overall score, color-coded by tier.
- 🗝️ **Keystone** — your current keystone, with the full item tooltip on hover.
- 🗄️ **Weekly Vault** — reward previews and progress for all three vault slots.
- ✨ **Trait Nodes** — Omnium Folio rune choices, with an interactive select/refund popup.
- 💰 **Currencies** — your relevant Mythic+ currencies, highlighted when capped.
- ⚔️ **Affixes** — this week's active affixes, with tooltips.
- 📈 **Run Statistics** — your best run this week, plus a timed-run breakdown by key level.
- 📊 **Statistics** — average score, average keystone level, how many currently hold a key, and the best performer — automatically follows whichever Keystones-tab mode (Group, Alts, or Guild) is selected.

### Minimap Button
- 🧭 A draggable minimap button, available in a large freely-movable style or a compact edge-locked style — left-click opens the tracker, right-click opens the Great Vault.

### Slash Commands
- ⌨️ Everything's available via `/mpt` (or `/mythicplustracker`) — run `/mpt help` in-game for the full command list.
- 📢 `/mpt announce` — posts your current keystone to party, raid, or instance chat, as a clickable item link when possible.

### Group & Guild Communication
- 🔄 Keystone and score data syncs automatically between group/raid members running the addon — no manual action needed.
- 🏰 The same sync happens guild-wide over guild chat, covering every currently online guild member running the addon (shown in the Keystones tab's Guild view).

### Settings
- ⚙️ Configure everything under **Options → AddOns → Mythic Plus Tracker** (or `/mpt settings`) — minimap visibility/style, dashboard default tab, and more.
- 🐛 **Debug Mode** — prints additional diagnostic chat messages, useful for troubleshooting.

---

## Localization

MythicPlusTracker ships with full support for:

| | Locale | Language |
|---|--------|----------|
| ![US](https://flagcdn.com/w20/us.png) | `enUS` | English  |
| ![DE](https://flagcdn.com/w20/de.png) | `deDE` | German   |
| ![FR](https://flagcdn.com/w20/fr.png) | `frFR` | French   |
| ![ES](https://flagcdn.com/w20/es.png) | `esES` | Spanish  |
| ![RU](https://flagcdn.com/w20/ru.png) | `ruRU` | Russian  |

Want to add your language? See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on submitting pull requests, reporting bugs, and adding translations.

---

## License

This project is licensed under [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/) — see the [LICENSE](LICENSE) file for details. You may share this AddOn unmodified for free, with attribution, but not for commercial purposes or as a modified derivative. Pull requests to the official repository are always welcome.

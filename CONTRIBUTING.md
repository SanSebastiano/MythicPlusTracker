# Contributing to MythicPlusTracker

Thank you for your interest in contributing! This document explains how to report issues, submit pull requests, and add localizations.

---

## Reporting Bugs

1. Check [existing issues](../../issues) to avoid duplicates.
2. Open a new issue with:
   - A clear title and description.
   - Steps to reproduce the problem.
   - Your WoW version and addon version (shown in chat on login).
   - Any relevant error output from the Lua error frame.

---

## Pull Requests

1. Fork the repository and create a branch from `develop`.
2. Keep changes focused — one feature or fix per pull request.
3. Follow the existing code style (see below).
4. Test your changes in-game before submitting.
5. Write a clear PR description explaining *what* changed and *why*.

---

## Code Style

See [`AGENTS.md`](AGENTS.md) for the full picture (load order, SavedVariables, UI architecture, validation tooling). The essentials for a PR:

- Every file starts with `local addonName, addon = ...` — use `addon` as the shared namespace.
- Attach module globals with the `MPT_*` prefix (e.g. `MPT_Tracker`, `MPT_Dashboard`).
- Never use `print()` directly — use the `addon.*Message()` helpers (`addonMessage`, `chatMessage`, `errorMessage`, etc.).
- Never hardcode color escape codes — use `addon.colors.*` and always close with `addon.colors.RESET`.
- New files must be registered in the correct `.xml` or `.toc` file **at the correct load-order position**.
- Always spell out variable, function, and file names in full — avoid abbreviations (e.g. `Communication.lua`/`addon.Communication`, not `Comm.lua`/`addon.Comm`).
- Only comment code that needs clarification — explain non-obvious business logic or WoW API quirks, not what the code is already saying. Avoid section-divider banners, redundant labels, or dead commented-out code.
- Run `luacheck .` before submitting a PR to catch syntax errors and unused/undefined globals. The repo's `.luacheckrc` is preconfigured with the WoW API globals used by this addon.

---

## Adding Locales

1. Open `Locales/en-US.lua` and copy the locale table as a reference.
2. Create a new file `Locales/<locale-code>.lua` (e.g. `fr-FR.lua`).
3. Translate all string values — do **not** change the keys.
4. Register the new file in `Locales/locales.xml`.
5. Submit a pull request with your new locale file and the updated `locales.xml`.

---

## Re-skinning the UI (Theme)

All decorative WoW Atlas textures used across the UI (frame backgrounds/borders, card title backgrounds, icon backgrounds, tab-bar decorations, sidebar dividers, minimap icon/border, and a few status icons) are cataloged in a single file: `Utils/Theme.lua`.

To re-skin the addon, edit the atlas name values in that file — the same principle as translating a locale file, just swap the values, not the keys. Dynamic, data-driven icons (e.g. class/role icons in the Keystones tab) are **not** part of the theme catalog, since they depend on game data rather than a visual skin choice.

---

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short summary>
```

Common types: `feat`, `fix`, `docs`, `style`, `refactor`, `chore`.  
Keep the header under 50 characters. Wrap the body at 72 characters.

---

## Questions?

Open a [GitHub Discussion](../../discussions) or create an issue with the `question` label.

---

## License Note

MythicPlusTracker is licensed under [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/). By submitting a pull request, you agree that your contribution may be included in the project under these same license terms.

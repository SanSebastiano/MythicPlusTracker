---
name: locale-validator
description: Validates that all locale files in the WoW addon are complete and consistent with the reference locale (en-US.lua). Use when adding new locale keys, checking for missing translations, after editing any Locales/*.lua file, or when the user asks about missing translations.
allowed-tools: shell
---

# Locale Validator

Compares every locale file in `Locales/` against the reference (`Locales/en-US.lua`) and reports missing or extra keys.

## Steps

Run the validator script from the repository root:

```bash
bash Tools/locale-validator.sh
```

## Output

- `OK   Locales/de-DE.lua (30 keys)` — file is complete
- `FAIL Locales/de-DE.lua -- MISSING keys:` — keys to add
- `WARN Locales/de-DE.lua -- EXTRA keys:` — keys no longer in en-US (stale)

Exit code `1` if any issues are found.

## Fixing Issues

**MISSING keys** — add the key to the locale file with the translated value:
```lua
["NEW_KEY"] = "Translated text here",
```

**EXTRA keys** — the key was removed from `en-US.lua` but not from this locale. Remove it.

## Convention

- `en-US.lua` is always the reference. All other locale files must contain exactly the same keys.
- Key format: `["SCREAMING_SNAKE_CASE"]`
- When adding a new feature with user-facing text, add keys to **all** locale files simultaneously.

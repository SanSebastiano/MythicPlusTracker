# Feature Ideas

A running collection of feature ideas for Mythic Plus Tracker. Nothing here is committed or scheduled — this is a backlog to pick from, not a roadmap. Each idea notes what it would do, which existing code/API it would build on, and a rough effort tag: `low` (a contained change following an existing pattern), `medium` (new UI or new logic, but no new architecture), `high` (needs new architecture, e.g. a new protocol or navigation layer).

Direction note: releases 1.2.0 → 1.3.1 focused entirely on **social visibility** (who in your group/guild/account holds which key) and UI polish. **Analytics, progression and recommendations are a completely unexplored area** — hence section A.

---

## A. Analytics & Progression

The addon currently only ever *displays* scores; there is no predictive or comparative math anywhere.

- **Score projection** `medium` — "what would timing a +18 in dungeon X give me?" Shown as a tooltip or a projected-score column. Two possible approaches: reimplement Blizzard's documented score formula, or derive a level→score mapping from your own run history. **The self-calibrating variant is the more robust one** — the official formula is season-dependent and would have to be re-checked every season, while your own history is always current.
- **Weakest dungeon / best next run** `medium` — rank dungeons by potential score gain so the addon can answer "which key is worth the most to me right now?" Builds directly on score projection.
- **Target score tracker** `low-medium` — set a goal ("I want 3000") and show what's still missing, per dungeon.
- **Per-affix performance breakdown** `medium` — `C_MythicPlus.GetSeasonBestAffixScoreInfoForMap` is the **single biggest completely unused M+ API block**: it returns the best run per affix category per dungeon (`level`, `durationSec`, `score`). This is what reveals which half of a dungeon's score is dragging you down, and it's also the data foundation for accurate score projection.
- **Weekly statistics panel** `low-medium` — how much score was gained each week, how many keys completed. `addon.getRunHistory()` already returns `completionDate`/`runScore`/`thisWeek` per run; bucketing by weekly-reset boundaries reuses the pattern in `Utils/AltKeystones.lua` (`C_DateAndTime.GetWeeklyResetStartTime()`). No sync needed.
- **Score/key trend graph** `medium` — a small multi-week sparkline instead of just the current week. Same bucketing. For anything beyond the current season, see the season archive in section H.
- **Personal bests / trends per dungeon** `low-medium` — extends `Utils/RunHistoryCache.lua`, which already has the raw data.

## B. Great Vault

- **Missing vault slots** `low-medium` — the sidebar only reads `Enum.WeeklyRewardChestThresholdType.Activities` (Mythic+). Raid, PvP and Delves slots aren't shown at all.
- **Readable slot progress** `low` — locked slots currently show a bare `progress / threshold` counter; a "2 more runs to unlock slot 3" line or a progress bar communicates the same thing far better.
- **Reward preview per key level** `low` — `C_MythicPlus.GetRewardLevelForDifficultyLevel` returns `weeklyRewardLevel` and `endOfRunRewardLevel` and is currently unused. A small "key level → end-of-run ilvl / vault ilvl" table answers "is this key even worth running?" before the run.
- **Alt vault overview** `medium` — see at a glance which characters still need vault runs. Needs the alt persistence extended, which today stores keystones only.
- **Live vault refresh** `low` — `WEEKLY_REWARDS_UPDATE` isn't registered, so vault data only refreshes on panel rebuild.

## C. Chat & Announce

- **Bulk-announce group keys** `medium` — a button that posts *all* currently known keystones in the group (`addon.groupKeystones`) at once, instead of just your own (`/mpt announce` already exists, see `Services/KeystoneService.lua`). Needs throttle-safe multi-message sending, since the client silently drops `SendChatMessage` calls fired too close together.
- **Bulk-announce alt keys** `medium` — same for `MythicPlusTrackerAltDB`, e.g. to show the group which twink could bring a useful key.
- **Auto-announce on run completion** `medium` — opt-in, posts a short summary ("+18 X, timed, 3:02 to spare") after `CHALLENGE_MODE_COMPLETED` via `C_ChallengeMode.GetChallengeCompletionInfo()`. Must default to OFF.
- **Announce to guild** `low` — Guild Sync is silent today; there's no visible guild-chat post of your own key.
- **Announce a single member's key** `low` — a per-row button instead of a bulk one (text only, no item link possible for someone else's key).
- **Weekly recap announce** `medium` — an opt-in "this week: 5 keys, +340 score" message at reset, to group or guild. Combines with section A.

## D. Social: Group & Guild

- **Player detail page** `high` — clicking a member's name opens a page with their season-best per dungeon and recent runs. Today only a single tuple (`mapID:level:score`) is broadcast per player, so this needs a new targeted, chunked request/response protocol with reassembly and timeouts, plus a detail-page navigation layer the Dashboard doesn't have yet (only noted as an intent in `AGENTS.md`). The biggest and riskiest item on this list, but doable without new dependencies. Deserves its own planning pass.
- **Gear score in sync** `low` — add average item level (`GetAverageItemLevel`) to the existing single-line sync message so the group/guild view can show rough gear next to score and key level. Unlike the detail page this needs no new protocol — just one more number in the message that's already being sent.
- **Guild achievement announcements** `medium` — when a guild member running the addon hits a personal best or a record (`isMapRecord`/`isAffixRecord`), broadcast it to other addon users and show a local notification, or optionally post to guild chat. A new message type on the existing `GuildComm.lua` protocol; one message is enough. Open questions: what counts as "notable", and on-by-default vs. opt-in to avoid spamming the guild.
- **Weekly guild recap** `medium` — a batched "this week in the guild: 12 new personal bests, highest key +21 by X" instead of individual announcements. Less spammy, same data, pairs with section A.
- **Guild leaderboard** `medium` — `C_ChallengeMode.GetGuildLeaders()`/`RequestLeaders()` are unused and would give a per-dungeon guild leaderboard *without* any sync, since Blizzard serves the data directly.
- **Spec display in the group view** `low` — role icons already exist; spec (icon or name) does not.
- **Show the realm** `low` — realm is already stored in the alt DB and resolved for sync lookups, but never displayed. A free win for cross-realm groups and guilds.
- **Group composition check** `low` — role data is already read but never counted; a simple "no tank" / "2 healers" hint would use what's already there.
- **Row context menu** `low` — whisper / invite / copy name on a row, as a small alternative to the full detail page above.
- **Unit tooltip enhancement** `medium` — show a member's known keystone when hovering their unit frame. The addon currently hooks no external tooltips at all (no `TooltipDataProcessor`, no `hooksecurefunc`), so this would be the first such integration.

## E. Before and During the Run

- **"Who has a key for this dungeon" frame** `medium` — on entering a M+ dungeon, before the timer starts, show which group members also hold a keystone for *this* dungeon. The data already exists via group sync; this is filtering plus a small non-blocking frame. Trigger via keystone slotting (`C_ChallengeMode.HasSlottedKeystone`/`GetSlottedKeystoneInfo`) rather than after completion.
- **Would this be a group best?** `low` — extend the above to show whether the slotted key would be a new best level for anyone present.
- **Auto-slot the keystone** `low-medium` — put your key in the font automatically when the receptacle opens (`C_ChallengeMode.SlotKeystone` + `CHALLENGE_MODE_KEYSTONE_RECEPTACLE_OPEN`). A standard convenience feature in competing addons; neither the API nor the event is used here today.
- **Auto-open on dungeon entry** `low` — `CHALLENGE_MODE_START` isn't registered at all. There's already a "open on the Keystones tab when in a group" setting, so this fits the existing settings pattern.
- **Live death counter** `low` — `C_ChallengeMode.GetDeathCount()` (`numDeaths`, `timeLost`) is unused; a simple basis for a small live HUD. See also the description mismatch in section I.
- **Post-run record callout** `low` — `GetChallengeCompletionInfo()` also returns `isMapRecord`/`isAffixRecord`, currently unused; could drive a "New record!" callout.
- **Live timer overlay** `high` — time remaining vs. limit, pace, pull counter. Considerably bigger scope, effectively a standalone feature.

## F. Runs Tab & Tables

- **Sort by dungeon** `low` — the Keystones and Overview tabs already have a complete, reusable sorting pattern (clickable headers, asc/desc indicator, sort function); the Runs tab has none and is hardcoded to sort by date.
- **More sortable columns** `low` — level, score, duration, using the same pattern.
- **Filter / search** `medium` — by dungeon, timed vs. depleted, or key level range. The list is unfiltered today.
- **Row virtualization** `medium` — the tab renders *every* run of the season into the scroll frame at once. Fine early in a season, increasingly wasteful later; only visible rows need to exist.
- **Season selector** — blocked on having own persistence, since `C_MythicPlus.GetRunHistory()` only ever returns the current season. See the season archive in section H.

## G. Entry Points & Accessibility

- **Addon compartment entry** `low` — `## AddonCompartmentFunc` (plus the optional `OnEnter`/`OnLeave` variants) is missing entirely. It adds the addon to Blizzard's minimap addon-compartment menu, needs no library at all, and is one TOC directive plus a small global function. Cheapest win on this list.
- **Keybinding** `low` — there's no `Bindings.xml`; the tracker can only be opened via the minimap button or a slash command. A single "toggle tracker" binding would cover it.
- **UI scale / font size setting** `medium` — no scaling option exists; all font sizes come from fixed Blizzard templates.
- **Resizable main frame** `medium-high` — the window is a fixed 1100×550 with hardcoded layout widths throughout, which is a real constraint on smaller resolutions. Would require the layout constants to become derived values.
- **More languages** `low` per locale — currently English, German, French, Spanish and Russian.

## H. Settings & Data Management

- **Reset to defaults** `low` — there is no way to reset settings, via UI or slash command.
- **Per-character profiles** `medium` — both saved variables are account-wide, so window position and the default tab are necessarily identical on every character.
- **Remove stale alt entries** `low` — renamed, deleted or transferred characters stay in `MythicPlusTrackerAltDB` forever with no way to remove them. A per-row remove action or a prune button would fix a slowly accumulating annoyance.
- **Export / import string** `medium` — share keystone snapshots outside the game, WeakAuras-style.
- **Season archive** `medium` — **prerequisite for several ideas above.** All history comes live from `C_MythicPlus.GetRunHistory()`, which only covers the current season, and nothing is persisted; when the season flips, everything is simply gone. Storing a compact end-of-season snapshot (per-dungeon best, overall score, run count) would enable season comparisons (section A) and a season selector (section F).

## I. Maintainability

- **Centralize season configuration** `low-medium` — the teleport spell table, the five currency IDs and the trait system ID are hardcoded in three separate places, each with its own "bump this every season" comment. A single season config file would turn a new season into a one-file change and remove the risk of forgetting one of them.
- **Teleport polish** `low-medium` — clicking a dungeon to teleport already works, including an "is it learned?" check and a hover glow. What's missing: teleports from *earlier* seasons and expansions (permanently owned, not in the current table), an at-a-glance unlocked indicator instead of hover-only feedback, an overall "6/8 learned" view, and teleporting from anywhere other than the Overview tab.
- **Currency polish** `low` — cap progress is only communicated through text color; a bar or an "earned / max this week" value would be clearer.
- **Description vs. reality** `low` — the TOC notes advertise tracking of "deaths" in all five languages, but `C_ChallengeMode.GetDeathCount()` is never called. Either implement it (pairs with the live death counter in section E) or correct the description.

## J. Feedback Layer

The addon plays **no sounds at all**, shows no toasts or alerts, and contains exactly one animation in the entire codebase. All feedback is chat text.

- **Optional completion / achievement feedback** `low` — an opt-in sound or on-screen notification when a key is completed, a personal best is set, or a guild achievement arrives. Small on its own, but it makes several other ideas here (post-run callout, guild achievements, records) land much better.

## K. Other Unused APIs & External Integration

No concrete idea behind these yet, just noting what's available and untouched: `C_MythicPlus.GetCurrentSeasonValues`, `GetEndOfRunGearSequenceLevel`, `GetLastWeeklyBestInformation`, `GetSeasonBestMythicRatingFromThisExpansion`, `GetWeeklyBestForMap`, `GetRewardLevelFromKeystoneLevel`, `IsMythicPlusActive`; `C_ChallengeMode.GetLeaverPenaltyWarningTimeLeft`, `GetMapScoreInfo`, `CanUseKeystoneInCurrentMap`, and `GetDungeonScoreRarityColor`/`GetSpecificDungeonScoreRarityColor` (ready-made Blizzard color scales, possibly usable alongside `Core/Colors.lua`).

- **Group Finder integration** `high` — auto-list your key with a level filter, or browse matching groups (`C_LFGList`). Needs its own deeper API research.
- **Weekly reset countdown** `low` — e.g. as a minimap tooltip line. A LibDataBroker display would mean a new dependency (conflicts with "no external libraries"); a plain tooltip line does not.
- **RaiderIO cross-check** `medium` — read-only, active only when RaiderIO is installed, so no new hard dependency.

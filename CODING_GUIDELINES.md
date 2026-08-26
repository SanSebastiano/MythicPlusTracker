# MythicPlusTracker — Coding Guidelines

1. Scope And Authority
   1.1 Purpose
   1.2 Relationship To AGENTS.md
   1.3 Exclusions
   1.4 Normative Language
2. Engineering Principles
   2.1 Readability And Cognitive Complexity
   2.2 Separation Of Concerns
   2.3 Minimal Implementation Surface
3. Naming
   3.1 General Naming
   3.2 Function Names
   3.3 Namespace And Module Names
4. Lua Language Baseline
   4.1 Locals Over Globals
   4.2 The Two Sanctioned Global Surfaces
   4.3 Type Annotations
   4.4 Table Shape Discipline
5. Data Shapes And Contracts
   5.1 Module Tables As Public Contracts
   5.2 Event Payloads And Varargs
   5.3 SavedVariables Schema Stability
6. Functions And Control Flow
   6.1 Function Scope
   6.2 Control Flow
   6.3 The `and`/`or` Ternary Trap
   6.4 Boolean Flag Parameters
7. Constants And Technical Strings
   7.1 Constants
   7.2 Hardcoded Values
8. Comments And Documentation
   8.1 Comments
   8.2 LuaCATS Annotations
9. Modules And File Organization
   9.1 Module Shape
   9.2 File Registration
10. WoW Events And Frames
    10.1 Registration Pattern
    10.2 Dispatch And Delegation
    10.3 Payload Validation
11. Performance And Hot Paths
    11.1 OnUpdate Discipline
    11.2 Throttling
    11.3 Redundant API Calls
12. SavedVariables And Persistence
    12.1 Lazy Initialization
    12.2 Additive Evolution
13. Addon Communication
    13.1 Message Contracts
    13.2 Trust Boundary
14. Error Handling And User Feedback
    14.1 Messaging
    14.2 pcall Policy
    14.3 Debug Diagnostics
15. UI Construction And Theming
    15.1 Frame Construction
    15.2 Colors And Atlas Textures
16. Localization
    16.1 Locale Keys
17. Testing And Quality Gates
    17.1 Automated Gates
    17.2 Manual Verification
18. Banned Patterns

## 1. Scope And Authority

### 1.1 Purpose

1.1.1: This document defines the backend (Lua) coding standard for the MythicPlusTracker addon.

1.1.2: These rules apply to all Lua code in this repository: modules, utilities, event handlers, frames, commands, and locale-consuming code.

1.1.3: This document is a technical reference. It MUST define rules and constraints, not a review checklist.

### 1.2 Relationship To AGENTS.md

1.2.1: `AGENTS.md` documents project facts: file load order, the `.toc`/`.xml` structure, the namespace globals that exist, the exact SavedVariables names, and the validation tooling available. It answers "what exists and where."

1.2.2: This document defines engineering rules: how code MUST be named, structured, and written. It answers "what good code looks like here."

1.2.3: Where a rule in this document depends on a project fact (for example, the exact load-order file), this document references `AGENTS.md` instead of restating it. If the two documents ever disagree on a fact, `AGENTS.md` is authoritative for that fact.

### 1.3 Exclusions

1.3.1: This document MUST NOT define formatting rules. Formatting and mechanical lint issues are enforced by `luacheck` (`.luacheckrc`) and MUST NOT be debated manually during review.

1.3.2: This document MUST NOT define `.toc`/`.xml` load-order rules, UI layout dimensions, or feature-specific product decisions. See `AGENTS.md` for those.

1.3.3: This document MUST NOT define locale translation content. See `Locales/*.lua`.

### 1.4 Normative Language

1.4.1: The key words MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY MUST be interpreted as described in RFC 2119 and RFC 8174 when they appear in uppercase.

1.4.2: A deviation from a MUST or MUST NOT rule requires an explicit technical reason and review approval.

1.4.3: A deviation from a SHOULD or SHOULD NOT rule is acceptable only when the local code context makes the default worse.

## 2. Engineering Principles

### 2.1 Readability And Cognitive Complexity

2.1.1: Code MUST optimize for low cognitive complexity.

2.1.2: Code MUST make its behavior obvious from names, structure, and control flow without requiring explanatory comments.

2.1.3: Explicit, boring, predictable implementations MUST be preferred over clever ones. Lua rewards cleverness with fragile code — prefer the straightforward `if`/`elseif` over compact one-liners that hide a branch.

### 2.2 Separation Of Concerns

2.2.1: Domain logic MUST live in the relevant module table (for example `addon.Keystone`, `addon.Communication`), not in event handlers, frame scripts, or slash-command dispatch.

2.2.2: Event handlers and `OnEvent`/`OnClick`/`OnUpdate` scripts MUST translate WoW callbacks into calls to named module functions. They MUST NOT contain multi-step business logic inline.

2.2.3: UI-construction code (frames, textures, fonts) MUST NOT contain business decisions such as eligibility checks, data transformation, or state calculation. Compute the value first, then render it.

### 2.3 Minimal Implementation Surface

2.3.1: This addon intentionally has zero third-party dependencies (no Ace3, no LibStub). A new dependency MUST NOT be introduced without an explicit, reviewed reason.

2.3.2: Native Lua 5.1 and the Blizzard WoW API MUST be used before custom abstractions are introduced.

2.3.3: Custom wrappers, factories, generic utilities, or extra indirection layers (for example, a generic "event bus" on top of `RegisterEvent`) MUST NOT be introduced without a concrete current need across multiple real call sites.

2.3.4: Code MUST NOT contain placeholders, speculative TODOs, unfinished branches, commented-out code, or dead code.

## 3. Naming

### 3.1 General Naming

3.1.1: Names MUST be descriptive, domain-specific, and unambiguous.

3.1.2: Abbreviations MUST NOT be used in file names, table names, or function names (for example `Communication.lua`/`addon.Communication`, not `Comm.lua`/`addon.Comm`). This matches existing practice documented in `AGENTS.md`.

3.1.3: Generic variable names such as `data`, `tbl`, `result`, `tmp`, `val`, `obj` MUST NOT be used when a domain-specific name is possible (`keystoneInfo`, `runEntry`, `sidebarFrame`).

3.1.4: Locals and functions MUST use `camelCase`. Constants MUST use `SCREAMING_SNAKE_CASE`.

### 3.2 Function Names

3.2.1: Functions MUST describe the domain action they perform (`broadcastOwnKeystoneStatus`, `handleIncomingMessage`), not a generic verb like `process()`, `handle()`, or `update()` on its own.

3.2.2: When a WoW API callback shape forces a generic name (`OnEvent`, `OnUpdate`, `OnClick`), the surrounding module/frame name MUST carry the missing domain meaning, and the handler body MUST delegate to a precisely named function.

3.2.3: Boolean-returning functions MUST be phrased as questions, for example `isDebugModeEnabled()` or `hasPendingKeystoneRequest()`.

### 3.3 Namespace And Module Names

3.3.1: Shared addon state and utilities MUST live on the `addon` table (`local addonName, addon = ...`), never as bare globals.

3.3.2: Module-level UI roots MUST use the `MPT_<Name>` prefix (`MPT_Tracker`, `MPT_Dashboard`, `MPT_Sidebar`), pre-declared in the module's entry file as documented in `AGENTS.md`.

3.3.3: A namespace or module table MUST NOT be created for a single trivial helper function. Add the function to the closest existing relevant module instead.

## 4. Lua Language Baseline

### 4.1 Locals Over Globals

4.1.1: Every value MUST be declared `local` unless it is one of the two sanctioned global surfaces described in 4.2.

4.1.2: Implicit global assignment (forgetting `local`) MUST be treated as a bug. `luacheck` flags this — a `luacheck` warning about an undeclared/implicit global MUST be fixed, not suppressed.

4.1.3: Frequently accessed Blizzard API functions MAY be cached into locals inside a hot path (for example inside a loop or a frequently-firing handler) when profiling or clear reasoning shows it matters. This SHOULD NOT be done reflexively for every file — it adds noise without benefit outside real hot paths.

### 4.2 The Two Sanctioned Global Surfaces

4.2.1: `_G["MPT"]` (the shared `addon` table, assigned once in `init.lua`) and the two declared SavedVariables globals (`MythicPlusTrackerDB`, `MythicPlusTrackerAltDB`) are the only globals code MAY write to directly.

4.2.2: `MPT_<Name>` UI-module globals declared per `AGENTS.md`'s namespace pattern MAY be written to only from within that module's own files.

4.2.3: New top-level globals MUST NOT be introduced. New shared state belongs on `addon.<Feature>`.

### 4.3 Type Annotations

4.3.1: Public module functions (functions called from another file) MUST carry LuaCATS annotations (`---@param`, `---@return`) describing their parameter and return shapes.

4.3.2: Purely internal, file-local helper functions MAY omit annotations when their signature is trivially obvious from the name and a one-line body.

4.3.3: A parameter or field MUST be documented as nullable (`?type`) only when `nil`/absence is a genuine valid state, not as a way to avoid deciding a default.

### 4.4 Table Shape Discipline

4.4.1: Code MUST NOT index into a table key without knowing, from local construction or prior validation, that the key exists or is safely `nil`-able.

4.4.2: Values coming from outside this addon's direct control — SavedVariables loaded from disk, incoming addon-message payloads, event `...` varargs — MUST be validated before their fields are read. See section 5.2 and 5.3.

## 5. Data Shapes And Contracts

### 5.1 Module Tables As Public Contracts

5.1.1: A module table's public functions are its contract with the rest of the addon. Changing a public function's parameter order, return shape, or side effects MUST be treated as a breaking change requiring review, not a local tweak.

5.1.2: Public functions SHOULD return structured tables with documented (LuaCATS-annotated) shapes rather than bare positional multi-returns when more than two values are returned.

### 5.2 Event Payloads And Varargs

5.2.1: Event handler bodies MUST NOT assume the shape of `...` without checking the specific `event` name first — different events carry different argument lists.

5.2.2: Values extracted from event arguments that will be used in further logic (an item ID, a unit GUID, a message string) MUST be checked for `nil`/type before use when the event can legitimately fire with missing data.

### 5.3 SavedVariables Schema Stability

5.3.1: The shape of `MythicPlusTrackerDB` and `MythicPlusTrackerAltDB` MUST be treated as a stable, additive-only contract with existing users' saved data. See section 12.

5.3.2: A value read from a SavedVariables table MUST NOT be trusted to have the expected type without a lazy-init default (section 12.1), because it may have been written by an older addon version.

## 6. Functions And Control Flow

### 6.1 Function Scope

6.1.1: Functions MUST do one thing at one level of abstraction.

6.1.2: A function MUST be split when it mixes orchestration (deciding what to do) with low-level transformation (doing it), or when it needs internal comments to explain distinct phases.

6.1.3: Extracted helper functions MUST have a meaningful domain name and a clear standalone responsibility — not be extracted merely to shorten a function.

### 6.2 Control Flow

6.2.1: Guard clauses SHOULD be used to keep control flow flat (early `return`/`do return end` for the not-applicable case).

6.2.2: Deep nesting SHOULD be avoided; prefer flattening with guard clauses over adding another `if` level.

6.2.3: Nested ternary-style expressions MUST NOT be used.

6.2.4: Long chained `x = a or b or c or d` fallback expressions MUST NOT be used when a named intermediate variable or an explicit guard clause is more readable.

### 6.3 The `and`/`or` Ternary Trap

6.3.1: The `condition and a or b` idiom MUST NOT be used when `a` can itself be `false` or `nil`, because Lua then silently falls through to `b`, producing a wrong result. This is a well-known Lua correctness footgun, not a style preference.

6.3.2: When `condition and a or b` is used, `a` MUST be statically known to never be `false`/`nil` (for example a string literal or a table). Otherwise an explicit `if/else` assigning to a local MUST be used instead.

### 6.4 Boolean Flag Parameters

6.4.1: Boolean flag parameters that switch a function's behavior between two unrelated code paths SHOULD NOT be used. Split into two clearly named functions instead (for example `showFrame()` / `hideFrame()` rather than `setFrameVisibility(shown)`).

6.4.2: A boolean parameter MAY be used when it represents a single, genuinely boolean piece of domain data being passed through, not a mode switch.

## 7. Constants And Technical Strings

### 7.1 Constants

7.1.1: Repeated technical strings MUST be represented as constants: WoW event names used more than once, slash-command literals, locale keys, addon-message prefixes/types, atlas texture names, and color-table keys.

7.1.2: Constants that are part of an external contract (an addon-message protocol byte, a SavedVariables field name relied on elsewhere) SHOULD be grouped together near the code that owns that contract (for example the constants at the top of `Utils/Communication.lua`).

7.1.3: Magic strings MUST NOT be duplicated across modules, event handlers, commands, and UI files. Reference the constant instead.

### 7.2 Hardcoded Values

7.2.1: Business logic MUST NOT depend on hardcoded item IDs, spell IDs, or dungeon IDs scattered inline — centralize them as named constants near their point of use or in the relevant module.

7.2.2: User-facing color codes (`|cFF...`) and atlas texture names MUST NOT be hardcoded inline in UI or logic files. See section 15.2.

7.2.3: User-facing strings MUST NOT be hardcoded inline. See section 16.

## 8. Comments And Documentation

### 8.1 Comments

8.1.1: Code MUST be self-documenting through naming and structure. If a comment is needed to explain what local code does, rename or restructure the code first.

8.1.2: Comments MUST NOT restate what the code already says.

8.1.3: Comments MAY be used for non-obvious WoW API quirks (undocumented behavior, throttling limits, client-side caching oddities), non-obvious business decisions, or the reason behind a workaround.

8.1.4: Banner comments and commented-out code MUST NOT be introduced. This matches the existing rule in `AGENTS.md`.

### 8.2 LuaCATS Annotations

8.2.1: LuaCATS (`---@param`, `---@return`, `---@class`, `---@field`) annotations MUST be used for public module functions and for any table shape that Lua's syntax cannot otherwise express.

8.2.2: A LuaCATS annotation MUST NOT be added as a restatement of an already-obvious parameter name and type; it exists to add information a reader cannot get from the signature alone (for example, valid value ranges, or that a `nil` return means "not found" versus "error").

## 9. Modules And File Organization

### 9.1 Module Shape

9.1.1: A feature MUST be represented as one `addon.<Feature>` table (or one `MPT_<Module>` UI-root table) owning its related state and functions.

9.1.2: A module table's functions MUST relate to the same business responsibility. Unrelated functionality MUST NOT be bolted onto an existing module table for convenience — create or extend the correct module instead.

### 9.2 File Registration

9.2.1: A new `.lua` file MUST be registered in the correct `.toc`/`.xml` position, respecting the load order documented in `AGENTS.md`. Adding a file without registering it, or registering it in the wrong position relative to its dependencies, is a defect.

9.2.2: `bash Tools/toc-validator.sh` MUST pass after adding, removing, or renaming any file referenced from `.toc`/`.xml`.

## 10. WoW Events And Frames

### 10.1 Registration Pattern

10.1.1: Event-driven code MUST follow the established pattern: `CreateFrame("Frame")` (or an existing module frame), `RegisterEvent("EVENT_NAME")`, and `SetScript("OnEvent", function(self, event, ...) ... end)`.

10.1.2: A new generic event-dispatch abstraction (an "event bus", a decorator layer over `RegisterEvent`) MUST NOT be introduced. This project deliberately keeps event wiring direct and visible per section 2.3.

10.1.3: One-shot events (for example `PLAYER_LOGIN`, initial `ADDON_LOADED`) MUST be unregistered with `UnregisterEvent` once they have fired and their purpose is served.

### 10.2 Dispatch And Delegation

10.2.1: The `OnEvent` body MUST dispatch on the `event` argument (`if event == "..." then ... elseif event == "..." then ... end`) and MUST delegate each branch to a named module function rather than inlining multi-step logic in the branch.

10.2.2: A single `OnEvent` handler MUST NOT perform expensive processing for event types it does not need to act on. Check relevance first and return early.

### 10.3 Payload Validation

10.3.1: See 5.2 — event arguments MUST be validated for the specific event before use.

## 11. Performance And Hot Paths

### 11.1 OnUpdate Discipline

11.1.1: `OnUpdate` scripts MUST NOT run persistently for the addon's lifetime. `OnUpdate` MAY be used only for the duration of an active interactive operation (for example, dragging the minimap button), and MUST be cleared with `SetScript("OnUpdate", nil)` as soon as that operation ends.

11.1.2: Polling via `OnUpdate` MUST NOT be used as a substitute for the correct WoW event when a suitable event exists.

### 11.2 Throttling

11.2.1: Work triggered by high-frequency events (`GROUP_ROSTER_UPDATE`, `CHAT_MSG_ADDON`, `COMBAT_LOG_EVENT_UNFILTERED`) that results in outbound requests or expensive recomputation MUST be throttled with an explicit cooldown constant, following the existing pattern in `Utils/Communication.lua` (`REQUEST_COOLDOWN_SECONDS`).

11.2.2: A throttle/cooldown constant MUST be a named constant (section 7.1), not a bare inline number.

### 11.3 Redundant API Calls

11.3.1: Blizzard API calls that return stable data for the duration of a code path (for example unit/item lookups) MUST NOT be called repeatedly inside a loop when the result can be fetched once and reused.

11.3.2: Frequently-firing handlers MUST NOT allocate new tables/closures per invocation when a reusable local or module-level table would avoid the churn, if that churn is measurable and the handler fires often enough to matter (for example a `COMBAT_LOG_EVENT_UNFILTERED` listener). This SHOULD NOT be applied to rarely-firing handlers where it would only add complexity.

## 12. SavedVariables And Persistence

### 12.1 Lazy Initialization

12.1.1: Every SavedVariables table and nested field MUST be initialized with the lazy-init idiom before use: `MythicPlusTrackerDB = MythicPlusTrackerDB or {}`, then per-field `MythicPlusTrackerDB.someField = MythicPlusTrackerDB.someField or <default>`.

12.1.2: Code MUST NOT assume a SavedVariables field already exists just because a previous addon version wrote it — a user may be upgrading from a version that predates that field.

### 12.2 Additive Evolution

12.2.1: New fields MUST be added to SavedVariables tables in an additive, backward-compatible way. Existing fields MUST NOT be renamed or restructured in a way that silently drops or misreads existing users' data.

12.2.2: A SavedVariables table MUST NOT be reintroduced after removal without a clear reason — see the Guild Sync history documented in `AGENTS.md` (the removed `MythicPlusTrackerGuildDB` MUST NOT be reintroduced for a case that the live request/response model already covers).

12.2.3: If a field's meaning must change incompatibly, the change MUST include explicit handling for the old value (a one-time conversion on load), not a silent reinterpretation.

## 13. Addon Communication

### 13.1 Message Contracts

13.1.1: Addon-message prefixes and message-type identifiers MUST be constants, never inline string literals repeated across files.

13.1.2: Message payloads MUST respect the addon-message size limit and MUST be validated for shape before being decoded into business data.

### 13.2 Trust Boundary

13.2.1: Incoming addon messages MUST be treated as untrusted input. Code MUST NOT assume a message payload has the expected fields, count, or types without checking.

13.2.2: Outbound requests triggered by an inbound message or event MUST be throttled per section 11.2 to prevent feedback loops or spam across a group/guild.

## 14. Error Handling And User Feedback

### 14.1 Messaging

14.1.1: `print()` MUST NOT be used directly for any user-facing or debug output.

14.1.2: All output MUST go through the `addon.*Message()` helpers in `Core/Messages.lua` (`chatMessage`, `addonMessage`, `errorMessage`, `successMessage`, `warningMessage`, `infoMessage`, `debugMessage`), matching the existing rule in `AGENTS.md`.

14.1.3: The helper MUST match the severity of the message: `errorMessage` for failures, `warningMessage` for recoverable unexpected states, `successMessage`/`infoMessage` for normal outcomes, `debugMessage` for diagnostics gated behind debug mode.

### 14.2 pcall Policy

14.2.1: Blizzard API calls known to be able to throw, or to return unpredictable `nil` for reasons outside this addon's control (for example `C_*` APIs that depend on server-side data not yet available), MUST be wrapped in `pcall` when a failure would otherwise break the addon's UI or state.

14.2.2: A `pcall` failure MUST NOT be swallowed silently. It MUST be logged via `debugMessage` (or `errorMessage` when user-visible) with enough context — which call failed and what data was involved — to diagnose the issue later.

14.2.3: `pcall` MUST NOT be used as a substitute for validating input this addon controls (a locally-constructed table, a known SavedVariables shape). Use it only at the boundary where an external/uncontrolled call can fail.

### 14.3 Debug Diagnostics

14.3.1: Diagnostic-only logging MUST be gated by `addon.isDebugMode` (backed by `MythicPlusTrackerDB.debugMode`), so it is silent for users who have not enabled `/mpt debug`.

## 15. UI Construction And Theming

### 15.1 Frame Construction

15.1.1: UI MUST be built with the raw Frame API (`CreateFrame`, `:CreateTexture`, `:SetPoint`, `:SetAtlas`), consistent with existing modules. Ad-hoc XML widget templates MUST NOT be introduced for this purpose — this addon's `.xml` files are load-order manifests only, not UI templates.

15.1.2: UI-construction code MUST NOT contain business logic (see 2.2.3). Compute values in the owning module, then pass them to the frame-building code.

### 15.2 Colors And Atlas Textures

15.2.1: Raw `|cFF...` color escape codes MUST NOT be hardcoded in UI or logic files. Use `addon.colors.*` from `Core/Colors.lua` and close with `addon.colors.RESET`.

15.2.2: Atlas texture names MUST NOT be hardcoded inline. New decorative textures MUST be added to `Core/Theme.lua` and referenced from there, so re-skinning stays a one-file change.

## 16. Localization

### 16.1 Locale Keys

16.1.1: User-facing strings MUST NOT be hardcoded. They MUST be added as a key to `Locales/*.lua` and accessed via `addon.locale["KEY"]`.

16.1.2: A new locale key MUST be added to all five locale files (`en-US`, `de-DE`, `fr-FR`, `es-ES`, `ru-RU`) with `en-US` as the reference, matching keys exactly.

16.1.3: `bash Tools/locale-validator.sh` MUST pass after any locale-key change.

## 17. Testing And Quality Gates

### 17.1 Automated Gates

17.1.1: `luacheck .` MUST report zero warnings for changed code before it is considered done. `.luacheckrc` (Lua 5.1, `max_line_length = 160`, WoW globals whitelist) is the project's linting contract.

17.1.2: If `luacheck` flags a genuine WoW API global as undefined, it MUST be added to the `globals` table in `.luacheckrc` rather than suppressed inline.

17.1.3: `Tools/locale-validator.sh` and `Tools/toc-validator.sh` MUST pass for any change touching locale files or file registration.

### 17.2 Manual Verification

17.2.1: This repository has no automated Lua unit-test framework. Behavior changes MUST be manually verified in-game via `/reload` and by exercising the affected UI panel, slash command, or event path before the change is considered complete.

17.2.2: Bug fixes SHOULD document the reproduction steps used to confirm the fix, since a regression test cannot be committed alongside the fix today.

## 18. Banned Patterns

18.1: `print()` for any output MUST NOT be introduced. Use the `Core/Messages.lua` helpers.

18.2: Hardcoded `|cFF...` color codes or hardcoded atlas texture names MUST NOT be introduced. Use `addon.colors.*` and `Core/Theme.lua`.

18.3: New top-level globals outside `MPT`, the two SavedVariables tables, and module-declared `MPT_<Name>` UI roots MUST NOT be introduced.

18.4: A persistent `OnUpdate` script that runs for the addon's whole lifetime MUST NOT be introduced.

18.5: Business logic inlined directly in an `OnEvent`, `OnClick`, or slash-command dispatch body MUST NOT be introduced. Delegate to a named module function.

18.6: Unthrottled outbound addon-message or request loops triggered by high-frequency events MUST NOT be introduced.

18.7: `condition and a or b` MUST NOT be introduced when `a` can be `false` or `nil`.

18.8: A caught error or failed `pcall` MUST NOT be swallowed without logging.

18.9: Duplicated magic strings (event names, message prefixes, locale keys, atlas names) MUST NOT be introduced across files. Use a constant.

18.10: A new third-party library or build-step dependency MUST NOT be introduced without explicit, reviewed justification.

18.11: A destructive, non-additive rewrite of a SavedVariables table's shape MUST NOT be introduced without explicit handling for existing users' previously saved data.

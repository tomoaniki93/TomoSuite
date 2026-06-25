# Changelog

All notable changes to TomoSync are documented in this file. The format is based on
[Keep a Changelog](https://keepachangelog.com/); this project keeps granular per-file notes.

## [1.4.0] — 2026-06-25

### Added

#### Modules/Browser.lua
A **Time** view, reachable from a third tab in the bottom strip (**Items** / **Gold** / **Time**). It lists every tracked character with their total `/played` time (class-coloured, sorted descending, current character highlighted) plus a grand **Total** — there is no Warband line since playtime is per-character, not account-wide. Time is formatted compactly (`Xj Yh Zm` / `Xd Yh Zm`). The current character's time updates **live** once per second via a ticker that runs *only* while the Time tab is visible (and is cancelled when the window hides), and which re-renders values without re-sorting so rows never flicker. The character list is a scrollable `FauxScrollFrame` (skinned + mouse-wheel), consistent with the Gold view. Characters that have never been captured show a grey dash.

#### Modules/Scanner.lua
Playtime tracking. WoW exposes no synchronous getter, so the data is captured by calling `RequestTimePlayed()` once per session (2 s after login) and reading `TIME_PLAYED_MSG`. Per character we store `played` (cumulative seconds at the last anchor), `playedAt` (wall-clock at that anchor) and `playedLevel`. The **current** character is shown live as `played + (now - playedAt)`; alts show their frozen snapshot. The snapshot is re-anchored on `PLAYER_LOGOUT` — just before SavedVariables are written — so the persisted value stays exact when viewed from another character. A runtime `playedCaptured` guard prevents adding offline time before the first capture of the session. The default *"Time played"* chat line is suppressed for our silent request by wrapping `ChatFrame_DisplayTimePlayed` (best-effort; harmless if absent), reset on the next frame so manual `/played` still prints.

#### Locales/*.lua
Added 5 keys (`TAB_TIME`, `PLAYED`, `TIME_D`, `TIME_H`, `TIME_M`) to all six locales (parity now 51 keys each).

## [1.3.0] — 2026-06-20

### Changed

#### Modules/Browser.lua
The items list is now organised into **collapsible category sections** (accordion) instead of one long flat scroll. Items are grouped into Consumables, Reagents, Equipment, Containers, Recipes, Quest and Miscellaneous — classified by `classID` from `GetItemInfoInstant` (synchronous, so grouping is immediate). Each category shows a header with a +/- toggle and its item count; clicking collapses or expands it (state kept for the session). A search expands all categories so matches are always visible. Item names are now coloured by quality, and the default selection lands on the first item under the first expanded category.

#### Core.lua
Added `GetItemInstant` (returns icon + `classID` in a single `GetItemInfoInstant` call) used by the category grouping.

#### Locales/*.lua
Added 7 category keys (`CAT_CONSUMABLE`, `CAT_COMPONENTS`, `CAT_EQUIPMENT`, `CAT_CONTAINER`, `CAT_RECIPE`, `CAT_QUEST`, `CAT_MISC`) to all six locales (parity now 46 keys each).

## [1.2.0] — 2026-06-20

### Added

#### Modules/Browser.lua
A **Gold** view, reachable from a new tab strip at the bottom of the window (**Items** / **Gold**). The gold view lists every tracked character with their gold (class-coloured, sorted by amount, current character highlighted), plus a shared **Warband bank** gold line and a grand total — all formatted with coin icons via `GetCoinTextureString`. The character list is a scrollable `FauxScrollFrame` (skinned + mouse-wheel) so any number of alts fits. Switching tabs shows/hides the relevant view; the item-name refresh is now gated to the items view so it can't bleed into the gold page. Window height increased to fit the tab strip.

#### Modules/Scanner.lua
Gold tracking. Character gold is read with `GetMoney()` on `PLAYER_MONEY` and at login (`ScanMoney`, stored per character). Warband bank gold is read with `C_Bank.FetchDepositedMoney(Enum.BankType.Account)` during the bank scan (stored under `_account.warband.money`); a `PLAYER_MONEY` event while at the bank also refreshes it, so deposits/withdrawals are captured.

#### Locales/*.lua
Added `GOLD` and `TAB_ITEMS` to all six locales (parity now 39 keys each).

## [1.1.4] — 2026-06-20

### Added

#### Modules/Minimap.lua *(new)*
A self-contained minimap button (no LibDBIcon dependency — TomoSync stays library-free). It is draggable around the minimap edge, its position is saved account-wide, and it uses the suite's flat purple look via a circular mask. **Left-click** opens the browser window, **right-click** opens settings; hovering shows a tooltip with those hints.

#### Core.lua
Added account-wide minimap defaults (`_account.minimap.angle`, `_account.minimap.hide`) in `InitDB`.

#### Config.lua
Added a **Minimap button** checkbox to show or hide the button.

#### Locales/*.lua
Added 3 keys to all six locales (`CFG_MINIMAP_BUTTON`, `MM_LEFT`, `MM_RIGHT`), keeping full parity at 37 keys each.

## [1.1.3] — 2026-06-20

### Fixed

#### Modules/Scanner.lua
The Warband (account) bank was not being captured. Two root causes, both tied to the Midnight bag-index reassignment (confirmed against the API docs):
- **Timing.** The Warband tabs are scanned 0.4 s after `BANKFRAME_OPENED`, but those tab containers can finish loading *after* the bank opens (e.g. when the player views the Warband tab), so the early scan saw nothing. Fixed by (a) adding a second scan at 1.2 s and (b) re-scanning the bank + Warband on `BAG_UPDATE` while the bank is open — `BAG_UPDATE` fires for the bank/Warband containers as they populate, so the data is now captured whenever it arrives.
- **Robustness.** `ScanWarband` now falls back to the fixed Midnight account-bank range (bag indices 12–16, `AccountBankTab_1..5`) when `C_Bank.FetchPurchasedBankTabIDs(Enum.BankType.Account)` returns nothing. It also returns the number of distinct items found, surfaced in the bank-open message (e.g. *"Banque scannée. Banque Warband: 23"*) as live confirmation.

Also corrected the **character bank** scan: in Midnight, bag index `-1` is now the **keyring**, not the bank, so reading it was pointless. The character bank is entirely tab-based now (indices 6–11); the obsolete `-1` read was removed and the scan relies on `C_Bank.FetchPurchasedBankTabIDs(Enum.BankType.Character)` with a 6–11 fallback.

## [1.1.2] — 2026-06-20

### Changed

#### Modules/Widgets.lua
Added `SkinScrollBar` — restyles a FauxScrollFrame scrollbar into a thin, flat modern bar: the original groove textures and the up/down arrow buttons are hidden (the buttons keep their geometry via alpha so the thumb's travel range is preserved), a subtle track background is drawn, and the thumb becomes a slim flat purple bar. Written defensively so template differences degrade gracefully instead of erroring.

#### Modules/Browser.lua
Applied `SkinScrollBar` to the item-list scrollbar (the default Blizzard scrollbar clashed with the flat-dark window). Added mouse-wheel scrolling to the list — two rows per tick, wired on both the scroll frame and the row buttons — which also covers scrolling now that the arrow buttons are hidden.

## [1.1.1] — 2026-06-20

### Fixed

#### Modules/Browser.lua
**Critical:** `detail.rows` was never initialised before the detail-row pool was populated, so `Build()` raised *"attempt to perform indexed assignment on field 'rows' (a nil value)"* and aborted **before** creating the rest of the detail panel (`sep2`, the total row, the footer buttons, the `GET_ITEM_INFO_RECEIVED` handler and the `UISpecialFrames` entry). The window therefore showed only the left-hand item list while the right-hand breakdown table stayed blank, and `UpdateDetail()` then threw on the missing `sep2`. Initialised `detail.rows = {}` — `Build()` now completes and the full breakdown table renders.

### Changed

#### Modules/Browser.lua
Polished the detail panel to match the design mockup: an item-type subtitle under the item name, a class-coloured dot on each character row, the current character's row highlighted with a left accent bar, a "shared" pill on the Warband line, and a left accent bar on the selected item in the list.

## [1.1.0] — 2026-06-20

### Added

#### Modules/Browser.lua *(new)*
Searchable browser window — "who has what, and where". A `FauxScrollFrame` item list is filtered live by the search box; the right-hand detail table shows a per-character breakdown (bags / bank / total, class-coloured) plus a shared **Warband** row and a grand total. Item icons resolve instantly via `GetItemInfoInstant`; names resolve asynchronously and the list refreshes on `GET_ITEM_INFO_RECEIVED`. Opened with `/tms`. Hovering a row shows the native item tooltip.

#### Modules/Widgets.lua *(new)*
Shared flat-dark UI toolkit for the suite look: palette, `StyleFlatFrame`, header bar, diamond accent, separators, flat buttons, checkboxes, and `OptionsSliderTemplate` sliders. Checkbox/slider initial values are set with a deferred `C_Timer.After(0, …)`. All solid fills use `WHITE8X8` + `SetVertexColor` (never `SetColorTexture`).

### Changed

#### Modules/Scanner.lua
Rebuilt container enumeration for the Midnight bank changes. **Root cause:** the reagent bank (index `-3`) was removed in 11.x and the character-bank / Warband containers are no longer at fixed indices. Character bank tabs and the account-wide Warband bank are now enumerated via `C_Bank.FetchPurchasedBankTabIDs(Enum.BankType.Character / Account)` with safe fallbacks; carried bags use `Constants.InventoryConstants`. Every `C_Container` / `C_Bank` call is wrapped in `pcall`, and `issecretvalue()` guards prevent summing or persisting secret values (Midnight silently converts them to tainted strings and drops them from SavedVariables). Added `ScanWarband`; `BANKFRAME_OPENED` now scans both the character bank and the Warband bank.

#### Modules/Tooltip.lua
Added a shared **Warband** line (cyan, tagged "shared") folded into the grand total, and removed the dead reagent line. **Root cause of the hyperlink fix:** when `TooltipDataProcessor` is available it already covers hyperlinks, so the separate `SetHyperlink` hook was adding the lines a second time for chat links — it is now registered only in the legacy fallback branch.

#### Core.lua
Removed the Lua `version` constant; the load message now reads the version from the `.toc` via `C_AddOns.GetAddOnMetadata` (version lives only in the `.toc`). Added the reserved `_account` store for the shared Warband bank, a `PurgeReagent` migration that strips obsolete reagent counts from saved data, and helpers (`ForEachChar`, `GetWarbandCount`, `GetItemName` / `GetItemIcon` / `GetItemQuality`, `ClassColorTriple`, `ResetData`). `ForEachChar` skips the `_account` key so it is never treated as a realm. `/tms` now opens the browser and `/tms config` opens settings.

#### Config.lua
Reskinned to the flat-dark suite style via Widgets (replacing the old `UI-DialogBox` backdrop). Replaced the reagent toggle with a **Warband** toggle. Getters/setters now read `TS.db.settings` dynamically so they survive a data reset (previously they captured the settings table by upvalue and broke after a reset). Solid separators use `SetVertexColor` instead of `SetColorTexture`. Added a confirmation popup before clearing all data.

#### Database.lua
Documented the new `_account.warband` structure and the per-character `{ bags, bank, equip }` item shape. Replaced the `showReagent` default with `showWarband`.

#### TomoSync.toc
Bumped to `1.1.0`; `## Interface: 120007, 120005, 120000`. Registered `Modules\Widgets.lua` and `Modules\Browser.lua`. **Locale load order fixed:** `enUS.lua` now loads **last**. **Root cause:** it previously loaded before deDE / esES / itIT / ptBR, and because each locale file assigns `TomoSyncLocale = {…}` (a full replace), those locales wiped the English fallback — any key missing from them became `nil`. With enUS last it backfills every gap.

#### Locales/*.lua
Added 12 keys to all six locales (Warband, "shared", search/browser strings, button labels, data-cleared message) keeping full parity at 34 keys each. `CMD_HELP` updated to mention the window.

### Removed

- Reagent-bank scanning and the reagent tooltip/config line — the reagent bank no longer exists on the Midnight client.

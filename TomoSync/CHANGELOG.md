# Changelog

All notable changes to TomoSync are documented in this file. The format is based on
[Keep a Changelog](https://keepachangelog.com/); this project keeps granular per-file notes.

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

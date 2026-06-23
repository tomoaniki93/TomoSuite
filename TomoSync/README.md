# TomoSync

![TomoSync](https://img.shields.io/badge/TomoSync-v1.3.0-CC44FF?style=for-the-badge) ![WoW](https://img.shields.io/badge/WoW-Midnight-blue?style=for-the-badge) ![Interface](https://img.shields.io/badge/Interface-120007-orange?style=for-the-badge)

Cross-character item tracker for World of Warcraft (Retail — Midnight), part of the **TomoSuite** collection. TomoSync records what each of your characters is carrying — bags, character bank and equipped gear — plus the shared **Warband bank**, and surfaces it in item tooltips and a searchable browser window.

## Features

- Per-character tracking of **bags**, **character bank** and **equipped** items.
- Account-wide **Warband bank** scanning — the shared bank is stored once, not duplicated per character.
- **Item tooltips**: per-character breakdown, a shared Warband line, and a grand total.
- **Browser window** (`/tms`): filter any tracked item and instantly see who owns it and where (bags / bank / Warband / total), class-coloured.
- Per-character settings: toggle each source, restrict to the current realm, set a minimum-count threshold.
- 6 locales: enUS, frFR, deDE, esES, itIT, ptBR.

## Slash commands

| Command | Action |
| --- | --- |
| `/tms` | Open the browser window |
| `/tms config` | Open settings |
| `/tms scan` | Force a bag / equipment scan |

## Midnight API notes

The 11.x / 12.0 bank rework changed how containers are enumerated, so the scanner was rebuilt accordingly:

- The **reagent bank** (old index `-3`) was removed; the legacy reagent code path has been dropped.
- **Character bank tabs** and the **Warband bank** are enumerated dynamically through `C_Bank.FetchPurchasedBankTabIDs(Enum.BankType.Character | Account)` instead of hardcoded bag ranges, with safe fallbacks. Carried bags use `Constants.InventoryConstants` ranges (back-pack + bags + reagent bag).
- Every `C_Container` / `C_Bank` call is wrapped in `pcall`, and item counts are guarded with `issecretvalue()` before any arithmetic — secret values are never summed or written to SavedVariables (Midnight silently turns them into tainted strings and drops them on reload).

## Data layout

Stored in `TomoSyncDB`:

- `["RealmName"]["CharName"].items[itemID] = { bags, bank, equip }`
- shared account data under the reserved `_account` key → `warband.items[itemID] = count`

## Suite standards

Lua 5.1 only; purple accent `#CC44FF`; solid textures via `WHITE8X8` + `SetVertexColor`; `OptionsSliderTemplate` sliders; `hooksecurefunc` post-hooks. Validated before each release with `luac5.1 -p`, a forbidden-pattern scan, an EOL check and a ZIP integrity test.

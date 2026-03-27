# TomoDamageMeter

# ![TomoDamageMeter](https://img.shields.io/badge/TomoDamageMeter-v1.0.4-0cd29f?style=for-the-badge) ![WoW](https://img.shields.io/badge/WoW-Midnight-blue?style=for-the-badge) ![Interface](https://img.shields.io/badge/Interface-120001-orange?style=for-the-badge)

A standalone, lightweight damage meter addon for **World of Warcraft: Midnight** (Retail). It replaces Blizzard's default Damage Meter UI with a dark, customizable, multi-window interface while leveraging the built-in `C_DamageMeter` data API.

## Features

- **9 meter types** across 3 categories:
  - **Damage** — DPS, Damage Taken, Avoidable Damage Taken, Enemy Damage Taken
  - **Healing** — HPS, Absorbs
  - **Actions** — Interrupts, Dispels, Deaths
- **Spell Breakdown window** — Dedicated standalone window showing per-spell details for any player. Displays spell icon, name, total, DPS/HPS per spell, and percentage. Includes a player selector strip to switch between group members without closing the window.
- **Category toggles** — Enable or disable entire meter categories (Damage, Healing, Actions) from the settings panel. Disabled categories are hidden from navigation and dropdowns.
- **Up to 3 independent windows**, each with its own meter type and session
- **2 session modes** — Current encounter and Overall
- **Live combat timer** updated every second
- **Bar animations** on data changes
- **Class-colored bars** with gradient fill
- **Report to chat** — Say, Party, Raid, Guild, Whisper
- **Lockable & resizable** windows with saved positions
- **Out-of-combat opacity** fade
- **Localized** in 6 languages: English, French, German, Spanish, Italian, Portuguese (Brazil)
- **Zero external dependencies** — pure namespace-based, no Ace3 or third-party libraries required

## Requirements

- World of Warcraft Retail (Midnight, Interface 120000+)
- The built-in `Blizzard_DamageMeter` module (loaded automatically by the game)

## Installation

1. Download or clone this repository into your WoW AddOns folder:
   ```
   World of Warcraft\_retail_\Interface\AddOns\TomoDamageMeter
   ```
2. Restart the game or reload the UI (`/reload`).

## Usage

### Slash Commands

| Command | Description |
|---|---|
| `/tdm` or `/tomodm` | Open the settings panel |
| `/tdm toggle` | Toggle visibility of all meter windows |
| `/tdm reset` | Reset all combat sessions |
| `/tdm lock` | Toggle lock on all windows |
| `/tdm help` | Print the command list in chat |

### Navigation

- **Click the category label** (left of the header) to cycle between enabled categories (Damage, Healing, Actions).
- **Click the type label** to cycle through meter types within the current category.
- **Click the session label** (sub-header) to switch between Current and Overall.

### Header Buttons (left to right)

| Icon | Action |
|---|---|
| Gear | Open the settings panel |
| Magnifying glass | Open the Spell Breakdown window |
| Lock | Toggle lock on the window position |
| Chat bubble | Report data to the selected chat channel |
| Reset | Reset all combat sessions |

### Spell Breakdown

The Spell Breakdown window can be opened in two ways:

1. **Click the magnifying glass icon** in any meter window header — opens the breakdown with the first player auto-selected.
2. **Click a player bar** in the meter — opens the breakdown with that player pre-selected.

The window includes a **player selector strip** at the top showing all group members with class-colored names. Click any name to switch the spell list to that player. The spell list shows ranked spells with icon, name, total damage/healing, per-second rate, and percentage of the player's total.

The window is movable, resizable (360×300 to 600×800), closable with ESC, and its opacity is configurable in the settings.

## Settings

### Appearance

| Option | Range | Default |
|---|---|---|
| Font Size | 8 – 16 | 10 |
| Bar Height | 14 – 32 | 21 |
| Background Opacity | 0 – 1 | 0.80 |
| Out of Combat Opacity | 0.1 – 1 | 1.0 |
| Spell Breakdown Opacity | 0.1 – 1 | 0.85 |

### General

| Option | Default |
|---|---|
| Strip Realm Names | Enabled |
| Use Class Color as accent | Disabled (green accent) |
| Auto-reset on instance entry | Enabled |

### Categories

| Option | Default |
|---|---|
| Damage | Enabled |
| Healing | Enabled |
| Actions | Enabled |

Toggle entire meter categories on or off. Disabled categories are hidden from navigation cycling and the meter type dropdown. At least one category must remain enabled.

### Report

| Option | Default |
|---|---|
| Channel | Say |
| Lines | 5 |

### Windows

Add or remove windows (1 to 3). Each new window spawns with a slight offset to avoid overlap. Each window has its own meter type, session type, and lock setting.

## Data Columns

Each bar in the main meter can display up to 3 value columns:

| Column | Default Visible | Format Options |
|---|---|---|
| Rate (DPS/HPS) | Yes | short, 1 decimal, 2 decimals, full |
| Total | Yes | short, 1 decimal, 2 decimals, full |
| Percent | No | integer, decimal |

## Technical Notes

- **Data source**: All meter and spell data comes from the `C_DamageMeter` API (Midnight). No combat log parsing (CLEU) is used, as `COMBAT_LOG_EVENT_UNFILTERED` is a protected event in Midnight.
- **Taint-free**: The addon depends on `Blizzard_DamageMeter` for data access and respects the Midnight taint model.
- **Spell icons and names** are resolved via `C_Spell.GetSpellInfo()`.

## Changelog

### v1.0.4
- **New**: Spell Breakdown window — standalone, resizable window with per-spell details and player selector strip
- **New**: Magnifying glass icon in the meter header to open the Spell Breakdown
- **New**: Category toggles (Damage, Healing, Actions) in the settings panel
- **New**: Spell Breakdown Opacity slider in the settings panel
- **Fix**: Tab bar overflow — long tab names (e.g. "Interruptions") are now capped and truncated
- **Fix**: Settings panel height adjusted for new sections

### v1.0.3
- Initial public release

## Author

**TomoAniki** — Part of the **TomoSuite** addon family.

## License

All rights reserved © TomoAniki.

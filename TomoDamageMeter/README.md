# TomoDamageMeter

# ![TomoDamageMeter](https://img.shields.io/badge/TomoDamageMeter-v1.0.1-0cd29f?style=for-the-badge) ![WoW](https://img.shields.io/badge/WoW-Midnight-blue?style=for-the-badge) ![Interface](https://img.shields.io/badge/Interface-120001-orange?style=for-the-badge)

A standalone, lightweight damage meter addon for **World of Warcraft: Midnight** (Retail). It replaces Blizzard's default Damage Meter UI with a dark, customizable, multi-window interface while leveraging the built-in `C_DamageMeter` data API.

## Features

- **9 meter types** across 3 categories:
  - **Damage** — DPS, Damage Taken, Avoidable Damage Taken, Enemy Damage Taken
  - **Healing** — HPS, Absorbs
  - **Actions** — Interrupts, Dispels, Deaths
- **Up to 3 independent windows**, each with its own meter type and session
- **2 session modes** — Current encounter and Overall
- **Live combat timer** updated every second
- **Bar animations** on data changes
- **Class-colored bars** with gradient fill
- **Report to chat** — Say, Party, Raid, Guild, Whisper
- **Lockable & resizable** windows with saved positions
- **Out-of-combat opacity** fade
- **Localized** in English and French
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

- **Click the category label** (left of the header) to cycle between Damage, Healing, and Actions.
- **Click the type label** to cycle through meter types within the current category.
- **Click the session label** (sub-header) to switch between Current and Overall.
- Use the **gear icon** to open settings, the **lock icon** to lock/unlock, the **report icon** to send data to chat, and the **reset icon** to clear sessions.

## Settings

### Appearance
| Option | Range | Default |
|---|---|---|
| Font Size | 8 – 16 | 10 |
| Bar Height | 14 – 32 | 21 |
| Background Opacity | 0 – 1 | 0.80 |
| Out of Combat Opacity | 0.1 – 1 | 1.0 |

### General
| Option | Default |
|---|---|
| Strip Realm Names | Enabled |
| Use Class Color as accent | Disabled (green accent) |

### Report
| Option | Default |
|---|---|
| Channel | Say |
| Lines | 5 |

### Windows
- Add or remove windows (1 to 3). Each new window spawns with a slight offset to avoid overlap.

## Data Columns

Each bar can display up to 3 value columns:

| Column | Default Visible | Format Options |
|---|---|---|
| Rate (DPS/HPS) | Yes | short, 1 decimal, 2 decimals, full |
| Total | Yes | short, 1 decimal, 2 decimals, full |
| Percent | No | integer, decimal |

## Author

**TomoAniki** — Part of the **TomoSuite** addon family.

## License

All rights reserved © TomoAniki.


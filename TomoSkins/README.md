# TomoSkins

> Standalone UI skin addon for World of Warcraft: Midnight

# ![TomoSkins](https://img.shields.io/badge/TomoSkins-v1.0.0-0cd29f?style=for-the-badge) ![WoW](https://img.shields.io/badge/WoW-Midnight-blue?style=for-the-badge) ![Interface](https://img.shields.io/badge/Interface-120001-orange?style=for-the-badge)

---

## Overview

**TomoSkins** is a fully standalone UI reskin addon extracted from the TomoMod suite. It bundles five complementary cosmetic modules that restyle core Blizzard interface elements without replacing their functionality:

- **Character Skin** — restyled character and inspection windows with item detail overlays
- **Action Bar Skin** — per-bar opacity, class colors, and combat-only visibility
- **Minimap** — square minimap with class-colored or black border
- **Info Panel** — slim data bar beneath the minimap (time, coordinates, durability)
- **Objective Tracker** — semi-transparent background and custom font sizes for the quest tracker

TomoSkins is completely independent — it does not require TomoMod, TomoPlates, TomoFrames, or TomoCooldown to function.

---

## Features

---

### Character Skin

Replaces the default Character and Inspection frame with a cleaner, more compact layout.

**Features:**
- Restyled character sheet with consistent panel borders and background
- Restyled inspection window matching the character sheet aesthetic
- Item information overlay: displays item level, enchant, and gem slot details directly on equipment slots
- **Midnight enchant support** — enabled by default, adapts enchantable slot detection to the upcoming Midnight expansion's revised slot configuration
- Global scale slider to resize the window independently of the UI scale

**Midnight enchants** are active out of the box. If you want to revert to the standard Midnight slot list, uncheck the option in the Character tab.

---

### Action Bar Skin

Applies a visual skin to WoW's action bars with per-bar opacity and context-sensitive visibility.

**Features:**
- Class-colored border and glow on action buttons
- Per-bar opacity control (0–100%) for all 10 bar types
- **Combat-only mode** per bar: bars fade out of combat and reappear when combat starts
- **Shift reveal**: hold Shift to temporarily show bars that are normally hidden
- Colors update dynamically on spec change

**Supported bars:**

| Key | Bar |
|---|---|
| `ActionButton` | Action Bar 1 |
| `MultiBarBottomLeft` | Action Bar 2 (Bottom Left) |
| `MultiBarBottomRight` | Action Bar 3 (Bottom Right) |
| `MultiBarRight` | Action Bar 4 (Right) |
| `MultiBarLeft` | Action Bar 5 (Left) |
| `MultiBar5` | Action Bar 6 |
| `MultiBar6` | Action Bar 7 |
| `MultiBar7` | Action Bar 8 |
| `PetActionButton` | Pet Bar |
| `StanceButton` | Stance / Shapeshift Bar |

---

### Minimap

Resizes and reskins the Minimap into a clean square shape.

**Features:**
- Forces the Minimap into a perfect square (removes the default round shape)
- Configurable pixel size (150–300 px)
- Independent scale slider (0.5×–2.0×)
- Border color: **class color** (updates on login and spec change) or flat **black**
- Border color is shared with the Info Panel for a unified look

---

### Info Panel

A slim information bar that attaches below the Minimap.

**Features:**
- **Time display** — local or server time, 12h or 24h format
- **Zone coordinates** — X / Y position updated as you move
- **Durability** — shows lowest item durability as a percentage, color-coded (green → yellow → red)
- Matches the Minimap border color automatically
- Automatically hides when the Minimap skin is disabled

---

### Objective Tracker

Adds a subtle background skin to Blizzard's default Objective Tracker (quest list).

**Features:**
- Semi-transparent backdrop behind the tracker (alpha configurable from 0 to 1)
- Optional visible border
- **Hide when empty** — automatically hides the tracker background when no quests are tracked
- Independent font size controls for four text levels:
  - Header (zone / dungeon name)
  - Category (quest group label)
  - Quest title
  - Objective line

---

## Installation

1. Download `TomoSkins-1_0_0.zip`
2. Extract to your WoW AddOns folder:
   ```
   World of Warcraft/_retail_/Interface/AddOns/TomoSkins/
   ```
3. Enable **TomoSkins** in the AddOns list at character select
4. Type `/ts` in-game to open configuration

---

## Slash Commands

| Command | Description |
|---|---|
| `/ts` | Open configuration window |
| `/ts refresh` | Re-apply all active skins immediately |
| `/ts reset` | Reset all settings to defaults |

---

## Configuration

Open with `/ts` or via **Escape → Settings → AddOns → TomoSkins**.

### Character Tab
- Enable / disable the character skin
- Skin the character sheet independently from the inspection window
- Toggle item information overlay
- Toggle Midnight enchant slot support *(enabled by default)*
- Window scale slider

### Bars Tab
- Enable / disable the action bar skin
- Class color toggle
- Shift-reveal toggle
- Per-bar opacity slider (×10 bars)
- Per-bar combat-only checkbox (×10 bars)

### Minimap Tab

**Minimap section:**
- Enable / disable the minimap skin
- Size in pixels (150–300)
- Scale multiplier (0.5×–2.0×)
- Border color: class / black

**Info Panel section:**
- Enable / disable the info panel
- Show / hide time
- 24h format toggle
- Server time toggle
- Show / hide coordinates
- Show / hide durability

### Objectives Tab
- Enable / disable the tracker skin
- Background opacity slider
- Show / hide border
- Hide-when-empty toggle
- Font size sliders: header, category, quest title, objective line

### About Tab
- Module summary
- Reset all settings to defaults button

--- 

## Credits

Extracted and adapted from **TomoMod** by TomoAniki.

# TomoGroupFrame

**Modern group frames for dungeons and raids.**

TomoGroupFrame is a lightweight, fully customizable party and raid frame replacement built for The War Within. Part of the **Tomo Suite** addon collection, it replaces Blizzard's default group frames with a clean, dark-themed UI that stays out of your way while giving you all the information you need.

---

## Features

### Party Frames (5-man)
- Automatically shown in dungeons and open-world parties
- Hidden in PvP instances
- Configurable layout: grow **down**, **up**, **left**, or **right**
- Secure unit buttons with full click-targeting and right-click menu support

### Raid Frames (up to 40-man)
- Automatically shown in raid instances, hidden in PvP
- 8 group containers with optional group labels (G1–G8)
- Configurable groups per row for different raid sizes
- **Per-size positioning**: save independent screen positions for 10, 15, 20, 25, 30, and 40-man raids — the addon auto-detects and repositions when you enter a raid

### Dispel Highlight
- Colored border overlay when a unit has a dispellable debuff **you can remove**
- Color-coded by dispel type:
  - **Magic** — Blue
  - **Curse** — Purple
  - **Disease** — Brown
  - **Poison** — Green
- Subtle inner glow effect for visibility
- Configurable border thickness

### HoT Tracking
- Displays active Heal-over-Time effects from **all healers** in your group
- Uses Blizzard spell icons with cooldown spirals and stack counts
- Tracks 40+ HoT spells across all healer specs:
  - **Druid**: Rejuvenation, Regrowth, Lifebloom, Wild Growth, Germination, Cenarion Ward, Cultivation
  - **Priest**: Renew, Prayer of Mending, Echo of Light, Atonement, Power Word: Shield
  - **Paladin**: Glimmer of Light, Bestow Faith, Beacon of Light/Faith
  - **Shaman**: Riptide, Earthliving
  - **Monk**: Renewing Mist, Enveloping Mist, Life Cocoon, Essence Font
  - **Evoker**: Dream Breath, Reversion, Echo, Call of Ysera, Lifebind

### Customization
- **6 bar textures** included: Flat, Gradient, Glossy, Striped, Smooth, Minimalist
- **4 font choices**: Poppins, Poppins Bold, Expressway, Accidental Presidency
- Class-colored health bars and names
- Adjustable frame width, height, spacing
- Name truncation to fit frame size
- HP percentage display
- Role icons and raid target markers
- Out-of-range alpha dimming
- Optional power bar with configurable height

### Profile System
- Create, load, rename, duplicate, and delete named profiles
- **Per-specialization profiles**: assign a profile to each spec, auto-switches on spec change
- Reset individual modules (Party / Raid) or reset everything

### Test Mode
- Preview party frames with 5 fake players (class-colored)
- Preview raid frames with selectable size: **10, 15, 20, 25, 30, or 40 players**
- Groups beyond the test size are automatically hidden

---

## Slash Commands

| Command | Action |
|---|---|
| `/tgf` | Open the config panel |
| `/tgf test` | Toggle party test mode |
| `/tgf test raid` | Toggle raid test mode |
| `/tgf lock` | Toggle unlock mode (drag to reposition) |
| `/tgf reset` | Reset all settings to defaults |
| `/tgf help` | Show available commands |

---

## Installation

1. Download and extract into your `World of Warcraft/_retail_/Interface/AddOns/` folder
2. The folder should be named `TomoGroupFrame`
3. Reload your UI or restart the game
4. Type `/tgf` to open the configuration panel

---

## TWW Compatibility

TomoGroupFrame is fully compatible with The War Within's **secret number** system. Health values from `UnitHealth()` are handled entirely through C-side widget methods (`SetMinMaxValues`, `SetValue`, `SetFormattedText`) — no Lua arithmetic on tainted values, no pcall workarounds. The same approach used by oUF and other major unit frame addons.

---

## Tomo Suite

TomoGroupFrame is part of the **Tomo Suite**, a collection of World of Warcraft addons sharing consistent branding, bilingual support (English + French), and a unified dark UI theme.

| Addon | Description |
|---|---|
| **TomoMod** | Lite interface overhaul with UnitFrames, Nameplates, QOL |omoSkins** | UI skinning |
| **TomoMythic** | Mythic+ interface replacement |
| **TomoSync** | Item sync across characters |
| **TomoMail** | Advanced mail management |
| **TomoPorter** | Dungeon/Raid/Mage teleporter display |
| **TomoGroupFrame** | Party & Raid frames ← *you are here* |

---

## Localization

- **English** (enUS) — Full support
- **French** (frFR) — Full support

---

## Feedback & Issues

Found a bug or have a suggestion? Leave a comment on the CurseForge project page or open an issue. Pull requests are welcome.

---

*Made by TomoAniki*

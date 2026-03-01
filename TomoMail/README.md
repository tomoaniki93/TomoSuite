# TomoMail

# ![TomoMail](https://img.shields.io/badge/TomoMail-v1.0.0-0cd29f?style=for-the-badge) ![WoW](https://img.shields.io/badge/WoW-Midnight-blue?style=for-the-badge) ![Interface](https://img.shields.io/badge/Interface-120001-orange?style=for-the-badge)

> Streamlined in-game mail manager for World of Warcraft — send to your alts, guild members, and recent recipients in seconds.

---

## Features

**Smart Recipient Dropdown**
A small button appears next to the **To:** field whenever you open a mailbox. Click it to reveal a categorized contact list:

- **My Characters** — all your alts on the same realm and faction, displayed with their class color and level, auto-detected as you log in on each character.
- **Guild Members** — your entire guild roster with an online/offline indicator. Can be filtered to online members only.
- **Recent** — the last recipients you mailed, up to 25 entries.

**Send to All Alts**
A dedicated button lets you send the current mail (subject + body) to every one of your registered alts in a single click. Sends are queued with a small delay to respect the server throttle.

**Name Autocomplete**
Start typing a name in the **To:** field and a suggestion popup will appear, listing matching alts and guild members. Click any suggestion to fill in the field instantly.

**Persistent Alt Registry**
Your characters are registered automatically each time you log in. The list persists across sessions via SavedVariables — no manual setup required.

---

## Installation

1. Download the latest release.
2. Extract the `TomoMail` folder into your `World of Warcraft/_retail_/Interface/AddOns/` directory.
3. Reload the game or enable the addon in the character selection screen.

---

## Usage

| Action | How |
|---|---|
| Open contact menu | Click the **▼** button next to the **To:** field |
| Select a recipient | Click any name in the dropdown |
| Send to all alts | Click **Send to all alts** button |
| Autocomplete a name | Type 2+ characters in the **To:** field |
| Open settings | `/tml` |

---

## Configuration

Open the settings panel with `/tml`.

| Option | Description |
|---|---|
| Show my characters | Toggle the alts section in the dropdown |
| Show guild members | Toggle the guild section in the dropdown |
| Online guild members only | Only show currently connected guild members |
| Show recent recipients | Toggle the recent history section |
| Number of recent recipients | How many recent entries to keep (5–25) |
| Autocomplete | Enable/disable the name suggestion popup |

The panel also provides buttons to **clear your recent history** or **reset your alt list**.

---

## Compatibility

- **Retail (The War Within)** — Interface 120000 / 120001
- Standalone — does **not** require TomoMod to function
- Compatible with the TomoMod addon suite

---

## Notes

- Alts are tracked **per realm and faction**. Cross-realm or cross-faction characters will not appear in the list.
- The "Send to all alts" feature requires a subject and a body to be filled in before sending.
- Guild roster data is refreshed automatically each time you open the mailbox.

---

## Feedback & Support

Found a bug or have a suggestion? Leave a comment on the CurseForge page or reach out at **komroa@gmail.com**.

---

*Part of the TomoMod addon suite.*

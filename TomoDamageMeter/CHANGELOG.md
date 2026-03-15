# Changelog

All notable changes to **TomoDamageMeter** will be documented in this file.

## [1.0.4] - 2025-03-15

### Added
- **Spell Breakdown window**: Dedicated standalone window displaying per-spell details for any player in the group. Shows spell rank, icon, name, total damage/healing, per-second rate, and percentage. The window is movable, resizable (360×300 to 600×800), and closable with ESC.
- **Player selector strip**: Horizontal bar inside the Spell Breakdown window listing all group members with class-colored names. Click any name to instantly load that player's spell data.
- **Magnifying glass icon**: New header button (between lock and gear) that opens the Spell Breakdown window directly, auto-selecting the first player.
- **Click-to-inspect**: Left-click any player bar in the meter to open the Spell Breakdown pre-selected to that player.
- **Column header bar**: Label row in the Spell Breakdown window showing column names (Spell, Total, /s, %).
- **Category toggles**: Three checkboxes in the General settings tab (Damage, Healing, Actions) to enable or disable entire meter categories. Disabled categories are hidden from header cycling, type dropdown, and navigation. At least one category must remain enabled.
- **Spell Breakdown Opacity slider**: New setting in the Appearance section (range 0.10–1.00, default 0.85) controlling the opacity of the Spell Breakdown window, with real-time preview.
- **details.tga icon**: Custom 32×32 white magnifying glass + list icon for the Spell Breakdown header button.
- **SpellBridge module**: Queries `C_DamageMeter.GetCombatSessionSourceFromType()` for per-spell data. Fully taint-free — no CLEU parsing required.
- **Localization**: Added German (deDE), Spanish (esES), Italian (itIT), and Portuguese-Brazil (ptBR) translations for all new strings (category toggles, breakdown labels, column headers, opacity slider).

### Changed
- **Header button order**: Now reads Gear → Details → Lock → Report → Reset (left to right).
- **Category cycling**: Clicking the category label in the meter header now skips disabled categories.
- **Meter type dropdown**: Per-window dropdowns in the settings panel now filter out types belonging to disabled categories.
- **Settings panel height**: Increased from 520px to 690px to accommodate new sections (Categories, Breakdown Opacity).

### Fixed
- **Tab bar overflow**: Long tab names (e.g. "Interruptions") are now capped at 80px max width with text truncation, preventing visual overlap with adjacent tabs and the +/- buttons.
- **Checkbox visual glitch**: When attempting to disable the last remaining category, the checkbox now correctly resets its visual state after the operation is blocked.

## [1.0.3] - 2025-03-10

### Added
- Initial public release.
- 9 meter types across 3 categories (Damage, Healing, Actions).
- Up to 3 independent windows with per-window meter type and session settings.
- Current and Overall session modes.
- Live combat timer.
- Class-colored bars with gradient fill and grow animation.
- Report to chat (Say, Party, Raid, Guild, Whisper).
- Lockable and resizable windows with saved positions.
- Out-of-combat opacity fade.
- Auto-reset on instance entry.
- Custom scrollbar styling.
- Slash commands: `/tdm`, `/tomodm`.
- Localization: English (enUS) and French (frFR).

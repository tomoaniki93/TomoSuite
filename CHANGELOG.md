# Changelog

## v1.0.6
- **New**: Segment Browser — two-level drill-down using Blizzard's `C_DamageMeter` segment API
  - Level 1 lists combat segments (boss name + duration) from `GetAvailableCombatSessions()`
  - Level 2 shows enemies within a selected segment via `GetCombatSessionFromID()`
  - Click an enemy to open the Spell Breakdown showing your per-spell damage for that segment
- **New**: Crosshair icon button in the meter header to open the Segment Browser
- **New**: Segment Browser auto-refreshes during combat and resets with session data
- **New**: Localized segment/target labels for all 6 supported languages (EN, FR, DE, ES, IT, PT-BR)

## v1.0.5
- Internal improvements

## v1.0.4
- **New**: Spell Breakdown window — standalone, resizable window with per-spell details and player selector strip
- **New**: Magnifying glass icon in the meter header to open the Spell Breakdown
- **New**: Category toggles (Damage, Healing, Actions) in the settings panel
- **New**: Spell Breakdown Opacity slider in the settings panel
- **Fix**: Tab bar overflow — long tab names (e.g. "Interruptions") are now capped and truncated
- **Fix**: Settings panel height adjusted for new sections

## v1.0.3
- Initial public release
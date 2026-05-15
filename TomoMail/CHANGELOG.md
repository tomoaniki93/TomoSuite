# Changelog

All notable changes to TomoMail will be documented in this file.

## [2.0.0] - 2026-05-15

### Changed
- **Complete UI redesign** — modern dark theme consistent with TomoSuite
- Replaced cascading `UIDropDownMenu` with a custom flyout panel featuring tabs (Alts / Guild / Recent)
- Added live search bar in contact flyout — filters across all guild members in real-time
- Flat scrollable member list with class colors, online dot indicators, and level display
- Redesigned autocomplete dropdown with match highlighting (purple accent) and source tags (alt / guild / recent)
- Modern config panel with toggle switches replacing Blizzard checkboxes
- Styled slider for recent count with purple accent
- Dark themed action buttons with danger styling for destructive actions
- New `UIHelpers.lua` shared UI factory for consistent component styling

### Added
- `Core.lua`: `ClassColorRGB()` utility returning raw r,g,b values
- `UIHelpers.lua`: `CreatePanel`, `CreateTab`, `CreateSearchBox`, `CreateToggle`, `CreateStyledButton`, `CreateDivider`, `CreateSectionTitle`, `AddRowHighlight`
- Locale keys: `NO_RESULTS`, `CLOSE`, `CFG_SECTION_DISPLAY`, `CFG_SECTION_BEHAVIOR`, `CFG_SHOW_ALTS_SUB`, `CFG_SHOW_GUILD_SUB`, `CFG_AUTOCOMPLETE_SUB`, `CFG_CLEAR_RECENT`, `CFG_CLEAR_ALTS`, `CFG_RECENT_CLEARED`, `CFG_ALTS_CLEARED`

### Removed
- All `UIDropDownMenu` / `UIDropDownMenuTemplate` usage
- `Blizzard UIPanelButtonTemplate` and `UICheckButtonTemplate` usage in config

## [1.0.0] - 2026-03-01

### Added
- Initial release
- Contact dropdown with Alts, Guild (alphabetical), Recent categories
- Autocomplete in recipient field
- Configuration panel via `/tomomail`
- Multi-locale support (frFR, enUS, deDE, esES, itIT, ptBR)

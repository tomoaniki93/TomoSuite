# Changelog

All notable changes to TomoMail will be documented in this file.

## [2.1.9] - 2026-06-12

### Fixed
- **Reader message area no longer shows Blizzard's gold scrollbar.** The reader body used `UIPanelScrollFrameTemplate`, whose gold up/down scrollbar was visible even on mails with no text and clashed with the dark theme. The scrollbar is now hidden and the body scrolls with the mouse wheel instead; the body was also widened to reclaim the freed gutter (`Modules/Inbox.lua`, `BuildReader`).

## [2.1.8] - 2026-06-12

### Added
- **Take individual attachments from the reader.** Opening a mail now shows each item attachment as its own clickable slot (with stack count, quality border and item tooltip on hover); clicking one takes just that item/stack via `TakeInboxItem`, instead of being forced to "Take all". This is aimed at bulk auction-house commodity mail (herbs, ores) where several stacks arrive in one mail and you only want some. "Take all" remains available. The reader auto-closes when the mail's last item is taken (it auto-deletes and inbox indices shift); otherwise the slot row refreshes in place. `Modules/Inbox.lua` (`PopulateReaderAttachments`, `MakeReaderSlot`).

## [2.1.7] - 2026-06-12

### Fixed
- **Error flood (and looping error sound) when opening the Send tab, introduced in 2.1.6.** `SendMailBodyEditBox` is a ScrollingEditBox whose `OnUpdate` / `OnCursorChanged` / `OnTextChanged` scripts drive its parent `SendMailScrollFrame`. After 2.1.6 reparented the edit box into a plain dark holder, those scripts called scroll methods the holder doesn't have and threw every frame, tripping Blizzard's "too many errors" warning and looping the error sound. Those three scripts are now cleared once the edit box is detached (`Modules/Compose.lua`, `EnsureDarkBody`); the edit box still scrolls its own display to keep the cursor visible, so typing is unaffected. (Trade-off unchanged: the bare body has no mouse-wheel scroll; navigate long text with the arrow keys.)

## [2.1.6] - 2026-06-12

### Changed
- **Dark message body in the Send tab (no more gold scrollbar arrows).** The native body lived in `SendMailScrollFrame`, whose scrollbar shows Blizzard's gold up/down arrows that can't be cleanly dark-themed. The compose tab now drops that scroll frame and presents the *same* native `SendMailBodyEditBox` as a bare multiline field inside a dark holder (`Modules/Compose.lua`, `EnsureDarkBody`). The edit box is reused as-is, so `SendMail()` still reads its text natively — only its container changes, and there is no scrollbar to theme. Re-asserted on every Send-tab mount.

## [2.1.5] - 2026-06-12

### Fixed
- **Item icon size slider now applies live (no /reload needed).** The slider wrote the new size to the profile (so it took effect on the next reload), but the live refresh went through a full inbox rebuild that could be swallowed silently, so dragging the slider appeared to do nothing. `Inbox:ApplyIconSize()` now resizes the on-screen attachment slots in place; because each slot's texture fills it and the cluster/subject/sender anchors are relative to the slots' edges, the rows reflow immediately. Off-screen (pooled) rows still pick up the size the next time they render.

## [2.1.4] - 2026-06-12

### Fixed
- **Minimap "pending mail" icon staying lit after using the modern inbox (regression vs the native UI).** Root cause: the native mailbox *opens* (reads) a mail when you take its attachments, which clears the mail's unread flag; the modern list took attachments via `AutoLootMailItem` without reading, so any mail that keeps a text body stayed flagged "unread" forever, kept `HasNewMail()` true, and left the minimap mail icon on (confirmed by the icon's tooltip still naming the unread sender). Taking a mail — both the per-row button and "Take all" — now also marks it read (`GetInboxText`), matching the native flow, so the icon clears once everything has been collected. Mails opened from the reader were already marked read.
- The minimap mail frame is now resolved via the path confirmed on Midnight with `/fstack` (`MinimapCluster.IndicatorFrame.MailFrame`), with `MiniMapMailIcon:GetParent()` and the legacy names kept as fallbacks.

## [2.1.3] - 2026-06-12

### Fixed
- **Minimap "pending mail" icon staying lit after the inbox is emptied.** On the Midnight client Blizzard's own minimap mail handler (`Blizzard_Minimap/Minimap.lua:479`) errors on `UPDATE_PENDING_MAIL` and never hides the reminder icon, so it could remain shown with an empty inbox. The previous self-sync probed frame names (`MinimapCluster.IndicatorFrame.MailFrame`, `MiniMapMailFrame`) that don't resolve on this build, so it had nothing to hide. The indicator is now resolved authoritatively via `MiniMapMailIcon:GetParent()` (the named global texture confirmed in the frame dump), and its visibility is driven from `HasNewMail()` plus — while the mailbox is open — the actual inbox item count, so an empty inbox forces the icon off even if the new-mail flag is stuck. It is re-evaluated on mail events and shortly after the mailbox closes.

### Changed
- **Full deDE / esES / itIT / ptBR translations of the 2.1 UI.** The four locales were stuck on the pre-2.1 key set and showed English for the entire modern window (tabs, settings cog, inbox list, filters, config sections, "Item icon size"). All missing keys are now translated using standard WoW terminology (e.g. Inbox → Posteingang / Bandeja de entrada / Posta in arrivo / Caixa de entrada; Auction House → Auktionshaus / Casa de subastas / Casa d'aste / Casa de Leilões). enUS loads last as the unconditional fallback, so any future key still degrades to English.
- Cleaned up a pre-existing duplicate `SETTINGS` key in `enUS.lua` / `frFR.lua` (and the duplicate that resulted in the four locales), so each locale now defines every key exactly once.

## [2.1.2] - 2026-06-12

### Added
- **Configurable inbox attachment icon size.** The item icons shown on each inbox row are now resizable independently of the window scale (raising the window scale enlarged everything proportionally, so the icons never looked any bigger relative to the row). A new "Item icon size" slider in the window settings (cog) controls it, ranging from 18 to 36 px; the default is now 30 (previously a fixed 18). Changes apply live without a reload.

### Changed
- `Modules/Inbox.lua` — icon slots now read their size from `profile.inboxIconSize` (clamped 18-36) instead of a hardcoded 18x18. Slots are bottom-aligned so larger icons grow upward into otherwise-empty row space. When a mail has no money/C.O.D. the icon cluster is kept clear of the expiry column on the right, and both the sender and subject lines are now bounded to the left of the cluster so a taller icon can never overlap the row text. Added `Inbox:ApplyIconSize()` to re-render rows when the setting changes.
- `Modules/Window.lua` — settings popover grew to fit the new slider, which writes `profile.inboxIconSize` and calls `Inbox:ApplyIconSize()`.
- `Database.lua` — added `inboxIconSize = 30` default.
- `Locales/frFR.lua`, `Locales/enUS.lua` — added the `INBOX_ICON_SIZE` string.

## [2.1.1] - 2026-06-11

### Fixed
- **Locale fallback was broken — the addon showed French on every client.** `Locales/frFR.lua` set the `TomoMailLocale` table unconditionally, missing the `if GetLocale() ~= "frFR" then return end` guard that every other locale file has. Because `enUS.lua` only fills keys that are still `nil`, the French strings posted by `frFR.lua` were never overridden, so non-French players saw French everywhere. Added the missing guard to `frFR.lua`.
- **English fallback now loads last.** `Locales/enUS.lua` (the fill-missing default) was loaded before `deDE`/`esES`/`itIT`/`ptBR` in the TOC. Those files reassign the whole `TomoMailLocale` table and do not yet contain the 2.1 keys (`INBOX_*`, `TAB_*`, `SETTINGS`, `FONT`, …), which wiped the English fallback for those keys on German/Spanish/Italian/Portuguese clients. `enUS.lua` is now loaded last so it fills any key a localized table is missing. Net result: French clients get French, every other client gets its own translation with a clean English fallback for untranslated keys.

## [2.1.0] - 2026-06-10

### Added
- **Standalone window** (`Modules/Window.lua`) — TomoMail now draws its own dark window that fully replaces the Blizzard mail frame instead of overlaying it. The native `MailFrame` is kept functional but made invisible (`SetAlpha(0)` + mouse disabled, re-asserted on `MAIL_SHOW`/`MAIL_INBOX_UPDATE`/`MAIL_SEND_SUCCESS`), and the native `SendMailFrame` is reparented into the window's compose page so the real cursor-driven attachment flow and `SendMail()` keep working inside our chrome. The window is sized independently of Blizzard's frame (440x640), is movable with a saved position (`global.window`), and uses modern underline tabs (Inbox / Send).
- **Font picker** — a settings cog on the window opens a popover with a live font selector (built-in WoW fonts plus any LibSharedMedia fonts if present, previewed in-list) and a text-size slider. Fonts are applied through shared font objects, so changing the font or size updates the whole UI (including the native send fields) instantly. New profile keys `font` and `fontSize`.
- **Modern inbox** (`Modules/Inbox.lua`) — a fully custom, API-driven inbox list that replaces the native row layout while the dark theme is active. Includes a live search box, category filter chips (All / Players / Auction House / System), and rich two-line rows showing an unread dot, a class-colored sender avatar, the subject, a colored expiry badge, and an attachment preview cluster (item icons with quality borders, stacked counts, money and C.O.D. amounts).
  - Senders are class-colored using the existing alt registry and guild roster cache (via the new `Contacts:ResolveClass`); auction-house and system mails get dedicated gold / purple accents.
  - Per-row hover actions: **Take all** (`AutoLootMailItem`) and **Delete** (`DeleteInboxItem`, guarded by `InboxItemCanDelete`). Clicking a row opens an integrated reader that pulls the body from `GetInboxText` and offers Take / Reply / Delete.
  - A footer **Take all** button sequentially loots every non-C.O.D. mail with a throttle-friendly `C_Timer` ticker, plus a live "messages / unread" summary.
  - Native inbox rows, pagination and `OpenAllMail` are hidden on every `MAIL_INBOX_UPDATE` so Blizzard's row refresh never fights the custom list.
- **Modern compose** (`Modules/Compose.lua`) — owns the dark restyle of the native Send Mail widgets in place (no repositioning of the cursor-driven attachment slots or the body, so `SendMail()` and `ClickSendMailItemButton` stay intact). Adds gold / silver / copper coin dots next to the money fields and a segmented Gold / C.O.D. look (pill backdrop + accent on the active option).
- `Contacts.lua`: `Contacts:ResolveClass(name)` — resolves a mail sender's class from the alt registry and guild cache (realm suffix stripped) for sender coloring.
- `Database.lua`: `modernUI` profile flag (default `true`). Setting it to `false` falls back to the classic in-place reskin.
- Locale keys (frFR + enUS): `INBOX_SYSTEM`, `INBOX_EMPTY`, `INBOX_NO_MATCH`, `INBOX_MESSAGES`, `INBOX_UNREAD`, `INBOX_TAKE`, `INBOX_TAKE_ALL`, `INBOX_DELETE`, `INBOX_REPLY`, `INBOX_NO_TEXT`, `INBOX_CANT_DELETE`, `INBOX_FILTER_ALL`, `INBOX_FILTER_PLAYERS`, `INBOX_FILTER_AH`, `INBOX_FILTER_SYSTEM`.

### Changed
- `Modules/Skin.lua`: when `modernUI` is active, `ApplySkin` now only touches the native `OpenMail` reader (used by rare confirmation dialogs); the whole mail frame, inbox and send frame are owned by the standalone window. The classic in-place reskin still runs when `modernUI` is disabled.
- `TomoMail.toc`: load `Modules/Window.lua`, `Modules/Inbox.lua` and `Modules/Compose.lua` after `Skin.lua`.

### Fixed
- `Modules/Inbox.lua`: suppressed a recurring Blizzard error surfaced when reading/taking/deleting mail. On the Midnight (12.0) client, changing the "pending mail" state (which `GetInboxText`, `AutoLootMailItem` and `DeleteInboxItem` all do) fires `UPDATE_PENDING_MAIL`, and Blizzard's own minimap mail-reminder handler (`Blizzard_Minimap/Mainline/Minimap.lua:479`) then calls a nil value and throws. This is a Blizzard bug (it also fires from any other mail-pending change, including Blizzard's own UI), not a TomoMail logic error — the stack simply passes through TomoMail because TomoMail initiates the read. A scoped `WithMinimapErrorGuard` now swaps the error handler for the duration of each of TomoMail's mail calls to swallow only this specific `Blizzard_Minimap` error, then restores the previous handler immediately so all other errors are still reported normally.

### Notes
- All new mail API access is wrapped in `pcall` with type guards; the modern layer degrades gracefully (and the classic reskin remains available) if a global is unavailable on a given client build.

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

local ADDON_NAME, ns = ...

----------------------------------------------------------------------
-- Localization: English (default / fallback)
----------------------------------------------------------------------

local L = {}
ns.L = L

-- General
L["ADDON_NAME"] = "TomoDamageMeter"
L["ADDON_SHORT"] = "Tomo"
L["ADDON_PREFIX"] = "|cffe0115fTomo DM :|r "

-- Meter types
L["DPS"] = "DPS"
L["HPS"] = "HPS"
L["DAMAGE_TAKEN"] = "Damage Taken"
L["AVOIDABLE"] = "Avoidable"
L["ENEMY_DAMAGE"] = "Enemy Damage"
L["ABSORBS"] = "Absorbs"
L["INTERRUPTS"] = "Interrupts"
L["DISPELS"] = "Dispels"
L["DEATHS"] = "Deaths"

-- Categories
L["DAMAGE"] = "Damage"
L["HEALING"] = "Healing"
L["ACTIONS"] = "Actions"

-- Sessions
L["CURRENT"] = "Current"
L["OVERALL"] = "Overall"

-- Header / UI
L["RESET"] = "Reset"
L["LOCK"] = "Lock"
L["UNLOCK"] = "Unlock"
L["SETTINGS"] = "Settings"
L["REPORT"] = "Report"
L["CLOSE"] = "Close"

-- Format labels
L["FMT_COMPACT"] = "Compact"
L["FMT_1DEC"] = "1 Dec"
L["FMT_2DEC"] = "2 Dec"
L["FMT_REGULAR"] = "Regular"
L["FMT_INT"] = "Int"
L["FMT_DEC"] = "Dec"

-- Report
L["REPORT_HEADER"] = "TomoDamageMeter: %s (%s)"
L["REPORT_NO_TARGET"] = "No whisper target. Select a player first."
L["REPORT_NO_DATA"] = "No data to report."
L["REPORT_CHANNEL_SAY"] = "Say"
L["REPORT_CHANNEL_PARTY"] = "Party"
L["REPORT_CHANNEL_RAID"] = "Raid"
L["REPORT_CHANNEL_GUILD"] = "Guild"
L["REPORT_CHANNEL_WHISPER"] = "Whisper"

-- Settings
L["SETTINGS_TITLE"] = "TomoDamageMeter Settings"
L["SETTINGS_GENERAL"] = "General"
L["SETTINGS_APPEARANCE"] = "Appearance"
L["SETTINGS_COLUMNS"] = "Columns"
L["SETTINGS_FONT_SIZE"] = "Font Size"
L["SETTINGS_BAR_HEIGHT"] = "Bar Height"
L["SETTINGS_BG_OPACITY"] = "Background Opacity"
L["SETTINGS_OOC_OPACITY"] = "Out of Combat Opacity"
L["SETTINGS_STRIP_REALM"] = "Strip Realm Names"
L["SETTINGS_ACCENT_COLOR"] = "Accent Color"
L["SETTINGS_USE_CLASS_COLOR"] = "Use Class Color"
L["SETTINGS_REPORT_CHANNEL"] = "Report Channel"
L["SETTINGS_REPORT_LINES"] = "Report Lines"
L["SETTINGS_WINDOWS"] = "Windows"
L["SETTINGS_ADD_WINDOW"] = "+ Add"
L["SETTINGS_REMOVE_WINDOW"] = "- Remove"
L["SETTINGS_WINDOW_COUNT"] = "Windows: %d / %d"
L["SETTINGS_COL_RATE"] = "Rate (DPS/HPS)"
L["SETTINGS_COL_TOTAL"] = "Total"
L["SETTINGS_COL_PCT"] = "Percent"
L["SETTINGS_TAB_GENERAL"] = "General"
L["SETTINGS_TAB_WINDOW"] = "Window %d"
L["SETTINGS_METER_TYPE"] = "Meter Type"
L["SETTINGS_SESSION_TYPE"] = "Session Type"
L["SETTINGS_LOCKED"] = "Lock Position"

-- Slash commands
L["CMD_RESET"] = "Données réinitialisées."
L["CMD_LOCKED"] = "Locked"
L["CMD_UNLOCKED"] = "Unlocked"
L["CMD_HELP_HEADER"] = "Commands:"
L["CMD_HELP_TOGGLE"] = "  /tdm — open settings"
L["CMD_HELP_TOGGLE_VIS"] = "  /tdm toggle — toggle window visibility"
L["CMD_HELP_RESET"] = "  /tdm reset — reset all combat data"
L["CMD_HELP_LOCK"] = "  /tdm lock — lock/unlock window position"
L["CMD_HELP_HELP"] = "  /tdm help — this message"

-- Auto-reset
L["SETTINGS_AUTO_RESET_INSTANCE"] = "Auto-reset on instance entry"
L["AUTO_RESET_MSG"] = "Data auto-reset (instance entry)."

-- Combat
L["COMBAT_SETTINGS_UNAVAILABLE"] = "Settings unavailable during combat."
L["WAITING_COMBAT_END"] = "Unavailable until after combat"

-- Detail
L["SPELL_BREAKDOWN"] = "Spell Breakdown"
L["NO_DATA"] = "No data available"
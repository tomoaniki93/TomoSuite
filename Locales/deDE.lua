local ADDON_NAME, ns = ...

----------------------------------------------------------------------
-- Localization: German
----------------------------------------------------------------------

if GetLocale() ~= "deDE" then return end

local L = ns.L

-- General
L["ADDON_NAME"]     = "TomoDamageMeter"
L["ADDON_SHORT"]    = "Tomo"

-- Meter types
L["DPS"]            = "DPS"
L["HPS"]            = "HPS"
L["DAMAGE_TAKEN"]   = "Erlittener Schaden"
L["AVOIDABLE"]      = "Vermeidbar"
L["ENEMY_DAMAGE"]   = "Feindschaden"
L["ABSORBS"]        = "Absorbierungen"
L["INTERRUPTS"]     = "Unterbrechungen"
L["DISPELS"]        = "Entzauberungen"
L["DEATHS"]         = "Tode"

-- Categories
L["DAMAGE"]         = "Schaden"
L["HEALING"]        = "Heilung"
L["ACTIONS"]        = "Aktionen"

-- Sessions
L["CURRENT"]        = "Aktuell"
L["OVERALL"]        = "Gesamt"

-- Header / UI
L["RESET"]          = "Zurücksetzen"
L["LOCK"]           = "Sperren"
L["UNLOCK"]         = "Entsperren"
L["SETTINGS"]       = "Einstellungen"
L["REPORT"]         = "Bericht"
L["CLOSE"]          = "Schließen"

-- Format labels
L["FMT_COMPACT"]    = "Kompakt"
L["FMT_1DEC"]       = "1 Dez"
L["FMT_2DEC"]       = "2 Dez"
L["FMT_REGULAR"]    = "Regulär"
L["FMT_INT"]        = "Ganzzahl"
L["FMT_DEC"]        = "Dezimal"

-- Report
L["REPORT_HEADER"]          = "TomoDamageMeter: %s (%s)"
L["REPORT_NO_TARGET"]       = "Kein Flüsterziel. Wähle zuerst einen Spieler."
L["REPORT_NO_DATA"]         = "Keine Daten zum Berichten."
L["REPORT_CHANNEL_SAY"]     = "Sagen"
L["REPORT_CHANNEL_PARTY"]   = "Gruppe"
L["REPORT_CHANNEL_RAID"]    = "Schlachtzug"
L["REPORT_CHANNEL_GUILD"]   = "Gilde"
L["REPORT_CHANNEL_WHISPER"] = "Flüstern"

-- Settings
L["SETTINGS_TITLE"]             = "TomoDamageMeter Einstellungen"
L["SETTINGS_GENERAL"]           = "Allgemein"
L["SETTINGS_APPEARANCE"]        = "Aussehen"
L["SETTINGS_COLUMNS"]           = "Spalten"
L["SETTINGS_FONT_SIZE"]         = "Schriftgröße"
L["SETTINGS_BAR_HEIGHT"]        = "Balkenhöhe"
L["SETTINGS_BG_OPACITY"]        = "Hintergrundtransparenz"
L["SETTINGS_OOC_OPACITY"]       = "Transparenz außerhalb des Kampfes"
L["SETTINGS_BREAKDOWN_OPACITY"] = "Zauberdetail-Transparenz"
L["SETTINGS_STRIP_REALM"]       = "Realmname ausblenden"
L["SETTINGS_ACCENT_COLOR"]      = "Akzentfarbe"
L["SETTINGS_USE_CLASS_COLOR"]   = "Klassenfarbe verwenden"
L["SETTINGS_REPORT_CHANNEL"]    = "Berichtskanal"
L["SETTINGS_REPORT_LINES"]      = "Berichtszeilen"
L["SETTINGS_WINDOWS"]           = "Fenster"
L["SETTINGS_ADD_WINDOW"]        = "+ Hinzufügen"
L["SETTINGS_REMOVE_WINDOW"]     = "- Entfernen"
L["SETTINGS_WINDOW_COUNT"]      = "Fenster: %d / %d"
L["SETTINGS_COL_RATE"]          = "Rate (DPS/HPS)"
L["SETTINGS_COL_TOTAL"]         = "Gesamt"
L["SETTINGS_COL_PCT"]           = "Prozent"
L["SETTINGS_TAB_GENERAL"]       = "Allgemein"
L["SETTINGS_TAB_WINDOW"]        = "Fenster %d"
L["SETTINGS_METER_TYPE"]        = "Messertyp"
L["SETTINGS_SESSION_TYPE"]      = "Sitzungstyp"
L["SETTINGS_LOCKED"]            = "Position gesperrt"

-- Slash commands
L["CMD_RESET"]          = "Daten zurückgesetzt."
L["CMD_LOCKED"]         = "Gesperrt"
L["CMD_UNLOCKED"]       = "Entsperrt"
L["CMD_HELP_HEADER"]    = "Befehle:"
L["CMD_HELP_TOGGLE"]    = "  /tdm — Einstellungen öffnen"
L["CMD_HELP_TOGGLE_VIS"]= "  /tdm toggle — Fenster ein-/ausblenden"
L["CMD_HELP_RESET"]     = "  /tdm reset — Alle Kampfdaten zurücksetzen"
L["CMD_HELP_LOCK"]      = "  /tdm lock — Fensterposition sperren/entsperren"
L["CMD_HELP_HELP"]      = "  /tdm help — diese Nachricht"

-- Auto-reset
L["SETTINGS_AUTO_RESET_INSTANCE"] = "Auto-Reset beim Instanzbeitritt"
L["SETTINGS_CATEGORIES"] = "Kategorien"
L["SETTINGS_CATEGORIES_MIN"] = "Mindestens eine Kategorie muss aktiviert bleiben."
L["AUTO_RESET_MSG"]                = "Daten automatisch zurückgesetzt (Instanzbeitritt)."

-- Combat
L["COMBAT_SETTINGS_UNAVAILABLE"] = "Einstellungen im Kampf nicht verfügbar."
L["WAITING_COMBAT_END"]          = "Nicht verfügbar bis nach dem Kampf"

-- Detail
L["SPELL_BREAKDOWN"] = "Zauberaufteilung"
L["NO_DATA"]         = "Keine Daten verfügbar"
L["BREAKDOWN_SPELLS_LABEL"] = "Zauber"
L["BREAKDOWN_CRITS_LABEL"]  = "Krits"
L["BREAKDOWN_CRIT_RATE_LABEL"] = "Krit"
L["BREAKDOWN_COL_SPELL"] = "Zauber"
L["BREAKDOWN_COL_TOTAL"] = "Total"

-- Segments / Target Breakdown
L["SEGMENTS"] = "Segmente"
L["SEGMENT"] = "Segment"
L["SEGMENT_COL_NAME"] = "Begegnung"
L["TARGET_BREAKDOWN"] = "Zielaufschlüsselung"
L["TARGET_COL_NAME"] = "Ziel"

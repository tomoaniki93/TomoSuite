local ADDON_NAME, ns = ...

----------------------------------------------------------------------
-- Localization: Italian
----------------------------------------------------------------------

if GetLocale() ~= "itIT" then return end

local L = ns.L

-- General
L["ADDON_NAME"]     = "TomoDamageMeter"
L["ADDON_SHORT"]    = "Tomo"

-- Meter types
L["DPS"]            = "DPS"
L["HPS"]            = "HPS"
L["DAMAGE_TAKEN"]   = "Danno subito"
L["AVOIDABLE"]      = "Evitabile"
L["ENEMY_DAMAGE"]   = "Danno nemico"
L["ABSORBS"]        = "Assorbimenti"
L["INTERRUPTS"]     = "Interruzioni"
L["DISPELS"]        = "Dissoluzioni"
L["DEATHS"]         = "Morti"

-- Categories
L["DAMAGE"]         = "Danno"
L["HEALING"]        = "Cura"
L["ACTIONS"]        = "Azioni"

-- Sessions
L["CURRENT"]        = "Attuale"
L["OVERALL"]        = "Totale"

-- Header / UI
L["RESET"]          = "Resetta"
L["LOCK"]           = "Blocca"
L["UNLOCK"]         = "Sblocca"
L["SETTINGS"]       = "Impostazioni"
L["REPORT"]         = "Rapporto"
L["CLOSE"]          = "Chiudi"

-- Format labels
L["FMT_COMPACT"]    = "Compatto"
L["FMT_1DEC"]       = "1 Dec"
L["FMT_2DEC"]       = "2 Dec"
L["FMT_REGULAR"]    = "Regolare"
L["FMT_INT"]        = "Intero"
L["FMT_DEC"]        = "Decimale"

-- Report
L["REPORT_HEADER"]          = "TomoDamageMeter: %s (%s)"
L["REPORT_NO_TARGET"]       = "Nessun bersaglio sussurrato. Seleziona prima un giocatore."
L["REPORT_NO_DATA"]         = "Nessun dato da riportare."
L["REPORT_CHANNEL_SAY"]     = "Dire"
L["REPORT_CHANNEL_PARTY"]   = "Gruppo"
L["REPORT_CHANNEL_RAID"]    = "Incursione"
L["REPORT_CHANNEL_GUILD"]   = "Gilda"
L["REPORT_CHANNEL_WHISPER"] = "Sussurro"

-- Settings
L["SETTINGS_TITLE"]             = "Impostazioni TomoDamageMeter"
L["SETTINGS_GENERAL"]           = "Generale"
L["SETTINGS_APPEARANCE"]        = "Aspetto"
L["SETTINGS_COLUMNS"]           = "Colonne"
L["SETTINGS_FONT_SIZE"]         = "Dimensione carattere"
L["SETTINGS_BAR_HEIGHT"]        = "Altezza barra"
L["SETTINGS_BG_OPACITY"]        = "Opacità sfondo"
L["SETTINGS_OOC_OPACITY"]       = "Opacità fuori combattimento"
L["SETTINGS_BREAKDOWN_OPACITY"] = "Opacità dettaglio incantesimi"
L["SETTINGS_STRIP_REALM"]       = "Rimuovi nome reame"
L["SETTINGS_ACCENT_COLOR"]      = "Colore accento"
L["SETTINGS_USE_CLASS_COLOR"]   = "Usa colore classe"
L["SETTINGS_REPORT_CHANNEL"]    = "Canale rapporto"
L["SETTINGS_REPORT_LINES"]      = "Righe rapporto"
L["SETTINGS_WINDOWS"]           = "Finestre"
L["SETTINGS_ADD_WINDOW"]        = "+ Aggiungi"
L["SETTINGS_REMOVE_WINDOW"]     = "- Rimuovi"
L["SETTINGS_WINDOW_COUNT"]      = "Finestre: %d / %d"
L["SETTINGS_COL_RATE"]          = "Tasso (DPS/HPS)"
L["SETTINGS_COL_TOTAL"]         = "Totale"
L["SETTINGS_COL_PCT"]           = "Percentuale"
L["SETTINGS_TAB_GENERAL"]       = "Generale"
L["SETTINGS_TAB_WINDOW"]        = "Finestra %d"
L["SETTINGS_METER_TYPE"]        = "Tipo di misuratore"
L["SETTINGS_SESSION_TYPE"]      = "Tipo di sessione"
L["SETTINGS_LOCKED"]            = "Posizione bloccata"

-- Slash commands
L["CMD_RESET"]          = "Dati resettati."
L["CMD_LOCKED"]         = "Bloccato"
L["CMD_UNLOCKED"]       = "Sbloccato"
L["CMD_HELP_HEADER"]    = "Comandi:"
L["CMD_HELP_TOGGLE"]    = "  /tdm — apri impostazioni"
L["CMD_HELP_TOGGLE_VIS"]= "  /tdm toggle — mostra/nascondi finestra"
L["CMD_HELP_RESET"]     = "  /tdm reset — resetta tutti i dati di combattimento"
L["CMD_HELP_LOCK"]      = "  /tdm lock — blocca/sblocca posizione finestra"
L["CMD_HELP_HELP"]      = "  /tdm help — questo messaggio"

-- Auto-reset
L["SETTINGS_AUTO_RESET_INSTANCE"] = "Auto-reset all'ingresso in istanza"
L["SETTINGS_CATEGORIES"] = "Categorie"
L["SETTINGS_CATEGORIES_MIN"] = "Almeno una categoria deve rimanere attivata."
L["AUTO_RESET_MSG"]                = "Dati resettati automaticamente (ingresso in istanza)."

-- Combat
L["COMBAT_SETTINGS_UNAVAILABLE"] = "Impostazioni non disponibili durante il combattimento."
L["WAITING_COMBAT_END"]          = "Non disponibile fino a dopo il combattimento"

-- Detail
L["SPELL_BREAKDOWN"] = "Dettaglio incantesimi"
L["NO_DATA"]         = "Nessun dato disponibile"
L["BREAKDOWN_SPELLS_LABEL"] = "incantesimi"
L["BREAKDOWN_CRITS_LABEL"]  = "critici"
L["BREAKDOWN_CRIT_RATE_LABEL"] = "crit"
L["BREAKDOWN_COL_SPELL"] = "Incantesimo"
L["BREAKDOWN_COL_TOTAL"] = "Total"

-- Segments / Target Breakdown
L["SEGMENTS"] = "Segmenti"
L["SEGMENT"] = "Segmento"
L["SEGMENT_COL_NAME"] = "Incontro"
L["TARGET_BREAKDOWN"] = "Dettaglio bersagli"
L["TARGET_COL_NAME"] = "Bersaglio"

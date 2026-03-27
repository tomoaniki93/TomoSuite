local ADDON_NAME, ns = ...

----------------------------------------------------------------------
-- Localization: French
----------------------------------------------------------------------

if GetLocale() ~= "frFR" then return end

local L = ns.L

-- General
L["ADDON_NAME"] = "TomoDamageMeter"
L["ADDON_SHORT"] = "Tomo"

-- Meter types
L["DPS"] = "DPS"
L["HPS"] = "HPS"
L["DAMAGE_TAKEN"] = "Dégâts subis"
L["AVOIDABLE"] = "Évitable"
L["ENEMY_DAMAGE"] = "Dégâts ennemis"
L["ABSORBS"] = "Absorptions"
L["INTERRUPTS"] = "Interruptions"
L["DISPELS"] = "Dissipations"
L["DEATHS"] = "Morts"

-- Categories
L["DAMAGE"] = "Dégâts"
L["HEALING"] = "Soins"
L["ACTIONS"] = "Actions"

-- Sessions
L["CURRENT"] = "Actuel"
L["OVERALL"] = "Global"

-- Header / UI
L["RESET"] = "Réinitialiser"
L["LOCK"] = "Verrouiller"
L["UNLOCK"] = "Déverrouiller"
L["SETTINGS"] = "Options"
L["REPORT"] = "Rapporter"
L["CLOSE"] = "Fermer"

-- Format labels
L["FMT_COMPACT"] = "Compact"
L["FMT_1DEC"] = "1 Déc"
L["FMT_2DEC"] = "2 Déc"
L["FMT_REGULAR"] = "Normal"
L["FMT_INT"] = "Ent"
L["FMT_DEC"] = "Déc"

-- Report
L["REPORT_HEADER"] = "TomoDamageMeter : %s (%s)"
L["REPORT_NO_TARGET"] = "Pas de cible pour le chuchotement. Sélectionnez un joueur."
L["REPORT_NO_DATA"] = "Aucune donnée à rapporter."
L["REPORT_CHANNEL_SAY"] = "Dire"
L["REPORT_CHANNEL_PARTY"] = "Groupe"
L["REPORT_CHANNEL_RAID"] = "Raid"
L["REPORT_CHANNEL_GUILD"] = "Guilde"
L["REPORT_CHANNEL_WHISPER"] = "Chuchoter"

-- Settings
L["SETTINGS_TITLE"] = "Options TomoDamageMeter"
L["SETTINGS_GENERAL"] = "Général"
L["SETTINGS_APPEARANCE"] = "Apparence"
L["SETTINGS_COLUMNS"] = "Colonnes"
L["SETTINGS_FONT_SIZE"] = "Taille de police"
L["SETTINGS_BAR_HEIGHT"] = "Hauteur des barres"
L["SETTINGS_BG_OPACITY"] = "Opacité du fond"
L["SETTINGS_OOC_OPACITY"] = "Opacité hors combat"
L["SETTINGS_BREAKDOWN_OPACITY"] = "Opacité détail des sorts"
L["SETTINGS_STRIP_REALM"] = "Masquer les noms de royaume"
L["SETTINGS_ACCENT_COLOR"] = "Couleur d'accentuation"
L["SETTINGS_USE_CLASS_COLOR"] = "Utiliser la couleur de classe"
L["SETTINGS_REPORT_CHANNEL"] = "Canal de rapport"
L["SETTINGS_REPORT_LINES"] = "Lignes du rapport"
L["SETTINGS_WINDOWS"] = "Fenêtres"
L["SETTINGS_ADD_WINDOW"] = "+ Ajouter"
L["SETTINGS_REMOVE_WINDOW"] = "- Supprimer"
L["SETTINGS_WINDOW_COUNT"] = "Fenêtres : %d / %d"
L["SETTINGS_COL_RATE"] = "Taux (DPS/HPS)"
L["SETTINGS_COL_TOTAL"] = "Total"
L["SETTINGS_COL_PCT"] = "Pourcentage"
L["SETTINGS_TAB_GENERAL"] = "Général"
L["SETTINGS_TAB_WINDOW"] = "Fenêtre %d"
L["SETTINGS_METER_TYPE"] = "Type de mètre"
L["SETTINGS_SESSION_TYPE"] = "Type de session"
L["SETTINGS_LOCKED"] = "Verrouiller la position"

-- Slash commands
L["CMD_RESET"] = "Données réinitialisées."
L["CMD_LOCKED"] = "Verrouillé"
L["CMD_UNLOCKED"] = "Déverrouillé"
L["CMD_HELP_HEADER"] = "Commandes :"
L["CMD_HELP_TOGGLE"] = "  /tdm — ouvrir les options"
L["CMD_HELP_TOGGLE_VIS"] = "  /tdm toggle — basculer la visibilité"
L["CMD_HELP_RESET"] = "  /tdm reset — réinitialiser les données"
L["CMD_HELP_LOCK"] = "  /tdm lock — verrouiller/déverrouiller la position"
L["CMD_HELP_HELP"] = "  /tdm help — ce message"

-- Auto-reset
L["SETTINGS_AUTO_RESET_INSTANCE"] = "Réinitialiser à l'entrée d'instance"
L["SETTINGS_CATEGORIES"] = "Catégories"
L["SETTINGS_CATEGORIES_MIN"] = "Au moins une catégorie doit rester activée."
L["AUTO_RESET_MSG"] = "Données réinitialisées (entrée d'instance)."

-- Combat
L["COMBAT_SETTINGS_UNAVAILABLE"] = "Options indisponibles en combat."
L["WAITING_COMBAT_END"] = "Indisponible jusqu'à la fin du combat"

-- Detail
L["SPELL_BREAKDOWN"] = "Détail des sorts"
L["NO_DATA"] = "Aucune donnée disponible"
L["BREAKDOWN_SPELLS_LABEL"] = "sorts"
L["BREAKDOWN_CRITS_LABEL"] = "crits"
L["BREAKDOWN_CRIT_RATE_LABEL"] = "crit"
L["BREAKDOWN_COL_SPELL"] = "Sort"
L["BREAKDOWN_COL_TOTAL"] = "Total"

-- Segments / Target Breakdown
L["SEGMENTS"] = "Segments"
L["SEGMENT"] = "Segment"
L["SEGMENT_COL_NAME"] = "Rencontre"
L["TARGET_BREAKDOWN"] = "Détail des cibles"
L["TARGET_COL_NAME"] = "Cible"
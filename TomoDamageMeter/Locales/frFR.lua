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
L["SETTINGS_STRIP_REALM"] = "Masquer les noms de royaume"
L["SETTINGS_ACCENT_COLOR"] = "Couleur d'accentuation"
L["SETTINGS_USE_CLASS_COLOR"] = "Utiliser la couleur de classe"
L["SETTINGS_REPORT_CHANNEL"] = "Canal de rapport"
L["SETTINGS_REPORT_LINES"] = "Lignes du rapport"
L["SETTINGS_COL_RATE"] = "Taux (DPS/HPS)"
L["SETTINGS_COL_TOTAL"] = "Total"
L["SETTINGS_COL_PCT"] = "Pourcentage"

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

-- Combat
L["COMBAT_SETTINGS_UNAVAILABLE"] = "Options indisponibles en combat."
L["WAITING_COMBAT_END"] = "Indisponible jusqu'à la fin du combat"

-- Detail
L["SPELL_BREAKDOWN"] = "Détail des sorts"
L["NO_DATA"] = "Aucune donnée disponible"
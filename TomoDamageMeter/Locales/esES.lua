local ADDON_NAME, ns = ...

----------------------------------------------------------------------
-- Localization: Spanish
----------------------------------------------------------------------

if GetLocale() ~= "esES" and GetLocale() ~= "esMX" then return end

local L = ns.L

-- General
L["ADDON_NAME"]     = "TomoDamageMeter"
L["ADDON_SHORT"]    = "Tomo"

-- Meter types
L["DPS"]            = "DPS"
L["HPS"]            = "HPS"
L["DAMAGE_TAKEN"]   = "Daño recibido"
L["AVOIDABLE"]      = "Evadible"
L["ENEMY_DAMAGE"]   = "Daño enemigo"
L["ABSORBS"]        = "Absorciones"
L["INTERRUPTS"]     = "Interrupciones"
L["DISPELS"]        = "Disipaciones"
L["DEATHS"]         = "Muertes"

-- Categories
L["DAMAGE"]         = "Daño"
L["HEALING"]        = "Sanación"
L["ACTIONS"]        = "Acciones"

-- Sessions
L["CURRENT"]        = "Actual"
L["OVERALL"]        = "Global"

-- Header / UI
L["RESET"]          = "Reiniciar"
L["LOCK"]           = "Bloquear"
L["UNLOCK"]         = "Desbloquear"
L["SETTINGS"]       = "Ajustes"
L["REPORT"]         = "Informe"
L["CLOSE"]          = "Cerrar"

-- Format labels
L["FMT_COMPACT"]    = "Compacto"
L["FMT_1DEC"]       = "1 Dec"
L["FMT_2DEC"]       = "2 Dec"
L["FMT_REGULAR"]    = "Regular"
L["FMT_INT"]        = "Entero"
L["FMT_DEC"]        = "Decimal"

-- Report
L["REPORT_HEADER"]          = "TomoDamageMeter: %s (%s)"
L["REPORT_NO_TARGET"]       = "Sin objetivo de susurro. Selecciona un jugador primero."
L["REPORT_NO_DATA"]         = "No hay datos para informar."
L["REPORT_CHANNEL_SAY"]     = "Decir"
L["REPORT_CHANNEL_PARTY"]   = "Grupo"
L["REPORT_CHANNEL_RAID"]    = "Banda"
L["REPORT_CHANNEL_GUILD"]   = "Hermandad"
L["REPORT_CHANNEL_WHISPER"] = "Susurrar"

-- Settings
L["SETTINGS_TITLE"]             = "Ajustes de TomoDamageMeter"
L["SETTINGS_GENERAL"]           = "General"
L["SETTINGS_APPEARANCE"]        = "Apariencia"
L["SETTINGS_COLUMNS"]           = "Columnas"
L["SETTINGS_FONT_SIZE"]         = "Tamaño de fuente"
L["SETTINGS_BAR_HEIGHT"]        = "Altura de barra"
L["SETTINGS_BG_OPACITY"]        = "Opacidad de fondo"
L["SETTINGS_OOC_OPACITY"]       = "Opacidad fuera de combate"
L["SETTINGS_BREAKDOWN_OPACITY"] = "Opacidad desglose de hechizos"
L["SETTINGS_STRIP_REALM"]       = "Quitar nombre de reino"
L["SETTINGS_ACCENT_COLOR"]      = "Color de acento"
L["SETTINGS_USE_CLASS_COLOR"]   = "Usar color de clase"
L["SETTINGS_REPORT_CHANNEL"]    = "Canal de informe"
L["SETTINGS_REPORT_LINES"]      = "Líneas de informe"
L["SETTINGS_WINDOWS"]           = "Ventanas"
L["SETTINGS_ADD_WINDOW"]        = "+ Añadir"
L["SETTINGS_REMOVE_WINDOW"]     = "- Eliminar"
L["SETTINGS_WINDOW_COUNT"]      = "Ventanas: %d / %d"
L["SETTINGS_COL_RATE"]          = "Tasa (DPS/HPS)"
L["SETTINGS_COL_TOTAL"]         = "Total"
L["SETTINGS_COL_PCT"]           = "Porcentaje"
L["SETTINGS_TAB_GENERAL"]       = "General"
L["SETTINGS_TAB_WINDOW"]        = "Ventana %d"
L["SETTINGS_METER_TYPE"]        = "Tipo de medidor"
L["SETTINGS_SESSION_TYPE"]      = "Tipo de sesión"
L["SETTINGS_LOCKED"]            = "Posición bloqueada"

-- Slash commands
L["CMD_RESET"]          = "Datos reiniciados."
L["CMD_LOCKED"]         = "Bloqueado"
L["CMD_UNLOCKED"]       = "Desbloqueado"
L["CMD_HELP_HEADER"]    = "Comandos:"
L["CMD_HELP_TOGGLE"]    = "  /tdm — abrir ajustes"
L["CMD_HELP_TOGGLE_VIS"]= "  /tdm toggle — alternar visibilidad de ventana"
L["CMD_HELP_RESET"]     = "  /tdm reset — reiniciar todos los datos de combate"
L["CMD_HELP_LOCK"]      = "  /tdm lock — bloquear/desbloquear posición de ventana"
L["CMD_HELP_HELP"]      = "  /tdm help — este mensaje"

-- Auto-reset
L["SETTINGS_AUTO_RESET_INSTANCE"] = "Autoreinicio al entrar en instancia"
L["SETTINGS_CATEGORIES"] = "Categorías"
L["SETTINGS_CATEGORIES_MIN"] = "Al menos una categoría debe permanecer activada."
L["AUTO_RESET_MSG"]                = "Datos reiniciados automáticamente (entrada en instancia)."

-- Combat
L["COMBAT_SETTINGS_UNAVAILABLE"] = "Ajustes no disponibles durante el combate."
L["WAITING_COMBAT_END"]          = "No disponible hasta después del combate"

-- Detail
L["SPELL_BREAKDOWN"] = "Desglose de hechizos"
L["NO_DATA"]         = "No hay datos disponibles"
L["BREAKDOWN_SPELLS_LABEL"] = "hechizos"
L["BREAKDOWN_CRITS_LABEL"]  = "críts"
L["BREAKDOWN_CRIT_RATE_LABEL"] = "crít"
L["BREAKDOWN_COL_SPELL"] = "Hechizo"
L["BREAKDOWN_COL_TOTAL"] = "Total"

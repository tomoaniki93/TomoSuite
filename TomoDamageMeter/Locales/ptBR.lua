local ADDON_NAME, ns = ...

----------------------------------------------------------------------
-- Localization: Portuguese (Brazil)
----------------------------------------------------------------------

if GetLocale() ~= "ptBR" then return end

local L = ns.L

-- General
L["ADDON_NAME"]     = "TomoDamageMeter"
L["ADDON_SHORT"]    = "Tomo"

-- Meter types
L["DPS"]            = "DPS"
L["HPS"]            = "HPS"
L["DAMAGE_TAKEN"]   = "Dano recebido"
L["AVOIDABLE"]      = "Evitável"
L["ENEMY_DAMAGE"]   = "Dano inimigo"
L["ABSORBS"]        = "Absorções"
L["INTERRUPTS"]     = "Interrupções"
L["DISPELS"]        = "Dissipações"
L["DEATHS"]         = "Mortes"

-- Categories
L["DAMAGE"]         = "Dano"
L["HEALING"]        = "Cura"
L["ACTIONS"]        = "Ações"

-- Sessions
L["CURRENT"]        = "Atual"
L["OVERALL"]        = "Total"

-- Header / UI
L["RESET"]          = "Redefinir"
L["LOCK"]           = "Travar"
L["UNLOCK"]         = "Destravar"
L["SETTINGS"]       = "Configurações"
L["REPORT"]         = "Relatório"
L["CLOSE"]          = "Fechar"

-- Format labels
L["FMT_COMPACT"]    = "Compacto"
L["FMT_1DEC"]       = "1 Dec"
L["FMT_2DEC"]       = "2 Dec"
L["FMT_REGULAR"]    = "Regular"
L["FMT_INT"]        = "Inteiro"
L["FMT_DEC"]        = "Decimal"

-- Report
L["REPORT_HEADER"]          = "TomoDamageMeter: %s (%s)"
L["REPORT_NO_TARGET"]       = "Nenhum alvo de sussurro. Selecione um jogador primeiro."
L["REPORT_NO_DATA"]         = "Sem dados para relatar."
L["REPORT_CHANNEL_SAY"]     = "Dizer"
L["REPORT_CHANNEL_PARTY"]   = "Grupo"
L["REPORT_CHANNEL_RAID"]    = "Raide"
L["REPORT_CHANNEL_GUILD"]   = "Guilda"
L["REPORT_CHANNEL_WHISPER"] = "Sussurrar"

-- Settings
L["SETTINGS_TITLE"]             = "Configurações do TomoDamageMeter"
L["SETTINGS_GENERAL"]           = "Geral"
L["SETTINGS_APPEARANCE"]        = "Aparência"
L["SETTINGS_COLUMNS"]           = "Colunas"
L["SETTINGS_FONT_SIZE"]         = "Tamanho da fonte"
L["SETTINGS_BAR_HEIGHT"]        = "Altura da barra"
L["SETTINGS_BG_OPACITY"]        = "Opacidade do fundo"
L["SETTINGS_OOC_OPACITY"]       = "Opacidade fora de combate"
L["SETTINGS_BREAKDOWN_OPACITY"] = "Opacidade detalhamento de feitiço"
L["SETTINGS_STRIP_REALM"]       = "Remover nome de reino"
L["SETTINGS_ACCENT_COLOR"]      = "Cor de destaque"
L["SETTINGS_USE_CLASS_COLOR"]   = "Usar cor da classe"
L["SETTINGS_REPORT_CHANNEL"]    = "Canal de relatório"
L["SETTINGS_REPORT_LINES"]      = "Linhas do relatório"
L["SETTINGS_WINDOWS"]           = "Janelas"
L["SETTINGS_ADD_WINDOW"]        = "+ Adicionar"
L["SETTINGS_REMOVE_WINDOW"]     = "- Remover"
L["SETTINGS_WINDOW_COUNT"]      = "Janelas: %d / %d"
L["SETTINGS_COL_RATE"]          = "Taxa (DPS/HPS)"
L["SETTINGS_COL_TOTAL"]         = "Total"
L["SETTINGS_COL_PCT"]           = "Percentual"
L["SETTINGS_TAB_GENERAL"]       = "Geral"
L["SETTINGS_TAB_WINDOW"]        = "Janela %d"
L["SETTINGS_METER_TYPE"]        = "Tipo de medidor"
L["SETTINGS_SESSION_TYPE"]      = "Tipo de sessão"
L["SETTINGS_LOCKED"]            = "Posição travada"

-- Slash commands
L["CMD_RESET"]          = "Dados redefinidos."
L["CMD_LOCKED"]         = "Travado"
L["CMD_UNLOCKED"]       = "Destravado"
L["CMD_HELP_HEADER"]    = "Comandos:"
L["CMD_HELP_TOGGLE"]    = "  /tdm — abrir configurações"
L["CMD_HELP_TOGGLE_VIS"]= "  /tdm toggle — alternar visibilidade da janela"
L["CMD_HELP_RESET"]     = "  /tdm reset — redefinir todos os dados de combate"
L["CMD_HELP_LOCK"]      = "  /tdm lock — travar/destravar posição da janela"
L["CMD_HELP_HELP"]      = "  /tdm help — esta mensagem"

-- Auto-reset
L["SETTINGS_AUTO_RESET_INSTANCE"] = "Redefinição automática ao entrar em instância"
L["SETTINGS_CATEGORIES"] = "Categorias"
L["SETTINGS_CATEGORIES_MIN"] = "Pelo menos uma categoria deve permanecer ativada."
L["AUTO_RESET_MSG"]                = "Dados redefinidos automaticamente (entrada em instância)."

-- Combat
L["COMBAT_SETTINGS_UNAVAILABLE"] = "Configurações indisponíveis durante o combate."
L["WAITING_COMBAT_END"]          = "Indisponível até o fim do combate"

-- Detail
L["SPELL_BREAKDOWN"] = "Detalhamento de feitiço"
L["NO_DATA"]         = "Nenhum dado disponível"
L["BREAKDOWN_SPELLS_LABEL"] = "feitiços"
L["BREAKDOWN_CRITS_LABEL"]  = "críts"
L["BREAKDOWN_CRIT_RATE_LABEL"] = "crít"
L["BREAKDOWN_COL_SPELL"] = "Feitiço"
L["BREAKDOWN_COL_TOTAL"] = "Total"

-- TomoSync | Localización Española
if GetLocale() ~= "esES" and GetLocale() ~= "esMX" then return end

TomoSyncLocale = {
    ADDON_NAME      = "TomoSync",
    BAGS            = "Bolsas",
    BANK            = "Banco",
    REAGENT         = "Reactivos",
    EQUIPPED        = "Equipado",
    TOTAL           = "Total",
    LAST_SCAN       = "Último escaneo",
    NEVER           = "Nunca",
    NO_DATA         = "Sin datos",
    -- Config
    CFG_TITLE       = "TomoSync — Configuración",
    CFG_SHOW_BAGS   = "Mostrar bolsas",
    CFG_SHOW_BANK   = "Mostrar banco",
    CFG_SHOW_REAGENT= "Mostrar banco de reactivos",
    CFG_SHOW_EQUIP  = "Mostrar objetos equipados",
    CFG_SHOW_TOTAL  = "Mostrar total",
    CFG_ONLY_REALM  = "Solo mismo reino",
    CFG_THRESHOLD   = "Umbral mínimo de visualización",
    CFG_THRESHOLD_TT= "Solo muestra un personaje en el tooltip si su total supera este valor.",
    -- Mensajes
    SCAN_BAGS_DONE  = "Bolsas escaneadas.",
    SCAN_BANK_DONE  = "Banco escaneado.",
    SCAN_REAGENT_DONE = "Banco de reactivos escaneado.",
    CMD_HELP        = "Comandos: /tms — ventana, /tms scan — forzar escaneo.",
    -- Warband + ventana (1.1.0)
    WARBAND         = "Banco Warband",
    SHARED          = "compartido",
    CFG_SHOW_WARBAND= "Mostrar banco Warband",
    SEARCH_PLACEHOLDER = "Buscar un objeto…",
    COL_CHARACTER   = "Personaje",
    NO_RESULTS      = "Ningún objeto encontrado",
    BTN_SCAN        = "Forzar escaneo",
    BTN_SETTINGS    = "Ajustes",
    BTN_CLEAR       = "Borrar todos los datos",
    BROWSER_HINT    = "Pasa el ratón sobre un objeto o escribe arriba para buscar.",
    ITEMS_TRACKED   = "%d objetos registrados",
    DATA_CLEARED    = "Todos los datos han sido borrados.",
}

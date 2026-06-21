-- TomoSync | English (enUS)
-- Chargé en dernier dans le .toc : remplit toute clé manquante de la locale
-- active (fallback inconditionnel, sans garde GetLocale).

local defaults = {
    ADDON_NAME      = "TomoSync",
    BAGS            = "Bags",
    BANK            = "Bank",
    REAGENT         = "Reagents",
    EQUIPPED        = "Equipped",
    TOTAL           = "Total",
    LAST_SCAN       = "Last scan",
    NEVER           = "Never",
    NO_DATA         = "No data",
    -- Config
    CFG_TITLE       = "TomoSync — Settings",
    CFG_SHOW_BAGS   = "Show bags",
    CFG_SHOW_BANK   = "Show bank",
    CFG_SHOW_REAGENT= "Show reagent bank",
    CFG_SHOW_EQUIP  = "Show equipped items",
    CFG_SHOW_TOTAL  = "Show total",
    CFG_ONLY_REALM  = "Same realm only",
    CFG_THRESHOLD   = "Minimum display threshold",
    CFG_THRESHOLD_TT= "Only shows a character in the tooltip if their total exceeds this value.",
    -- Messages
    SCAN_BAGS_DONE  = "Bags scanned.",
    SCAN_BANK_DONE  = "Bank scanned.",
    SCAN_REAGENT_DONE = "Reagent bank scanned.",
    CMD_HELP        = "Commands: /tms — open window, /tms scan — force a scan.",
    -- Warband + window (1.1.0)
    WARBAND         = "Warband Bank",
    SHARED          = "shared",
    CFG_SHOW_WARBAND= "Show Warband bank",
    SEARCH_PLACEHOLDER = "Search for an item…",
    COL_CHARACTER   = "Character",
    NO_RESULTS      = "No items found",
    BTN_SCAN        = "Force scan",
    BTN_SETTINGS    = "Settings",
    BTN_CLEAR       = "Clear all data",
    BROWSER_HINT    = "Hover an item in-game, or type above to search.",
    ITEMS_TRACKED   = "%d items tracked",
    DATA_CLEARED    = "All data cleared.",
    CFG_MINIMAP_BUTTON = "Minimap button",
    MM_LEFT         = "Left-click: open window",
    MM_RIGHT        = "Right-click: settings",
}

TomoSyncLocale = TomoSyncLocale or {}
for k, v in pairs(defaults) do
    if TomoSyncLocale[k] == nil then
        TomoSyncLocale[k] = v
    end
end

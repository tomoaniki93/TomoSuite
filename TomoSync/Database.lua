-- TomoSync | Database.lua

--[[
    Structure de TomoSyncDB (SavedVariables, globale) :
    TomoSyncDB = {
        ["_account"] = {                          -- reserve : donnees partagees au compte
            warband = {
                lastScan = <timestamp>,
                items    = { [itemID] = count },   -- banque Warband (partagee, account-wide)
            },
        },
        ["Nom du Royaume"] = {
            ["NomDuPerso"] = {
                class    = "WARRIOR",
                level    = 80,
                lastScan = <timestamp>,
                settings = { ... },                -- reglages par personnage
                items    = { [itemID] = { bags=N, bank=N, equip=N } },
            },
        },
    }

    NOTE Midnight : la banque de reactifs (ancien index -3) a ete supprimee au
    patch 11.x. Le champ "reagent" des anciennes donnees est purge a l'init.
    La banque Warband est account-wide : stockee une seule fois sous _account.
--]]

TomoSyncDB_Defaults = {
    showBags    = true,
    showBank    = true,
    showWarband = true,
    showEquip   = false,
    showTotal   = true,
    onlyRealm   = true,
    threshold   = 0,
}

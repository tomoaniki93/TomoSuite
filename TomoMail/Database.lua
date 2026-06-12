-- TomoMail | Database.lua
-- Valeurs par défaut de la base de données sauvegardée

TomoMailDB_Defaults = {
    -- Données globales (partagées entre tous les personnages du compte)
    global = {
        -- Table des alts : "Nom|Royaume|Faction|Niveau|Classe"
        alts = {},

        -- Position de la fenêtre TomoMail
        window = { point = "TOP", x = -160, y = -100 },
    },

    -- Données par profil (par personnage)
    profile = {
        -- 10 derniers destinataires : "Nom|Royaume|Faction"
        recent = {},

        -- Options
        showAlts        = true,
        showGuild       = true,
        showRecent      = true,
        guildOnlineOnly = false,
        useAutocomplete = true,
        maxRecent       = 10,
        skinEnabled     = true,
        modernUI        = true,
        mailScale       = 1.0,

        -- Police de l'interface
        font            = "Fonts\\FRIZQT__.TTF",
        fontSize        = 1.0,

        -- Taille des icônes d'objets dans la boîte de réception (18-36)
        inboxIconSize   = 30,

        -- Couleurs du thème
        color = { r = 0.8, g = 0.267, b = 1.0 },
    },
}

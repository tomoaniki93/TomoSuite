-- =====================================
-- Locales/frFR.lua — Français
-- =====================================

if GetLocale() ~= "frFR" then return end
local L = TGF_L

-- Général
L["addon_name"]           = "TomoGroupFrame"
L["addon_title"]          = "|cffCC44FFTomo|r|cffFFFFFFGroupFrame|r"
L["msg_loaded"]           = "chargé. Tapez %s pour ouvrir la configuration."
L["msg_db_reset"]         = "Base de données réinitialisée."
L["msg_db_not_init"]      = "Base de données non initialisée."
L["msg_module_reset"]     = "%s réinitialisé aux valeurs par défaut."

-- Commandes slash
L["msg_help_title"]       = "Commandes :"
L["msg_help_open"]        = "Ouvrir le panneau de config"
L["msg_help_lock"]        = "Verrouiller/déverrouiller les frames"
L["msg_help_test"]        = "Activer/désactiver le mode test"
L["msg_help_reset"]       = "Réinitialiser tous les paramètres"
L["msg_help_help"]        = "Afficher cette aide"

-- Catégories
L["cat_party"]            = "Groupe"
L["cat_raid"]             = "Raid"
L["cat_profiles"]         = "Profils"

-- Panneau Groupe
L["section_party_general"]   = "Cadres de Groupe — Général"
L["section_party_layout"]    = "Disposition"
L["section_party_bars"]      = "Barres de Vie"
L["section_party_text"]      = "Texte & Polices"
L["section_party_dispel"]    = "Surbrillance Dissipation"
L["section_party_hots"]      = "Suivi des HoTs"
L["opt_enabled"]             = "Activer les cadres de groupe"
L["opt_width"]               = "Largeur du cadre"
L["opt_height"]              = "Hauteur du cadre"
L["opt_spacing"]             = "Espacement"
L["opt_grow_direction"]      = "Direction de croissance"
L["grow_down"]               = "Vers le bas"
L["grow_up"]                 = "Vers le haut"
L["grow_right"]              = "Vers la droite"
L["grow_left"]               = "Vers la gauche"
L["opt_bar_texture"]         = "Texture de barre"
L["opt_use_class_color"]     = "Couleurs de classe"
L["opt_show_name"]           = "Afficher le nom"
L["opt_name_truncate"]       = "Tronquer le nom"
L["opt_show_hp_percent"]     = "Afficher le % PV"
L["opt_name_font"]           = "Police du nom"
L["opt_hp_font"]             = "Police des PV"
L["opt_font_size"]           = "Taille de police"
L["opt_show_dispel"]         = "Afficher le contour de dissipation"
L["opt_dispel_border_size"]  = "Épaisseur du contour"
L["opt_show_hots"]           = "Afficher les HoTs des soigneurs"
L["opt_hot_icon_size"]       = "Taille des icônes HoT"
L["opt_hot_font_size"]       = "Taille texte HoT"
L["opt_max_hots"]            = "Nombre max de HoTs"
L["opt_show_power_bar"]      = "Afficher la barre de ressource"
L["opt_power_height"]        = "Hauteur barre de ressource"
L["opt_show_role_icon"]      = "Afficher l'icône de rôle"
L["opt_show_raid_icon"]      = "Afficher l'icône de cible"
L["opt_range_alpha"]         = "Opacité hors portée"

-- Panneau Raid
L["section_raid_general"]    = "Cadres de Raid — Général"
L["section_raid_layout"]     = "Disposition"
L["section_raid_groups"]     = "Affichage des Groupes"
L["opt_raid_enabled"]        = "Activer les cadres de raid"
L["opt_raid_width"]          = "Largeur du cadre"
L["opt_raid_height"]         = "Hauteur du cadre"
L["opt_groups_per_row"]      = "Groupes par rangée"
L["opt_sort_by_role"]        = "Trier par rôle"
L["opt_show_group_labels"]   = "Afficher les labels de groupe"
L["opt_compact_mode"]        = "Mode compact"

-- Profils
L["tab_profiles"]            = "Profils"
L["tab_import_export"]       = "Import/Export"
L["tab_resets"]              = "Réinitialiser"
L["section_named_profiles"]  = "Profils Nommés"
L["section_spec_profiles"]   = "Profils par Spécialisation"
L["section_import"]          = "Importer"
L["section_export"]          = "Exporter"
L["section_reset_all"]       = "Réinitialisation Complète"
L["btn_create"]              = "Créer"
L["btn_load"]                = "Charger"
L["btn_delete"]              = "Supprimer"
L["btn_rename"]              = "Renommer"
L["btn_duplicate"]           = "Dupliquer"
L["btn_export"]              = "Exporter le profil actuel"
L["btn_import"]              = "Importer un Profil..."
L["btn_close"]               = "Fermer"
L["btn_reload_ui"]           = "Recharger l'UI"
L["btn_reset_all"]           = "Tout Réinitialiser et Recharger"
L["placeholder_profile"]     = "Nom du nouveau profil..."
L["msg_profile_created"]     = "Profil '%s' créé."
L["msg_profile_loaded"]      = "Profil '%s' chargé."
L["msg_profile_deleted"]     = "Profil '%s' supprimé."
L["msg_profile_renamed"]     = "'%s' renommé en '%s'."
L["msg_profile_duplicated"]  = "'%s' dupliqué en '%s'."
L["msg_import_success"]      = "Import réussi."
L["msg_import_as_profile"]   = "Importé sous '%s'."
L["msg_spec_changed_reload"] = "Spécialisation changée — rechargement..."
L["info_profiles"]           = "Créez, chargez et gérez vos profils d'interface."
L["info_spec_profiles"]      = "Assignez un profil à chaque spécialisation. Changer de spec basculera automatiquement."
L["info_import"]             = "Collez une chaîne d'export. Vous pouvez la sauvegarder sous un nouveau nom."
L["info_import_warning"]     = "L'import sans nom de profil remplace vos paramètres actuels."
L["info_reset_warning"]      = "Réinitialise TOUS les paramètres. Action irréversible."
L["popup_export_title"]      = "Exporter le Profil"
L["popup_export_hint"]       = "Sélectionnez tout (Ctrl+A) et copiez (Ctrl+C)"
L["popup_confirm"]           = "Confirmer"
L["popup_cancel"]            = "Annuler"

-- Textures de barre
L["bar_flat"]                = "Plat"
L["bar_gradient"]            = "Dégradé"
L["bar_glossy"]              = "Brillant"
L["bar_striped"]             = "Rayé"
L["bar_smooth"]              = "Lisse"
L["bar_minimalist"]          = "Minimaliste"

-- Polices
L["font_poppins"]            = "Poppins"
L["font_expressway"]         = "Expressway"
L["font_accidental"]         = "Accidental Presidency"
L["font_poppins_bold"]       = "Poppins Gras"

-- Types de dissipation
L["dispel_magic"]            = "Magie"
L["dispel_curse"]            = "Malédiction"
L["dispel_disease"]          = "Maladie"
L["dispel_poison"]           = "Poison"

-- Texte de statut
L["status_dead"]             = "MORT"
L["status_offline"]          = "HORS LIGNE"

-- Mode test
L["test_mode_on"]            = "Mode test |cff00ff00activé|r."
L["test_mode_off"]           = "Mode test |cffff0000désactivé|r."

-- TomoSync | Core.lua

local ADDON_NAME = "TomoSync"
local L          = TomoSyncLocale

-- ============================================================
--  Namespace global
-- ============================================================

TomoSync = {
    modules  = {},
    db       = nil,   -- { global = TomoSyncDB, settings = entry.settings, char = entry }
    account  = nil,   -- TomoSyncDB._account (donnees partagees au compte)
    realm    = nil,
    charName = nil,
}

local TS = TomoSync

-- Cle reservee du store account-wide (les noms de royaume ne commencent jamais par "_")
TS.ACCOUNT_KEY = "_account"

-- ============================================================
--  Constantes de couleur
-- ============================================================

TS.COLOR       = "CC44FF"
TS.COLOR_HEX   = "|cFFCC44FF"      -- pourpre principal
TS.COLOR_GRAY  = "|cFFAAAAAA"      -- gris secondaire
TS.COLOR_WHITE = "|cFFFFFFFF"
TS.COLOR_CYAN  = "|cFF40D2E0"      -- cyan "partage" (Warband)

-- ============================================================
--  Utilitaires
-- ============================================================

function TS:RegisterModule(name, obj)
    self.modules[name] = obj
    obj.name = name
end

function TS:L(key)
    return (L and L[key]) or key
end

function TS:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(TS.COLOR_HEX .. "TomoSync|r " .. (msg or ""))
end

function TS:ClassColor(class)
    if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        return string.format("|cFF%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
    end
    return "|cFFFFFFFF"
end

-- Variante renvoyant un triplet {r,g,b} pour SetTextColor
function TS:ClassColorTriple(class)
    if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        return { c.r, c.g, c.b }
    end
    return { 1, 1, 1 }
end

-- Extrait itemID depuis un lien ou un itemID direct
function TS:GetItemID(link)
    if not link then return nil end
    if type(link) == "number" then return link end
    return tonumber(link:match("item:(%d+)"))
end

-- Nom d'objet (peut etre nil si non encore en cache client)
function TS:GetItemName(itemID)
    if C_Item and C_Item.GetItemInfo then
        local ok, name = pcall(C_Item.GetItemInfo, itemID)
        if ok and name then return name end
    end
    if GetItemInfo then
        local name = GetItemInfo(itemID)
        return name
    end
    return nil
end

-- Icone d'objet (disponible immediatement via GetItemInfoInstant)
function TS:GetItemIcon(itemID)
    if C_Item and C_Item.GetItemInfoInstant then
        local ok, _, _, _, _, icon = pcall(C_Item.GetItemInfoInstant, itemID)
        if ok and icon then return icon end
    end
    if GetItemInfoInstant then
        return select(5, GetItemInfoInstant(itemID))
    end
    return nil
end

-- Qualite d'objet (0..8) ou nil
function TS:GetItemQuality(itemID)
    if C_Item and C_Item.GetItemInfo then
        local ok, _, _, quality = pcall(C_Item.GetItemInfo, itemID)
        if ok then return quality end
    end
    return nil
end

-- Demande le chargement des donnees d'un objet non encore en cache
function TS:RequestItem(itemID)
    if C_Item and C_Item.RequestLoadItemDataByID then
        pcall(C_Item.RequestLoadItemDataByID, itemID)
    end
end

local function GetVersion()
    local v
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        v = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
    elseif GetAddOnMetadata then
        v = GetAddOnMetadata(ADDON_NAME, "Version")
    end
    return v or "?"
end

-- ============================================================
--  Initialisation de la base de donnees
-- ============================================================

local function MergeDefaults(target, defaults)
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            if type(target[k]) ~= "table" then target[k] = {} end
            MergeDefaults(target[k], v)
        elseif target[k] == nil then
            target[k] = v
        end
    end
end

-- Migration 1.1.0 : retire le champ "reagent" des anciennes donnees
-- (banque de reactifs supprimee au patch 11.x).
local function PurgeReagent()
    for realm, chars in pairs(TomoSyncDB) do
        if realm ~= TS.ACCOUNT_KEY and type(chars) == "table" then
            for _, entry in pairs(chars) do
                if type(entry) == "table" and type(entry.items) == "table" then
                    for _, data in pairs(entry.items) do
                        if type(data) == "table" then data.reagent = nil end
                    end
                end
            end
        end
    end
end

local function InitDB()
    if type(TomoSyncDB) ~= "table" then
        TomoSyncDB = {}
    end

    TS.realm    = GetRealmName()
    TS.charName = UnitName("player")

    -- Store account-wide (banque Warband partagee)
    if type(TomoSyncDB[TS.ACCOUNT_KEY]) ~= "table" then
        TomoSyncDB[TS.ACCOUNT_KEY] = {}
    end
    local account = TomoSyncDB[TS.ACCOUNT_KEY]
    if type(account.warband) ~= "table" then account.warband = {} end
    if type(account.warband.items) ~= "table" then account.warband.items = {} end
    TS.account = account

    -- Entree du personnage courant
    if not TomoSyncDB[TS.realm] then
        TomoSyncDB[TS.realm] = {}
    end
    if not TomoSyncDB[TS.realm][TS.charName] then
        TomoSyncDB[TS.realm][TS.charName] = { items = {} }
    end

    local charEntry = TomoSyncDB[TS.realm][TS.charName]
    if not charEntry.items then charEntry.items = {} end

    -- Reglages par personnage (stockes dans la SavedVariable pour persister)
    if type(charEntry.settings) ~= "table" then
        charEntry.settings = {}
    end
    MergeDefaults(charEntry.settings, TomoSyncDB_Defaults)

    -- Infos du personnage
    local _, class = UnitClass("player")
    charEntry.class = class
    charEntry.level = UnitLevel("player")

    PurgeReagent()

    TS.db = {
        global   = TomoSyncDB,
        settings = charEntry.settings,
        char     = charEntry,
    }
end

-- Reinitialise toutes les donnees (utilise par le bouton "Effacer")
function TS:ResetData()
    TomoSyncDB = {}
    InitDB()
    local tip = self.modules["Tooltip"]; if tip and tip.ResetCache then tip:ResetCache() end
    local br  = self.modules["Browser"]; if br and br.Refresh then br:Refresh() end
end

-- ============================================================
--  Accesseurs DB
-- ============================================================

function TS:GetCharEntry(realm, charName)
    local db = self.db and self.db.global
    if not db then return nil end
    return db[realm] and db[realm][charName]
end

-- Itere sur tous les personnages (saute la cle account-wide)
function TS:ForEachChar(fn)
    local db = self.db and self.db.global
    if not db then return end
    for realm, chars in pairs(db) do
        if realm ~= self.ACCOUNT_KEY and type(chars) == "table" then
            for charName, entry in pairs(chars) do
                if type(entry) == "table" and entry.items then
                    fn(realm, charName, entry)
                end
            end
        end
    end
end

-- Total stocke d'un itemID pour un personnage (sacs + banque + equipe)
function TS:GetCharItemCount(entry, itemID, showBags, showBank, showEquip)
    if not entry or not entry.items then return 0 end
    local data = entry.items[itemID]
    if not data then return 0 end
    local total = 0
    if showBags  and data.bags  then total = total + data.bags  end
    if showBank  and data.bank  then total = total + data.bank  end
    if showEquip and data.equip then total = total + data.equip end
    return total
end

-- Compte de la banque Warband (partagee) pour un itemID
function TS:GetWarbandCount(itemID)
    local a = self.account
    if not a or not a.warband or not a.warband.items then return 0 end
    return a.warband.items[itemID] or 0
end

-- ============================================================
--  Frame principale et evenements
-- ============================================================

local frame = CreateFrame("Frame", "TomoSyncFrame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LEVEL_UP")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == ADDON_NAME then
            InitDB()
            for _, mod in pairs(TS.modules) do
                if mod.OnInitialize then mod:OnInitialize() end
            end
            TS:Print("v" .. GetVersion() .. " " .. TS:L("CMD_HELP"))
            self:UnregisterEvent("ADDON_LOADED")
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        if TS.db then
            local _, class = UnitClass("player")
            TS.db.char.class = class
            TS.db.char.level = UnitLevel("player")
        end
        for _, mod in pairs(TS.modules) do
            if mod.OnEnteringWorld then mod:OnEnteringWorld() end
        end

    elseif event == "PLAYER_LEVEL_UP" then
        if TS.db then
            TS.db.char.level = UnitLevel("player")
        end
    end
end)

-- ============================================================
--  Commandes slash
-- ============================================================

SLASH_TOMOSYNC1 = "/tomosync"
SLASH_TOMOSYNC2 = "/tms"

SlashCmdList["TOMOSYNC"] = function(msg)
    local cmd = msg and msg:lower():match("^%s*(%S*)") or ""
    if cmd == "scan" then
        local scanner = TS.modules["Scanner"]
        if scanner then
            scanner:ScanBags()
            scanner:ScanEquipped()
            TS:Print(TS:L("SCAN_BAGS_DONE"))
        end
    elseif cmd == "config" or cmd == "options" or cmd == "settings" then
        if TomoSyncConfig and TomoSyncConfig.Toggle then
            TomoSyncConfig:Toggle()
        end
    else
        local br = TS.modules["Browser"]
        if br and br.Toggle then br:Toggle() end
    end
end

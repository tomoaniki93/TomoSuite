-- TomoSync | Modules/Scanner.lua
-- Scanne sacs, banque du personnage et banque Warband (compte) du joueur courant.
--
-- NOTE Midnight : la banque de reactifs (ancien index -3) a ete supprimee au
-- patch 11.x. Les onglets de banque perso sont desormais CharacterBankTab_1..6
-- et la banque Warband (partagee, account-wide) est enumeree dynamiquement via
-- C_Bank.FetchPurchasedBankTabIDs au lieu d'une plage codee en dur.

local TS = TomoSync
local Scanner = {}
TS:RegisterModule("Scanner", Scanner)

-- ============================================================
--  Constantes de conteneurs (resolues via Enum/Constants, avec repli)
-- ============================================================

local BAG_BACKPACK = (Enum and Enum.BagIndex and Enum.BagIndex.Backpack) or 0
local NUM_BAGS     = (Constants and Constants.InventoryConstants and Constants.InventoryConstants.NumBagSlots) or 4
local NUM_RBAG     = (Constants and Constants.InventoryConstants and Constants.InventoryConstants.NumReagentBagSlots) or 1
local BAG_LAST     = BAG_BACKPACK + NUM_BAGS + NUM_RBAG          -- 0..5 : sac a dos + 4 sacs + sac a reactifs

local BANK_TYPE_CHARACTER = (Enum and Enum.BankType and Enum.BankType.Character) or 0
local BANK_TYPE_ACCOUNT   = (Enum and Enum.BankType and Enum.BankType.Account)   or 2

-- Replis si FetchPurchasedBankTabIDs renvoie vide. Index Midnight (12.x) :
--   banque perso  = CharacterBankTab_1..6 -> 6..11
--   banque Warband= AccountBankTab_1..5   -> 12..16
-- NB Midnight : l'index -1 est desormais le TROUSSEAU (plus la banque), donc on
-- ne le scanne plus ; la banque perso est entierement decoupee en onglets.
local FALLBACK_CHAR_BANK    = { 6, 7, 8, 9, 10, 11 }
local FALLBACK_ACCOUNT_BANK = { 12, 13, 14, 15, 16 }

local EQUIP_FIRST, EQUIP_LAST = 1, 19

-- ============================================================
--  Garde "secret value" (Midnight) + wrappers pcall sur les API C_*
-- ============================================================

local function IsSecret(v)
    return issecretvalue and issecretvalue(v)
end

local function SafeNumSlots(bag)
    if not (C_Container and C_Container.GetContainerNumSlots) then return 0 end
    local ok, n = pcall(C_Container.GetContainerNumSlots, bag)
    if ok and n and not IsSecret(n) then return n end
    return 0
end

local function SafeItemInfo(bag, slot)
    if not (C_Container and C_Container.GetContainerItemInfo) then return nil end
    local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
    if ok then return info end
    return nil
end

local function SafeBankTabs(bankType)
    if not (C_Bank and C_Bank.FetchPurchasedBankTabIDs) then return nil end
    local ok, ids = pcall(C_Bank.FetchPurchasedBankTabIDs, bankType)
    if ok and type(ids) == "table" then return ids end
    return nil
end

-- Lit un conteneur et appelle add(itemID, count) pour chaque pile valide.
-- On n'additionne jamais une valeur secret : sinon Midnight produit une chaine
-- tainted (crash au formatage) et ne persiste pas la valeur en SavedVariables.
local function ReadContainer(bag, add)
    local n = SafeNumSlots(bag)
    if n <= 0 then return end
    for slot = 1, n do
        local info = SafeItemInfo(bag, slot)
        if info then
            local id    = info.itemID
            local count = info.stackCount
            if id and count and not IsSecret(id) and not IsSecret(count)
               and id ~= 0 and count > 0 then
                add(id, count)
            end
        end
    end
end

-- ============================================================
--  Helpers d'accumulation (par personnage)
-- ============================================================

local function ResetSlot(items, slotKey)
    for _, data in pairs(items) do
        if type(data) == "table" then data[slotKey] = 0 end
    end
end

local function AddSlot(items, slotKey, id, count)
    local d = items[id]
    if not d then
        d = { bags = 0, bank = 0, equip = 0 }
        items[id] = d
    end
    d[slotKey] = (d[slotKey] or 0) + count
end

local function Prune(items)
    for id, data in pairs(items) do
        if type(data) == "table" then
            if (data.bags or 0) == 0 and (data.bank or 0) == 0 and (data.equip or 0) == 0 then
                items[id] = nil
            end
        end
    end
end

-- Invalide le cache tooltip + rafraichit la fenetre apres un scan.
function Scanner:AfterScan()
    local tip = TS.modules["Tooltip"]
    if tip and tip.ResetCache then tip:ResetCache() end
    local br = TS.modules["Browser"]
    if br and br.Refresh then br:Refresh() end
end

-- ============================================================
--  API publique
-- ============================================================

function Scanner:ScanBags()
    if not TS.db or not TS.db.char then return end
    local items = TS.db.char.items
    ResetSlot(items, "bags")
    for bag = BAG_BACKPACK, BAG_LAST do
        ReadContainer(bag, function(id, c) AddSlot(items, "bags", id, c) end)
    end
    TS.db.char.lastScan = time()
    Prune(items)
    Scanner:AfterScan()
end

function Scanner:ScanBank()
    if not TS.db or not TS.db.char then return end
    local items = TS.db.char.items
    ResetSlot(items, "bank")
    -- Banque perso : entierement decoupee en onglets (Midnight). -1 = trousseau,
    -- on ne le scanne plus. Onglets achetes via l'API, ou repli 6..11.
    local tabs = SafeBankTabs(BANK_TYPE_CHARACTER)
    if not tabs or #tabs == 0 then tabs = FALLBACK_CHAR_BANK end
    for _, bag in ipairs(tabs) do
        ReadContainer(bag, function(id, c) AddSlot(items, "bank", id, c) end)
    end
    TS.db.char.lastScan = time()
    Prune(items)
    Scanner:AfterScan()
end

-- Banque Warband : partagee au compte, stockee une seule fois sous _account.
-- Banque Warband : partagee au compte, stockee une seule fois sous _account.
-- Retourne le nombre d'objets distincts trouves (diagnostic).
function Scanner:ScanWarband()
    if not TS.account or not TS.account.warband then return 0 end
    local wb = TS.account.warband
    wipe(wb.items)
    -- Onglets Warband achetes via l'API ; repli sur la plage fixe Midnight 12..16
    local tabs = SafeBankTabs(BANK_TYPE_ACCOUNT)
    if not tabs or #tabs == 0 then tabs = FALLBACK_ACCOUNT_BANK end
    for _, bag in ipairs(tabs) do
        ReadContainer(bag, function(id, c)
            wb.items[id] = (wb.items[id] or 0) + c
        end)
    end
    wb.lastScan = time()
    local n = 0
    for _ in pairs(wb.items) do n = n + 1 end
    wb.count = n
    Scanner:AfterScan()
    return n
end

function Scanner:ScanEquipped()
    if not TS.db or not TS.db.char then return end
    local items = TS.db.char.items
    ResetSlot(items, "equip")
    for slot = EQUIP_FIRST, EQUIP_LAST do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local id = TS:GetItemID(link)
            if id then
                local count = GetInventoryItemCount("player", slot)
                if IsSecret(count) then count = 1 end
                count = count or 1
                if count > 0 then AddSlot(items, "equip", id, count) end
            end
        end
    end
    Prune(items)
    Scanner:AfterScan()
end

-- ============================================================
--  Evenements
-- ============================================================

local scanFrame = CreateFrame("Frame", "TomoSyncScanFrame")

function Scanner:OnInitialize()
    scanFrame:RegisterEvent("BAG_UPDATE")
    scanFrame:RegisterEvent("BANKFRAME_OPENED")
    scanFrame:RegisterEvent("BANKFRAME_CLOSED")
    scanFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

    scanFrame:SetScript("OnEvent", function(self, event)
        if event == "BAG_UPDATE" then
            -- Throttle : on ne rescanne pas a chaque objet deplace
            if not self._bagTimer then
                self._bagTimer = C_Timer.NewTimer(0.5, function()
                    self._bagTimer = nil
                    Scanner:ScanBags()
                    -- A la banque, BAG_UPDATE se declenche aussi quand un onglet
                    -- (banque perso ou Warband) finit de se charger : on en profite
                    -- pour (re)scanner banque + Warband, ce qui capte l'onglet
                    -- Warband meme s'il se charge apres l'ouverture initiale.
                    if Scanner.atBank then
                        Scanner:ScanBank()
                        Scanner:ScanWarband()
                    end
                end)
            end

        elseif event == "BANKFRAME_OPENED" then
            Scanner.atBank = true
            -- Laisse le serveur peupler les onglets (banque perso + Warband).
            -- On scanne a 0.4s puis a 1.2s : les onglets Warband peuvent arriver
            -- apres l'ouverture initiale de la banque.
            local function doScan(announce)
                Scanner:ScanBank()
                local n = Scanner:ScanWarband()
                if announce then
                    TS:Print(TS:L("SCAN_BANK_DONE") .. "  |cFF40D2E0" .. TS:L("WARBAND") .. ": " .. n .. "|r")
                end
            end
            C_Timer.After(0.4, function() doScan(false) end)
            C_Timer.After(1.2, function() doScan(true) end)

        elseif event == "BANKFRAME_CLOSED" then
            Scanner.atBank = false

        elseif event == "PLAYER_EQUIPMENT_CHANGED" then
            Scanner:ScanEquipped()
        end
    end)
end

function Scanner:OnEnteringWorld()
    -- Scan initial des sacs et de l'equipement au login
    C_Timer.After(1.0, function()
        Scanner:ScanBags()
        Scanner:ScanEquipped()
    end)
end

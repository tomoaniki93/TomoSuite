-- TomoSync | Modules/Tooltip.lua
-- Affiche les comptes d'objets par personnage + banque Warband dans les tooltips.

local TS = TomoSync
local Tooltip = {}
TS:RegisterModule("Tooltip", Tooltip)

-- ============================================================
--  Cache tooltip (evite de recalculer a chaque survol)
-- ============================================================

local cache         = {}   -- [itemID] = { time, out = {...}, total = {l,r} }
local CACHE_MAX_AGE = 5     -- secondes

function Tooltip:ResetCache()
    wipe(cache)
end

-- ============================================================
--  Formatage des nombres
-- ============================================================

local function Fmt(n)
    if not n or n == 0 then return "0" end
    if BreakUpLargeNumbers then
        return tostring(BreakUpLargeNumbers(n))
    end
    return tostring(n)
end

-- ============================================================
--  Collecte des donnees pour un itemID
-- ============================================================

local function CollectLines(itemID)
    local s         = TS.db.settings
    local threshold = s.threshold or 0
    local lines     = {}
    local grand     = 0

    TS:ForEachChar(function(realm, charName, entry)
        if s.onlyRealm and realm ~= TS.realm then return end
        local d = entry.items[itemID]
        if not d then return end
        local bags  = (s.showBags  and d.bags)  or 0
        local bank  = (s.showBank  and d.bank)  or 0
        local equip = (s.showEquip and d.equip) or 0
        local total = bags + bank + equip
        if total > threshold then
            lines[#lines + 1] = {
                charName  = charName,
                realm     = realm,
                class     = entry.class,
                bags      = bags,
                bank      = bank,
                equip     = equip,
                total     = total,
                isCurrent = (charName == TS.charName and realm == TS.realm),
            }
            grand = grand + total
        end
    end)

    table.sort(lines, function(a, b)
        if a.isCurrent ~= b.isCurrent then return a.isCurrent end
        if a.total ~= b.total then return a.total > b.total end
        return a.charName < b.charName
    end)

    -- Banque Warband (partagee au compte)
    local warband = 0
    if s.showWarband then
        warband = TS:GetWarbandCount(itemID)
        grand = grand + warband
    end

    return lines, warband, grand
end

-- Construit la liste des lignes affichables (chaines avec couleurs incorporees).
local function Build(itemID)
    local lines, warband, grand = CollectLines(itemID)
    if #lines == 0 and warband == 0 then return nil, nil end

    local s  = TS.db.settings
    local G  = TS.COLOR_GRAY
    local P  = TS.COLOR_HEX
    local CY = TS.COLOR_CYAN
    local out = {}

    for _, e in ipairs(lines) do
        if e.isCurrent then
            -- Personnage courant : detail par emplacement (style BagSync)
            if s.showBags and e.bags > 0 then
                out[#out + 1] = { G .. TS:L("BAGS") .. ":|r", P .. Fmt(e.bags) .. "|r" }
            end
            if s.showBank and e.bank > 0 then
                out[#out + 1] = { G .. TS:L("BANK") .. ":|r", P .. Fmt(e.bank) .. "|r" }
            end
            if s.showEquip and e.equip > 0 then
                out[#out + 1] = { G .. TS:L("EQUIPPED") .. ":|r", P .. Fmt(e.equip) .. "|r" }
            end
        else
            -- Autres persos : Nom    Total (Sacs: X, Banque: Y)
            local parts = {}
            if s.showBags  and e.bags  > 0 then parts[#parts + 1] = TS:L("BAGS")  .. ": " .. Fmt(e.bags)  end
            if s.showBank  and e.bank  > 0 then parts[#parts + 1] = TS:L("BANK")  .. ": " .. Fmt(e.bank)  end
            if s.showEquip and e.equip > 0 then parts[#parts + 1] = TS:L("EQUIPPED") .. ": " .. Fmt(e.equip) end

            local left = TS:ClassColor(e.class) .. e.charName .. "|r"
            if e.realm ~= TS.realm then
                left = left .. G .. " [" .. e.realm .. "]|r"
            end
            local right = P .. Fmt(e.total) .. "|r"
            if #parts > 0 then
                right = right .. " " .. G .. "(" .. table.concat(parts, ", ") .. ")|r"
            end
            out[#out + 1] = { left, right }
        end
    end

    -- Ligne Warband (partagee)
    if warband > 0 then
        local left = CY .. TS:L("WARBAND") .. "|r " .. G .. "(" .. TS:L("SHARED") .. ")|r"
        out[#out + 1] = { left, CY .. Fmt(warband) .. "|r" }
    end

    -- Ligne Total
    local total = nil
    if s.showTotal and grand > 0 then
        total = { P .. TS:L("TOTAL") .. ":|r", P .. Fmt(grand) .. "|r" }
    end

    return out, total
end

-- ============================================================
--  Ajout des lignes au tooltip
-- ============================================================

local function AddToTooltip(tt, itemID)
    if not TS.db or not TS.db.settings then return end

    local c = cache[itemID]
    if not (c and (GetTime() - c.time) < CACHE_MAX_AGE) then
        local out, total = Build(itemID)
        c = { time = GetTime(), out = out, total = total }
        cache[itemID] = c
    end

    if not c.out then return end

    tt:AddLine(" ")
    for _, l in ipairs(c.out) do
        tt:AddDoubleLine(l[1], l[2], 1, 1, 1, 1, 1, 1)
    end
    if c.total then
        tt:AddDoubleLine(c.total[1], c.total[2], 1, 1, 1, 1, 1, 1)
    end
    tt:Show()
end

-- ============================================================
--  Hook du tooltip
-- ============================================================

function Tooltip:OnInitialize()
    -- Purge des entrees de cache expirees toutes les 30s.
    C_Timer.NewTicker(30, function()
        local now = GetTime()
        for id, entry in pairs(cache) do
            if (now - entry.time) >= CACHE_MAX_AGE then
                cache[id] = nil
            end
        end
    end)

    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        -- Retail moderne : couvre objets ET liens hypertexte (un seul hook,
        -- sinon les liens du chat afficheraient les lignes en double).
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tt, data)
            if not TS.db then return end
            local itemID = data and data.id
            if not itemID or itemID == 0 then return end
            AddToTooltip(tt, itemID)
        end)
    else
        -- Repli : hooks classiques
        hooksecurefunc(GameTooltip, "SetItem", function(tt)
            if not TS.db then return end
            local _, link = tt:GetItem()
            if not link then return end
            local itemID = TS:GetItemID(link)
            if itemID then AddToTooltip(tt, itemID) end
        end)
        hooksecurefunc(GameTooltip, "SetHyperlink", function(tt, link)
            if not TS.db then return end
            if not link or link:sub(1, 4) ~= "item" then return end
            local itemID = TS:GetItemID(link)
            if itemID then AddToTooltip(tt, itemID) end
        end)
    end
end

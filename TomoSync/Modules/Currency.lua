-- TomoSync | Modules/Currency.lua
-- Suivi des monnaies par personnage.
--
-- 1) Scanner : lit la liste de monnaies du client (C_CurrencyInfo) et stocke la
--    quantite par personnage, plus les metadonnees partagees au compte (nom,
--    icone, qualite, categorie, drapeau "account-wide") sous _account.currency.
-- 2) Page "Monnaies" de la fenetre : liste accordeon a gauche (categories du
--    jeu : Midnight, Saison 1, Divers, Donjons & Raids, JcJ...), detail par
--    personnage a droite, sur le modele de la vue Objets.
-- 3) Tooltip : lignes "qui possede combien" sur les tooltips de monnaie.
--
-- NOTE Midnight : aucune arithmetique sur une valeur secret. Toute valeur
-- renvoyee par une API C_* est passee par issecretvalue() avant comparaison,
-- addition ou formatage, et tous les appels C_* sont proteges par pcall.

local TS = TomoSync
local UI = TS.UI
local Currency = {}
TS:RegisterModule("Currency", Currency)

-- Geometrie (identique a la vue Objets pour rester coherent)
local NUM_ROWS, ROW_H = 14, 24
local ROW_HD          = 22
local MAX_DETAIL      = 10
local DEFAULT_ICON    = 134400      -- INV_Misc_QuestionMark
local LIST_W          = 222
local DETAIL_X        = 252
local DETAIL_W        = 368

-- Etat du module
local page, listScroll, evtFrame
local detail      = {}
local rows        = {}
local displayList = {}
local curCount    = 0
local selectedID  = nil
local searchText  = ""
local expandState = {}      -- [catKey] = false si replie (deplie par defaut)
local scanning    = false
local lastScan    = 0

local UpdateList, UpdateDetail, SelectCurrency, ToggleCategory

-- ============================================================
--  Gardes "secret value" + wrappers pcall sur les API C_*
-- ============================================================

local function IsSecret(v)
    return issecretvalue and issecretvalue(v)
end

local function SafeNum(v)
    if v == nil or IsSecret(v) then return nil end
    if type(v) ~= "number" then return nil end
    return v
end

local function ListSize()
    if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListSize) then return 0 end
    local ok, n = pcall(C_CurrencyInfo.GetCurrencyListSize)
    if ok then return SafeNum(n) or 0 end
    return 0
end

local function ListInfo(index)
    if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListInfo) then return nil end
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyListInfo, index)
    if ok and type(info) == "table" then return info end
    return nil
end

-- L'API de liste n'expose pas l'ID : on l'extrait du lien "currency:<id>".
local function ListID(index)
    if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListLink) then return nil end
    local ok, link = pcall(C_CurrencyInfo.GetCurrencyListLink, index)
    if ok and type(link) == "string" then
        return tonumber(link:match("currency:(%d+)"))
    end
    return nil
end

local function CurrencyInfoByID(id)
    if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then return nil end
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
    if ok and type(info) == "table" then return info end
    return nil
end

-- ============================================================
--  Store partage (metadonnees) sous _account.currency
-- ============================================================
--   _account.currency = {
--       info = { [currencyID] = { name, icon, quality, account } },
--       cats = { { name = "Midnight", ids = { id, id, ... } }, ... },
--   }

local function Meta()
    local acc = TS.account
    if not acc then return nil end
    if type(acc.currency) ~= "table" then acc.currency = {} end
    local st = acc.currency
    if type(st.info) ~= "table" then st.info = {} end
    if type(st.cats) ~= "table" then st.cats = {} end
    return st
end

-- ============================================================
--  Scan : deplie temporairement les categories repliees
-- ============================================================
-- Les monnaies d'une categorie repliee sont absentes de la liste : on deplie
-- tout, on lit, puis on restaure l'etat initial. Chaque (de)pliage decale les
-- index, donc on repart du debut apres chaque action (garde d'iterations).

local function CanExpand()
    return C_CurrencyInfo and type(C_CurrencyInfo.ExpandCurrencyList) == "function"
end

local function ExpandAll()
    local collapsed = {}
    if not CanExpand() then return collapsed end
    local guard = 0
    local again = true
    while again and guard < 60 do
        again = false
        guard = guard + 1
        local n = ListSize()
        for i = 1, n do
            local info = ListInfo(i)
            if info and info.isHeader and info.isHeaderExpanded == false then
                collapsed[info.name or ("#" .. i)] = true
                pcall(C_CurrencyInfo.ExpandCurrencyList, i, true)
                again = true
                break
            end
        end
    end
    return collapsed
end

local function RestoreCollapsed(collapsed)
    if not CanExpand() or not next(collapsed) then return end
    local guard = 0
    local again = true
    while again and guard < 60 do
        again = false
        guard = guard + 1
        local n = ListSize()
        for i = 1, n do
            local info = ListInfo(i)
            if info and info.isHeader and info.name and collapsed[info.name]
               and info.isHeaderExpanded ~= false then
                pcall(C_CurrencyInfo.ExpandCurrencyList, i, false)
                collapsed[info.name] = nil
                again = true
                break
            end
        end
    end
end

-- ============================================================
--  Scan public
-- ============================================================

function Currency:Scan(force)
    if scanning then return end
    if not TS.db or not TS.db.char then return end
    local st = Meta()
    if not st then return end

    local now = GetTime()
    if not force and (now - lastScan) < 3 then return end
    lastScan = now

    scanning = true

    -- Ne pas manipuler les categories pendant que le panneau du jeu est ouvert :
    -- l'utilisateur verrait ses sections s'ouvrir/se refermer.
    local panelOpen = (TokenFrame and TokenFrame.IsShown and TokenFrame:IsShown()) and true or false
    local collapsed = (not panelOpen) and ExpandAll() or {}

    local cats, data = {}, {}
    local curCat = nil
    local n = ListSize()

    for i = 1, n do
        local info = ListInfo(i)
        if info then
            if info.isHeader then
                local label = info.name
                if IsSecret(label) or type(label) ~= "string" then label = "?" end
                curCat = { name = label, ids = {} }
                cats[#cats + 1] = curCat
            else
                local id = ListID(i)
                if id and not IsSecret(id) then
                    local q = SafeNum(info.quantity) or 0
                    data[id] = q

                    local m = st.info[id]
                    if type(m) ~= "table" then m = {}; st.info[id] = m end
                    if type(info.name) == "string" and not IsSecret(info.name) then m.name = info.name end
                    local icon = SafeNum(info.iconFileID)
                    if icon then m.icon = icon end
                    local quality = SafeNum(info.quality)
                    if quality then m.quality = quality end
                    if info.isAccountWide ~= nil then
                        m.account = (info.isAccountWide == true) or nil
                    end

                    if curCat then curCat.ids[#curCat.ids + 1] = id end
                end
            end
        end
    end

    RestoreCollapsed(collapsed)

    -- Une liste vide (pas encore recue du serveur) ne doit pas effacer l'existant.
    if next(data) then
        TS.db.char.currency   = data
        TS.db.char.currencyAt = time()
        if #cats > 0 then st.cats = cats end
    end

    scanning = false

    local br = TS.modules["Browser"]
    if br and br.Refresh then br:Refresh() end
end

-- ============================================================
--  Agregation
-- ============================================================

-- Total d'une monnaie sur les personnages affiches. Les monnaies account-wide
-- (partagees) ne s'additionnent pas : on retient la plus grande valeur vue.
local function TotalFor(id, accountWide)
    local s = TS.db and TS.db.settings
    local onlyRealm = s and s.onlyRealm
    local sum, best = 0, 0
    TS:ForEachChar(function(realm, charName, entry)
        if onlyRealm and realm ~= TS.realm then return end
        local c = entry.currency and entry.currency[id]
        if type(c) == "number" then
            sum = sum + c
            if c > best then best = c end
        end
    end)
    if accountWide then return best end
    return sum
end

-- Lignes par personnage pour une monnaie donnee.
local function BuildDetailRows(id, accountWide)
    local out, grand = {}, 0
    local s = TS.db and TS.db.settings
    local onlyRealm = s and s.onlyRealm
    TS:ForEachChar(function(realm, charName, entry)
        if onlyRealm and realm ~= TS.realm then return end
        local c = entry.currency and entry.currency[id]
        if type(c) == "number" and c > 0 then
            out[#out + 1] = {
                name      = charName,
                realm     = realm,
                class     = entry.class,
                color     = TS:ClassColorTriple(entry.class),
                qty       = c,
                isCurrent = (charName == TS.charName and realm == TS.realm),
            }
            if not accountWide then grand = grand + c end
            if accountWide and c > grand then grand = c end
        end
    end)
    table.sort(out, function(a, b)
        if a.qty ~= b.qty then return a.qty > b.qty end
        return a.name < b.name
    end)
    return out, grand
end

-- Metadonnees d'affichage d'une monnaie (repli sur l'API si le cache est vide).
local function DisplayMeta(id)
    local st = Meta()
    local m  = st and st.info[id]
    local name    = m and m.name
    local icon    = m and m.icon
    local quality = m and m.quality
    local acct    = m and m.account
    if not name or not icon then
        local info = CurrencyInfoByID(id)
        if info then
            if not name and type(info.name) == "string" and not IsSecret(info.name) then name = info.name end
            if not icon then icon = SafeNum(info.iconFileID) end
            if not quality then quality = SafeNum(info.quality) end
            if acct == nil and info.isAccountWide ~= nil then acct = (info.isAccountWide == true) or nil end
        end
    end
    return name, icon, quality, acct
end

local function BuildDisplayList()
    wipe(displayList)
    curCount = 0

    local st = Meta()
    if not st then return end

    local s        = TS.db and TS.db.settings
    local hideZero = s and s.hideZeroCur
    local q        = (searchText or ""):lower()
    local searching = (q ~= "")

    -- Ensemble des monnaies connues : metadonnees + donnees des personnages
    local known = {}
    for id in pairs(st.info) do known[id] = true end
    TS:ForEachChar(function(realm, charName, entry)
        if s and s.onlyRealm and realm ~= TS.realm then return end
        if type(entry.currency) == "table" then
            for id in pairs(entry.currency) do known[id] = true end
        end
    end)

    local function MakeEntry(id)
        local name, icon, quality, acct = DisplayMeta(id)
        local total = TotalFor(id, acct)
        if hideZero and total <= 0 then return nil end
        if searching then
            local nm = (name or ""):lower()
            if not (nm:find(q, 1, true) or tostring(id):find(q, 1, true)) then return nil end
        end
        return {
            id      = id,
            name    = name or ("#" .. id),
            icon    = icon or DEFAULT_ICON,
            quality = quality,
            total   = total,
            account = acct,
        }
    end

    local seen = {}

    local function PushCategory(key, label, ids)
        local bucket = {}
        for _, id in ipairs(ids) do
            if known[id] and not seen[id] then
                local e = MakeEntry(id)
                seen[id] = true
                if e then bucket[#bucket + 1] = e end
            end
        end
        if #bucket == 0 then return end
        local expanded = searching or (expandState[key] ~= false)
        displayList[#displayList + 1] = {
            header = true, catKey = key, label = label,
            count = #bucket, expanded = expanded,
        }
        if expanded then
            for _, e in ipairs(bucket) do displayList[#displayList + 1] = e end
        end
        curCount = curCount + #bucket
    end

    for idx, cat in ipairs(st.cats) do
        if type(cat) == "table" and type(cat.ids) == "table" then
            PushCategory("cat" .. idx .. ":" .. (cat.name or ""), cat.name or "?", cat.ids)
        end
    end

    -- Monnaies connues hors categorie (anciennes donnees, autre client, etc.)
    local leftovers = {}
    for id in pairs(known) do
        if not seen[id] then leftovers[#leftovers + 1] = id end
    end
    if #leftovers > 0 then
        table.sort(leftovers)
        PushCategory("misc", TS:L("CAT_MISC"), leftovers)
    end
end

local function FirstCurrencyID()
    for _, d in ipairs(displayList) do
        if not d.header then return d.id end
    end
    return nil
end

function ToggleCategory(key)
    expandState[key] = (expandState[key] == false)
    BuildDisplayList()
    UpdateList()
end

-- ============================================================
--  Rendu : liste de gauche
-- ============================================================

local function Fmt(n)
    if BreakUpLargeNumbers then return BreakUpLargeNumbers(n or 0) end
    return tostring(n or 0)
end

function UpdateList()
    if not page then return end
    local n = #displayList
    FauxScrollFrame_Update(listScroll, n, NUM_ROWS, ROW_H)
    local offset = FauxScrollFrame_GetOffset(listScroll)

    for i = 1, NUM_ROWS do
        local row  = rows[i]
        local data = displayList[i + offset]
        if data then
            if data.header then
                row.rowType = "header"
                row.catKey  = data.catKey
                row.id      = nil
                row.headerBg:Show()
                row.icon:Hide()
                row.expand:Show()
                row.expand:SetTexture(data.expanded
                    and "Interface\\Buttons\\UI-MinusButton-Up"
                    or  "Interface\\Buttons\\UI-PlusButton-Up")
                row.sel:Hide(); row.selBar:Hide()
                row.name:SetText(data.label)
                local p = UI.PURPLE
                row.name:SetTextColor(p[1], p[2], p[3])
                row.count:SetText(tostring(data.count))
                row.count:SetTextColor(0.55, 0.55, 0.6)
            else
                row.rowType = "currency"
                row.id      = data.id
                row.catKey  = nil
                row.headerBg:Hide()
                row.expand:Hide()
                row.icon:Show()
                row.icon:SetTexture(data.icon)
                row.name:SetText(data.name)
                if data.quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[data.quality] then
                    local c = ITEM_QUALITY_COLORS[data.quality]
                    row.name:SetTextColor(c.r, c.g, c.b)
                else
                    row.name:SetTextColor(0.9, 0.9, 0.9)
                end
                row.count:SetText(Fmt(data.total))
                if (data.total or 0) > 0 then
                    row.count:SetTextColor(0.85, 0.85, 0.85)
                else
                    row.count:SetTextColor(0.45, 0.45, 0.48)
                end
                if data.id == selectedID then row.sel:Show(); row.selBar:Show()
                else row.sel:Hide(); row.selBar:Hide() end
            end
            row:Show()
        else
            row.rowType = nil
            row.id = nil
            row:Hide()
        end
    end

    local parent = page:GetParent()
    if parent and parent.countLabel then
        parent.countLabel:SetText(string.format(TS:L("CUR_TRACKED"), curCount))
    end
end

-- ============================================================
--  Rendu : detail de droite
-- ============================================================

function UpdateDetail()
    if not page then return end

    detail.icon:Hide()
    detail.name:SetText("")
    detail.subtitle:SetText("")
    detail.colHeader:Hide()
    detail.sep1:Hide()
    detail.sep2:Hide()
    for _, r in ipairs(detail.rows) do r:Hide() end
    detail.accountRow:Hide()
    detail.totalRow:Hide()
    detail.hint:Hide()

    if not selectedID then
        detail.hint:Show()
        return
    end

    local name, icon, quality, acct = DisplayMeta(selectedID)
    detail.icon:SetTexture(icon or DEFAULT_ICON)
    detail.icon:Show()
    local hex = "|cFFFFFFFF"
    if quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] then
        hex = ITEM_QUALITY_COLORS[quality].hex or hex
    end
    detail.name:SetText(hex .. (name or ("#" .. selectedID)) .. "|r")

    -- Sous-titre : plafond eventuel (API, personnage courant)
    local sub = ""
    local info = CurrencyInfoByID(selectedID)
    if info then
        local maxQ = SafeNum(info.maxQuantity)
        if maxQ and maxQ > 0 then
            sub = TS:L("CUR_CAP") .. " " .. Fmt(maxQ)
        end
    end
    detail.subtitle:SetText(sub)
    detail.sep1:Show()
    detail.colHeader:Show()

    local out, grand = BuildDetailRows(selectedID, acct)

    local startY = -68
    local shown  = 0
    for _, e in ipairs(out) do
        if shown >= MAX_DETAIL then break end
        shown = shown + 1
        local r = detail.rows[shown]
        local label = e.name
        if e.realm ~= TS.realm then label = label .. "  |cFF888888[" .. e.realm .. "]|r" end
        r.name:SetText(label)
        r.name:SetTextColor(e.color[1], e.color[2], e.color[3])
        r.dot:SetVertexColor(e.color[1], e.color[2], e.color[3], 1)
        if e.isCurrent then r.hl:Show(); r.bar:Show() else r.hl:Hide(); r.bar:Hide() end
        r.value:SetText(Fmt(e.qty))
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", page, "TOPLEFT", DETAIL_X, startY - (shown - 1) * ROW_HD)
        r:Show()
    end

    local nextY = startY - shown * ROW_HD - 4

    -- Monnaie partagee au compte : rappel explicite (pas d'addition entre persos)
    if acct then
        local ar = detail.accountRow
        ar:ClearAllPoints()
        ar:SetPoint("TOPLEFT", page, "TOPLEFT", DETAIL_X, nextY)
        ar.value:SetText(Fmt(grand))
        ar:Show()
        nextY = nextY - ROW_HD - 2
    end

    detail.sep2:ClearAllPoints()
    detail.sep2:SetPoint("TOPLEFT", page, "TOPLEFT", DETAIL_X + 6, nextY)
    detail.sep2:SetPoint("RIGHT", page, "TOPRIGHT", -8, 0)
    detail.sep2:Show()

    local tr = detail.totalRow
    tr:ClearAllPoints()
    tr:SetPoint("TOPLEFT", page, "TOPLEFT", DETAIL_X, nextY - 8)
    tr.value:SetText(Fmt(grand))
    tr:Show()
end

function SelectCurrency(id)
    selectedID = id
    UpdateDetail()
    UpdateList()
end

-- ============================================================
--  Construction de la page (parent = fenetre du Browser)
-- ============================================================

function Currency:BuildPage(parent)
    if page then return page end

    page = CreateFrame("Frame", nil, parent)
    page:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -54)
    page:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 58)
    page:Hide()

    -- ----- Liste (gauche) -----
    listScroll = CreateFrame("ScrollFrame", "TomoSyncCurrencyScroll", page, "FauxScrollFrameTemplate")
    listScroll:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -4)
    listScroll:SetSize(LIST_W, NUM_ROWS * ROW_H)
    listScroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_H, UpdateList)
    end)
    UI.SkinScrollBar(listScroll.ScrollBar or _G["TomoSyncCurrencyScrollScrollBar"])

    local function Wheel(delta)
        local sb = listScroll.ScrollBar or _G["TomoSyncCurrencyScrollScrollBar"]
        if sb then sb:SetValue(sb:GetValue() - delta * ROW_H * 2) end
    end
    listScroll:EnableMouseWheel(true)
    listScroll:SetScript("OnMouseWheel", function(_, d) Wheel(d) end)

    for i = 1, NUM_ROWS do
        local row = CreateFrame("Button", nil, page)
        row:SetSize(LIST_W, ROW_H)
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function(_, d) Wheel(d) end)
        if i == 1 then
            row:SetPoint("TOPLEFT", listScroll, "TOPLEFT", 0, 0)
        else
            row:SetPoint("TOPLEFT", rows[i - 1], "BOTTOMLEFT", 0, 0)
        end

        local headerBg = UI.Solid(row, "BACKGROUND")
        headerBg:SetAllPoints()
        local hb = UI.ROW_HL
        headerBg:SetVertexColor(hb[1], hb[2], hb[3], 0.14)
        headerBg:Hide()
        row.headerBg = headerBg

        local sel = UI.Solid(row, "BACKGROUND")
        sel:SetAllPoints()
        local hl = UI.ROW_HL
        sel:SetVertexColor(hl[1], hl[2], hl[3], hl[4])
        sel:Hide()
        row.sel = sel

        local selBar = UI.Solid(row, "ARTWORK")
        selBar:SetSize(3, ROW_H)
        selBar:SetPoint("LEFT", row, "LEFT", 0, 0)
        local pp = UI.PURPLE
        selBar:SetVertexColor(pp[1], pp[2], pp[3], 1)
        selBar:Hide()
        row.selBar = selBar

        local hover = UI.Solid(row, "BACKGROUND")
        hover:SetAllPoints()
        hover:SetVertexColor(1, 1, 1, 0.06)
        hover:Hide()

        local expand = row:CreateTexture(nil, "OVERLAY")
        expand:SetSize(16, 16)
        expand:SetPoint("LEFT", row, "LEFT", 5, 0)
        expand:Hide()
        row.expand = expand

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(18, 18)
        icon:SetPoint("LEFT", row, "LEFT", 8, 0)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        row.icon = icon

        local count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        count:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        count:SetWidth(56)
        count:SetJustifyH("RIGHT")
        row.count = count

        local nm = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nm:SetPoint("LEFT", row, "LEFT", 28, 0)
        nm:SetPoint("RIGHT", count, "LEFT", -4, 0)
        nm:SetJustifyH("LEFT")
        row.name = nm

        row:SetScript("OnEnter", function(self)
            hover:Show()
            if self.rowType == "currency" and self.id then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if GameTooltip.SetCurrencyByID then
                    pcall(GameTooltip.SetCurrencyByID, GameTooltip, self.id)
                    GameTooltip:Show()
                end
            end
        end)
        row:SetScript("OnLeave", function() hover:Hide(); GameTooltip:Hide() end)
        row:SetScript("OnClick", function(self)
            if self.rowType == "header" then
                ToggleCategory(self.catKey)
            elseif self.id then
                SelectCurrency(self.id)
            end
        end)

        rows[i] = row
    end

    -- Separateur vertical
    local vline = UI.Solid(page, "ARTWORK")
    vline:SetWidth(1)
    vline:SetPoint("TOPLEFT", page, "TOPLEFT", 238, -2)
    vline:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 238, 2)
    vline:SetVertexColor(0.25, 0.25, 0.30, 1)

    -- ----- Detail (droite) -----
    detail.rows = {}

    detail.icon = page:CreateTexture(nil, "ARTWORK")
    detail.icon:SetSize(30, 30)
    detail.icon:SetPoint("TOPLEFT", page, "TOPLEFT", DETAIL_X + 2, -4)
    detail.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    detail.name = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    detail.name:SetPoint("TOPLEFT", detail.icon, "TOPRIGHT", 10, -1)
    detail.name:SetPoint("RIGHT", page, "TOPRIGHT", -8, 0)
    detail.name:SetJustifyH("LEFT")

    detail.subtitle = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    detail.subtitle:SetPoint("TOPLEFT", detail.name, "BOTTOMLEFT", 0, -3)
    detail.subtitle:SetPoint("RIGHT", page, "TOPRIGHT", -8, 0)
    detail.subtitle:SetJustifyH("LEFT")

    detail.sep1 = UI.CreateSeparator(page, UI.PURPLE, 0.25)
    detail.sep1:SetPoint("TOPLEFT", page, "TOPLEFT", DETAIL_X, -44)
    detail.sep1:SetPoint("RIGHT", page, "TOPRIGHT", -8, 0)

    detail.colHeader = CreateFrame("Frame", nil, page)
    detail.colHeader:SetSize(DETAIL_W, 16)
    detail.colHeader:SetPoint("TOPLEFT", page, "TOPLEFT", DETAIL_X, -48)
    do
        local ch = detail.colHeader
        local cName = ch:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        cName:SetPoint("LEFT", ch, "LEFT", 8, 0)
        cName:SetText(TS:L("COL_CHARACTER"))
        local cQty = ch:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        cQty:SetPoint("RIGHT", ch, "RIGHT", -12, 0)
        cQty:SetText(TS:L("CUR_QUANTITY"))
    end

    for i = 1, MAX_DETAIL do
        local r = CreateFrame("Frame", nil, page)
        r:SetSize(DETAIL_W, ROW_HD)

        local hl = UI.Solid(r, "BACKGROUND")
        hl:SetAllPoints()
        local rh = UI.ROW_HL
        hl:SetVertexColor(rh[1], rh[2], rh[3], 0.10)
        hl:Hide()
        r.hl = hl

        local bar = UI.Solid(r, "BACKGROUND")
        bar:SetSize(3, ROW_HD)
        bar:SetPoint("LEFT", r, "LEFT", 0, 0)
        local p = UI.PURPLE
        bar:SetVertexColor(p[1], p[2], p[3], 1)
        bar:Hide()
        r.bar = bar

        local dot = UI.CreateDiamond(r, 7, { 1, 1, 1 })
        dot:SetPoint("LEFT", r, "LEFT", 12, 0)
        r.dot = dot

        local val = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        val:SetPoint("RIGHT", r, "RIGHT", -12, 0)
        val:SetWidth(90)
        val:SetJustifyH("RIGHT")
        r.value = val

        local nm = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nm:SetPoint("LEFT", dot, "RIGHT", 7, 0)
        nm:SetPoint("RIGHT", val, "LEFT", -6, 0)
        nm:SetJustifyH("LEFT")
        r.name = nm

        r:Hide()
        detail.rows[i] = r
    end

    -- Ligne "compte" (monnaie partagee entre tous les personnages)
    detail.accountRow = CreateFrame("Frame", nil, page)
    detail.accountRow:SetSize(DETAIL_W, ROW_HD)
    do
        local ar = detail.accountRow
        local cy = UI.CYAN
        local dot = UI.CreateDiamond(ar, 9, UI.CYAN)
        dot:SetPoint("LEFT", ar, "LEFT", 12, 0)
        local lbl = ar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("LEFT", dot, "RIGHT", 7, 0)
        lbl:SetText(TS:L("CUR_ACCOUNT"))
        lbl:SetTextColor(cy[1], cy[2], cy[3])
        local pillTxt = ar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        pillTxt:SetText(TS:L("SHARED"))
        pillTxt:SetTextColor(cy[1], cy[2], cy[3])
        pillTxt:SetPoint("LEFT", lbl, "RIGHT", 10, 0)
        local pill = UI.Solid(ar, "ARTWORK")
        pill:SetVertexColor(cy[1], cy[2], cy[3], 0.16)
        pill:SetPoint("LEFT", pillTxt, "LEFT", -7, 0)
        pill:SetPoint("RIGHT", pillTxt, "RIGHT", 7, 0)
        pill:SetHeight(15)
        local val = ar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        val:SetPoint("RIGHT", ar, "RIGHT", -12, 0)
        val:SetWidth(90)
        val:SetJustifyH("RIGHT")
        val:SetTextColor(cy[1], cy[2], cy[3])
        ar.value = val
        ar:Hide()
    end

    detail.sep2 = UI.CreateSeparator(page, UI.PURPLE, 0.45)
    detail.sep2:SetHeight(1)
    detail.sep2:Hide()

    detail.totalRow = CreateFrame("Frame", nil, page)
    detail.totalRow:SetSize(DETAIL_W, ROW_HD)
    do
        local tr = detail.totalRow
        local p = UI.PURPLE
        local lbl = tr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("LEFT", tr, "LEFT", 8, 0)
        lbl:SetText(TS:L("TOTAL"))
        lbl:SetTextColor(p[1], p[2], p[3])
        local val = tr:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        val:SetPoint("RIGHT", tr, "RIGHT", -12, 0)
        val:SetWidth(110)
        val:SetJustifyH("RIGHT")
        val:SetTextColor(p[1], p[2], p[3])
        tr.value = val
        tr:Hide()
    end

    detail.hint = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    detail.hint:SetPoint("CENTER", page, "TOPLEFT", DETAIL_X + DETAIL_W / 2, -180)
    detail.hint:SetWidth(320)
    detail.hint:SetText(TS:L("CUR_HINT"))

    return page
end

-- ============================================================
--  API publique (utilisee par le Browser)
-- ============================================================

function Currency:ShowPage()
    if not page then return end
    page:Show()
    BuildDisplayList()
    if not selectedID then selectedID = FirstCurrencyID() end
    local sb = _G["TomoSyncCurrencyScrollScrollBar"]
    if sb then sb:SetValue(0) end
    UpdateList()
    UpdateDetail()
end

function Currency:HidePage()
    if page then page:Hide() end
end

function Currency:SetSearch(text)
    searchText = text or ""
    if not page or not page:IsShown() then return end
    BuildDisplayList()
    local sb = _G["TomoSyncCurrencyScrollScrollBar"]
    if sb then sb:SetValue(0) end
    selectedID = FirstCurrencyID()
    UpdateList()
    UpdateDetail()
end

function Currency:Refresh()
    if not page or not page:IsShown() then return end
    BuildDisplayList()
    local ok = false
    for _, d in ipairs(displayList) do
        if not d.header and d.id == selectedID then ok = true break end
    end
    if not ok then selectedID = FirstCurrencyID() end
    UpdateList()
    UpdateDetail()
end

-- ============================================================
--  Tooltip de monnaie : "qui possede combien"
-- ============================================================

local function AddTooltipLines(tt, id)
    if not TS.db or not TS.db.settings then return end
    local st = Meta()
    if not st then return end

    local _, _, _, acct = DisplayMeta(id)
    local out, grand = BuildDetailRows(id, acct)
    if #out == 0 then return end

    local s = TS.db.settings
    local G, P, CY = TS.COLOR_GRAY, TS.COLOR_HEX, TS.COLOR_CYAN

    tt:AddLine(" ")
    if acct then
        tt:AddDoubleLine(CY .. TS:L("CUR_ACCOUNT") .. "|r " .. G .. "(" .. TS:L("SHARED") .. ")|r",
            CY .. Fmt(grand) .. "|r", 1, 1, 1, 1, 1, 1)
    else
        local shown = 0
        for _, e in ipairs(out) do
            if shown >= 12 then break end
            shown = shown + 1
            local left = TS:ClassColor(e.class) .. e.name .. "|r"
            if e.realm ~= TS.realm then left = left .. G .. " [" .. e.realm .. "]|r" end
            tt:AddDoubleLine(left, P .. Fmt(e.qty) .. "|r", 1, 1, 1, 1, 1, 1)
        end
        if s.showTotal and grand > 0 then
            tt:AddDoubleLine(P .. TS:L("TOTAL") .. ":|r", P .. Fmt(grand) .. "|r", 1, 1, 1, 1, 1, 1)
        end
    end
    tt:Show()
end

-- ============================================================
--  Evenements
-- ============================================================

function Currency:OnInitialize()
    evtFrame = CreateFrame("Frame", "TomoSyncCurrencyFrame")
    evtFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    evtFrame:SetScript("OnEvent", function(self)
        if scanning then return end
        if self._t then return end
        self._t = C_Timer.NewTimer(1.0, function()
            self._t = nil
            Currency:Scan()
        end)
    end)

    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
       and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Currency then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Currency, function(tt, data)
            if not TS.db then return end
            local id = data and data.id
            if not id or IsSecret(id) or id == 0 then return end
            AddTooltipLines(tt, id)
        end)
    end
end

function Currency:OnEnteringWorld()
    C_Timer.After(3.0, function() Currency:Scan(true) end)
end

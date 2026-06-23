-- TomoSync | Modules/Browser.lua
-- Fenetre de recherche / inventaire : "qui possede quoi et ou".
-- Liste d'objets filtrable a gauche, detail par personnage + Warband a droite.

local TS = TomoSync
local UI = TS.UI
local Browser = {}
TS:RegisterModule("Browser", Browser)

local NUM_ROWS, ROW_H = 14, 24      -- liste de gauche
local ROW_HD          = 22          -- lignes du detail
local MAX_DETAIL      = 12          -- persos affiches max dans le detail
local DEFAULT_ICON    = 134400      -- INV_Misc_QuestionMark
local GOLD_VISIBLE, GOLD_ROW_H = 9, 26   -- liste d'or

local frame, scrollFrame, evtFrame
local itemRows  = {}
local detail    = {}
local itemList  = {}
local displayList = {}      -- liste a plat : en-tetes de categorie + objets (accordeon)
local itemCount = 0
local searchText = ""
local selectedID = nil

-- Onglets / vue Or
local currentView = "items"        -- "items" | "gold"
local tabItems, tabGold
local goldPage, goldScroll
local goldRows = {}
local goldList = {}
local goldWB, goldTotal            -- lignes fixes (Warband + Total)

-- Forward declarations
local UpdateList, UpdateDetail, SelectItem, UpdateGold, SwitchView, HideItemsView, ToggleCategory

-- ============================================================
--  Categories (accordeon)
-- ============================================================
-- classID = Enum.ItemClass : 0 Consommable, 1 Conteneur, 2 Arme, 3 Gemme,
-- 4 Armure, 5 Reactif, 7 Artisanat, 8 Amelioration, 9 Recette, 12 Quete, ...

local CATEGORIES = {
    { id = "consumable", key = "CAT_CONSUMABLE", classes = { [0] = true } },
    { id = "components", key = "CAT_COMPONENTS", classes = { [7] = true, [5] = true, [3] = true, [8] = true } },
    { id = "equipment",  key = "CAT_EQUIPMENT",  classes = { [2] = true, [4] = true } },
    { id = "container",  key = "CAT_CONTAINER",  classes = { [1] = true } },
    { id = "recipe",     key = "CAT_RECIPE",     classes = { [9] = true } },
    { id = "quest",      key = "CAT_QUEST",      classes = { [12] = true } },
    { id = "misc",       key = "CAT_MISC",       classes = {} },   -- fourre-tout
}

local expandState = {}   -- [catId] = false si replie (deplie par defaut)

local function CategoryFor(classID)
    if classID ~= nil then
        for _, cat in ipairs(CATEGORIES) do
            if cat.classes[classID] then return cat.id end
        end
    end
    return "misc"
end

-- ============================================================
--  Agregation + liste d'affichage (accordeon par categorie)
-- ============================================================

local function BuildItemList()
    wipe(itemList)
    wipe(displayList)
    local s = TS.db and TS.db.settings
    local onlyRealm = s and s.onlyRealm
    local seen = {}   -- itemID -> total

    TS:ForEachChar(function(realm, charName, entry)
        if onlyRealm and realm ~= TS.realm then return end
        for id, d in pairs(entry.items) do
            if type(d) == "table" then
                local t = (d.bags or 0) + (d.bank or 0) + (d.equip or 0)
                if t > 0 then seen[id] = (seen[id] or 0) + t end
            end
        end
    end)

    if s and s.showWarband and TS.account and TS.account.warband then
        for id, c in pairs(TS.account.warband.items) do
            if c and c > 0 then seen[id] = (seen[id] or 0) + c end
        end
    end

    -- Regroupe par categorie
    local buckets = {}
    for _, cat in ipairs(CATEGORIES) do buckets[cat.id] = {} end

    local q = (searchText or ""):lower()
    local count = 0
    for id, total in pairs(seen) do
        local name = TS:GetItemName(id)
        if not name then TS:RequestItem(id) end
        local match = true
        if q ~= "" then
            local nm = (name or ""):lower()
            match = (nm:find(q, 1, true) ~= nil) or (tostring(id):find(q, 1, true) ~= nil)
        end
        if match then
            local icon, classID = TS:GetItemInstant(id)
            local catId = CategoryFor(classID)
            local entry = {
                id      = id,
                name    = name or ("#" .. id),
                icon    = icon or DEFAULT_ICON,
                quality = TS:GetItemQuality(id),
                total   = total,
                named   = (name ~= nil),
            }
            local b = buckets[catId]
            b[#b + 1] = entry
            itemList[#itemList + 1] = entry
            count = count + 1
        end
    end
    itemCount = count

    local function sortBucket(b)
        table.sort(b, function(a, c)
            if a.named ~= c.named then return a.named end
            if a.name ~= c.name then return a.name < c.name end
            return a.id < c.id
        end)
    end

    -- En-tete de categorie, puis ses objets si la categorie est depliee.
    -- Repliees par defaut (fenetre compacte) ; une recherche deplie tout.
    local searching = (q ~= "")
    for _, cat in ipairs(CATEGORIES) do
        local b = buckets[cat.id]
        if #b > 0 then
            sortBucket(b)
            local expanded = searching or (expandState[cat.id] == true)
            displayList[#displayList + 1] = {
                header = true, catId = cat.id, label = TS:L(cat.key),
                count = #b, expanded = expanded,
            }
            if expanded then
                for _, e in ipairs(b) do displayList[#displayList + 1] = e end
            end
        end
    end
end

function ToggleCategory(catId)
    expandState[catId] = not (expandState[catId] == true)
    BuildItemList()
    UpdateList()
end

-- Premier objet (en sautant les en-tetes) de la liste d'affichage
local function FirstItemId()
    for _, d in ipairs(displayList) do
        if not d.header then return d.id end
    end
    return nil
end

local function BuildDetail(itemID)
    local out, grand = {}, 0
    local s = TS.db.settings
    local onlyRealm = s.onlyRealm

    TS:ForEachChar(function(realm, charName, entry)
        if onlyRealm and realm ~= TS.realm then return end
        local d = entry.items[itemID]
        if not d then return end
        local bags  = d.bags  or 0
        local bank  = (d.bank or 0) + (d.equip or 0)   -- equipe replie dans "banque"
        local total = bags + bank
        if total > 0 then
            out[#out + 1] = {
                name      = charName,
                realm     = realm,
                color     = TS:ClassColorTriple(entry.class),
                bags      = bags,
                bank      = bank,
                total     = total,
                isCurrent = (charName == TS.charName and realm == TS.realm),
            }
            grand = grand + total
        end
    end)

    table.sort(out, function(a, b)
        if a.total ~= b.total then return a.total > b.total end
        return a.name < b.name
    end)

    local warband = (s.showWarband and TS:GetWarbandCount(itemID)) or 0
    grand = grand + warband
    return out, warband, grand
end

-- ============================================================
--  Mise a jour de la liste (FauxScrollFrame)
-- ============================================================

function UpdateList()
    local n = #displayList
    FauxScrollFrame_Update(scrollFrame, n, NUM_ROWS, ROW_H)
    local offset = FauxScrollFrame_GetOffset(scrollFrame)

    for i = 1, NUM_ROWS do
        local row  = itemRows[i]
        local data = displayList[i + offset]
        if data then
            if data.header then
                -- En-tete de categorie
                row.rowType = "header"
                row.catId = data.catId
                row.id = nil
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
                -- Ligne d'objet
                row.rowType = "item"
                row.id = data.id
                row.catId = nil
                row.headerBg:Hide()
                row.expand:Hide()
                row.icon:Show()
                row.icon:SetTexture(data.icon)
                row.name:SetText(data.name)
                local hex
                if data.quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[data.quality] then
                    local c = ITEM_QUALITY_COLORS[data.quality]
                    row.name:SetTextColor(c.r, c.g, c.b)
                else
                    row.name:SetTextColor(0.9, 0.9, 0.9)
                end
                row.count:SetText(BreakUpLargeNumbers and BreakUpLargeNumbers(data.total) or tostring(data.total))
                row.count:SetTextColor(0.85, 0.85, 0.85)
                if data.id == selectedID then row.sel:Show(); row.selBar:Show() else row.sel:Hide(); row.selBar:Hide() end
            end
            row:Show()
        else
            row.rowType = nil
            row.id = nil
            row:Hide()
        end
    end

    if frame.countLabel then
        frame.countLabel:SetText(string.format(TS:L("ITEMS_TRACKED"), itemCount))
    end
end

-- ============================================================
--  Mise a jour du detail
-- ============================================================

function UpdateDetail()
    -- Reset
    detail.icon:Hide()
    detail.name:SetText("")
    detail.subtitle:SetText("")
    detail.colHeader:Hide()
    detail.sep1:Hide()
    detail.sep2:Hide()
    for _, r in ipairs(detail.rows) do r:Hide() end
    detail.warbandRow:Hide()
    detail.totalRow:Hide()
    detail.hint:Hide()

    if not selectedID then
        detail.hint:Show()
        return
    end

    -- En-tete objet
    detail.icon:SetTexture(TS:GetItemIcon(selectedID) or DEFAULT_ICON)
    detail.icon:Show()
    local name = TS:GetItemName(selectedID) or ("#" .. selectedID)
    local quality = TS:GetItemQuality(selectedID)
    local hex = "|cFFFFFFFF"
    if quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] then
        hex = ITEM_QUALITY_COLORS[quality].hex or hex
    end
    detail.name:SetText(hex .. name .. "|r")
    local typeText = TS:GetItemTypeText(selectedID)
    detail.subtitle:SetText(typeText or "")
    detail.sep1:Show()
    detail.colHeader:Show()

    local out, warband, grand = BuildDetail(selectedID)

    -- Lignes par personnage
    local startY = -116
    local shown = 0
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
        r.bags:SetText(e.bags > 0 and tostring(e.bags) or "|cFF555555-|r")
        r.bank:SetText(e.bank > 0 and tostring(e.bank) or "|cFF555555-|r")
        r.total:SetText(tostring(e.total))
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", frame, "TOPLEFT", 262, startY - (shown - 1) * ROW_HD)
        r:Show()
    end

    local nextY = startY - shown * ROW_HD - 4

    -- Ligne Warband (partagee)
    if warband > 0 then
        local wr = detail.warbandRow
        wr:ClearAllPoints()
        wr:SetPoint("TOPLEFT", frame, "TOPLEFT", 262, nextY)
        wr.value:SetText(tostring(warband))
        wr:Show()
        nextY = nextY - ROW_HD - 2
    end

    -- Separateur + Total
    detail.sep2:ClearAllPoints()
    detail.sep2:SetPoint("TOPLEFT", frame, "TOPLEFT", 268, nextY)
    detail.sep2:SetPoint("RIGHT", frame, "TOPRIGHT", -18, 0)
    detail.sep2:Show()

    local tr = detail.totalRow
    tr:ClearAllPoints()
    tr:SetPoint("TOPLEFT", frame, "TOPLEFT", 262, nextY - 8)
    tr.value:SetText(BreakUpLargeNumbers and BreakUpLargeNumbers(grand) or tostring(grand))
    tr:Show()
end

function SelectItem(id)
    selectedID = id
    UpdateDetail()
    UpdateList()
end

-- ============================================================
--  Vue Or : "qui a combien de PO" + coffre Warband
-- ============================================================

local function CoinText(copper)
    if GetCoinTextureString then return GetCoinTextureString(copper or 0) end
    return tostring(math.floor((copper or 0) / 10000)) .. "g"
end

local function BuildGold()
    wipe(goldList)
    local s = TS.db and TS.db.settings
    local onlyRealm = s and s.onlyRealm
    local grand = 0
    TS:ForEachChar(function(realm, charName, entry)
        if onlyRealm and realm ~= TS.realm then return end
        local m = entry.money or 0
        goldList[#goldList + 1] = {
            name = charName, realm = realm,
            color = TS:ClassColorTriple(entry.class),
            money = m,
            isCurrent = (charName == TS.charName and realm == TS.realm),
        }
        grand = grand + m
    end)
    table.sort(goldList, function(a, b)
        if a.money ~= b.money then return a.money > b.money end
        return a.name < b.name
    end)
    local wb = (TS.account and TS.account.warband and TS.account.warband.money) or 0
    return wb, grand + wb
end

function UpdateGold()
    local wb, grand = BuildGold()

    local n = #goldList
    FauxScrollFrame_Update(goldScroll, n, GOLD_VISIBLE, GOLD_ROW_H)
    local offset = FauxScrollFrame_GetOffset(goldScroll)
    for i = 1, GOLD_VISIBLE do
        local row = goldRows[i]
        local d = goldList[i + offset]
        if d then
            local label = d.name
            if d.realm ~= TS.realm then label = label .. "  |cFF888888[" .. d.realm .. "]|r" end
            row.name:SetText(label)
            row.name:SetTextColor(d.color[1], d.color[2], d.color[3])
            row.dot:SetVertexColor(d.color[1], d.color[2], d.color[3], 1)
            row.value:SetText(CoinText(d.money))
            if d.isCurrent then row.hl:Show(); row.bar:Show() else row.hl:Hide(); row.bar:Hide() end
            row:Show()
        else
            row:Hide()
        end
    end

    -- Ligne Warband (partagee)
    goldWB.value:SetText(CoinText(wb))
    -- Ligne Total
    goldTotal.value:SetText(CoinText(grand))
end

-- ============================================================
--  Bascule de vue (onglets)
-- ============================================================

function HideItemsView()
    if frame.search then frame.search:Hide() end
    if scrollFrame then scrollFrame:Hide() end
    local sb = _G["TomoSyncBrowserScrollScrollBar"]; if sb then sb:Hide() end
    if frame.vline then frame.vline:Hide() end
    for _, r in ipairs(itemRows) do r:Hide() end
    detail.icon:Hide(); detail.name:SetText(""); detail.subtitle:SetText("")
    detail.colHeader:Hide(); detail.sep1:Hide(); detail.sep2:Hide()
    for _, r in ipairs(detail.rows) do r:Hide() end
    detail.warbandRow:Hide(); detail.totalRow:Hide(); detail.hint:Hide()
    if frame.countLabel then frame.countLabel:Hide() end
end

local function SetTabVisual(tab, active)
    tab.active = active
    if active then
        local p = UI.PURPLE
        tab.Text:SetTextColor(1, 1, 1)
        tab.underline:Show()
    else
        tab.Text:SetTextColor(0.6, 0.6, 0.65)
        tab.underline:Hide()
    end
end

function SwitchView(view)
    currentView = view
    SetTabVisual(tabItems, view == "items")
    SetTabVisual(tabGold,  view == "gold")
    if view == "gold" then
        HideItemsView()
        goldPage:Show()
        UpdateGold()
    else
        goldPage:Hide()
        if frame.search then frame.search:Show() end
        if scrollFrame then scrollFrame:Show() end
        if frame.vline then frame.vline:Show() end
        if frame.countLabel then frame.countLabel:Show() end
        BuildItemList()
        if not selectedID then selectedID = FirstItemId() end
        UpdateList()
        UpdateDetail()
    end
end

-- ============================================================
--  Rafraichissement public (apres un scan)
-- ============================================================

function Browser:Refresh()
    if not frame or not frame:IsShown() then return end
    if currentView == "gold" then
        UpdateGold()
        return
    end
    BuildItemList()
    local stillThere = false
    for _, d in ipairs(itemList) do
        if d.id == selectedID then stillThere = true break end
    end
    if not stillThere then
        selectedID = FirstItemId()
    end
    UpdateList()
    UpdateDetail()
end

-- ============================================================
--  Construction de la fenetre
-- ============================================================

local function MakeColumnLabels(parentFrame, anchorFrame, isHeader)
    -- Cree name/bags/bank/total ancres a anchorFrame (row de 362 de large).
    local function fs(justify)
        local f = anchorFrame:CreateFontString(nil, "OVERLAY",
            isHeader and "GameFontDisableSmall" or "GameFontHighlightSmall")
        f:SetJustifyH(justify)
        return f
    end
    local total = fs("RIGHT"); total:SetWidth(40); total:SetPoint("RIGHT", anchorFrame, "RIGHT", -10, 0)
    local bank  = fs("RIGHT"); bank:SetWidth(40);  bank:SetPoint("RIGHT", anchorFrame, "RIGHT", -66, 0)
    local bags  = fs("RIGHT"); bags:SetWidth(40);  bags:SetPoint("RIGHT", anchorFrame, "RIGHT", -122, 0)
    local name  = fs("LEFT")
    name:SetPoint("LEFT", anchorFrame, "LEFT", 8, 0)
    name:SetPoint("RIGHT", bags, "LEFT", -6, 0)
    return name, bags, bank, total
end

local function Build()
    frame = CreateFrame("Frame", "TomoSyncBrowser", UIParent, "BackdropTemplate")
    frame:SetSize(640, 474)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    UI.StyleFlatFrame(frame)
    frame:Hide()

    -- En-tete
    UI.CreateHeaderBar(frame, 46)
    local diamond = UI.CreateDiamond(frame, 11)
    diamond:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -18)
    local logo = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    logo:SetPoint("LEFT", diamond, "RIGHT", 10, 0)
    logo:SetText("|cFFCC44FFTomo|r|cFFFFFFFFSync|r")

    -- Bouton fermer
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() frame:Hide() end)

    -- Champ de recherche
    local search = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
    search:SetSize(230, 24)
    search:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, -12)
    search:SetAutoFocus(false)
    search:SetFontObject(ChatFontNormal)
    search:SetTextInsets(8, 8, 0, 0)
    search:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    search:SetBackdropColor(0.05, 0.05, 0.07, 1)
    search:SetBackdropBorderColor(0.30, 0.30, 0.36, 1)

    local ph = search:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ph:SetPoint("LEFT", 10, 0)
    ph:SetText(TS:L("SEARCH_PLACEHOLDER"))

    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    search:SetScript("OnEditFocusGained", function() ph:Hide() end)
    search:SetScript("OnEditFocusLost", function(self) if self:GetText() == "" then ph:Show() end end)
    search:SetScript("OnTextChanged", function(self)
        if not scrollFrame then return end
        searchText = self:GetText() or ""
        BuildItemList()
        local sb = _G["TomoSyncBrowserScrollScrollBar"]
        if sb then sb:SetValue(0) end
        selectedID = itemList[1] and itemList[1].id or nil
        UpdateList()
        UpdateDetail()
    end)
    frame.search = search

    -- Liste defilante (gauche)
    scrollFrame = CreateFrame("ScrollFrame", "TomoSyncBrowserScroll", frame, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -58)
    scrollFrame:SetSize(222, NUM_ROWS * ROW_H)
    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_H, UpdateList)
    end)

    -- Skin moderne de la barre + molette de souris
    local scrollbar = scrollFrame.ScrollBar or _G["TomoSyncBrowserScrollScrollBar"]
    UI.SkinScrollBar(scrollbar)

    local function ScrollByWheel(delta)
        local sb = scrollFrame.ScrollBar or _G["TomoSyncBrowserScrollScrollBar"]
        if sb then sb:SetValue(sb:GetValue() - delta * ROW_H * 2) end
    end
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(_, delta) ScrollByWheel(delta) end)

    for i = 1, NUM_ROWS do
        local row = CreateFrame("Button", nil, frame)
        row:SetSize(222, ROW_H)
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function(_, delta) ScrollByWheel(delta) end)
        if i == 1 then
            row:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
        else
            row:SetPoint("TOPLEFT", itemRows[i - 1], "BOTTOMLEFT", 0, 0)
        end

        -- Fond d'en-tete de categorie
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

        -- Icone +/- pour les en-tetes de categorie
        local expand = row:CreateTexture(nil, "OVERLAY")
        expand:SetSize(16, 16)
        expand:SetPoint("LEFT", row, "LEFT", 5, 0)
        expand:Hide()
        row.expand = expand

        -- Icone d'objet
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(18, 18)
        icon:SetPoint("LEFT", row, "LEFT", 8, 0)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        row.icon = icon

        local count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        count:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        count:SetWidth(46)
        count:SetJustifyH("RIGHT")
        count:SetTextColor(0.85, 0.85, 0.85)
        row.count = count

        -- Nom : position fixe (vaut pour en-tete et objet)
        local nm = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nm:SetPoint("LEFT", row, "LEFT", 28, 0)
        nm:SetPoint("RIGHT", count, "LEFT", -4, 0)
        nm:SetJustifyH("LEFT")
        row.name = nm

        row:SetScript("OnEnter", function(self)
            hover:Show()
            if self.rowType == "item" and self.id then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetItemByID(self.id)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function() hover:Hide(); GameTooltip:Hide() end)
        row:SetScript("OnClick", function(self)
            if self.rowType == "header" then
                ToggleCategory(self.catId)
            elseif self.id then
                SelectItem(self.id)
            end
        end)

        itemRows[i] = row
    end

    -- Separateur vertical entre liste et detail
    local vline = UI.Solid(frame, "ARTWORK")
    vline:SetWidth(1)
    vline:SetPoint("TOPLEFT", frame, "TOPLEFT", 254, -54)
    vline:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 254, 52)
    vline:SetVertexColor(0.25, 0.25, 0.30, 1)
    frame.vline = vline

    -- ----- Detail (droite) -----
    detail.rows = {}

    detail.icon = frame:CreateTexture(nil, "ARTWORK")
    detail.icon:SetSize(32, 32)
    detail.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 264, -56)
    detail.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    detail.name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    detail.name:SetPoint("TOPLEFT", detail.icon, "TOPRIGHT", 10, -1)
    detail.name:SetPoint("RIGHT", frame, "TOPRIGHT", -18, 0)
    detail.name:SetJustifyH("LEFT")

    detail.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    detail.subtitle:SetPoint("TOPLEFT", detail.name, "BOTTOMLEFT", 0, -3)
    detail.subtitle:SetPoint("RIGHT", frame, "TOPRIGHT", -18, 0)
    detail.subtitle:SetJustifyH("LEFT")

    detail.sep1 = UI.CreateSeparator(frame, UI.PURPLE, 0.25)
    detail.sep1:SetPoint("TOPLEFT", frame, "TOPLEFT", 262, -94)
    detail.sep1:SetPoint("RIGHT", frame, "TOPRIGHT", -18, 0)

    -- En-tete de colonnes
    detail.colHeader = CreateFrame("Frame", nil, frame)
    detail.colHeader:SetSize(362, 16)
    detail.colHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 262, -98)
    local cName, cBags, cBank, cTotal = MakeColumnLabels(frame, detail.colHeader, true)
    cName:SetText(TS:L("COL_CHARACTER"))
    cBags:SetText(TS:L("BAGS"))
    cBank:SetText(TS:L("BANK"))
    cTotal:SetText(TS:L("TOTAL"))

    -- Pool de lignes de detail
    for i = 1, MAX_DETAIL do
        local r = CreateFrame("Frame", nil, frame)
        r:SetSize(362, ROW_HD)

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

        local nm, bags, bank, total = MakeColumnLabels(frame, r, false)
        nm:ClearAllPoints()
        nm:SetPoint("LEFT", dot, "RIGHT", 7, 0)
        nm:SetPoint("RIGHT", bags, "LEFT", -6, 0)
        nm:SetFontObject("GameFontNormal")
        r.name, r.bags, r.bank, r.total = nm, bags, bank, total
        r:Hide()
        detail.rows[i] = r
    end

    -- Ligne Warband (partagee)
    detail.warbandRow = CreateFrame("Frame", nil, frame)
    detail.warbandRow:SetSize(362, ROW_HD)
    do
        local wr = detail.warbandRow
        local cy = UI.CYAN
        local dot = UI.CreateDiamond(wr, 9, UI.CYAN)
        dot:SetPoint("LEFT", wr, "LEFT", 12, 0)
        local lbl = wr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("LEFT", dot, "RIGHT", 7, 0)
        lbl:SetText(TS:L("WARBAND"))
        lbl:SetTextColor(cy[1], cy[2], cy[3])
        -- pastille "partagé"
        local pillTxt = wr:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        pillTxt:SetText(TS:L("SHARED"))
        pillTxt:SetTextColor(cy[1], cy[2], cy[3])
        pillTxt:SetPoint("LEFT", lbl, "RIGHT", 10, 0)
        local pill = UI.Solid(wr, "ARTWORK")
        pill:SetVertexColor(cy[1], cy[2], cy[3], 0.16)
        pill:SetPoint("LEFT", pillTxt, "LEFT", -7, 0)
        pill:SetPoint("RIGHT", pillTxt, "RIGHT", 7, 0)
        pill:SetHeight(15)
        local val = wr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        val:SetPoint("RIGHT", wr, "RIGHT", -10, 0)
        val:SetWidth(40)
        val:SetJustifyH("RIGHT")
        val:SetTextColor(cy[1], cy[2], cy[3])
        wr.value = val
        wr:Hide()
    end

    detail.sep2 = UI.CreateSeparator(frame, UI.PURPLE, 0.45)
    detail.sep2:SetHeight(1)
    detail.sep2:Hide()

    -- Ligne Total
    detail.totalRow = CreateFrame("Frame", nil, frame)
    detail.totalRow:SetSize(362, 22)
    do
        local tr = detail.totalRow
        local p = UI.PURPLE
        local lbl = tr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("LEFT", tr, "LEFT", 8, 0)
        lbl:SetText(TS:L("TOTAL"))
        lbl:SetTextColor(p[1], p[2], p[3])
        local val = tr:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        val:SetPoint("RIGHT", tr, "RIGHT", -10, 0)
        val:SetWidth(60)
        val:SetJustifyH("RIGHT")
        val:SetTextColor(p[1], p[2], p[3])
        tr.value = val
        tr:Hide()
    end

    -- Texte d'invite (rien de selectionne)
    detail.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    detail.hint:SetPoint("CENTER", frame, "TOPLEFT", 262 + 181, -240)
    detail.hint:SetWidth(330)
    detail.hint:SetText(TS:L("BROWSER_HINT"))

    -- ============================================================
    --  Page Or (cachee par defaut)
    -- ============================================================
    goldPage = CreateFrame("Frame", nil, frame)
    goldPage:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -54)
    goldPage:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 58)
    goldPage:Hide()

    -- En-tete de colonnes
    local gh = goldPage:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    gh:SetPoint("TOPLEFT", goldPage, "TOPLEFT", 24, -4)
    gh:SetText(TS:L("COL_CHARACTER"))
    local ghv = goldPage:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ghv:SetPoint("TOPRIGHT", goldPage, "TOPRIGHT", -14, -4)
    ghv:SetText(TS:L("GOLD"))

    -- Liste defilante des persos
    goldScroll = CreateFrame("ScrollFrame", "TomoSyncGoldScroll", goldPage, "FauxScrollFrameTemplate")
    goldScroll:SetPoint("TOPLEFT", goldPage, "TOPLEFT", 4, -22)
    goldScroll:SetSize(600, GOLD_VISIBLE * GOLD_ROW_H)
    goldScroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, GOLD_ROW_H, UpdateGold)
    end)
    UI.SkinScrollBar(goldScroll.ScrollBar or _G["TomoSyncGoldScrollScrollBar"])
    local function GoldWheel(delta)
        local sb = goldScroll.ScrollBar or _G["TomoSyncGoldScrollScrollBar"]
        if sb then sb:SetValue(sb:GetValue() - delta * GOLD_ROW_H * 2) end
    end
    goldScroll:EnableMouseWheel(true)
    goldScroll:SetScript("OnMouseWheel", function(_, d) GoldWheel(d) end)

    for i = 1, GOLD_VISIBLE do
        local r = CreateFrame("Frame", nil, goldPage)
        r:SetSize(600, GOLD_ROW_H)
        r:EnableMouseWheel(true)
        r:SetScript("OnMouseWheel", function(_, d) GoldWheel(d) end)
        if i == 1 then
            r:SetPoint("TOPLEFT", goldScroll, "TOPLEFT", 0, 0)
        else
            r:SetPoint("TOPLEFT", goldRows[i - 1], "BOTTOMLEFT", 0, 0)
        end
        local hl = UI.Solid(r, "BACKGROUND"); hl:SetAllPoints()
        local rh = UI.ROW_HL; hl:SetVertexColor(rh[1], rh[2], rh[3], 0.10); hl:Hide(); r.hl = hl
        local bar = UI.Solid(r, "BACKGROUND"); bar:SetSize(3, GOLD_ROW_H); bar:SetPoint("LEFT", r, "LEFT", 0, 0)
        local pp = UI.PURPLE; bar:SetVertexColor(pp[1], pp[2], pp[3], 1); bar:Hide(); r.bar = bar
        local dot = UI.CreateDiamond(r, 8, { 1, 1, 1 }); dot:SetPoint("LEFT", r, "LEFT", 12, 0); r.dot = dot
        local val = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        val:SetPoint("RIGHT", r, "RIGHT", -12, 0); val:SetJustifyH("RIGHT"); r.value = val
        local nm = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nm:SetPoint("LEFT", dot, "RIGHT", 8, 0); nm:SetPoint("RIGHT", val, "LEFT", -8, 0); nm:SetJustifyH("LEFT"); r.name = nm
        r:Hide()
        goldRows[i] = r
    end

    -- Separateur + ligne Warband + Total
    local gsep = UI.CreateSeparator(goldPage, UI.PURPLE, 0.30)
    gsep:SetPoint("TOPLEFT", goldPage, "TOPLEFT", 8, -256)
    gsep:SetPoint("TOPRIGHT", goldPage, "TOPRIGHT", -8, -256)

    goldWB = CreateFrame("Frame", nil, goldPage)
    goldWB:SetSize(600, GOLD_ROW_H)
    goldWB:SetPoint("TOPLEFT", goldPage, "TOPLEFT", 4, -262)
    do
        local cy = UI.CYAN
        local wdot = UI.CreateDiamond(goldWB, 9, UI.CYAN); wdot:SetPoint("LEFT", goldWB, "LEFT", 12, 0)
        local wlbl = goldWB:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        wlbl:SetPoint("LEFT", wdot, "RIGHT", 8, 0); wlbl:SetText(TS:L("WARBAND")); wlbl:SetTextColor(cy[1], cy[2], cy[3])
        local wval = goldWB:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        wval:SetPoint("RIGHT", goldWB, "RIGHT", -12, 0); wval:SetJustifyH("RIGHT"); wval:SetTextColor(cy[1], cy[2], cy[3])
        goldWB.value = wval
    end

    goldTotal = CreateFrame("Frame", nil, goldPage)
    goldTotal:SetSize(600, GOLD_ROW_H)
    goldTotal:SetPoint("TOPLEFT", goldPage, "TOPLEFT", 4, -292)
    do
        local p = UI.PURPLE
        local tlbl = goldTotal:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tlbl:SetPoint("LEFT", goldTotal, "LEFT", 12, 0); tlbl:SetText(TS:L("TOTAL")); tlbl:SetTextColor(p[1], p[2], p[3])
        local tval = goldTotal:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        tval:SetPoint("RIGHT", goldTotal, "RIGHT", -12, 0); tval:SetJustifyH("RIGHT"); tval:SetTextColor(p[1], p[2], p[3])
        goldTotal.value = tval
    end

    -- ============================================================
    --  Pied de page : separateur + onglets + boutons
    -- ============================================================
    local footSep = UI.CreateSeparator(frame, { 0.2, 0.2, 0.24 }, 1)
    footSep:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 44)
    footSep:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 0)

    frame.countLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.countLabel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 48)

    -- Onglets
    local function MakeTab(label, onClick)
        local t = CreateFrame("Button", nil, frame)
        local fs = t:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("CENTER", 0, 1)
        fs:SetText(label)
        t.Text = fs
        local w = fs:GetStringWidth() or 40
        if w < 30 then w = 30 end
        t:SetSize(w + 22, 26)
        local ul = UI.Solid(t, "OVERLAY")
        ul:SetHeight(2)
        ul:SetPoint("BOTTOMLEFT", t, "BOTTOMLEFT", 4, 2)
        ul:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", -4, 2)
        local p = UI.PURPLE; ul:SetVertexColor(p[1], p[2], p[3], 1); ul:Hide()
        t.underline = ul
        t:SetScript("OnEnter", function() if not t.active then fs:SetTextColor(0.85, 0.85, 0.9) end end)
        t:SetScript("OnLeave", function() if not t.active then fs:SetTextColor(0.6, 0.6, 0.65) end end)
        t:SetScript("OnClick", onClick)
        return t
    end
    tabItems = MakeTab(TS:L("TAB_ITEMS"), function() SwitchView("items") end)
    tabItems:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 10)
    tabGold = MakeTab(TS:L("GOLD"), function() SwitchView("gold") end)
    tabGold:SetPoint("LEFT", tabItems, "RIGHT", 4, 0)

    -- Boutons
    local scanBtn = UI.CreateButton(frame, TS:L("BTN_SCAN"), 130, 24)
    scanBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -148, 11)
    scanBtn:SetScript("OnClick", function()
        local sc = TS.modules["Scanner"]
        if sc then
            sc:ScanBags(); sc:ScanEquipped(); sc:ScanMoney()
            if sc.atBank then sc:ScanBank(); sc:ScanWarband() end
            TS:Print(TS:L("SCAN_BAGS_DONE"))
            Browser:Refresh()
        end
    end)

    local cfgBtn = UI.CreateButton(frame, TS:L("BTN_SETTINGS"), 130, 24)
    cfgBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 11)
    cfgBtn:SetScript("OnClick", function()
        if TomoSyncConfig and TomoSyncConfig.Toggle then TomoSyncConfig:Toggle() end
    end)

    -- Resolution differee des noms d'objets
    evtFrame = CreateFrame("Frame")
    evtFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    evtFrame:SetScript("OnEvent", function()
        if not frame:IsShown() or currentView ~= "items" then return end
        if evtFrame._t then return end
        evtFrame._t = C_Timer.NewTimer(0.3, function()
            evtFrame._t = nil
            if frame:IsShown() and currentView == "items" then
                BuildItemList()
                UpdateList()
                UpdateDetail()
            end
        end)
    end)

    tinsert(UISpecialFrames, "TomoSyncBrowser")
end

-- ============================================================
--  API publique
-- ============================================================

function Browser:Toggle()
    if not frame then Build() end
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        local sb = _G["TomoSyncBrowserScrollScrollBar"]
        if sb then sb:SetValue(0) end
        selectedID = nil
        SwitchView(currentView)
    end
end

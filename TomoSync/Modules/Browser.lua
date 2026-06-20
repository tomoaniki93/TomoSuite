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

local frame, scrollFrame, evtFrame
local itemRows  = {}
local detail    = {}
local itemList  = {}
local searchText = ""
local selectedID = nil

-- Forward declarations
local UpdateList, UpdateDetail, SelectItem

-- ============================================================
--  Agregation des donnees
-- ============================================================

local function BuildItemList()
    wipe(itemList)
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

    local q = (searchText or ""):lower()
    for id, total in pairs(seen) do
        local name = TS:GetItemName(id)
        if not name then TS:RequestItem(id) end
        local match = true
        if q ~= "" then
            local nm = (name or ""):lower()
            match = (nm:find(q, 1, true) ~= nil) or (tostring(id):find(q, 1, true) ~= nil)
        end
        if match then
            itemList[#itemList + 1] = {
                id    = id,
                name  = name or ("#" .. id),
                icon  = TS:GetItemIcon(id) or DEFAULT_ICON,
                total = total,
                named = (name ~= nil),
            }
        end
    end

    table.sort(itemList, function(a, b)
        if a.named ~= b.named then return a.named end   -- objets nommes d'abord
        if a.name ~= b.name then return a.name < b.name end
        return a.id < b.id
    end)
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
                name  = charName,
                realm = realm,
                color = TS:ClassColorTriple(entry.class),
                bags  = bags,
                bank  = bank,
                total = total,
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
    local n = #itemList
    FauxScrollFrame_Update(scrollFrame, n, NUM_ROWS, ROW_H)
    local offset = FauxScrollFrame_GetOffset(scrollFrame)

    for i = 1, NUM_ROWS do
        local row  = itemRows[i]
        local data = itemList[i + offset]
        if data then
            row.id = data.id
            row.icon:SetTexture(data.icon)
            row.name:SetText(data.name)
            row.count:SetText(BreakUpLargeNumbers and BreakUpLargeNumbers(data.total) or tostring(data.total))
            if data.id == selectedID then row.sel:Show() else row.sel:Hide() end
            row:Show()
        else
            row.id = nil
            row:Hide()
        end
    end

    if frame.countLabel then
        frame.countLabel:SetText(string.format(TS:L("ITEMS_TRACKED"), n))
    end
end

-- ============================================================
--  Mise a jour du detail
-- ============================================================

function UpdateDetail()
    -- Reset
    detail.icon:Hide()
    detail.name:SetText("")
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
--  Rafraichissement public (apres un scan)
-- ============================================================

function Browser:Refresh()
    if not frame or not frame:IsShown() then return end
    BuildItemList()
    local stillThere = false
    for _, d in ipairs(itemList) do
        if d.id == selectedID then stillThere = true break end
    end
    if not stillThere then
        selectedID = itemList[1] and itemList[1].id or nil
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
    frame:SetSize(640, 448)
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

    for i = 1, NUM_ROWS do
        local row = CreateFrame("Button", nil, frame)
        row:SetSize(222, ROW_H)
        if i == 1 then
            row:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
        else
            row:SetPoint("TOPLEFT", itemRows[i - 1], "BOTTOMLEFT", 0, 0)
        end

        local sel = UI.Solid(row, "BACKGROUND")
        sel:SetAllPoints()
        local hl = UI.ROW_HL
        sel:SetVertexColor(hl[1], hl[2], hl[3], hl[4])
        sel:Hide()
        row.sel = sel

        local hover = UI.Solid(row, "BACKGROUND")
        hover:SetAllPoints()
        hover:SetVertexColor(1, 1, 1, 0.06)
        hover:Hide()

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(18, 18)
        icon:SetPoint("LEFT", row, "LEFT", 4, 0)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        row.icon = icon

        local count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        count:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        count:SetWidth(46)
        count:SetJustifyH("RIGHT")
        count:SetTextColor(0.85, 0.85, 0.85)
        row.count = count

        local nm = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nm:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        nm:SetPoint("RIGHT", count, "LEFT", -4, 0)
        nm:SetJustifyH("LEFT")
        row.name = nm

        row:SetScript("OnEnter", function(self)
            hover:Show()
            if self.id then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetItemByID(self.id)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function() hover:Hide(); GameTooltip:Hide() end)
        row:SetScript("OnClick", function(self) if self.id then SelectItem(self.id) end end)

        itemRows[i] = row
    end

    -- Separateur vertical entre liste et detail
    local vline = UI.Solid(frame, "ARTWORK")
    vline:SetWidth(1)
    vline:SetPoint("TOPLEFT", frame, "TOPLEFT", 254, -54)
    vline:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 254, 44)
    vline:SetVertexColor(0.25, 0.25, 0.30, 1)

    -- ----- Detail (droite) -----
    detail.icon = frame:CreateTexture(nil, "ARTWORK")
    detail.icon:SetSize(30, 30)
    detail.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 264, -56)
    detail.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    detail.name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    detail.name:SetPoint("LEFT", detail.icon, "RIGHT", 8, 0)
    detail.name:SetPoint("RIGHT", frame, "TOPRIGHT", -18, 0)
    detail.name:SetJustifyH("LEFT")
    detail.name:SetHeight(30)

    detail.sep1 = UI.CreateSeparator(frame, UI.PURPLE, 0.25)
    detail.sep1:SetPoint("TOPLEFT", frame, "TOPLEFT", 262, -92)
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
        local nm, bags, bank, total = MakeColumnLabels(frame, r, false)
        r.name, r.bags, r.bank, r.total = nm, bags, bank, total
        r.name:SetFontObject("GameFontNormal")
        r:Hide()
        detail.rows[i] = r
    end

    -- Ligne Warband (partagee)
    detail.warbandRow = CreateFrame("Frame", nil, frame)
    detail.warbandRow:SetSize(362, ROW_HD)
    do
        local wr = detail.warbandRow
        local dot = UI.CreateDiamond(wr, 9, UI.CYAN)
        dot:SetPoint("LEFT", wr, "LEFT", 10, 0)
        local lbl = wr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("LEFT", dot, "RIGHT", 8, 0)
        local cy = UI.CYAN
        lbl:SetText(TS:L("WARBAND") .. "  |cFF888888(" .. TS:L("SHARED") .. ")|r")
        lbl:SetTextColor(cy[1], cy[2], cy[3])
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

    -- ----- Pied de page -----
    local footSep = UI.CreateSeparator(frame, { 0.2, 0.2, 0.24 }, 1)
    footSep:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 40)
    footSep:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 0)

    frame.countLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.countLabel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 14)

    local scanBtn = UI.CreateButton(frame, TS:L("BTN_SCAN"), 130, 24)
    scanBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -148, 10)
    scanBtn:SetScript("OnClick", function()
        local sc = TS.modules["Scanner"]
        if sc then
            sc:ScanBags(); sc:ScanEquipped()
            if sc.atBank then sc:ScanBank(); sc:ScanWarband() end
            TS:Print(TS:L("SCAN_BAGS_DONE"))
            Browser:Refresh()
        end
    end)

    local cfgBtn = UI.CreateButton(frame, TS:L("BTN_SETTINGS"), 130, 24)
    cfgBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 10)
    cfgBtn:SetScript("OnClick", function()
        if TomoSyncConfig and TomoSyncConfig.Toggle then TomoSyncConfig:Toggle() end
    end)

    -- Resolution differee des noms d'objets
    evtFrame = CreateFrame("Frame")
    evtFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    evtFrame:SetScript("OnEvent", function()
        if not frame:IsShown() then return end
        if evtFrame._t then return end
        evtFrame._t = C_Timer.NewTimer(0.3, function()
            evtFrame._t = nil
            if frame:IsShown() then
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
        BuildItemList()
        selectedID = itemList[1] and itemList[1].id or nil
        local sb = _G["TomoSyncBrowserScrollScrollBar"]
        if sb then sb:SetValue(0) end
        UpdateList()
        UpdateDetail()
    end
end

-- TomoPorter | TomoPorter.lua
-- Addon standalone — téléporteurs donjon/raid + sorts Mage
-- Auteur : Tomo | Version 1.3.2
-- Thème : Cyan
--
-- /porter  ou  /tpt  → ouvre/ferme la fenêtre

TomoPorter = TomoPorter or {}

local L    = TomoPorter.L
local Data = TomoPorter.Data

-- =========================================================
-- PALETTE CYAN
-- =========================================================
local CYAN = {
    bgMain      = { 0.04, 0.07, 0.10, 0.97 },
    bgTitleBar  = { 0.02, 0.05, 0.09, 1    },
    bgBtn       = { 0.05, 0.12, 0.18, 0.88 },
    bgBtnHover  = { 0.08, 0.25, 0.35, 1    },
    bgBtnOff    = { 0.04, 0.07, 0.10, 0.50 },
    bgTabActive = { 0.03, 0.28, 0.38, 1    },
    bgTabIdle   = { 0.04, 0.10, 0.15, 1    },
    bgCatActive = { 0.05, 0.22, 0.34, 1    },
    bgCatIdle   = { 0.03, 0.08, 0.12, 1    },
    bgSep       = { 0.05, 0.22, 0.30, 1    },
    border      = { 0.10, 0.55, 0.70, 0.80 },
    borderDim   = { 0.07, 0.30, 0.40, 0.60 },
    textMain    = { 1.00, 1.00, 1.00, 1    },
    textHeader  = { 0.30, 0.90, 1.00, 1    },
    textDim     = { 0.35, 0.60, 0.65, 1    },
    textTitle   = { 0.30, 0.90, 1.00, 1    },
    textTabOn   = { 0.20, 1.00, 1.00, 1    },
    textTabOff  = { 0.55, 0.75, 0.80, 1    },
    textCatOn   = { 0.20, 1.00, 1.00, 1    },
    textCatOff  = { 0.45, 0.70, 0.80, 1    },
}

-- =========================================================
-- DIMENSIONS
-- =========================================================
local CFG = {
    frameW  = 580,
    frameH  = 490,
    colW    = 255,
    colGap  = 20,
    btnH    = 30,
    btnPad  = 3,
    iconSz  = 22,
    tabH    = 22,
    headerH = 20,
    catTabH = 26,   -- hauteur de la ligne d'onglets de catégorie (Téléporteurs / Mage)
    catTabW = 115,  -- largeur d'un onglet de catégorie
}

-- =========================================================
-- LISTE GLOBALE DES BOUTONS TP (pour le refresh)
-- =========================================================
TomoPorter.allButtons = {}

-- =========================================================
-- HELPERS API
-- =========================================================
local function HasTeleport(spellID)
    if not spellID then return false end
    if IsPlayerSpell then return IsPlayerSpell(spellID) end
    return false
end

local function GetSpellIcon(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, tex = pcall(C_Spell.GetSpellTexture, spellID)
        if ok and tex then return tex end
    end
    return nil
end

-- =========================================================
-- REFRESH D'UN BOUTON
-- =========================================================
local function RefreshButton(btn)
    local spellID = btn.tpSpellID
    local owned   = HasTeleport(spellID)
    btn.tpOwned   = owned

    if owned then
        btn:SetAttribute("type",  "spell")
        btn:SetAttribute("spell", spellID)
        btn.tpBg:SetVertexColor(unpack(CYAN.bgBtn))
        btn.tpIcon:SetDesaturated(false)
        btn.tpIcon:SetAlpha(1)
        btn.tpLabel:SetTextColor(unpack(CYAN.textMain))
    else
        btn:SetAttribute("type",  nil)
        btn:SetAttribute("spell", nil)
        btn.tpBg:SetVertexColor(unpack(CYAN.bgBtnOff))
        btn.tpIcon:SetDesaturated(true)
        btn.tpIcon:SetAlpha(0.35)
        if spellID then
            btn.tpLabel:SetTextColor(unpack(CYAN.textDim))
        else
            btn.tpLabel:SetTextColor(0.40, 0.40, 0.40, 1)
        end
    end
end

local function RefreshAllButtons()
    if InCombatLockdown() then return end
    for _, btn in ipairs(TomoPorter.allButtons) do
        if btn:IsVisible() or btn.tpSpellID then
            RefreshButton(btn)
        end
    end
end

-- =========================================================
-- HELPERS UI
-- =========================================================
local function SetBG(frame, r, g, b, a)
    local t = frame.bgTex or frame:CreateTexture(nil, "BACKGROUND")
    frame.bgTex = t
    t:SetAllPoints()
    t:SetTexture("Interface/Buttons/WHITE8X8")
    t:SetVertexColor(r, g, b, a)
end

-- =========================================================
-- CADRE PRINCIPAL
-- =========================================================
local function CreateMainFrame()
    local f = CreateFrame("Frame", "TomoPorterFrame", UIParent, "BackdropTemplate")
    f:SetSize(CFG.frameW, CFG.frameH)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    f:Hide()

    f:SetBackdrop({
        bgFile   = "Interface/Buttons/WHITE8X8",
        edgeFile = "Interface/Buttons/WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropColor(unpack(CYAN.bgMain))
    f:SetBackdropBorderColor(unpack(CYAN.border))

    -- Barre de titre
    local bar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    bar:SetPoint("TOPLEFT",  f, "TOPLEFT",   1, -1)
    bar:SetPoint("TOPRIGHT", f, "TOPRIGHT",  -1, -1)
    bar:SetHeight(26)
    bar:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8X8",
                      edgeFile = "Interface/Buttons/WHITE8X8", edgeSize = 1 })
    bar:SetBackdropColor(unpack(CYAN.bgTitleBar))
    bar:SetBackdropBorderColor(unpack(CYAN.borderDim))
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function() f:StartMoving() end)
    bar:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)

    -- Trait cyan sous la titlebar
    local underline = f:CreateTexture(nil, "ARTWORK")
    underline:SetHeight(1)
    underline:SetPoint("TOPLEFT",  bar, "BOTTOMLEFT",  0, 0)
    underline:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, 0)
    underline:SetTexture("Interface/Buttons/WHITE8X8")
    underline:SetVertexColor(unpack(CYAN.border))

    local ico = bar:CreateTexture(nil, "ARTWORK")
    ico:SetSize(18, 18)
    ico:SetPoint("LEFT", bar, "LEFT", 8, 0)
    ico:SetTexture(132161)

    local titleTxt = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleTxt:SetPoint("LEFT", ico, "RIGHT", 6, 0)
    titleTxt:SetText(L["TITLE"])
    titleTxt:SetTextColor(unpack(CYAN.textTitle))

    -- Bouton X
    local closeBtn = CreateFrame("Button", nil, bar)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("RIGHT", bar, "RIGHT", -6, 0)
    SetBG(closeBtn, 0.55, 0.05, 0.05, 0.8)
    local xTxt = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xTxt:SetAllPoints()
    xTxt:SetText("X")
    xTxt:SetTextColor(1, 0.6, 0.6, 1)
    closeBtn:SetScript("OnEnter", function() closeBtn.bgTex:SetVertexColor(0.85, 0.10, 0.10, 1) end)
    closeBtn:SetScript("OnLeave", function() closeBtn.bgTex:SetVertexColor(0.55, 0.05, 0.05, 0.8) end)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Séparateur vertical central
    -- (sera repositionné après la bande d'onglets de catégorie)
    local vsep = f:CreateTexture(nil, "BACKGROUND")
    vsep:SetWidth(1)
    vsep:SetPoint("TOP",    f, "TOP",    0, -(28 + CFG.catTabH + 1))
    vsep:SetPoint("BOTTOM", f, "BOTTOM", 0, 6)
    vsep:SetTexture("Interface/Buttons/WHITE8X8")
    vsep:SetVertexColor(unpack(CYAN.borderDim))
    f.vsep = vsep

    return f
end

-- =========================================================
-- BOUTON DE TÉLÉPORT
-- =========================================================
local function CreateTeleportButton(parent, entry, yOff)
    local spellID = entry.spellID

    local btn = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetSize(CFG.colW - 6, CFG.btnH)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 3, -yOff)

    btn.tpSpellID = spellID
    btn.tpOwned   = false

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface/Buttons/WHITE8X8")
    bg:SetVertexColor(unpack(CYAN.bgBtnOff))
    btn.tpBg = bg

    local bline = btn:CreateTexture(nil, "BORDER")
    bline:SetHeight(1)
    bline:SetPoint("BOTTOMLEFT",  btn, "BOTTOMLEFT",  0, 0)
    bline:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    bline:SetTexture("Interface/Buttons/WHITE8X8")
    bline:SetVertexColor(unpack(CYAN.borderDim))

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(CFG.iconSz, CFG.iconSz)
    icon:SetPoint("LEFT", btn, "LEFT", 4, 0)
    local tex = GetSpellIcon(spellID)
    if tex then
        icon:SetTexture(tex)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        icon:SetTexture("Interface/Icons/INV_Misc_QuestionMark")
    end
    icon:SetDesaturated(true)
    icon:SetAlpha(0.35)
    btn.tpIcon = icon

    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT",  icon, "RIGHT", 5, 0)
    lbl:SetPoint("RIGHT", btn,  "RIGHT", -4, 0)
    lbl:SetJustifyH("LEFT")
    lbl:SetText(entry.name)
    lbl:SetTextColor(unpack(CYAN.textDim))
    btn.tpLabel = lbl

    btn:SetScript("OnEnter", function(self)
        if self.tpOwned then
            self.tpBg:SetVertexColor(unpack(CYAN.bgBtnHover))
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if spellID then
            GameTooltip:SetSpellByID(spellID)
        else
            GameTooltip:AddLine(entry.name, 1, 1, 1)
            GameTooltip:AddLine("SpellID non disponible", 0.6, 0.3, 0.3)
        end
        if self.tpOwned then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["TOOLTIP_CLICK"], 0.5, 0.9, 1)
        else
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["TOOLTIP_UNKNOWN"], 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        if self.tpOwned then
            self.tpBg:SetVertexColor(unpack(CYAN.bgBtn))
        end
        GameTooltip:Hide()
    end)

    table.insert(TomoPorter.allButtons, btn)

    if not InCombatLockdown() then
        RefreshButton(btn)
    end

    return btn
end

-- =========================================================
-- ONGLET (Current / Legacy)
-- =========================================================
local function CreateTab(parent, label)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(86, CFG.tabH)
    btn:SetBackdrop({ bgFile   = "Interface/Buttons/WHITE8X8",
                      edgeFile = "Interface/Buttons/WHITE8X8", edgeSize = 1 })

    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetAllPoints()
    txt:SetText(label)

    function btn:SetActive(active)
        if active then
            self:SetBackdropColor(unpack(CYAN.bgTabActive))
            self:SetBackdropBorderColor(unpack(CYAN.border))
            txt:SetTextColor(unpack(CYAN.textTabOn))
        else
            self:SetBackdropColor(unpack(CYAN.bgTabIdle))
            self:SetBackdropBorderColor(unpack(CYAN.borderDim))
            txt:SetTextColor(unpack(CYAN.textTabOff))
        end
    end

    btn:SetActive(false)
    return btn
end

-- =========================================================
-- EN-TÊTE DE GROUPE (expansion / saison)
-- =========================================================
local function CreateGroupHeader(parent, label, yOff)
    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(CFG.colW - 6, CFG.headerH)
    bg:SetPoint("TOPLEFT", parent, "TOPLEFT", 3, -yOff)
    bg:SetTexture("Interface/Buttons/WHITE8X8")
    bg:SetVertexColor(unpack(CYAN.bgSep))

    local accent = parent:CreateTexture(nil, "ARTWORK")
    accent:SetSize(2, CFG.headerH)
    accent:SetPoint("TOPLEFT", bg, "TOPLEFT", 0, 0)
    accent:SetTexture("Interface/Buttons/WHITE8X8")
    accent:SetVertexColor(unpack(CYAN.textHeader))

    local hdr = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("TOPLEFT",     bg, "TOPLEFT",     6, 0)
    hdr:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -4, 0)
    hdr:SetJustifyH("LEFT")
    hdr:SetText(label)
    hdr:SetTextColor(unpack(CYAN.textHeader))

    return CFG.headerH
end

-- =========================================================
-- SCROLL FRAME — scrollbar custom (thème cyan)
-- =========================================================
-- Architecture :
--   • sf          = ScrollFrame pur (pas de template WoW)
--   • track       = fond de la scrollbar (rail fixe à droite du sf)
--   • thumb       = curseur draggable
--   • content     = ScrollChild dont la hauteur est mise à jour
--     par PopulateColumn/BuildMageColumn → UpdateScrollBar() recalcule
-- La scrollbar se cache automatiquement quand le contenu tient dans la vue.
-- =========================================================
local SB_W     = 5   -- largeur du rail + curseur
local SB_GAP   = 3   -- espace entre le contenu et le rail

local function CreateScrollFrame(parent, x, y, w)
    -- ── ScrollFrame pur ──────────────────────────────────
    local sf = CreateFrame("ScrollFrame", nil, parent)
    sf:SetPoint("TOPLEFT",    parent, "TOPLEFT",    x, y)
    sf:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", x, 6)
    -- La largeur utile du SF laisse de la place pour le rail à droite
    sf:SetWidth(w - SB_W - SB_GAP)

    -- ── Contenu scrollable ───────────────────────────────
    local content = CreateFrame("Frame", nil, sf)
    content:SetWidth(sf:GetWidth())
    content:SetHeight(1)
    sf:SetScrollChild(content)

    -- ── Rail (track) ─────────────────────────────────────
    local track = CreateFrame("Frame", nil, parent)
    track:SetWidth(SB_W)
    track:SetPoint("TOPLEFT",    sf, "TOPRIGHT",    SB_GAP, 0)
    track:SetPoint("BOTTOMLEFT", sf, "BOTTOMRIGHT", SB_GAP, 0)

    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    trackBg:SetTexture("Interface/Buttons/WHITE8X8")
    trackBg:SetVertexColor(0.05, 0.15, 0.20, 0.55)

    -- Bordure latérale gauche du rail
    local trackLine = track:CreateTexture(nil, "BORDER")
    trackLine:SetWidth(1)
    trackLine:SetPoint("TOPLEFT",    track, "TOPLEFT",    0, 0)
    trackLine:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT", 0, 0)
    trackLine:SetTexture("Interface/Buttons/WHITE8X8")
    trackLine:SetVertexColor(unpack(CYAN.borderDim))

    track:Hide()  -- masqué tant que le contenu tient dans la vue

    -- ── Curseur (thumb) ───────────────────────────────────
    local thumb = CreateFrame("Button", nil, track)
    thumb:SetWidth(SB_W)
    thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 0, 0)

    local thumbBg = thumb:CreateTexture(nil, "BACKGROUND")
    thumbBg:SetAllPoints()
    thumbBg:SetTexture("Interface/Buttons/WHITE8X8")
    thumbBg:SetVertexColor(unpack(CYAN.border))

    thumb:SetScript("OnEnter", function()
        thumbBg:SetVertexColor(unpack(CYAN.textHeader))
    end)
    thumb:SetScript("OnLeave", function()
        thumbBg:SetVertexColor(unpack(CYAN.border))
    end)

    -- ── Logique de scroll ─────────────────────────────────
    -- Recalcule la position et la taille du thumb
    local function UpdateThumb()
        local viewH    = sf:GetHeight()
        local totalH   = content:GetHeight()
        local trackH   = track:GetHeight()
        if totalH <= viewH or trackH <= 0 then
            track:Hide()
            return
        end
        track:Show()
        local ratio    = viewH / totalH
        local thumbH   = math.max(trackH * ratio, 16)
        thumb:SetHeight(thumbH)

        local scrollPct = sf:GetVerticalScroll() / (totalH - viewH)
        local maxY      = trackH - thumbH
        thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 0, -(scrollPct * maxY))
    end

    -- Scroll depuis la molette souris
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        local totalH  = content:GetHeight()
        local viewH   = self:GetHeight()
        local maxScroll = math.max(0, totalH - viewH)
        local cur     = self:GetVerticalScroll()
        local step    = CFG.btnH + CFG.btnPad
        local new     = math.min(math.max(cur - delta * step, 0), maxScroll)
        self:SetVerticalScroll(new)
        UpdateThumb()
    end)

    -- Clic sur le rail (scroll proportionnel)
    track:EnableMouse(true)
    track:SetScript("OnMouseDown", function(self, btn)
        if btn ~= "LeftButton" then return end
        local _, trackTop = self:GetPoint()
        local _, my = GetCursorPosition()
        local scale = self:GetEffectiveScale()
        local trackH = self:GetHeight()
        local clickY = (self:GetTop() - my / scale)
        local pct    = math.min(math.max(clickY / trackH, 0), 1)
        local totalH = content:GetHeight()
        local viewH  = sf:GetHeight()
        sf:SetVerticalScroll(pct * math.max(0, totalH - viewH))
        UpdateThumb()
    end)

    -- Drag du thumb
    local dragStartY, dragStartScroll = nil, nil
    thumb:SetScript("OnMouseDown", function(self, btn)
        if btn ~= "LeftButton" then return end
        local _, my = GetCursorPosition()
        local scale = self:GetEffectiveScale()
        dragStartY      = my / scale
        dragStartScroll = sf:GetVerticalScroll()
        self:SetScript("OnUpdate", function()
            local _, cy = GetCursorPosition()
            local s = self:GetEffectiveScale()
            local dy        = dragStartY - cy / s
            local trackH    = track:GetHeight()
            local thumbH    = self:GetHeight()
            local totalH    = content:GetHeight()
            local viewH     = sf:GetHeight()
            local scrollRange = math.max(0, totalH - viewH)
            local pct = dy / math.max(1, trackH - thumbH)
            local new = math.min(math.max(dragStartScroll + pct * scrollRange, 0), scrollRange)
            sf:SetVerticalScroll(new)
            UpdateThumb()
        end)
    end)
    thumb:SetScript("OnMouseUp", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    -- Expose UpdateThumb pour que PopulateColumn puisse le rappeler
    sf._UpdateScrollBar = UpdateThumb
    -- Recalcul automatique lors du redimensionnement
    sf:SetScript("OnSizeChanged", function() UpdateThumb() end)

    return sf, content
end

-- =========================================================
-- POPULATION D'UNE COLONNE (Donjons / Raids)
-- =========================================================
local function PopulateColumn(scrollFrame, content, sections, isLegacy)
    local parent = content:GetParent()

    -- Purge buttons belonging to the old content frame from allButtons,
    -- then detach the frame so WoW can GC it and all its children.
    for i = #TomoPorter.allButtons, 1, -1 do
        local btn = TomoPorter.allButtons[i]
        if btn:GetParent() == content then
            table.remove(TomoPorter.allButtons, i)
        end
    end
    -- Ne jamais appeler SetParent(nil) en WoW : le moteur déréférence
    -- le parent nul lors du rendu → ACCESS_VIOLATION (Error #132).
    -- On masque et on efface la position ; le frame reste en mémoire mais inoffensif.
    content:Hide()
    content:ClearAllPoints()

    local newContent = CreateFrame("Frame", nil, parent)
    newContent:SetWidth(content:GetWidth())
    newContent:SetHeight(1)
    scrollFrame:SetScrollChild(newContent)
    scrollFrame:SetVerticalScroll(0)

    local yOff  = 2
    local count = 0

    for _, section in ipairs(sections) do
        local lbl = section.seasonLabel or section.expansion or ""

        if isLegacy and lbl ~= "" then
            local hUsed = CreateGroupHeader(newContent, lbl, yOff)
            yOff = yOff + hUsed + 3
        end

        for _, entry in ipairs(section.entries) do
            CreateTeleportButton(newContent, entry, yOff)
            yOff  = yOff + CFG.btnH + CFG.btnPad
            count = count + 1
        end

        if isLegacy then yOff = yOff + 6 end
    end

    if count == 0 then
        local empty = newContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        empty:SetPoint("TOP", newContent, "TOP", 0, -20)
        empty:SetText(L["NO_TELEPORT"])
        empty:SetTextColor(unpack(CYAN.textDim))
        yOff = 50
    end

    newContent:SetHeight(math.max(yOff, 10))
    -- Met à jour la scrollbar custom après chaque peuplement
    if scrollFrame._UpdateScrollBar then
        C_Timer.After(0, scrollFrame._UpdateScrollBar)
    end
    return newContent
end

-- =========================================================
-- CONSTRUCTION D'UNE COLONNE (Donjons / Raids)
-- =========================================================
local function BuildColumn(parent, title, category, xOff)
    local colW = CFG.colW

    local hdr = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff + 3, -8)
    hdr:SetText(title)
    hdr:SetTextColor(unpack(CYAN.textHeader))

    local hline = parent:CreateTexture(nil, "ARTWORK")
    hline:SetHeight(1)
    hline:SetWidth(colW)
    hline:SetPoint("TOPLEFT", hdr, "BOTTOMLEFT", 0, -2)
    hline:SetTexture("Interface/Buttons/WHITE8X8")
    hline:SetVertexColor(unpack(CYAN.border))

    local tabCur = CreateTab(parent, L["CURRENT"])
    tabCur:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff + 3, -26)

    local tabLeg = CreateTab(parent, L["LEGACY"])
    tabLeg:SetPoint("TOPLEFT", tabCur, "TOPRIGHT", 3, 0)

    local scrollFrame, contentRef = CreateScrollFrame(parent, xOff + 3, -52, colW)
    local currentContent = contentRef

    local tabActive = "current"

    local function Refresh()
        local isLeg = (tabActive == "legacy")
        local secs  = Data[category][isLeg and "legacy" or "current"]
        tabCur:SetActive(not isLeg)
        tabLeg:SetActive(isLeg)
        currentContent = PopulateColumn(scrollFrame, currentContent, secs, isLeg)
    end

    tabCur:SetScript("OnClick", function() tabActive = "current"; Refresh() end)
    tabLeg:SetScript("OnClick", function() tabActive = "legacy";  Refresh() end)

    tabCur:SetActive(true)
    local initSecs = Data[category]["current"]
    currentContent = PopulateColumn(scrollFrame, currentContent, initSecs, false)
end

-- =========================================================
-- CONSTRUCTION D'UNE COLONNE MAGE (Téléportations / Portails)
-- =========================================================
local function BuildMageColumn(parent, title, spellGroups, xOff)
    local colW = CFG.colW

    -- En-tête de colonne
    local hdr = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff + 3, -8)
    hdr:SetText(title)
    hdr:SetTextColor(unpack(CYAN.textHeader))

    local hline = parent:CreateTexture(nil, "ARTWORK")
    hline:SetHeight(1)
    hline:SetWidth(colW)
    hline:SetPoint("TOPLEFT", hdr, "BOTTOMLEFT", 0, -2)
    hline:SetTexture("Interface/Buttons/WHITE8X8")
    hline:SetVertexColor(unpack(CYAN.border))

    -- Scroll frame (pas de sous-onglets Current/Legacy pour Mage)
    local sf, content = CreateScrollFrame(parent, xOff + 3, -26, colW)

    -- Population
    local yOff = 2
    for _, section in ipairs(spellGroups) do
        local hUsed = CreateGroupHeader(content, section.group, yOff)
        yOff = yOff + hUsed + 3
        for _, entry in ipairs(section.entries) do
            CreateTeleportButton(content, entry, yOff)
            yOff = yOff + CFG.btnH + CFG.btnPad
        end
        yOff = yOff + 6
    end
    content:SetHeight(math.max(yOff, 10))
    if sf._UpdateScrollBar then
        C_Timer.After(0, sf._UpdateScrollBar)
    end
end

-- =========================================================
-- PANEL MAGE
-- =========================================================
local function BuildMagePanel(parent)
    BuildMageColumn(parent, L["TELEPORTS"], Data.mage.teleports, 0)
    BuildMageColumn(parent, L["PORTALS"],   Data.mage.portals,   CFG.colW + CFG.colGap + 10)
end

-- =========================================================
-- BUILD UI
-- =========================================================
local function BuildUI()
    local f = CreateMainFrame()
    TomoPorter.frame = f

    -- ── Bande d'onglets de catégorie ─────────────────────────
    -- Fond de la bande
    local catBg = f:CreateTexture(nil, "ARTWORK")
    catBg:SetHeight(CFG.catTabH)
    catBg:SetPoint("TOPLEFT",  f, "TOPLEFT",  1, -28)
    catBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -28)
    catBg:SetTexture("Interface/Buttons/WHITE8X8")
    catBg:SetVertexColor(0.03, 0.07, 0.11, 1)

    -- Séparateur horizontal sous la bande de catégorie
    local catSep = f:CreateTexture(nil, "ARTWORK")
    catSep:SetHeight(1)
    catSep:SetPoint("TOPLEFT",  f, "TOPLEFT",  1, -(28 + CFG.catTabH))
    catSep:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -(28 + CFG.catTabH))
    catSep:SetTexture("Interface/Buttons/WHITE8X8")
    catSep:SetVertexColor(unpack(CYAN.border))

    -- Création d'un onglet de catégorie
    local function MakeCatTab(label, xOff)
        local btn = CreateFrame("Button", nil, f, "BackdropTemplate")
        btn:SetSize(CFG.catTabW, CFG.catTabH - 2)
        btn:SetPoint("TOPLEFT", f, "TOPLEFT", xOff, -29)
        btn:SetBackdrop({ bgFile   = "Interface/Buttons/WHITE8X8",
                          edgeFile = "Interface/Buttons/WHITE8X8", edgeSize = 1 })

        local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        txt:SetAllPoints()
        txt:SetText(label)

        function btn:SetActive(active)
            if active then
                btn:SetBackdropColor(unpack(CYAN.bgCatActive))
                btn:SetBackdropBorderColor(unpack(CYAN.border))
                txt:SetTextColor(unpack(CYAN.textCatOn))
            else
                btn:SetBackdropColor(unpack(CYAN.bgCatIdle))
                btn:SetBackdropBorderColor(unpack(CYAN.borderDim))
                txt:SetTextColor(unpack(CYAN.textCatOff))
            end
        end
        btn:SetActive(false)
        return btn
    end

    local catTabTP   = MakeCatTab(L["TAB_PORTEURS"], 6)
    local catTabMage = MakeCatTab(L["TAB_MAGE"],     6 + CFG.catTabW + 4)

    -- ── Panel Téléporteurs (Donjons + Raids) ─────────────────
    local tpPanel = CreateFrame("Frame", nil, f)
    tpPanel:SetPoint("TOPLEFT",     f, "TOPLEFT",     0, -(28 + CFG.catTabH + 2))
    tpPanel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

    BuildColumn(tpPanel, L["DUNGEONS"], "dungeons", 0)
    BuildColumn(tpPanel, L["RAIDS"],    "raids",    CFG.colW + CFG.colGap + 10)

    -- ── Panel Mage ────────────────────────────────────────────
    local magePanel = CreateFrame("Frame", nil, f)
    magePanel:SetPoint("TOPLEFT",     f, "TOPLEFT",     0, -(28 + CFG.catTabH + 2))
    magePanel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    magePanel:Hide()

    BuildMagePanel(magePanel)

    -- ── Handlers des onglets de catégorie ────────────────────
    catTabTP:SetScript("OnClick", function()
        catTabTP:SetActive(true)
        catTabMage:SetActive(false)
        tpPanel:Show()
        magePanel:Hide()
        f.vsep:Show()
    end)
    catTabMage:SetScript("OnClick", function()
        catTabMage:SetActive(true)
        catTabTP:SetActive(false)
        magePanel:Show()
        tpPanel:Hide()
        f.vsep:Show()
    end)

    catTabTP:SetActive(true)
end

-- =========================================================
-- SLASH COMMANDS
-- =========================================================
local function Toggle()
    local f = TomoPorter.frame
    if not f then return end
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
        if not InCombatLockdown() then
            RefreshAllButtons()
        end
    end
end

SLASH_TOPORTER1 = "/porter"
SLASH_TOPORTER2 = "/tpt"
SlashCmdList["TOPORTER"] = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(%S*)")
    if cmd == "help" or cmd == "?" then
        print("|cff00ddffTomoPorter|r  v1.3.1")
        print("  /porter  — ouvre/ferme la fenêtre")
        print("  /tpt     — alias")
    else
        Toggle()
    end
end

-- =========================================================
-- EVENTS
-- =========================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        BuildUI()
        print("|cff00ddffTomoPorter|r v1.3.2 chargé — |cff4db8cc/porter|r pour ouvrir")
        self:UnregisterEvent("PLAYER_LOGIN")

    elseif event == "SPELLS_CHANGED" then
        if not InCombatLockdown() then
            RefreshAllButtons()
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        RefreshAllButtons()
    end
end)

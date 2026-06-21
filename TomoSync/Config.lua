-- TomoSync | Config.lua
-- Panneau de parametres (style sombre plat de la suite).

TomoSyncConfig = {}
local Config = TomoSyncConfig
local TS     = TomoSync
local UI     = TS.UI

local panel

-- Applique un changement de reglage : invalide le cache tooltip + rafraichit la fenetre.
local function ApplyChange()
    local tip = TS.modules["Tooltip"]; if tip and tip.ResetCache then tip:ResetCache() end
    local br  = TS.modules["Browser"]; if br and br.Refresh then br:Refresh() end
end

-- Confirmation avant effacement total
StaticPopupDialogs["TOMOSYNC_CLEAR"] = {
    text = "TomoSync : " .. (TomoSyncLocale and TomoSyncLocale.BTN_CLEAR or "Clear all data") .. " ?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        TS:ResetData()
        if panel and panel:IsShown() then panel:Hide(); panel:Show() end
        TS:Print(TS:L("DATA_CLEARED"))
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function Build()
    panel = CreateFrame("Frame", "TomoSyncConfigPanel", UIParent, "BackdropTemplate")
    panel:SetSize(420, 426)
    panel:SetPoint("CENTER", 80, 0)
    panel:SetFrameStrata("DIALOG")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:SetClampedToScreen(true)
    UI.StyleFlatFrame(panel)
    panel:Hide()

    -- En-tete
    UI.CreateHeaderBar(panel, 40)
    local diamond = UI.CreateDiamond(panel, 10)
    diamond:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -15)
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", diamond, "RIGHT", 10, 0)
    title:SetText("|cFFCC44FFTomo|r|cFFFFFFFFSync|r |cFFAAAAAA— " .. TS:L("BTN_SETTINGS") .. "|r")

    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() panel:Hide() end)

    -- ----- Cases d'affichage tooltip -----
    local checks = {
        { key = "CFG_SHOW_BAGS",    field = "showBags" },
        { key = "CFG_SHOW_BANK",    field = "showBank" },
        { key = "CFG_SHOW_WARBAND", field = "showWarband" },
        { key = "CFG_SHOW_EQUIP",   field = "showEquip" },
        { key = "CFG_SHOW_TOTAL",   field = "showTotal" },
    }
    local y = -52
    for _, c in ipairs(checks) do
        local field = c.field
        local cb = UI.CreateCheckbox(panel, TS:L(c.key), nil,
            function() return TS.db.settings[field] end,
            function(v) TS.db.settings[field] = v; ApplyChange() end)
        cb:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, y)
        y = y - 28
    end

    -- Separateur
    local sep1 = UI.CreateSeparator(panel, { 1, 1, 1 }, 0.10)
    sep1:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -196)
    sep1:SetPoint("RIGHT", panel, "TOPRIGHT", -20, 0)

    -- Filtre meme royaume
    local realmCb = UI.CreateCheckbox(panel, TS:L("CFG_ONLY_REALM"), nil,
        function() return TS.db.settings.onlyRealm end,
        function(v) TS.db.settings.onlyRealm = v; ApplyChange() end)
    realmCb:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -208)

    -- Bouton minicarte
    local mmCb = UI.CreateCheckbox(panel, TS:L("CFG_MINIMAP_BUTTON"), nil,
        function() return not (TS.account and TS.account.minimap and TS.account.minimap.hide) end,
        function(v)
            local mm = TS.modules["Minimap"]
            if mm then mm:SetHidden(not v) end
        end)
    mmCb:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -236)

    -- Separateur
    local sep2 = UI.CreateSeparator(panel, { 1, 1, 1 }, 0.10)
    sep2:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -266)
    sep2:SetPoint("RIGHT", panel, "TOPRIGHT", -20, 0)

    -- Curseur seuil
    local slider = UI.CreateSlider(panel, TS:L("CFG_THRESHOLD"), TS:L("CFG_THRESHOLD_TT"),
        0, 100, 1,
        function() return TS.db.settings.threshold or 0 end,
        function(v) TS.db.settings.threshold = v end,
        ApplyChange)
    slider:SetPoint("TOPLEFT", panel, "TOPLEFT", 22, -280)

    -- ----- Pied de page -----
    local footSep = UI.CreateSeparator(panel, UI.PURPLE, 0.40)
    footSep:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 16, 44)
    footSep:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 0)

    local scanBtn = UI.CreateButton(panel, TS:L("BTN_SCAN"), 150, 26)
    scanBtn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 20, 12)
    scanBtn:SetScript("OnClick", function()
        local sc = TS.modules["Scanner"]
        if sc then
            sc:ScanBags(); sc:ScanEquipped()
            if sc.atBank then sc:ScanBank(); sc:ScanWarband() end
            TS:Print(TS:L("SCAN_BAGS_DONE"))
        end
    end)

    local clearBtn = UI.CreateButton(panel, "|cFFFF5555" .. TS:L("BTN_CLEAR") .. "|r", 180, 26)
    clearBtn:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -20, 12)
    clearBtn:SetScript("OnClick", function()
        StaticPopup_Show("TOMOSYNC_CLEAR")
    end)

    tinsert(UISpecialFrames, "TomoSyncConfigPanel")
end

function Config:Toggle()
    if not panel then Build() end
    if panel:IsShown() then
        panel:Hide()
    else
        panel:Show()
    end
end

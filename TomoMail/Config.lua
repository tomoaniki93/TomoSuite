-- TomoMail | Config.lua
-- Modern configuration panel with toggle switches

TomoMailConfig = {}
local Config = TomoMailConfig
local TM     = TomoMail

-- ============================================================
--  Panel state
-- ============================================================

local panel    = nil
local toggles  = {}  -- references to refresh on show

-- ============================================================
--  Helper: config row with label + optional subtitle
-- ============================================================

local function CreateConfigRow(parent, label, subtitle, yOffset, getter, setter, indent)
    local UI = TM.UI
    indent = indent or 0

    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(parent:GetWidth() - 32, 28)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 16 + indent, yOffset)

    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", row, "LEFT", 0, subtitle and 4 or 0)
    lbl:SetText(label)
    lbl:SetTextColor(0.8, 0.8, 0.8)

    if subtitle then
        local sub = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        sub:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -1)
        sub:SetText(subtitle)
        sub:SetTextColor(0.33, 0.33, 0.33)
        row:SetHeight(36)
    end

    local toggle = UI:CreateToggle(row, getter, setter)
    toggle:SetPoint("RIGHT", row, "RIGHT", 0, 0)

    table.insert(toggles, toggle)
    return row
end

-- ============================================================
--  Helper: styled slider
-- ============================================================

local function CreateConfigSlider(parent, label, min, max, step, yOffset, getter, setter)
    local UI = TM.UI
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(parent:GetWidth() - 32, 44)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, yOffset)

    local lbl = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    lbl:SetText(label)
    lbl:SetTextColor(0.8, 0.8, 0.8)

    local valText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valText:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)
    valText:SetTextColor(unpack(UI.COLORS.accent))

    local sliderName = "TomoMailCfgSlider_" .. label:gsub("%s", "_"):gsub("[^%w_]", "")
    local slider = CreateFrame("Slider", sliderName, container, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -18)
    slider:SetWidth(container:GetWidth())
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    -- Hide default low/high labels
    if slider.Low  then slider.Low:SetText("")  end
    if slider.High then slider.High:SetText("") end

    -- Try to style the thumb/track if accessible
    pcall(function()
        local thumb = slider:GetThumbTexture()
        if thumb then
            thumb:SetSize(14, 14)
            thumb:SetColorTexture(unpack(UI.COLORS.accent))
        end
    end)

    function container:Refresh()
        local v = getter()
        slider:SetValue(v)
        valText:SetText(tostring(v))
    end

    slider:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val + 0.5)
        valText:SetText(tostring(val))
        setter(val)
    end)

    table.insert(toggles, container)  -- reuse refresh list
    return container
end

-- ============================================================
--  Build panel
-- ============================================================

local PANEL_WIDTH  = 320
local PANEL_HEIGHT = 510

local function BuildPanel()
    local UI = TM.UI

    panel = UI:CreatePanel(UIParent, "TomoMailConfigPanel", PANEL_WIDTH, PANEL_HEIGHT)
    panel:SetPoint("CENTER")
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:Hide()

    tinsert(UISpecialFrames, "TomoMailConfigPanel")

    -- ---- Header ----
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -12)
    title:SetText("|cFFCC44FFTomo|r|cFFFFFFFFMail|r |cFF555555— " .. TM:L("SETTINGS") .. "|r")

    local closeBtn = CreateFrame("Button", nil, panel)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -10)
    local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeTxt:SetAllPoints()
    closeTxt:SetText("|cFF555555×|r")
    closeBtn:SetScript("OnClick", function() panel:Hide() end)
    closeBtn:SetScript("OnEnter", function() closeTxt:SetText("|cFFFFFFFF×|r") end)
    closeBtn:SetScript("OnLeave", function() closeTxt:SetText("|cFF555555×|r") end)

    -- ---- Divider ----
    local div1 = panel:CreateTexture(nil, "ARTWORK")
    div1:SetSize(PANEL_WIDTH - 2, 1)
    div1:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, -32)
    div1:SetColorTexture(unpack(UI.COLORS.borderDim))

    -- ---- Section: Display ----
    local secDisplay = UI:CreateSectionTitle(panel, TM:L("CFG_SECTION_DISPLAY") or "AFFICHAGE")
    secDisplay:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -42)

    local db = TM.db.profile
    local y = -58

    CreateConfigRow(panel,
        TM:L("CFG_SHOW_ALTS"), TM:L("CFG_SHOW_ALTS_SUB") or nil, y,
        function() return db.showAlts end,
        function(v) db.showAlts = v end)
    y = y - 36

    CreateConfigRow(panel,
        TM:L("CFG_SHOW_GUILD"), TM:L("CFG_SHOW_GUILD_SUB") or nil, y,
        function() return db.showGuild end,
        function(v) db.showGuild = v end)
    y = y - 36

    CreateConfigRow(panel,
        TM:L("CFG_GUILD_ONLINE"), nil, y,
        function() return db.guildOnlineOnly end,
        function(v) db.guildOnlineOnly = v end,
        16)  -- indented
    y = y - 30

    CreateConfigRow(panel,
        TM:L("CFG_SHOW_RECENT"), nil, y,
        function() return db.showRecent end,
        function(v) db.showRecent = v end)
    y = y - 36

    -- ---- Divider ----
    local div2 = panel:CreateTexture(nil, "ARTWORK")
    div2:SetSize(PANEL_WIDTH - 32, 1)
    div2:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
    div2:SetColorTexture(unpack(UI.COLORS.borderDim))
    y = y - 12

    -- ---- Slider: max recent ----
    CreateConfigSlider(panel,
        TM:L("CFG_MAX_RECENT"), 5, 25, 1, y,
        function() return db.maxRecent end,
        function(v)
            db.maxRecent = v
            while #db.recent > v do
                table.remove(db.recent)
            end
        end)
    y = y - 52

    -- ---- Divider ----
    local div3 = panel:CreateTexture(nil, "ARTWORK")
    div3:SetSize(PANEL_WIDTH - 2, 1)
    div3:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, y)
    div3:SetColorTexture(unpack(UI.COLORS.borderDim))
    y = y - 12

    -- ---- Section: Behavior ----
    local secBehav = UI:CreateSectionTitle(panel, TM:L("CFG_SECTION_BEHAVIOR") or "COMPORTEMENT")
    secBehav:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
    y = y - 18

    CreateConfigRow(panel,
        TM:L("CFG_AUTOCOMPLETE"), TM:L("CFG_AUTOCOMPLETE_SUB") or nil, y,
        function() return db.useAutocomplete end,
        function(v)
            db.useAutocomplete = v
            if v then
                local qs = TM.modules["QuickSend"]
                if qs then qs:EnableAutocomplete() end
            end
        end)
    y = y - 44

    -- ---- Divider ----
    local div4 = panel:CreateTexture(nil, "ARTWORK")
    div4:SetSize(PANEL_WIDTH - 2, 1)
    div4:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, y)
    div4:SetColorTexture(unpack(UI.COLORS.borderDim))
    y = y - 12

    -- ---- Section: Appearance ----
    local secAppear = UI:CreateSectionTitle(panel, TM:L("CFG_SECTION_APPEARANCE") or "APPARENCE")
    secAppear:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
    y = y - 18

    CreateConfigRow(panel,
        TM:L("CFG_SKIN_ENABLED"), TM:L("CFG_SKIN_ENABLED_SUB") or nil, y,
        function() return db.skinEnabled end,
        function(v)
            db.skinEnabled = v
            TM:Print(TM:L("CFG_SKIN_RELOAD") or "Rechargement nécessaire pour appliquer.")
        end)
    y = y - 38

    -- Scale slider (0.8 to 1.5, step 0.05)
    -- Custom slider with decimal display
    local scaleContainer = CreateFrame("Frame", nil, panel)
    scaleContainer:SetSize(PANEL_WIDTH - 32, 44)
    scaleContainer:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)

    local scaleLbl = scaleContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scaleLbl:SetPoint("TOPLEFT", scaleContainer, "TOPLEFT", 0, 0)
    scaleLbl:SetText(TM:L("CFG_MAIL_SCALE") or "Echelle de l'interface")
    scaleLbl:SetTextColor(0.8, 0.8, 0.8)

    local scaleValText = scaleContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scaleValText:SetPoint("TOPRIGHT", scaleContainer, "TOPRIGHT", 0, 0)
    scaleValText:SetTextColor(unpack(UI.COLORS.accent))

    local scaleSliderName = "TomoMailCfgSlider_Scale"
    local scaleSlider = CreateFrame("Slider", scaleSliderName, scaleContainer, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", scaleContainer, "TOPLEFT", 0, -18)
    scaleSlider:SetWidth(scaleContainer:GetWidth())
    scaleSlider:SetMinMaxValues(80, 150)
    scaleSlider:SetValueStep(5)
    scaleSlider:SetObeyStepOnDrag(true)

    if scaleSlider.Low  then scaleSlider.Low:SetText("")  end
    if scaleSlider.High then scaleSlider.High:SetText("") end

    pcall(function()
        local thumb = scaleSlider:GetThumbTexture()
        if thumb then
            thumb:SetSize(14, 14)
            thumb:SetColorTexture(unpack(UI.COLORS.accent))
        end
    end)

    function scaleContainer:Refresh()
        local v = math.floor((db.mailScale or 1.0) * 100 + 0.5)
        scaleSlider:SetValue(v)
        scaleValText:SetText(string.format("%d%%", v))
    end

    scaleSlider:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val / 5 + 0.5) * 5  -- snap to 5%
        local scale = val / 100
        scaleValText:SetText(string.format("%d%%", val))
        db.mailScale = scale
        local skinMod = TM.modules["Skin"]
        if skinMod and skinMod.UpdateScale then
            skinMod:UpdateScale(scale)
        end
        if TM.Window and TM.Window.ApplyScale then
            TM.Window:ApplyScale()
        end
    end)

    table.insert(toggles, scaleContainer)

    -- ---- Action buttons ----
    local div4 = panel:CreateTexture(nil, "ARTWORK")
    div4:SetSize(PANEL_WIDTH - 2, 1)
    div4:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 1, 42)
    div4:SetColorTexture(unpack(UI.COLORS.borderDim))

    local btnWidth = (PANEL_WIDTH - 40 - 8) / 3

    local clearRecentBtn = UI:CreateStyledButton(panel, TM:L("CFG_CLEAR_RECENT") or "Récents", btnWidth, 28, "dangerBg")
    clearRecentBtn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 12, 10)
    clearRecentBtn:SetScript("OnClick", function()
        TM.db.profile.recent = {}
        TM:Print(TM:L("CFG_RECENT_CLEARED") or "Historique des récents effacé.")
    end)

    local clearAltsBtn = UI:CreateStyledButton(panel, TM:L("CFG_CLEAR_ALTS") or "Alts", btnWidth, 28, "dangerBg")
    clearAltsBtn:SetPoint("LEFT", clearRecentBtn, "RIGHT", 4, 0)
    clearAltsBtn:SetScript("OnClick", function()
        TM.db.global.alts = {}
        TM:RegisterCurrentChar()
        TM:Print(TM:L("CFG_ALTS_CLEARED") or "Liste des alts effacée.")
    end)

    local closeActionBtn = UI:CreateStyledButton(panel, TM:L("CLOSE") or "Fermer", btnWidth, 28, "bgLight")
    closeActionBtn:SetPoint("LEFT", clearAltsBtn, "RIGHT", 4, 0)
    closeActionBtn:SetScript("OnClick", function() panel:Hide() end)
end

-- ============================================================
--  Public API
-- ============================================================

function Config:Toggle()
    if not panel then
        BuildPanel()
    end

    if panel:IsShown() then
        panel:Hide()
    else
        -- Refresh all toggles/sliders
        for _, widget in ipairs(toggles) do
            if widget.Refresh then
                widget:Refresh()
            end
        end
        panel:Show()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
    end
end

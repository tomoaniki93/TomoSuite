-- TomoSync | Modules/Widgets.lua
-- Helpers UI partages : style sombre plat + accent pourpre de la suite.
-- Toutes les textures unies utilisent WHITE8X8 + SetVertexColor (jamais
-- SetColorTexture), conformement au standard TomoSuite.

local TS = TomoSync
TS.UI = TS.UI or {}
local UI = TS.UI

local WHITE = "Interface\\Buttons\\WHITE8X8"

-- Palette
UI.PURPLE   = { 0.80, 0.267, 1.00 }
UI.BG       = { 0.075, 0.075, 0.095, 0.97 }
UI.BG_LIGHT = { 0.11, 0.11, 0.14, 1.00 }
UI.ROW_HL   = { 0.80, 0.267, 1.00, 0.12 }
UI.GRAY     = { 0.62, 0.62, 0.68 }
UI.CYAN     = { 0.25, 0.82, 0.88 }

-- Texture unie (WHITE8X8). Teinter ensuite via SetVertexColor.
function UI.Solid(parent, layer)
    local t = parent:CreateTexture(nil, layer or "ARTWORK")
    t:SetTexture(WHITE)
    return t
end

-- Applique un fond sombre plat + bordure pourpre a un cadre BackdropTemplate.
function UI.StyleFlatFrame(frame, borderAlpha)
    frame:SetBackdrop({
        bgFile   = WHITE,
        edgeFile = WHITE,
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    local bg = UI.BG
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    local p = UI.PURPLE
    frame:SetBackdropBorderColor(p[1], p[2], p[3], borderAlpha or 0.85)
end

-- Barre d'en-tete (fond legerement plus clair + fine ligne pourpre dessous).
function UI.CreateHeaderBar(frame, height)
    height = height or 46
    local bar = UI.Solid(frame, "ARTWORK")
    bar:SetHeight(height)
    bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    local c = UI.BG_LIGHT
    bar:SetVertexColor(c[1], c[2], c[3], 1)

    local line = UI.Solid(frame, "OVERLAY")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, 0)
    line:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, 0)
    local p = UI.PURPLE
    line:SetVertexColor(p[1], p[2], p[3], 0.5)
    return bar
end

-- Petit diamant pourpre (logo de la suite).
function UI.CreateDiamond(parent, size, color)
    local t = UI.Solid(parent, "OVERLAY")
    t:SetSize(size or 10, size or 10)
    local c = color or UI.PURPLE
    t:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
    t:SetRotation(math.rad(45))
    return t
end

-- Ligne de separation horizontale.
function UI.CreateSeparator(parent, color, alpha)
    local t = UI.Solid(parent, "ARTWORK")
    t:SetHeight(1)
    local c = color or UI.PURPLE
    t:SetVertexColor(c[1], c[2], c[3], alpha or 0.25)
    return t
end

-- Bouton plat sombre.
function UI.CreateButton(parent, text, width, height)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width or 130, height or 26)
    b:SetBackdrop({
        bgFile = WHITE, edgeFile = WHITE, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    b:SetBackdropColor(0.14, 0.14, 0.17, 1)
    b:SetBackdropBorderColor(0.30, 0.30, 0.36, 1)

    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("CENTER")
    fs:SetText(text or "")
    b.Text = fs

    b:SetScript("OnEnter", function(self)
        local p = UI.PURPLE
        self:SetBackdropBorderColor(p[1], p[2], p[3], 1)
        self:SetBackdropColor(0.18, 0.18, 0.22, 1)
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.14, 0.14, 0.17, 1)
        self:SetBackdropBorderColor(0.30, 0.30, 0.36, 1)
    end)
    return b
end

-- Case a cocher (libelle + tooltip). Init differee (standard suite).
function UI.CreateCheckbox(parent, label, tooltip, getter, setter)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    local txt = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    txt:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    txt:SetText(label)
    cb.Text = txt

    local function refresh() cb:SetChecked(getter() and true or false) end

    cb:SetScript("OnClick", function(self) setter(self:GetChecked() and true or false) end)
    cb:SetScript("OnShow", refresh)
    cb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(label, 1, 1, 1)
        if tooltip then GameTooltip:AddLine(tooltip, 0.8, 0.8, 0.8, true) end
        GameTooltip:Show()
    end)
    cb:SetScript("OnLeave", function() GameTooltip:Hide() end)

    C_Timer.After(0, refresh)   -- init differee
    return cb
end

-- Curseur (OptionsSliderTemplate uniquement). Init differee.
function UI.CreateSlider(parent, label, tooltip, minV, maxV, step, getter, setter, onChange)
    UI._sliderN = (UI._sliderN or 0) + 1
    local name = "TomoSyncUISlider" .. UI._sliderN

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(240, 52)

    local lbl = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", 0, 0)
    lbl:SetText(label)

    local slider = CreateFrame("Slider", name, container, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 0, -18)
    slider:SetWidth(220)
    slider:SetMinMaxValues(minV, maxV)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    if slider.Low  then slider.Low:SetText(tostring(minV))  end
    if slider.High then slider.High:SetText(tostring(maxV)) end

    local valText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valText:SetPoint("TOP", slider, "BOTTOM", 0, -2)

    local function refresh()
        local v = getter() or minV
        slider:SetValue(v)
        valText:SetText(tostring(v))
    end

    slider:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val + 0.5)
        valText:SetText(tostring(val))
        setter(val)
        if onChange then onChange(val) end
    end)
    slider:SetScript("OnShow", refresh)
    slider:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(label, 1, 1, 1)
        if tooltip then GameTooltip:AddLine(tooltip, 0.8, 0.8, 0.8, true) end
        GameTooltip:Show()
    end)
    slider:SetScript("OnLeave", function() GameTooltip:Hide() end)

    container.slider = slider
    C_Timer.After(0, refresh)   -- init differee
    return container
end

-- Skinne une barre de defilement FauxScrollFrame en version plate et fine :
-- gouttiere d'origine masquee, fleches masquees (geometrie conservee), piste
-- discrete + pouce pourpre plat. Tolerant aux variations de template (gardes).
function UI.SkinScrollBar(bar)
    if not bar then return end
    bar:SetWidth(8)
    local name  = bar:GetName()
    local up    = bar.ScrollUpButton   or (name and _G[name .. "ScrollUpButton"])
    local down  = bar.ScrollDownButton or (name and _G[name .. "ScrollDownButton"])
    local thumb = (bar.GetThumbTexture and bar:GetThumbTexture()) or (name and _G[name .. "ThumbTexture"])

    -- Masque les textures de gouttiere d'origine (sauf le pouce)
    for _, region in ipairs({ bar:GetRegions() }) do
        if region ~= thumb and region.GetObjectType and region:GetObjectType() == "Texture" then
            region:SetAlpha(0)
        end
    end

    -- Masque les fleches (alpha 0 pour conserver la course du pouce)
    for _, b in ipairs({ up, down }) do
        if b then b:SetAlpha(0); b:EnableMouse(false) end
    end

    -- Fond de piste discret
    if not bar._tsTrack then
        local track = UI.Solid(bar, "BACKGROUND")
        track:SetPoint("TOPLEFT", bar, "TOPLEFT", 2, -2)
        track:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -2, 2)
        track:SetVertexColor(1, 1, 1, 0.05)
        bar._tsTrack = track
    end

    -- Pouce plat pourpre
    if thumb then
        thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
        local p = UI.PURPLE
        thumb:SetVertexColor(p[1], p[2], p[3], 0.55)
        thumb:SetWidth(4)
    end
end

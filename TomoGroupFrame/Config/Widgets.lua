-- =====================================
-- Config/Widgets.lua — Custom Config UI Widgets
-- Tomo Suite dark modern theme for TomoGroupFrame
-- =====================================

TGF_Widgets = {}
local W = TGF_Widgets

-- =====================================
-- THEME CONSTANTS (Tomo Suite purple palette)
-- =====================================
W.Theme = {
    bg           = { 0.08, 0.08, 0.10, 0.97 },
    bgLight      = { 0.12, 0.12, 0.15, 1 },
    bgMid        = { 0.10, 0.10, 0.13, 1 },
    accent       = { 0.80, 0.27, 1.00, 1 },     -- #CC44FF tomo purple
    accentDark   = { 0.60, 0.20, 0.80, 1 },
    accentHover  = { 0.90, 0.40, 1.00, 1 },
    border       = { 0.20, 0.20, 0.25, 1 },
    borderLight  = { 0.30, 0.30, 0.35, 1 },
    text         = { 0.90, 0.90, 0.92, 1 },
    textDim      = { 0.55, 0.55, 0.60, 1 },
    textHeader   = { 0.80, 0.27, 1.00, 1 },
    red          = { 0.90, 0.20, 0.20, 1 },
    yellow       = { 0.98, 0.82, 0.11, 1 },
    green        = { 0.20, 0.80, 0.40, 1 },
    white        = { 1, 1, 1, 1 },
    separator    = { 0.20, 0.20, 0.25, 0.6 },
}

local T = W.Theme
local ADDON_PATH = "Interface\\AddOns\\TomoGroupFrame\\"
local FONT = ADDON_PATH .. "Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = ADDON_PATH .. "Assets\\Fonts\\Poppins-SemiBold.ttf"

-- =====================================
-- SCROLL PANEL
-- =====================================

function W.CreateScrollPanel(parent)
    local SCROLLBAR_W = 6
    local SCROLLBAR_PAD = 10
    local TRACK_PAD_V = 6
    local THUMB_MIN_H = 24

    local container = CreateFrame("Frame", nil, parent)
    container:SetAllPoints()

    local track = container:CreateTexture(nil, "BACKGROUND")
    track:SetWidth(SCROLLBAR_W)
    track:SetPoint("TOPRIGHT", -4, -TRACK_PAD_V)
    track:SetPoint("BOTTOMRIGHT", -4, TRACK_PAD_V)
    track:SetColorTexture(0.15, 0.15, 0.18, 1)

    local thumbFrame = CreateFrame("Frame", nil, container)
    thumbFrame:SetWidth(SCROLLBAR_W)
    thumbFrame:SetPoint("TOPRIGHT", -4, -TRACK_PAD_V)

    local thumb = thumbFrame:CreateTexture(nil, "OVERLAY")
    thumb:SetAllPoints()
    thumb:SetColorTexture(unpack(T.accent))

    local scroll = CreateFrame("ScrollFrame", nil, container)
    scroll:SetPoint("TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", -SCROLLBAR_PAD, 0)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(scroll:GetWidth() or 440)
    child:SetHeight(1)
    scroll:SetScrollChild(child)

    local function UpdateThumb()
        local scrollH = scroll:GetHeight() or 0
        local childH = child:GetHeight() or 0
        local trackH = scrollH - 2 * TRACK_PAD_V
        local maxScroll = childH - scrollH

        if maxScroll <= 0 then
            thumbFrame:Hide()
            track:Hide()
            return
        end

        track:Show()
        thumbFrame:Show()

        local ratio = math.min(scrollH / childH, 1)
        local thumbH = math.max(math.floor(trackH * ratio), THUMB_MIN_H)
        thumbFrame:SetHeight(thumbH)

        local cur = scroll:GetVerticalScroll()
        local thumbY = (cur / maxScroll) * (trackH - thumbH)
        thumbFrame:ClearAllPoints()
        thumbFrame:SetPoint("TOPRIGHT", container, "TOPRIGHT", -4, -(TRACK_PAD_V + thumbY))
    end

    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(cur - delta * 30, max)))
        UpdateThumb()
    end)

    thumbFrame:EnableMouse(true)
    thumbFrame:RegisterForDrag("LeftButton")
    thumbFrame:SetScript("OnDragStart", function(self)
        local dragStartY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local dragStartScroll = scroll:GetVerticalScroll()
        self:SetScript("OnUpdate", function()
            local curY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
            local delta = dragStartY - curY
            local scrollH = scroll:GetHeight() or 0
            local childH = child:GetHeight() or 0
            local trackH = scrollH - 2 * TRACK_PAD_V
            local ratio = math.min(scrollH / childH, 1)
            local thumbH = math.max(math.floor(trackH * ratio), THUMB_MIN_H)
            local maxScroll = childH - scrollH
            local newScroll = dragStartScroll + delta * (maxScroll / (trackH - thumbH))
            scroll:SetVerticalScroll(math.max(0, math.min(newScroll, maxScroll)))
            UpdateThumb()
        end)
    end)
    thumbFrame:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    thumbFrame:SetScript("OnEnter", function() thumb:SetColorTexture(unpack(T.accentHover)) end)
    thumbFrame:SetScript("OnLeave", function() thumb:SetColorTexture(unpack(T.accent)) end)

    scroll:SetScript("OnSizeChanged", function(self, w)
        child:SetWidth(math.max(w, 10))
        UpdateThumb()
    end)
    scroll:SetScript("OnShow", function(self)
        local w = self:GetWidth()
        if w and w > 0 then child:SetWidth(w) end
        UpdateThumb()
    end)

    scroll:SetScript("OnScrollRangeChanged", function(self, xRange, yRange)
        UpdateThumb()
    end)

    container.UpdateScroll = UpdateThumb
    container.child = child
    container.scroll = scroll
    scroll.child = child
    scroll.UpdateScroll = UpdateThumb

    return scroll
end

-- =====================================
-- SECTION HEADER
-- =====================================

function W.CreateSectionHeader(parent, text, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY")
    header:SetFont(FONT_BOLD, 14, "")
    header:SetPoint("TOPLEFT", 16, yOffset)
    header:SetTextColor(unpack(T.textHeader))
    header:SetText(text)

    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", 16, yOffset - 20)
    sep:SetPoint("TOPRIGHT", -16, yOffset - 20)
    sep:SetColorTexture(unpack(T.separator))

    return header, yOffset - 30
end

-- =====================================
-- SEPARATOR
-- =====================================

function W.CreateSeparator(parent, yOffset)
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", 16, yOffset - 6)
    sep:SetPoint("TOPRIGHT", -16, yOffset - 6)
    sep:SetColorTexture(unpack(T.separator))
    return sep, yOffset - 16
end

-- =====================================
-- INFO TEXT
-- =====================================

function W.CreateInfoText(parent, text, yOffset)
    local info = parent:CreateFontString(nil, "OVERLAY")
    info:SetFont(FONT, 10, "")
    info:SetPoint("TOPLEFT", 16, yOffset)
    info:SetPoint("TOPRIGHT", -16, yOffset)
    info:SetJustifyH("LEFT")
    info:SetTextColor(unpack(T.textDim))
    info:SetText(text)
    info:SetWordWrap(true)
    local h = info:GetStringHeight() or 14
    return info, yOffset - h - 8
end

-- =====================================
-- CHECKBOX
-- =====================================

function W.CreateCheckbox(parent, text, checked, yOffset, callback)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(28)
    frame:SetPoint("TOPLEFT", 16, yOffset)
    frame:SetPoint("RIGHT", parent, "RIGHT", -20, 0)

    local box = CreateFrame("Button", nil, frame)
    box:SetSize(18, 18)
    box:SetPoint("LEFT", 0, 0)

    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(T.bgLight))

    local border = CreateFrame("Frame", nil, box, "BackdropTemplate")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    border:SetBackdropBorderColor(unpack(T.border))

    local check = box:CreateTexture(nil, "OVERLAY")
    check:SetSize(12, 12)
    check:SetPoint("CENTER")
    check:SetColorTexture(T.accent[1], T.accent[2], T.accent[3], 1)

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 11, "")
    label:SetPoint("LEFT", box, "RIGHT", 8, 0)
    label:SetText(text)
    label:SetTextColor(unpack(T.text))

    local isChecked = checked
    local function UpdateVisual()
        if isChecked then
            check:Show()
            border:SetBackdropBorderColor(unpack(T.accent))
        else
            check:Hide()
            border:SetBackdropBorderColor(unpack(T.border))
        end
    end
    UpdateVisual()

    box:SetScript("OnClick", function()
        isChecked = not isChecked
        UpdateVisual()
        if callback then callback(isChecked) end
    end)

    frame.SetChecked = function(_, val)
        isChecked = val
        UpdateVisual()
    end
    frame.GetChecked = function() return isChecked end

    return frame, yOffset - 30
end

-- =====================================
-- SLIDER
-- =====================================

function W.CreateSlider(parent, text, minVal, maxVal, step, value, yOffset, callback)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(42)
    frame:SetPoint("TOPLEFT", 16, yOffset)
    frame:SetPoint("RIGHT", parent, "RIGHT", -120, 0)

    local valText = frame:CreateFontString(nil, "OVERLAY")
    valText:SetFont(FONT, 11, "")
    valText:SetPoint("TOPRIGHT", -2, 0)
    valText:SetJustifyH("RIGHT")
    valText:SetTextColor(unpack(T.accent))

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 11, "")
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetPoint("RIGHT", valText, "LEFT", -8, 0)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    label:SetTextColor(unpack(T.text))

    local slider = CreateFrame("Slider", nil, frame, "BackdropTemplate")
    slider:SetHeight(16)
    slider:SetPoint("TOPLEFT", 0, -18)
    slider:SetPoint("TOPRIGHT", -2, -18)
    slider:SetOrientation("HORIZONTAL")
    slider:EnableMouse(true)
    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    slider:SetBackdropColor(0.06, 0.06, 0.08, 1)
    slider:SetBackdropBorderColor(unpack(T.border))
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(value)

    -- Thumb texture (wider for easier grabbing)
    local thumbTex = slider:CreateTexture(nil, "OVERLAY")
    thumbTex:SetSize(14, 16)
    thumbTex:SetColorTexture(unpack(T.accent))
    slider:SetThumbTexture(thumbTex)

    -- Mouse wheel on slider
    slider:EnableMouseWheel(true)
    slider:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetValue()
        local newVal = cur + delta * step
        newVal = math.max(minVal, math.min(maxVal, newVal))
        self:SetValue(newVal)
    end)

    local function UpdateVal(val)
        if step >= 1 then
            valText:SetText(string.format("%d", val))
        else
            valText:SetText(string.format("%.2f", val))
        end
    end
    UpdateVal(value)

    slider:SetScript("OnValueChanged", function(self, val)
        UpdateVal(val)
        if callback then callback(val) end
    end)

    frame.slider = slider
    frame.SetValue = function(_, v) slider:SetValue(v); UpdateVal(v) end
    frame.GetValue = function() return slider:GetValue() end

    return frame, yOffset - 46
end

-- =====================================
-- DROPDOWN
-- =====================================

function W.CreateDropdown(parent, text, options, selectedKey, yOffset, callback)
    -- options = { { key="Flat", label="Flat" }, ... }
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(48)
    frame:SetPoint("TOPLEFT", 16, yOffset)
    frame:SetPoint("RIGHT", parent, "RIGHT", -20, 0)

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 11, "")
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetText(text)
    label:SetTextColor(unpack(T.text))

    local btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    btn:SetSize(200, 24)
    btn:SetPoint("TOPLEFT", 0, -18)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.06, 0.06, 0.08, 1)
    btn:SetBackdropBorderColor(unpack(T.border))

    local btnText = btn:CreateFontString(nil, "OVERLAY")
    btnText:SetFont(FONT, 11, "")
    btnText:SetPoint("LEFT", 8, 0)
    btnText:SetTextColor(unpack(T.text))

    local arrow = btn:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(FONT, 10, "")
    arrow:SetPoint("RIGHT", -8, 0)
    arrow:SetTextColor(unpack(T.textDim))
    arrow:SetText("v")

    -- Find initial label
    local currentKey = selectedKey
    for _, opt in ipairs(options) do
        if opt.key == selectedKey then
            btnText:SetText(opt.label)
            break
        end
    end

    -- Dropdown menu frame
    local menuFrame = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    menuFrame:SetWidth(200)
    menuFrame:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
    menuFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    menuFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    menuFrame:SetBackdropColor(0.06, 0.06, 0.08, 0.98)
    menuFrame:SetBackdropBorderColor(unpack(T.accent))
    menuFrame:Hide()

    local menuButtons = {}
    for i, opt in ipairs(options) do
        local mb = CreateFrame("Button", nil, menuFrame)
        mb:SetSize(198, 22)
        mb:SetPoint("TOPLEFT", 1, -(i - 1) * 22 - 1)

        local mbBg = mb:CreateTexture(nil, "BACKGROUND")
        mbBg:SetAllPoints()
        mbBg:SetColorTexture(0, 0, 0, 0)

        local mbLabel = mb:CreateFontString(nil, "OVERLAY")
        mbLabel:SetFont(FONT, 10, "")
        mbLabel:SetPoint("LEFT", 8, 0)
        mbLabel:SetText(opt.label)
        mbLabel:SetTextColor(unpack(T.text))

        mb:SetScript("OnEnter", function() mbBg:SetColorTexture(0.12, 0.12, 0.15, 1) end)
        mb:SetScript("OnLeave", function() mbBg:SetColorTexture(0, 0, 0, 0) end)
        mb:SetScript("OnClick", function()
            currentKey = opt.key
            btnText:SetText(opt.label)
            menuFrame:Hide()
            if callback then callback(opt.key) end
        end)

        menuButtons[i] = mb
    end
    menuFrame:SetHeight(#options * 22 + 2)

    btn:SetScript("OnClick", function()
        if menuFrame:IsShown() then
            menuFrame:Hide()
        else
            menuFrame:Show()
        end
    end)

    btn:SetScript("OnEnter", function() btn:SetBackdropBorderColor(unpack(T.accent)) end)
    btn:SetScript("OnLeave", function()
        if not menuFrame:IsShown() then
            btn:SetBackdropBorderColor(unpack(T.border))
        end
    end)

    frame.GetValue = function() return currentKey end
    frame.SetValue = function(_, key)
        currentKey = key
        for _, opt in ipairs(options) do
            if opt.key == key then btnText:SetText(opt.label); break end
        end
    end

    return frame, yOffset - 52
end

-- =====================================
-- BUTTON
-- =====================================

function W.CreateButton(parent, text, width, yOffset, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, 28)
    btn:SetPoint("TOPLEFT", 16, yOffset)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(unpack(T.bgLight))
    btn:SetBackdropBorderColor(unpack(T.border))

    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 11, "")
    label:SetPoint("CENTER")
    label:SetTextColor(unpack(T.text))
    label:SetText(text)

    btn:SetScript("OnEnter", function(b)
        b:SetBackdropBorderColor(unpack(T.accent))
        label:SetTextColor(unpack(T.accent))
    end)
    btn:SetScript("OnLeave", function(b)
        b:SetBackdropBorderColor(unpack(T.border))
        label:SetTextColor(unpack(T.text))
    end)
    btn:SetScript("OnClick", onClick)

    return btn, yOffset - 34
end

-- =====================================
-- TAB PANEL
-- =====================================

function W.CreateTabPanel(parent, tabs)
    local wrapper = CreateFrame("Frame", nil, parent)
    wrapper:SetAllPoints()

    local singleRowHeight = 34
    local tabBarHeight = singleRowHeight

    local tabBar = CreateFrame("Frame", nil, wrapper)
    tabBar:SetPoint("TOPLEFT", 0, 0)
    tabBar:SetPoint("TOPRIGHT", 0, 0)
    tabBar:SetHeight(tabBarHeight)

    local tabBarBg = tabBar:CreateTexture(nil, "BACKGROUND")
    tabBarBg:SetAllPoints()
    tabBarBg:SetColorTexture(0.06, 0.06, 0.08, 1)

    local tabBarSep = tabBar:CreateTexture(nil, "ARTWORK")
    tabBarSep:SetHeight(1)
    tabBarSep:SetPoint("BOTTOMLEFT", 0, 0)
    tabBarSep:SetPoint("BOTTOMRIGHT", 0, 0)
    tabBarSep:SetColorTexture(unpack(T.border))

    local content = CreateFrame("Frame", nil, wrapper)
    content:SetPoint("TOPLEFT", 0, -tabBarHeight)
    content:SetPoint("BOTTOMRIGHT", 0, 0)

    local tabButtons = {}
    local tabPanels = {}
    local currentTab = nil
    local totalTabs = #tabs
    local tabWidth = math.min(math.floor(600 / totalTabs), 120)

    local function SwitchTab(key)
        if currentTab == key then return end
        for _, panel in pairs(tabPanels) do panel:Hide() end
        for tabKey, btn in pairs(tabButtons) do
            if tabKey == key then
                btn.bg:SetColorTexture(unpack(T.bgLight))
                btn.indicator:Show()
                btn.label:SetTextColor(unpack(T.accent))
            else
                btn.bg:SetColorTexture(0, 0, 0, 0)
                btn.indicator:Hide()
                btn.label:SetTextColor(unpack(T.textDim))
            end
        end
        if not tabPanels[key] then
            for _, tab in ipairs(tabs) do
                if tab.key == key and tab.builder then
                    local panel = tab.builder(content)
                    panel:SetAllPoints(content)
                    tabPanels[key] = panel
                    break
                end
            end
        end
        if tabPanels[key] then tabPanels[key]:Show() end
        currentTab = key
    end

    for i, tab in ipairs(tabs) do
        local btn = CreateFrame("Button", nil, tabBar)
        btn:SetSize(tabWidth, singleRowHeight)
        btn:SetPoint("TOPLEFT", (i - 1) * tabWidth, 0)

        local bg = btn:CreateTexture(nil, "BACKGROUND", nil, 1)
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0)
        btn.bg = bg

        local indicator = btn:CreateTexture(nil, "OVERLAY")
        indicator:SetHeight(2)
        indicator:SetPoint("BOTTOMLEFT", 4, 0)
        indicator:SetPoint("BOTTOMRIGHT", -4, 0)
        indicator:SetColorTexture(unpack(T.accent))
        indicator:Hide()
        btn.indicator = indicator

        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT, 11, "")
        lbl:SetPoint("CENTER", 0, 1)
        lbl:SetTextColor(unpack(T.textDim))
        lbl:SetText(tab.label)
        btn.label = lbl

        btn:SetScript("OnEnter", function()
            if currentTab ~= tab.key then bg:SetColorTexture(0.10, 0.10, 0.13, 0.5) end
        end)
        btn:SetScript("OnLeave", function()
            if currentTab ~= tab.key then bg:SetColorTexture(0, 0, 0, 0) end
        end)
        btn:SetScript("OnClick", function() SwitchTab(tab.key) end)

        tabButtons[tab.key] = btn
    end

    if #tabs > 0 then SwitchTab(tabs[1].key) end

    wrapper.SwitchTab = SwitchTab
    wrapper.content = content
    return wrapper
end

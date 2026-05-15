-- TomoMail | UIHelpers.lua
-- Shared UI factory for modern dark-themed components

local TM = TomoMail

-- ============================================================
--  Theme constants
-- ============================================================

TM.UI = {}
local UI = TM.UI

UI.COLORS = {
    accent     = { 0.80, 0.267, 1.0 },       -- #CC44FF
    accentDim  = { 0.50, 0.20,  0.65 },       -- dimmed purple
    bg         = { 0.05, 0.05,  0.07 },       -- #0D0D12
    bgLight    = { 0.086, 0.086, 0.12 },      -- #16161F
    bgHover    = { 0.10, 0.10,  0.165 },      -- #1A1A2A
    border     = { 0.165, 0.165, 0.227 },     -- #2A2A3A
    borderDim  = { 0.118, 0.118, 0.18 },      -- #1E1E2E
    text       = { 0.85, 0.85, 0.85 },        -- #D9D9D9
    textDim    = { 0.40, 0.40, 0.40 },        -- #666666
    textMuted  = { 0.33, 0.33, 0.33 },        -- #555555
    white      = { 1.0, 1.0, 1.0 },
    online     = { 0.0, 1.0, 0.4 },           -- #00FF66
    danger     = { 1.0, 0.47, 0.47 },         -- #FF7878
    dangerBg   = { 0.165, 0.082, 0.082 },     -- #2A1515
}

UI.BACKDROP = {
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
}

-- ============================================================
--  CreatePanel — base dark panel with rounded feel
-- ============================================================

function UI:CreatePanel(parent, name, width, height)
    local f = CreateFrame("Frame", name, parent or UIParent, "BackdropTemplate")
    f:SetSize(width, height)
    f:SetBackdrop(UI.BACKDROP)
    f:SetBackdropColor(unpack(UI.COLORS.bg))
    f:SetBackdropBorderColor(unpack(UI.COLORS.border))
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    return f
end

-- ============================================================
--  CreateTab — a tab button for the flyout
-- ============================================================

function UI:CreateTab(parent, text, index, totalTabs)
    local tabWidth = parent:GetWidth() / totalTabs
    local tab = CreateFrame("Button", nil, parent)
    tab:SetSize(tabWidth, 30)

    tab.label = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tab.label:SetPoint("CENTER", 0, 0)
    tab.label:SetText(text)
    tab.label:SetTextColor(unpack(UI.COLORS.textDim))

    tab.underline = tab:CreateTexture(nil, "OVERLAY")
    tab.underline:SetHeight(2)
    tab.underline:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
    tab.underline:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
    tab.underline:SetColorTexture(unpack(UI.COLORS.accent))
    tab.underline:Hide()

    tab.count = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tab.count:SetPoint("LEFT", tab.label, "RIGHT", 3, 0)
    tab.count:SetTextColor(unpack(UI.COLORS.textMuted))

    function tab:SetActive(active)
        if active then
            tab.label:SetTextColor(unpack(UI.COLORS.accent))
            tab.count:SetTextColor(unpack(UI.COLORS.accentDim))
            tab.underline:Show()
        else
            tab.label:SetTextColor(unpack(UI.COLORS.textDim))
            tab.count:SetTextColor(unpack(UI.COLORS.textMuted))
            tab.underline:Hide()
        end
    end

    function tab:SetCount(n)
        tab.count:SetText(n and ("(" .. n .. ")") or "")
    end

    tab:SetScript("OnEnter", function(self)
        if not self._active then
            self.label:SetTextColor(0.7, 0.7, 0.7)
        end
    end)
    tab:SetScript("OnLeave", function(self)
        if not self._active then
            self.label:SetTextColor(unpack(UI.COLORS.textDim))
        end
    end)

    return tab
end

-- ============================================================
--  CreateSearchBox — dark themed search input
-- ============================================================

function UI:CreateSearchBox(parent, width)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, 32)

    local bg = container:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(UI.COLORS.bgLight))

    local border = CreateFrame("Frame", nil, container, "BackdropTemplate")
    border:SetAllPoints()
    border:SetBackdrop(UI.BACKDROP)
    border:SetBackdropColor(0, 0, 0, 0)
    border:SetBackdropBorderColor(unpack(UI.COLORS.border))

    local icon = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    icon:SetPoint("LEFT", container, "LEFT", 8, 0)
    icon:SetText("|cFF555555Q|r")

    local editbox = CreateFrame("EditBox", nil, container)
    editbox:SetPoint("LEFT", container, "LEFT", 28, 0)
    editbox:SetPoint("RIGHT", container, "RIGHT", -8, 0)
    editbox:SetHeight(20)
    editbox:SetAutoFocus(false)
    editbox:SetFontObject(GameFontNormalSmall)
    editbox:SetTextColor(0.8, 0.8, 0.8)
    editbox:SetMaxLetters(50)

    editbox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    container.editbox = editbox
    return container
end

-- ============================================================
--  CreateToggle — modern on/off toggle switch
-- ============================================================

function UI:CreateToggle(parent, getter, setter)
    local toggle = CreateFrame("Button", nil, parent)
    toggle:SetSize(36, 20)

    toggle.bg = toggle:CreateTexture(nil, "BACKGROUND")
    toggle.bg:SetAllPoints()
    toggle.bg:SetColorTexture(0, 0, 0, 0)

    -- Track background
    toggle.track = toggle:CreateTexture(nil, "ARTWORK")
    toggle.track:SetSize(36, 20)
    toggle.track:SetPoint("CENTER")
    toggle.track:SetColorTexture(unpack(UI.COLORS.border))

    -- Rounded overlay via atlas if available, fallback to flat
    toggle.knob = toggle:CreateTexture(nil, "OVERLAY")
    toggle.knob:SetSize(16, 16)
    toggle.knob:SetColorTexture(1, 1, 1, 1)

    function toggle:Refresh()
        local on = getter()
        if on then
            toggle.track:SetColorTexture(unpack(UI.COLORS.accent))
            toggle.knob:ClearAllPoints()
            toggle.knob:SetPoint("RIGHT", toggle, "RIGHT", -2, 0)
        else
            toggle.track:SetColorTexture(unpack(UI.COLORS.border))
            toggle.knob:ClearAllPoints()
            toggle.knob:SetPoint("LEFT", toggle, "LEFT", 2, 0)
        end
    end

    toggle:SetScript("OnClick", function(self)
        local newVal = not getter()
        setter(newVal)
        self:Refresh()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end)

    toggle:Refresh()
    return toggle
end

-- ============================================================
--  CreateStyledButton — flat dark button
-- ============================================================

function UI:CreateStyledButton(parent, text, width, height, colorKey)
    colorKey = colorKey or "bgLight"
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetBackdrop(UI.BACKDROP)

    local c = UI.COLORS[colorKey] or UI.COLORS.bgLight
    btn:SetBackdropColor(c[1], c[2], c[3], 1)
    btn:SetBackdropBorderColor(unpack(UI.COLORS.border))

    btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.label:SetPoint("CENTER")
    btn.label:SetText(text)

    if colorKey == "dangerBg" then
        btn.label:SetTextColor(unpack(UI.COLORS.danger))
    else
        btn.label:SetTextColor(unpack(UI.COLORS.textDim))
    end

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(UI.COLORS.accent))
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(UI.COLORS.border))
    end)

    return btn
end

-- ============================================================
--  CreateDivider — thin horizontal line
-- ============================================================

function UI:CreateDivider(parent, width, yOffset)
    local div = parent:CreateTexture(nil, "ARTWORK")
    div:SetSize(width, 1)
    div:SetColorTexture(unpack(UI.COLORS.borderDim))
    return div
end

-- ============================================================
--  CreateSectionTitle — small uppercase accent label
-- ============================================================

function UI:CreateSectionTitle(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetText(text)
    fs:SetTextColor(unpack(UI.COLORS.accent))
    return fs
end

-- ============================================================
--  Row highlight helper
-- ============================================================

function UI:AddRowHighlight(row)
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(UI.COLORS.bgHover[1], UI.COLORS.bgHover[2], UI.COLORS.bgHover[3], 0.6)
    return hl
end

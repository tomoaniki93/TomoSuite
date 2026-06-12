-- TomoMail | Modules/Window.lua
-- Standalone dark mail window that fully replaces the Blizzard frame.
-- The native MailFrame is kept functional but invisible (alpha 0); the
-- native SendMailFrame is reparented into our compose page so the real
-- send / attachment / money widgets keep working inside our own chrome.
-- Sized independently of Blizzard's frame, with a font picker and a
-- modern underline-tab layout.

local TM     = TomoMail
local UI     = TM.UI
local Window = {}
TM:RegisterModule("Window", Window)
TM.Window = Window

local win, inboxPage, composePage, settings, fontList
local tabs    = {}
local current = "INBOX"

local W, H = 440, 640

-- ============================================================
--  Gating
-- ============================================================

local function ModernEnabled()
    if not TM.db then return false end
    local p = TM.db.profile
    return p.skinEnabled ~= false and p.modernUI ~= false
end

-- ============================================================
--  Hide native frame visuals while keeping it functional
-- ============================================================

local function HideNativeChrome()
    pcall(function()
        if MailFrame then
            MailFrame:SetAlpha(0)
            MailFrame:EnableMouse(false)
        end
        if InboxFrame then InboxFrame:EnableMouse(false) end
        for _, n in ipairs({ "MailFrameTab1", "MailFrameTab2" }) do
            local t = _G[n]
            if t then t:EnableMouse(false) end
        end
    end)
end

-- ============================================================
--  Position persistence
-- ============================================================

local function SavePos()
    if not (win and TM.db and TM.db.global) then return end
    local point, _, _, x, y = win:GetPoint()
    if point then TM.db.global.window = { point = point, x = x, y = y } end
end

local function RestorePos()
    if not win then return end
    win:ClearAllPoints()
    local wp = TM.db and TM.db.global and TM.db.global.window
    if wp and wp.point and tostring(wp.point):find("TOP") then
        win:SetPoint(wp.point, UIParent, wp.point, wp.x or 0, wp.y or 0)
    else
        win:SetPoint("TOP", UIParent, "TOP", -160, -100)
    end
end

-- Fit the window height to the active tab: tall list for the inbox,
-- snug to the native compose content for the send tab. Anchoring by the
-- top means the height only grows/shrinks downward (no jump).
local function ApplyTabHeight(key)
    if not win then return end
    if key == "SEND" then
        C_Timer.After(0.05, function()
            if not win then return end
            -- Deterministic fit: window height = chrome + the native send
            -- frame's own logical height (+ small pad). GetHeight returns the
            -- set value, so this never depends on layout timing or UI scale,
            -- and the window always fully contains the native widgets.
            local newH = 540
            pcall(function()
                local fh = SendMailFrame and SendMailFrame:GetHeight()
                if fh and fh > 120 then
                    newH = 66 + 8 + fh + 12   -- chrome + frame top offset + frame + pad
                end
            end)
            if newH < 360 then newH = 360 elseif newH > 820 then newH = 820 end
            win:SetHeight(newH)
        end)
    else
        win:SetHeight(H)
    end
end

-- ============================================================
--  Underline tab button (modern)
-- ============================================================

local function CreateTabButton(parent, label, key)
    local b = CreateFrame("Button", nil, parent)
    b.label = UI:FS(b, "normal")
    b.label:SetPoint("CENTER", 0, 2)
    b.label:SetText(label)

    b.underline = b:CreateTexture(nil, "ARTWORK")
    b.underline:SetHeight(2)
    b.underline:SetPoint("BOTTOMLEFT", 8, 0)
    b.underline:SetPoint("BOTTOMRIGHT", -8, 0)
    b.underline:SetColorTexture(unpack(UI.COLORS.accent))
    b.underline:Hide()

    b._key = key
    function b:SetActive(a)
        if a then
            b.label:SetTextColor(unpack(UI.COLORS.accent))
            b.underline:Show()
        else
            b.label:SetTextColor(unpack(UI.COLORS.textDim))
            b.underline:Hide()
        end
    end
    b:SetScript("OnEnter", function(s) if s._key ~= current then s.label:SetTextColor(0.7, 0.7, 0.7) end end)
    b:SetScript("OnLeave", function(s) if s._key ~= current then s.label:SetTextColor(unpack(UI.COLORS.textDim)) end end)
    return b
end

-- ============================================================
--  Font picker popover
-- ============================================================

local function BuildFontList(ddBtn)
    if fontList then return fontList end
    fontList = UI:CreatePanel(win, "TomoMailFontList", 210, 220)
    fontList:SetFrameStrata("TOOLTIP")
    fontList:SetFrameLevel((settings and settings:GetFrameLevel() or win:GetFrameLevel()) + 50)
    fontList:SetPoint("TOPLEFT", ddBtn, "BOTTOMLEFT", 0, -2)
    fontList:Hide()

    -- guaranteed-opaque background so the widgets behind never show through
    fontList:SetBackdropColor(UI.COLORS.bg[1], UI.COLORS.bg[2], UI.COLORS.bg[3], 1)
    local solid = fontList:CreateTexture(nil, "BACKGROUND")
    solid:SetAllPoints()
    solid:SetColorTexture(UI.COLORS.bg[1], UI.COLORS.bg[2], UI.COLORS.bg[3], 1)

    local scroll = CreateFrame("ScrollFrame", nil, fontList)
    scroll:SetPoint("TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", -6, 4)
    scroll:EnableMouseWheel(true)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(10, 10)
    scroll:SetScrollChild(child)

    local fonts = UI:GetFontList()
    local y, rowH = 0, 22
    for _, e in ipairs(fonts) do
        local row = CreateFrame("Button", nil, child)
        row:SetHeight(rowH)
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetPoint("TOPRIGHT", 0, -y)
        UI:AddRowHighlight(row)
        local fs = row:CreateFontString(nil, "OVERLAY")
        pcall(function() fs:SetFont(e.path, 13, "") end)
        if not fs:GetFont() then fs:SetFontObject(UI._fontObjects.small) end
        fs:SetPoint("LEFT", 8, 0)
        fs:SetText(e.name)
        fs:SetTextColor(unpack(UI.COLORS.text))
        row:SetScript("OnClick", function()
            TM.db.profile.font = e.path
            UI:RefreshFonts()
            ddBtn.label:SetText(UI:GetFontName())
            fontList:Hide()
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end)
        y = y + rowH
    end
    child:SetHeight(math.max(y, 1))
    child:SetWidth(190)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local maxS = math.max(child:GetHeight() - self:GetHeight(), 0)
        self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScroll() - delta * rowH * 2, maxS)))
    end)
    return fontList
end

local function BuildSettings()
    settings = UI:CreatePanel(win, "TomoMailSettings", 240, 205)
    settings:SetFrameStrata("FULLSCREEN_DIALOG")
    settings:SetPoint("TOPRIGHT", win, "TOPRIGHT", -8, -32)
    settings:Hide()

    local header = UI:FS(settings, "small")
    header:SetPoint("TOPLEFT", 12, -10)
    header:SetText(TM:L("SETTINGS") or "Réglages")
    header:SetTextColor(unpack(UI.COLORS.accent))

    -- Font dropdown
    local fLabel = UI:FS(settings, "small")
    fLabel:SetPoint("TOPLEFT", 12, -30)
    fLabel:SetText(TM:L("FONT") or "Police")
    fLabel:SetTextColor(unpack(UI.COLORS.textDim))

    local ddBtn = CreateFrame("Button", nil, settings, "BackdropTemplate")
    ddBtn:SetSize(150, 22)
    ddBtn:SetPoint("TOPRIGHT", settings, "TOPRIGHT", -12, -28)
    ddBtn:SetBackdrop(UI.BACKDROP)
    ddBtn:SetBackdropColor(UI.COLORS.bgLight[1], UI.COLORS.bgLight[2], UI.COLORS.bgLight[3], 1)
    ddBtn:SetBackdropBorderColor(unpack(UI.COLORS.border))
    ddBtn.label = UI:FS(ddBtn, "small")
    ddBtn.label:SetPoint("LEFT", 8, 0)
    ddBtn.label:SetText(UI:GetFontName())
    local arrow = UI:FS(ddBtn, "small")
    arrow:SetPoint("RIGHT", -8, 0)
    arrow:SetText("v")
    arrow:SetTextColor(unpack(UI.COLORS.textDim))
    ddBtn:SetScript("OnEnter", function(s) s:SetBackdropBorderColor(unpack(UI.COLORS.accent)) end)
    ddBtn:SetScript("OnLeave", function(s) s:SetBackdropBorderColor(unpack(UI.COLORS.border)) end)
    ddBtn:SetScript("OnClick", function()
        local fl = BuildFontList(ddBtn)
        if fl:IsShown() then fl:Hide() else fl:Show() end
    end)

    -- Size slider
    local slider = CreateFrame("Slider", "TomoMailFontSizeSlider", settings, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 14, -76)
    slider:SetWidth(210)
    slider:SetMinMaxValues(0.8, 1.4)
    slider:SetValueStep(0.05)
    pcall(function() slider:SetObeyStepOnDrag(true) end)
    slider:SetValue(UI:GetFontSizeScale())
    if _G["TomoMailFontSizeSliderLow"]  then _G["TomoMailFontSizeSliderLow"]:SetText("A-") end
    if _G["TomoMailFontSizeSliderHigh"] then _G["TomoMailFontSizeSliderHigh"]:SetText("A+") end
    if _G["TomoMailFontSizeSliderText"] then
        _G["TomoMailFontSizeSliderText"]:SetText(TM:L("FONT_SIZE") or "Taille du texte")
    end
    slider:SetScript("OnValueChanged", function(_, val)
        if TM.db and TM.db.profile then TM.db.profile.fontSize = val end
        UI:RefreshFonts()
    end)

    -- Item icon size slider (inbox attachment icons)
    local isl = CreateFrame("Slider", "TomoMailIconSizeSlider", settings, "OptionsSliderTemplate")
    isl:SetPoint("TOPLEFT", 14, -120)
    isl:SetWidth(210)
    isl:SetMinMaxValues(18, 36)
    isl:SetValueStep(2)
    pcall(function() isl:SetObeyStepOnDrag(true) end)
    isl:SetValue((TM.db and TM.db.profile and TM.db.profile.inboxIconSize) or 30)
    if _G["TomoMailIconSizeSliderLow"]  then _G["TomoMailIconSizeSliderLow"]:SetText("-") end
    if _G["TomoMailIconSizeSliderHigh"] then _G["TomoMailIconSizeSliderHigh"]:SetText("+") end
    if _G["TomoMailIconSizeSliderText"] then
        _G["TomoMailIconSizeSliderText"]:SetText(TM:L("INBOX_ICON_SIZE") or "Taille des icônes")
    end
    isl:SetScript("OnValueChanged", function(_, val)
        val = math.floor((val or 30) + 0.5)
        if TM.db and TM.db.profile then TM.db.profile.inboxIconSize = val end
        local inbox = TM.modules and TM.modules["Inbox"]
        if inbox and inbox.ApplyIconSize then inbox:ApplyIconSize() end
    end)

    -- Reset position
    local reset = UI:CreateStyledButton(settings, TM:L("RESET_POS") or "Recentrer la fenêtre", 210, 22, "bgLight")
    reset:SetPoint("BOTTOMLEFT", 14, 10)
    reset:SetScript("OnClick", function()
        if TM.db and TM.db.global then TM.db.global.window = nil end
        RestorePos()
    end)
end

-- ============================================================
--  Build the window
-- ============================================================

local function Build()
    UI:RefreshFonts()

    win = UI:CreatePanel(UIParent, "TomoMailWindow", W, H)
    win:SetFrameStrata("HIGH")
    win:SetToplevel(true)
    win:SetMovable(true)
    win:SetClampedToScreen(true)
    win:Hide()

    -- Title bar (drag handle)
    local titlebar = CreateFrame("Frame", nil, win)
    titlebar:SetPoint("TOPLEFT", 0, 0)
    titlebar:SetPoint("TOPRIGHT", 0, 0)
    titlebar:SetHeight(30)
    titlebar:EnableMouse(true)
    titlebar:RegisterForDrag("LeftButton")
    titlebar:SetScript("OnDragStart", function() win:StartMoving() end)
    titlebar:SetScript("OnDragStop", function() win:StopMovingOrSizing(); SavePos() end)

    local accentDot = titlebar:CreateTexture(nil, "ARTWORK")
    accentDot:SetSize(8, 8)
    accentDot:SetPoint("LEFT", 12, 0)
    accentDot:SetColorTexture(unpack(UI.COLORS.accent))

    local title = UI:FS(titlebar, "title")
    title:SetPoint("LEFT", 26, 0)
    title:SetText("|cffCC44FFTomo|r|cffFFFFFFMail|r")

    -- Close
    local close = CreateFrame("Button", nil, titlebar)
    close:SetSize(20, 20)
    close:SetPoint("RIGHT", -10, 0)
    close.t = UI:FS(close, "large")
    close.t:SetAllPoints()
    close.t:SetText("×")
    close.t:SetTextColor(0.53, 0.53, 0.53)
    close:SetScript("OnEnter", function(s) s.t:SetTextColor(1, 1, 1) end)
    close:SetScript("OnLeave", function(s) s.t:SetTextColor(0.53, 0.53, 0.53) end)
    close:SetScript("OnClick", function()
        pcall(function()
            if CloseMail then CloseMail()
            elseif HideUIPanel and MailFrame then HideUIPanel(MailFrame) end
        end)
        Window:Hide()
    end)

    -- Settings cog
    local cog = CreateFrame("Button", nil, titlebar)
    cog:SetSize(18, 18)
    cog:SetPoint("RIGHT", close, "LEFT", -6, 0)
    cog.icon = cog:CreateTexture(nil, "ARTWORK")
    cog.icon:SetAllPoints()
    cog.icon:SetTexture("Interface\\Buttons\\UI-OptionsButton")
    cog.icon:SetVertexColor(0.6, 0.6, 0.6)
    cog:SetScript("OnEnter", function(s) s.icon:SetVertexColor(unpack(UI.COLORS.accent)) end)
    cog:SetScript("OnLeave", function(s) s.icon:SetVertexColor(0.6, 0.6, 0.6) end)
    cog:SetScript("OnClick", function()
        if not settings then BuildSettings() end
        if settings:IsShown() then
            settings:Hide()
            if fontList then fontList:Hide() end
        else
            settings:Show()
        end
    end)

    -- Divider under title
    local d1 = win:CreateTexture(nil, "ARTWORK")
    d1:SetHeight(1)
    d1:SetPoint("TOPLEFT", 1, -30)
    d1:SetPoint("TOPRIGHT", -1, -30)
    d1:SetColorTexture(unpack(UI.COLORS.borderDim))

    -- Tabs
    local tabRow = CreateFrame("Frame", nil, win)
    tabRow:SetPoint("TOPLEFT", 10, -34)
    tabRow:SetPoint("TOPRIGHT", -10, -34)
    tabRow:SetHeight(28)

    local defs = {
        { key = "INBOX", label = TM:L("TAB_INBOX") or "Boîte de réception" },
        { key = "SEND",  label = TM:L("TAB_SEND")  or "Envoyer un objet" },
    }
    local tw = (W - 20) / 2
    for i, def in ipairs(defs) do
        local b = CreateTabButton(tabRow, def.label, def.key)
        b:SetSize(tw, 28)
        b:SetPoint("LEFT", (i - 1) * tw, 0)
        b:SetScript("OnClick", function(self) Window:SelectTab(self._key) end)
        tabs[i] = b
    end

    local d2 = win:CreateTexture(nil, "ARTWORK")
    d2:SetHeight(1)
    d2:SetPoint("TOPLEFT", 1, -62)
    d2:SetPoint("TOPRIGHT", -1, -62)
    d2:SetColorTexture(unpack(UI.COLORS.borderDim))

    -- Content pages
    inboxPage = CreateFrame("Frame", nil, win)
    inboxPage:SetPoint("TOPLEFT", 6, -66)
    inboxPage:SetPoint("BOTTOMRIGHT", -6, 8)

    composePage = CreateFrame("Frame", nil, win)
    composePage:SetPoint("TOPLEFT", 6, -66)
    composePage:SetPoint("BOTTOMRIGHT", -6, 8)
    composePage:Hide()

    RestorePos()
end

-- ============================================================
--  Public API
-- ============================================================

function Window:Ensure()
    if not win then
        local ok, err = pcall(Build)
        if not ok then
            TM:Print("|cFFFF4444Window: |r" .. tostring(err))
            return nil
        end
    end
    return win
end

function Window:GetInboxPage()   self:Ensure(); return inboxPage end
function Window:GetComposePage() self:Ensure(); return composePage end
function Window:GetCurrent()     return current end

function Window:SelectTab(key)
    self:Ensure()
    current = key
    for _, b in ipairs(tabs) do b:SetActive(b._key == key) end

    if key == "SEND" then
        if inboxPage then inboxPage:Hide() end
        if composePage then composePage:Show() end
        local C = TM.modules["Compose"]
        if C and C.OnSelect then C:OnSelect() end
    else
        if composePage then composePage:Hide() end
        if inboxPage then inboxPage:Show() end
        local I = TM.modules["Inbox"]
        if I and I.OnSelect then I:OnSelect() end
    end
    ApplyTabHeight(key)
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

function Window:ApplyScale()
    self:Ensure()
    if not win then return end
    local s = TM.db and TM.db.profile and TM.db.profile.mailScale or 1.0
    s = tonumber(s) or 1.0
    if s < 0.6 then s = 0.6 elseif s > 1.6 then s = 1.6 end
    win:SetScale(s)
end

function Window:Show()
    self:Ensure()
    if not win then return end
    HideNativeChrome()
    self:ApplyScale()
    RestorePos()
    win:Show()
    self:SelectTab("INBOX")
end

function Window:Hide()
    if settings then settings:Hide() end
    if fontList then fontList:Hide() end
    if win then win:Hide() end
end

-- ============================================================
--  Re-assert invisibility when Blizzard touches the frame
-- ============================================================

local ef = CreateFrame("Frame")
ef:RegisterEvent("MAIL_SHOW")
ef:RegisterEvent("MAIL_INBOX_UPDATE")
ef:RegisterEvent("MAIL_SEND_SUCCESS")
ef:SetScript("OnEvent", function(_, event)
    if not ModernEnabled() then return end
    if win and win:IsShown() then
        HideNativeChrome()
        if event == "MAIL_SEND_SUCCESS" and current == "SEND" and SendMailFrame then
            pcall(function() SendMailFrame:Show() end)
        end
    end
end)

-- ============================================================
--  Module hooks
-- ============================================================

function Window:OnInitialize() end

function Window:OnMailShow()
    if not ModernEnabled() then return end
    self:Show()
end

function Window:OnMailHide()
    self:Hide()
end

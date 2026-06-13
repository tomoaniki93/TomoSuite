-- TomoMail | Modules/Compose.lua
-- Reparents the native SendMailFrame into the standalone window's compose
-- page (so the real cursor-driven attachment flow and SendMail() stay
-- intact), restyles it dark, binds its text to the live Tomo font objects,
-- and adds coin dots plus a segmented Gold / C.O.D. look.

local TM      = TomoMail
local UI      = TM.UI
local Compose = {}
TM:RegisterModule("Compose", Compose)

local styled  = false
local mounted = false

-- ============================================================
--  Gating
-- ============================================================

local function ModernEnabled()
    if not TM.db then return false end
    local p = TM.db.profile
    return p.skinEnabled ~= false and p.modernUI ~= false
end

-- ============================================================
--  Styling helpers
-- ============================================================

local BACKDROP_DARK = {
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
}

local function StripTextures(frame, ...)
    if not frame or not frame.GetRegions then return end
    local keep = {}
    for i = 1, select("#", ...) do
        local layer = select(i, ...)
        if layer then keep[layer] = true end
    end
    for _, region in pairs({ frame:GetRegions() }) do
        if region:IsObjectType("Texture") then
            local layer = region:GetDrawLayer()
            if not keep[layer] then
                region:SetTexture(nil); region:SetAtlas(""); region:Hide()
            end
        end
    end
end

local function ApplyDarkBackdrop(frame, r, g, b, a)
    if not frame then return end
    r = r or UI.COLORS.bg[1]; g = g or UI.COLORS.bg[2]; b = b or UI.COLORS.bg[3]; a = a or 1
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
        if frame.OnBackdropSizeChanged then
            frame:HookScript("OnSizeChanged", frame.OnBackdropSizeChanged)
        end
    end
    frame:SetBackdrop(BACKDROP_DARK)
    frame:SetBackdropColor(r, g, b, a)
    frame:SetBackdropBorderColor(unpack(UI.COLORS.border))
end

local function setFO(obj, key)
    if obj and obj.SetFontObject and UI._fontObjects and UI._fontObjects[key] then
        pcall(function() obj:SetFontObject(UI._fontObjects[key]) end)
    end
end

local function SkinButton(btn, isPrimary)
    if not btn then return end
    StripTextures(btn)
    ApplyDarkBackdrop(btn, UI.COLORS.bgLight[1], UI.COLORS.bgLight[2], UI.COLORS.bgLight[3], 1)
    local fs = (btn.Text) or (btn.GetFontString and btn:GetFontString())
    if fs then
        setFO(fs, "normal")
        if isPrimary then fs:SetTextColor(unpack(UI.COLORS.accent))
        else fs:SetTextColor(unpack(UI.COLORS.text)) end
    end
    btn:HookScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(UI.COLORS.accent)) end)
    btn:HookScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(UI.COLORS.border)) end)
end

local function SkinEditBox(editbox, fontKey)
    if not editbox then return end
    StripTextures(editbox)
    local name = editbox:GetName()
    if name then
        for _, suffix in pairs({ "Left", "Right", "Mid", "Middle" }) do
            local tex = _G[name .. suffix]
            if tex then tex:SetTexture(nil); tex:Hide() end
        end
    end
    ApplyDarkBackdrop(editbox, UI.COLORS.bgLight[1], UI.COLORS.bgLight[2], UI.COLORS.bgLight[3], 1)
    setFO(editbox, fontKey or "normal")
    editbox:SetTextColor(0.85, 0.85, 0.85)
end

local function AddCoinDot(editbox, r, g, b)
    if not editbox or editbox._tomoDot then return end
    local dot = editbox:CreateTexture(nil, "OVERLAY")
    dot:SetSize(7, 7)
    dot:SetPoint("RIGHT", editbox, "LEFT", -3, 0)
    dot:SetColorTexture(r, g, b, 1)
    editbox._tomoDot = dot
end

-- ============================================================
--  Dark body field
-- ============================================================
-- The native message body lives in SendMailScrollFrame, whose scrollbar shows
-- Blizzard's gold up/down arrows that can't be cleanly dark-themed. Rather than
-- fight them, we drop the scroll frame entirely and present the *same* native
-- SendMailBodyEditBox as a bare multiline field inside a dark holder (the same
-- approach a fully-custom compose uses). The edit box is reused as-is, so
-- SendMail() still reads its text natively; only its container changes.

local bodyHolder

local function EnsureDarkBody()
    if not SendMailFrame or not SendMailBodyEditBox then return end

    -- Build the dark holder once, over the native scroll frame's footprint.
    if not bodyHolder then
        bodyHolder = CreateFrame("Frame", nil, SendMailFrame, "BackdropTemplate")
        bodyHolder:SetBackdrop(BACKDROP_DARK)
        bodyHolder:SetBackdropColor(UI.COLORS.bgLight[1], UI.COLORS.bgLight[2], UI.COLORS.bgLight[3], 1)
        bodyHolder:SetBackdropBorderColor(unpack(UI.COLORS.border))
        if SendMailScrollFrame then
            bodyHolder:SetPoint("TOPLEFT", SendMailScrollFrame, "TOPLEFT", 0, 0)
            bodyHolder:SetPoint("BOTTOMRIGHT", SendMailScrollFrame, "BOTTOMRIGHT", 0, 0)
        end
        bodyHolder:EnableMouse(true)
        bodyHolder:SetScript("OnMouseDown", function()
            if SendMailBodyEditBox then SendMailBodyEditBox:SetFocus() end
        end)
    end

    -- Hide the native scroll frame and its gold-arrow scrollbar.
    if SendMailScrollFrame then
        local sb = SendMailScrollFrame.ScrollBar or _G["SendMailScrollFrameScrollBar"]
        if sb and sb.Hide then sb:Hide() end
        SendMailScrollFrame:Hide()
    end

    -- Reparent the native body edit box as a bare multiline field.
    if SendMailBodyEditBox:GetParent() ~= bodyHolder then
        SendMailBodyEditBox:SetParent(bodyHolder)
    end
    SendMailBodyEditBox:ClearAllPoints()
    SendMailBodyEditBox:SetPoint("TOPLEFT", bodyHolder, "TOPLEFT", 10, -8)
    SendMailBodyEditBox:SetPoint("BOTTOMRIGHT", bodyHolder, "BOTTOMRIGHT", -10, 8)
    pcall(function() SendMailBodyEditBox:SetMultiLine(true) end)
    SendMailBodyEditBox:SetAutoFocus(false)
    -- SendMailBodyEditBox is a ScrollingEditBox: its OnUpdate / OnCursorChanged /
    -- OnTextChanged scripts drive the parent SendMailScrollFrame. Detached from
    -- that scroll frame they call scroll methods the plain holder doesn't have
    -- and error every frame (the error flood + looping error sound). Clear them;
    -- the edit box still scrolls its own display to keep the cursor visible.
    SendMailBodyEditBox:SetScript("OnUpdate", nil)
    SendMailBodyEditBox:SetScript("OnCursorChanged", nil)
    SendMailBodyEditBox:SetScript("OnTextChanged", nil)
    setFO(SendMailBodyEditBox, "normal")
    SendMailBodyEditBox:SetTextColor(0.85, 0.85, 0.85)
    SendMailBodyEditBox:EnableMouse(true)
    SendMailBodyEditBox:Show()
end

-- ============================================================
--  Segmented Gold / C.O.D.
-- ============================================================

local function GetCheckLabel(btn)
    if not btn then return nil end
    local fs = btn.GetFontString and btn:GetFontString()
    if fs then return fs end
    local name = btn:GetName()
    if name then return _G[name .. "Text"] end
    return nil
end

local function RefreshMoneyType()
    local sendBtn = SendMailSendMoneyButton
    local sendOn = false
    pcall(function() sendOn = sendBtn and sendBtn:GetChecked() and true or false end)
    local sLabel = GetCheckLabel(SendMailSendMoneyButton)
    local cLabel = GetCheckLabel(SendMailCODButton)
    if sLabel then
        setFO(sLabel, "small")
        sLabel:SetTextColor(sendOn and UI.COLORS.accent[1] or UI.COLORS.textDim[1],
                            sendOn and UI.COLORS.accent[2] or UI.COLORS.textDim[2],
                            sendOn and UI.COLORS.accent[3] or UI.COLORS.textDim[3])
    end
    if cLabel then
        setFO(cLabel, "small")
        if not sendOn then cLabel:SetTextColor(0.88, 0.69, 0.25)
        else cLabel:SetTextColor(unpack(UI.COLORS.textDim)) end
    end
end

local function SetupMoneyTypeSegment()
    local sendBtn = SendMailSendMoneyButton
    local codBtn  = SendMailCODButton
    if not sendBtn or not codBtn then return end
    if not sendBtn._tomoPill then
        local pill = CreateFrame("Frame", nil, SendMailFrame, "BackdropTemplate")
        pill:SetFrameLevel(math.max(0, sendBtn:GetFrameLevel() - 1))
        pill:SetPoint("TOPLEFT", sendBtn, "TOPLEFT", -4, 4)
        pill:SetPoint("BOTTOMRIGHT", codBtn, "BOTTOMRIGHT", 4, -4)
        pill:SetBackdrop(BACKDROP_DARK)
        pill:SetBackdropColor(UI.COLORS.bgLight[1], UI.COLORS.bgLight[2], UI.COLORS.bgLight[3], 0.6)
        pill:SetBackdropBorderColor(unpack(UI.COLORS.border))
        sendBtn._tomoPill = pill
    end
    sendBtn:HookScript("OnClick", function() C_Timer.After(0, RefreshMoneyType) end)
    codBtn:HookScript("OnClick", function() C_Timer.After(0, RefreshMoneyType) end)
    RefreshMoneyType()
end

-- ============================================================
--  One-time styling
-- ============================================================

local function StyleOnce()
    if styled then return end
    if not SendMailFrame then return end
    styled = true

    StripTextures(SendMailFrame)

    SkinEditBox(SendMailNameEditBox, "normal")
    SkinEditBox(SendMailSubjectEditBox, "normal")
    SkinEditBox(SendMailMoneyGold, "small")
    SkinEditBox(SendMailMoneySilver, "small")
    SkinEditBox(SendMailMoneyCopper, "small")

    AddCoinDot(SendMailMoneyGold,   1.00, 0.82, 0.00)
    AddCoinDot(SendMailMoneySilver, 0.75, 0.75, 0.75)
    AddCoinDot(SendMailMoneyCopper, 0.72, 0.43, 0.25)

    -- The message body (native scroll frame + its gold scrollbar) is replaced
    -- by a bare dark multiline field in EnsureDarkBody(), called from Mount().

    for i = 1, (ATTACHMENTS_MAX_SEND or 12) do
        local slot = _G["SendMailAttachment" .. i]
        if slot then
            StripTextures(slot, "OVERLAY", "ARTWORK")
            ApplyDarkBackdrop(slot, UI.COLORS.bgLight[1], UI.COLORS.bgLight[2], UI.COLORS.bgLight[3], 1)
        end
    end

    SkinButton(SendMailMailButton, true)
    SkinButton(SendMailCancelButton)

    pcall(SetupMoneyTypeSegment)

    pcall(function()
        if SendMailMoneyText then setFO(SendMailMoneyText, "small"); SendMailMoneyText:SetTextColor(unpack(UI.COLORS.textDim)) end
    end)
    pcall(function()
        if SendMailCostMoneyFrame then
            for _, region in pairs({ SendMailCostMoneyFrame:GetRegions() }) do
                if region:IsObjectType("FontString") then
                    setFO(region, "small")
                    region:SetTextColor(unpack(UI.COLORS.textDim))
                end
            end
        end
    end)

    -- Best-effort: strip the ornate gold border around the money frames
    -- (player money / money input). Coin icons live in fontstrings/child
    -- textures and are preserved; only border/background art is removed.
    -- Player-money display: drop Blizzard's ornate gold inset + background
    -- (frame names confirmed in-game) and remove any editbox-style border
    -- pieces on the money frames, while keeping the coin amounts intact.
    pcall(function()
        if SendMailMoneyInset then SendMailMoneyInset:Hide() end
        if SendMailMoneyBg then SendMailMoneyBg:Hide() end
        for _, n in ipairs({ "SendMailMoneyButton", "SendMailMoneyFrame" }) do
            local f = _G[n]
            if f then
                if f.NineSlice then f.NineSlice:Hide() end
                if f.Border then f.Border:Hide() end
                if f.Left then f.Left:Hide() end
                if f.Right then f.Right:Hide() end
                if f.Middle then f.Middle:Hide() end
                local nm = f:GetName()
                if nm then
                    for _, suffix in pairs({ "Left", "Right", "Middle", "Border", "Background" }) do
                        local tex = _G[nm .. suffix]
                        if tex and tex.Hide then tex:Hide() end
                    end
                end
            end
        end
    end)
end

-- ============================================================
--  Mount the native send frame inside our compose page
-- ============================================================

function Compose:Mount()
    if not SendMailFrame then return end
    local page = TM.Window and TM.Window:GetComposePage()
    if not page then return end

    UI:RefreshFonts()

    if not mounted then
        local ok = pcall(function()
            -- Preserve Blizzard's native compose proportions when available,
            -- otherwise fall back to sensible defaults so GetHeight() is sound.
            local nw, nh = SendMailFrame:GetSize()
            if not (nw and nw > 80) then nw = 360 end
            if not (nh and nh > 120) then nh = 480 end
            SendMailFrame:SetParent(page)
            SendMailFrame:ClearAllPoints()
            SendMailFrame:SetSize(nw, nh)
            SendMailFrame:SetPoint("TOP", page, "TOP", 0, -8)
        end)
        if ok then mounted = true end
    end

    pcall(function() SendMailFrame:Show() end)
    pcall(StyleOnce)
    pcall(EnsureDarkBody)
    pcall(RefreshMoneyType)
end

-- ============================================================
--  Module hooks
-- ============================================================

function Compose:OnInitialize() end

function Compose:OnSelect()
    if not ModernEnabled() then return end
    local ok, err = pcall(function() Compose:Mount() end)
    if not ok then TM:Print("|cFFFF4444Compose: |r" .. tostring(err)) end
end

function Compose:OnMailShow()
    -- Mounting is deferred to the first "Send" tab selection.
end

-- TomoMail | Modules/Skin.lua
-- Reskin Blizzard mail frames in the dark TomoSuite theme

local TM = TomoMail
local UI = TM.UI
local Skin = {}
TM:RegisterModule("Skin", Skin)

local skinApplied = false

-- ============================================================
--  Helpers
-- ============================================================

local BACKDROP_DARK = {
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
}

--- Strip all non-essential textures from a region
local function StripTextures(frame, ...)
    if not frame or not frame.GetRegions then return end
    local keepLayers = {}
    for i = 1, select("#", ...) do
        local layer = select(i, ...)
        if layer then keepLayers[layer] = true end
    end

    for _, region in pairs({ frame:GetRegions() }) do
        if region:IsObjectType("Texture") then
            local layer = region:GetDrawLayer()
            if not keepLayers[layer] then
                region:SetTexture(nil)
                region:SetAtlas("")
                region:Hide()
            end
        end
    end
end

--- Apply dark backdrop to a frame
local function ApplyDarkBackdrop(frame, r, g, b, a, br, bg, bb)
    r  = r  or UI.COLORS.bg[1]
    g  = g  or UI.COLORS.bg[2]
    b  = b  or UI.COLORS.bg[3]
    a  = a  or 1
    br = br or UI.COLORS.border[1]
    bg = bg or UI.COLORS.border[2]
    bb = bb or UI.COLORS.border[3]

    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
        frame:HookScript("OnSizeChanged", frame.OnBackdropSizeChanged)
    end

    frame:SetBackdrop(BACKDROP_DARK)
    frame:SetBackdropColor(r, g, b, a)
    frame:SetBackdropBorderColor(br, bg, bb, 1)
end

--- Skin a standard Blizzard button
local function SkinButton(btn, isPrimary)
    if not btn then return end

    StripTextures(btn)

    ApplyDarkBackdrop(btn,
        UI.COLORS.bgLight[1], UI.COLORS.bgLight[2], UI.COLORS.bgLight[3], 1)

    if btn.Text then
        if isPrimary then
            btn.Text:SetTextColor(unpack(UI.COLORS.accent))
        else
            btn.Text:SetTextColor(unpack(UI.COLORS.text))
        end
    elseif btn.GetFontString then
        local fs = btn:GetFontString()
        if fs then
            if isPrimary then
                fs:SetTextColor(unpack(UI.COLORS.accent))
            else
                fs:SetTextColor(unpack(UI.COLORS.text))
            end
        end
    end

    btn:HookScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(UI.COLORS.accent))
    end)
    btn:HookScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(UI.COLORS.border))
    end)
end

--- Skin an EditBox
local function SkinEditBox(editbox)
    if not editbox then return end

    -- Try stripping existing textures
    StripTextures(editbox)

    -- Remove named sub-textures
    local name = editbox:GetName()
    if name then
        for _, suffix in pairs({ "Left", "Right", "Mid", "Middle" }) do
            local tex = _G[name .. suffix]
            if tex then
                tex:SetTexture(nil)
                tex:Hide()
            end
        end
    end

    ApplyDarkBackdrop(editbox,
        UI.COLORS.bgLight[1], UI.COLORS.bgLight[2], UI.COLORS.bgLight[3], 1)

    editbox:SetTextColor(0.85, 0.85, 0.85)
end

-- ============================================================
--  Skin the main MailFrame container
-- ============================================================

local function SkinMailFrame()
    local mf = MailFrame
    if not mf then return end

    -- Strip the ornate Blizzard border / parchment textures
    StripTextures(mf)

    -- Apply dark backdrop
    ApplyDarkBackdrop(mf)

    -- Title text
    if MailFrameTitleText then
        MailFrameTitleText:SetTextColor(unpack(UI.COLORS.accent))
    end

    -- Close button — leave untouched so the X stays visible
    -- (Blizzard close buttons use Normal/Pushed/Highlight textures)

    -- Tab buttons at the bottom
    for i = 1, 2 do
        local tab = _G["MailFrameTab" .. i]
        if tab then
            StripTextures(tab)
            ApplyDarkBackdrop(tab,
                UI.COLORS.bgLight[1], UI.COLORS.bgLight[2], UI.COLORS.bgLight[3], 1)

            local fs = tab:GetFontString()
            if fs then fs:SetTextColor(unpack(UI.COLORS.text)) end

            tab:HookScript("OnEnter", function(self)
                self:SetBackdropBorderColor(unpack(UI.COLORS.accent))
            end)
            tab:HookScript("OnLeave", function(self)
                self:SetBackdropBorderColor(unpack(UI.COLORS.border))
            end)
        end
    end
end

-- ============================================================
--  Skin the Inbox (InboxFrame)
-- ============================================================

local function SkinInbox()
    local inbox = InboxFrame
    if not inbox then return end

    StripTextures(inbox)

    -- Skin each mail item row
    for i = 1, INBOXITEMS_TO_DISPLAY or 7 do
        local item = _G["MailItem" .. i]
        if item then
            StripTextures(item)

            -- Dark row background
            local rowBg = item:CreateTexture(nil, "BACKGROUND")
            rowBg:SetAllPoints()
            rowBg:SetColorTexture(UI.COLORS.bgLight[1], UI.COLORS.bgLight[2], UI.COLORS.bgLight[3], 0.5)

            -- Row divider
            local divider = item:CreateTexture(nil, "BORDER")
            divider:SetHeight(1)
            divider:SetPoint("BOTTOMLEFT", item, "BOTTOMLEFT", 0, 0)
            divider:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", 0, 0)
            divider:SetColorTexture(UI.COLORS.borderDim[1], UI.COLORS.borderDim[2], UI.COLORS.borderDim[3], 1)

            -- Hover highlight
            local hl = item:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(UI.COLORS.bgHover[1], UI.COLORS.bgHover[2], UI.COLORS.bgHover[3], 0.6)

            -- Skin the item button/icon
            local button = _G["MailItem" .. i .. "Button"]
            if button then
                StripTextures(button, "OVERLAY", "ARTWORK")
                ApplyDarkBackdrop(button,
                    UI.COLORS.bg[1], UI.COLORS.bg[2], UI.COLORS.bg[3], 1)
            end

            -- Color the sender/subject text
            local sender = _G["MailItem" .. i .. "Sender"]
            if sender then
                sender:SetTextColor(0.85, 0.85, 0.85)
            end

            local subject = _G["MailItem" .. i .. "Subject"]
            if subject then
                subject:SetTextColor(unpack(UI.COLORS.textDim))
            end
        end
    end

    -- Navigation buttons — keep arrow textures, don't strip
    -- Just leave them as-is so Préc/Suiv arrows remain visible

    -- "Tout ouvrir" (OpenAllMail) button
    if OpenAllMail then
        SkinButton(OpenAllMail, true)
    end
end

-- ============================================================
--  Skin the Send Mail frame
-- ============================================================

local function SkinSendMail()
    local sm = SendMailFrame
    if not sm then return end

    StripTextures(sm)

    -- Edit boxes: To, Subject
    SkinEditBox(SendMailNameEditBox)
    SkinEditBox(SendMailSubjectEditBox)

    -- Money fields
    SkinEditBox(SendMailMoneyGold)
    SkinEditBox(SendMailMoneySilver)
    SkinEditBox(SendMailMoneyCopper)

    -- Body scroll frame
    if SendMailScrollFrame then
        StripTextures(SendMailScrollFrame)
        ApplyDarkBackdrop(SendMailScrollFrame,
            UI.COLORS.bgLight[1], UI.COLORS.bgLight[2], UI.COLORS.bgLight[3], 1)
    end

    -- Body editbox
    if SendMailBodyEditBox then
        SendMailBodyEditBox:SetTextColor(0.8, 0.8, 0.8)
    end

    -- Attachment item slots
    for i = 1, ATTACHMENTS_MAX_SEND or 7 do
        local slot = _G["SendMailAttachment" .. i]
        if slot then
            StripTextures(slot, "OVERLAY", "ARTWORK")
            ApplyDarkBackdrop(slot,
                UI.COLORS.bgLight[1], UI.COLORS.bgLight[2], UI.COLORS.bgLight[3], 1)
        end
    end

    -- Send & Cancel buttons
    SkinButton(SendMailMailButton, true)
    SkinButton(SendMailCancelButton)

    -- Stationery / radio buttons for COD / money
    pcall(function()
        if SendMailSendMoneyButton then
            local fs = SendMailSendMoneyButton:GetFontString() or _G["SendMailSendMoneyButtonText"]
            if fs then fs:SetTextColor(unpack(UI.COLORS.text)) end
        end
        if SendMailCODButton then
            local fs = SendMailCODButton:GetFontString() or _G["SendMailCODButtonText"]
            if fs then fs:SetTextColor(unpack(UI.COLORS.text)) end
        end
    end)

    -- "Montant à envoyer" label
    pcall(function()
        if SendMailMoneyText then
            SendMailMoneyText:SetTextColor(unpack(UI.COLORS.textDim))
        end
    end)

    -- "Port:" cost label
    pcall(function()
        if SendMailCostMoneyFrame then
            -- Find text children
            for _, region in pairs({ SendMailCostMoneyFrame:GetRegions() }) do
                if region:IsObjectType("FontString") then
                    region:SetTextColor(unpack(UI.COLORS.textDim))
                end
            end
        end
    end)
end

-- ============================================================
--  Skin the OpenMail (reading) frame
-- ============================================================

local function SkinOpenMail()
    local om = OpenMailFrame
    if not om then return end

    StripTextures(om)
    ApplyDarkBackdrop(om)

    -- Title
    if OpenMailFrameTitleText then
        OpenMailFrameTitleText:SetTextColor(unpack(UI.COLORS.accent))
    end

    -- Sender
    if OpenMailSender then
        OpenMailSender:SetTextColor(0.85, 0.85, 0.85)
    end

    -- Subject
    if OpenMailSubject then
        OpenMailSubject:SetTextColor(unpack(UI.COLORS.text))
    end

    -- Body scroll
    if OpenMailScrollFrame then
        StripTextures(OpenMailScrollFrame)
        ApplyDarkBackdrop(OpenMailScrollFrame,
            UI.COLORS.bgLight[1], UI.COLORS.bgLight[2], UI.COLORS.bgLight[3], 1)
    end

    -- Body text
    if OpenMailBodyText then
        OpenMailBodyText:SetTextColor(0.8, 0.8, 0.8)
    end

    -- Buttons
    SkinButton(OpenMailReplyButton, true)
    SkinButton(OpenMailDeleteButton)
    SkinButton(OpenMailCancelButton)
    SkinButton(OpenMailReportSpamButton)

    -- Close button
    -- Close button — leave untouched so the X stays visible

    -- Money frame
    pcall(function()
        if OpenMailMoneyButton then
            StripTextures(OpenMailMoneyButton, "OVERLAY", "ARTWORK")
            ApplyDarkBackdrop(OpenMailMoneyButton,
                UI.COLORS.bgLight[1], UI.COLORS.bgLight[2], UI.COLORS.bgLight[3], 1)
        end
    end)

    -- Attachment slots
    for i = 1, ATTACHMENTS_MAX_RECEIVE or 16 do
        local slot = _G["OpenMailAttachmentButton" .. i]
        if slot then
            StripTextures(slot, "OVERLAY", "ARTWORK")
            ApplyDarkBackdrop(slot,
                UI.COLORS.bgLight[1], UI.COLORS.bgLight[2], UI.COLORS.bgLight[3], 1)
        end
    end
end

-- ============================================================
--  Scale management
-- ============================================================

local function ApplyScale()
    if not MailFrame then return end
    local scale = TM.db and TM.db.profile.mailScale or 1.0
    MailFrame:SetScale(scale)
end

function Skin:UpdateScale(scale)
    if not TM.db then return end
    TM.db.profile.mailScale = scale
    ApplyScale()
end

function Skin:GetScale()
    return TM.db and TM.db.profile.mailScale or 1.0
end

-- ============================================================
--  Apply all skins
-- ============================================================

local function ApplySkin()
    if skinApplied then return end

    -- Check if skinning is enabled
    if TM.db and TM.db.profile.skinEnabled == false then return end

    skinApplied = true

    -- Wrap each section in pcall for robustness
    local sections = {
        { "MailFrame",  SkinMailFrame },
        { "Inbox",      SkinInbox },
        { "SendMail",   SkinSendMail },
        { "OpenMail",   SkinOpenMail },
    }

    for _, sec in ipairs(sections) do
        local ok, err = pcall(sec[2])
        if not ok then
            TM:Print("|cFFFF4444Skin " .. sec[1] .. ":|r " .. tostring(err))
        end
    end
end

-- ============================================================
--  Module hooks
-- ============================================================

function Skin:OnInitialize()
    if MailFrame then
        ApplySkin()
        ApplyScale()
    end
end

function Skin:OnMailShow()
    ApplySkin()
    ApplyScale()
end

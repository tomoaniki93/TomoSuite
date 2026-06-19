-- TomoMail | Modules/Inbox.lua
-- Modern API-driven inbox list mounted inside the standalone TomoMail
-- window. Search, category filters, rich rows (left accent bar, sender
-- class color, attachment preview, money/COD, colored expiry), hover
-- quick-actions and an integrated reader. Fully driven by the public
-- mail API.

local TM    = TomoMail
local UI    = TM.UI
local Inbox = {}
TM:RegisterModule("Inbox", Inbox)

-- ============================================================
--  Local state
-- ============================================================

local panel        = nil
local reader       = nil
local rowPool      = {}
local activeRows   = {}
local activeFilter = "ALL"          -- ALL | PLAYER | AUCTION | SYSTEM
local takeTicker   = nil

local CAT_PLAYER  = "PLAYER"
local CAT_AUCTION = "AUCTION"
local CAT_SYSTEM  = "SYSTEM"

local COLOR_AUCTION = { 0.88, 0.69, 0.25 }
local COLOR_SYSTEM  = { 0.75, 0.56, 0.88 }
local COLOR_GREEN   = { 0.37, 0.82, 0.48 }
local COLOR_AMBER   = { 0.88, 0.66, 0.23 }
local COLOR_RED     = { 0.89, 0.33, 0.31 }

local ROW_H  = 44
local AVATAR = 24

-- ============================================================
--  Gating
-- ============================================================

local function ModernEnabled()
    if not TM.db then return false end
    local p = TM.db.profile
    return p.skinEnabled ~= false and p.modernUI ~= false
end

-- ============================================================
--  Helpers
-- ============================================================

local function ResolveSenderClass(name)
    local C = TM.modules and TM.modules["Contacts"]
    if C and C.ResolveClass then
        local ok, class = pcall(function() return C:ResolveClass(name) end)
        if ok then return class end
    end
    return nil
end

local function CategorizeMail(index, sender)
    local isInvoice = false
    pcall(function()
        local t = GetInboxInvoiceInfo and GetInboxInvoiceInfo(index)
        if t then isInvoice = true end
    end)
    if isInvoice then return CAT_AUCTION, nil end
    if not sender or sender == "" then return CAT_SYSTEM, nil end
    local class = ResolveSenderClass(sender)
    if class then return CAT_PLAYER, class end
    return CAT_PLAYER, nil
end

local function FormatExpiry(daysLeft)
    daysLeft = tonumber(daysLeft) or 0
    local text
    if daysLeft >= 1 then
        text = string.format("%dj", math.floor(daysLeft))
    else
        local hours = math.floor(daysLeft * 24 + 0.5)
        if hours < 1 then hours = 1 end
        text = string.format("%dh", hours)
    end
    local color
    if daysLeft >= 7 then color = COLOR_GREEN
    elseif daysLeft >= 3 then color = COLOR_AMBER
    else color = COLOR_RED end
    return text, color
end

local function CategoryColor(entry)
    if entry.category == CAT_AUCTION then return unpack(COLOR_AUCTION) end
    if entry.category == CAT_SYSTEM then return unpack(COLOR_SYSTEM) end
    if entry.class then return TM:ClassColorRGB(entry.class) end
    return 0.82, 0.82, 0.86
end

-- ============================================================
--  Data gathering (pure public API)
-- ============================================================

local function BuildInboxData()
    local list = {}
    local num = 0
    pcall(function() num = (GetInboxNumItems and GetInboxNumItems()) or 0 end)

    for index = 1, num do
        local ok, packageIcon, stationeryIcon, sender, subject, money,
              codAmount, daysLeft, itemCount, wasRead = pcall(GetInboxHeaderInfo, index)
        if ok then
            sender  = sender  or ""
            subject = subject or ""

            local items, shown = {}, 0
            for j = 1, (ATTACHMENTS_MAX_RECEIVE or 16) do
                local iok, iname, itemID, texture, count, quality = pcall(GetInboxItem, index, j)
                if iok and texture then
                    shown = shown + 1
                    if #items < 3 then
                        table.insert(items, { texture = texture, count = count or 0, quality = quality })
                    end
                end
            end
            local extra = (shown > 3) and (shown - 3) or 0
            local category, classToken = CategorizeMail(index, sender)

            table.insert(list, {
                index    = index,
                sender   = sender,
                subject  = subject,
                money    = tonumber(money) or 0,
                cod      = tonumber(codAmount) or 0,
                daysLeft = tonumber(daysLeft) or 0,
                wasRead  = wasRead and true or false,
                items    = items,
                extra    = extra,
                category = category,
                class    = classToken,
            })
        end
    end
    return list
end

local function PassesFilters(entry, searchText)
    if activeFilter ~= "ALL" and entry.category ~= activeFilter then return false end
    if searchText and searchText ~= "" then
        local s = (entry.sender .. " " .. entry.subject):lower()
        if not s:find(searchText, 1, true) then return false end
    end
    return true
end

-- ============================================================
--  Row pool
-- ============================================================

local ICON_MIN, ICON_MAX = 18, 36
local function GetIconSize()
    local n = TM.db and TM.db.profile and TM.db.profile.inboxIconSize
    n = tonumber(n) or 30
    if n < ICON_MIN then n = ICON_MIN elseif n > ICON_MAX then n = ICON_MAX end
    return n
end

local function MakeIconSlot(parent)
    local slot = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    local sz = GetIconSize()
    slot:SetSize(sz, sz)
    slot:SetBackdrop(UI.BACKDROP)
    slot:SetBackdropColor(UI.COLORS.bg[1], UI.COLORS.bg[2], UI.COLORS.bg[3], 1)
    slot:SetBackdropBorderColor(unpack(UI.COLORS.border))
    slot.tex = slot:CreateTexture(nil, "ARTWORK")
    slot.tex:SetPoint("TOPLEFT", 1, -1)
    slot.tex:SetPoint("BOTTOMRIGHT", -1, 1)
    slot.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    slot.count = UI:FS(slot, "tiny")
    slot.count:SetPoint("BOTTOMRIGHT", 0, 0)
    slot:Hide()
    return slot
end

local function MakeActionButton(parent, glyphTex, glyphText)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(24, 24)
    b:SetBackdrop(UI.BACKDROP)
    b:SetBackdropColor(UI.COLORS.bg[1], UI.COLORS.bg[2], UI.COLORS.bg[3], 1)
    b:SetBackdropBorderColor(unpack(UI.COLORS.border))
    if glyphTex then
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetPoint("CENTER")
        b.icon:SetSize(14, 14)
        b.icon:SetTexture(glyphTex)
        b.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    else
        b.txt = UI:FS(b, "normal")
        b.txt:SetPoint("CENTER", 0, 0)
        b.txt:SetText(glyphText or "?")
        b.txt:SetTextColor(unpack(UI.COLORS.textDim))
    end
    return b
end

local function AcquireRow(parent)
    local row = table.remove(rowPool)
    if row then
        row:SetParent(parent)
        row:Show()
        return row
    end

    row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_H)
    UI:AddRowHighlight(row)

    -- left accent bar (category / class colour)
    row.accent = row:CreateTexture(nil, "ARTWORK")
    row.accent:SetWidth(3)
    row.accent:SetPoint("TOPLEFT", 0, -3)
    row.accent:SetPoint("BOTTOMLEFT", 0, 3)

    -- bottom divider
    row.divider = row:CreateTexture(nil, "BORDER")
    row.divider:SetHeight(1)
    row.divider:SetPoint("BOTTOMLEFT", 8, 0)
    row.divider:SetPoint("BOTTOMRIGHT", -4, 0)
    row.divider:SetColorTexture(unpack(UI.COLORS.borderDim))

    -- avatar
    row.avatar = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.avatar:SetSize(AVATAR, AVATAR)
    row.avatar:SetPoint("LEFT", row, "LEFT", 12, 0)
    row.avatar:SetBackdrop(UI.BACKDROP)
    row.avatar:SetBackdropColor(UI.COLORS.bgLight[1], UI.COLORS.bgLight[2], UI.COLORS.bgLight[3], 1)
    row.avatar.initial = UI:FS(row.avatar, "normal")
    row.avatar.initial:SetPoint("CENTER")

    -- unread badge (top-right of avatar)
    row.badge = row:CreateTexture(nil, "OVERLAY")
    row.badge:SetSize(7, 7)
    row.badge:SetPoint("TOPRIGHT", row.avatar, "TOPRIGHT", 2, 2)
    row.badge:SetColorTexture(unpack(UI.COLORS.accent))

    -- sender / expiry / subject
    row.sender = UI:FS(row, "normal")
    row.sender:SetPoint("TOPLEFT", row.avatar, "TOPRIGHT", 8, -1)
    row.sender:SetJustifyH("LEFT")
    row.sender:SetWordWrap(false)

    row.expiry = UI:FS(row, "small")
    row.expiry:SetPoint("TOPRIGHT", row, "TOPRIGHT", -10, -5)
    row.expiry:SetJustifyH("RIGHT")

    row.subject = UI:FS(row, "small")
    row.subject:SetPoint("BOTTOMLEFT", row.avatar, "BOTTOMRIGHT", 8, 1)
    row.subject:SetJustifyH("LEFT")
    row.subject:SetWordWrap(false)
    row.subject:SetTextColor(unpack(UI.COLORS.textDim))

    -- preview cluster
    row.money = UI:FS(row, "small")
    row.money:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -10, 5)

    row.icons = {}
    for i = 1, 3 do
        local s = MakeIconSlot(row)
        row.icons[i] = s
    end
    row.extra = UI:FS(row, "small")
    row.extra:SetTextColor(unpack(UI.COLORS.textDim))

    -- hover actions
    row.actions = CreateFrame("Frame", nil, row)
    row.actions:SetSize(56, ROW_H)
    row.actions:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.actions:Hide()
    local bg = row.actions:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(UI.COLORS.bgHover[1], UI.COLORS.bgHover[2], UI.COLORS.bgHover[3], 0.95)

    row.btnTake = MakeActionButton(row.actions, "Interface\\Icons\\INV_Misc_Coin_01", nil)
    row.btnTake:SetPoint("RIGHT", row.actions, "RIGHT", -2, 0)
    row.btnDelete = MakeActionButton(row.actions, nil, "×")
    row.btnDelete:SetPoint("RIGHT", row.btnTake, "LEFT", -4, 0)

    row:SetScript("OnEnter", function(self) if self._index then self.actions:Show() end end)
    row:SetScript("OnLeave", function(self)
        if not self.actions:IsMouseOver() then self.actions:Hide() end
    end)
    row.actions:SetScript("OnLeave", function(self)
        if not row:IsMouseOver() then self:Hide() end
    end)

    return row
end

local function ReleaseAllRows()
    for _, row in ipairs(activeRows) do
        row:Hide()
        row:ClearAllPoints()
        row.actions:Hide()
        row._index = nil
        table.insert(rowPool, row)
    end
    wipe(activeRows)
end

-- ============================================================
--  Action handlers
-- ============================================================

-- Reading/taking/deleting mail flips the "pending mail" state, which on the
-- Midnight build triggers a Blizzard bug in the minimap mail-reminder handler
-- (Blizzard_Minimap/Minimap.lua: "attempt to call a nil value"). We swap the
-- error handler for the duration of a single mail call to swallow ONLY that
-- specific Blizzard error, then restore it immediately so every other error
-- (including our own) is still reported normally.
local function WithMinimapErrorGuard(fn)
    local orig = geterrorhandler and geterrorhandler()
    if orig and seterrorhandler then
        seterrorhandler(function(msg)
            if type(msg) == "string" and msg:find("Blizzard_Minimap", 1, true) then return end
            return orig(msg)
        end)
    end
    pcall(fn)
    if orig and seterrorhandler then seterrorhandler(orig) end
end

-- The minimap "new mail" indicator. Blizzard's own UPDATE_PENDING_MAIL handler
-- is broken on Midnight (a nil call inside Blizzard_Minimap): it can throw
-- before it finishes hiding the icon, leaving it stuck "on" even after the
-- inbox has been emptied. We drive the indicator ourselves from the
-- authoritative HasNewMail() instead. The frame path differs across clients,
-- so probe the known candidates and no-op if none is found.
local function GetMailIndicator()
    -- Confirmed on Midnight via /fstack: the reminder frame is
    -- MinimapCluster.IndicatorFrame.MailFrame, with MiniMapMailIcon as its
    -- texture. Use the explicit path first, then the texture's parent, then
    -- legacy names, so we always hold the frame whose visibility IS the icon.
    local mc = MinimapCluster
    if mc and mc.IndicatorFrame and mc.IndicatorFrame.MailFrame then
        return mc.IndicatorFrame.MailFrame
    end
    if MiniMapMailIcon and MiniMapMailIcon.GetParent then
        local p = MiniMapMailIcon:GetParent()
        if p and p.SetShown then return p end
    end
    if mc and mc.MailFrame then return mc.MailFrame end
    if MiniMapMailFrame then return MiniMapMailFrame end
    return nil
end

-- Whether the minimap mail icon should be lit. While the mailbox is open the
-- inbox item count is authoritative (an empty inbox forces the icon off, which
-- guards against a stuck "new mail" flag); otherwise fall back to HasNewMail().
local function ShouldShowMailIcon()
    local has = false
    pcall(function() has = (HasNewMail and HasNewMail()) and true or false end)
    local boxOpen = false
    pcall(function() boxOpen = (MailFrame and MailFrame.IsShown and MailFrame:IsShown()) and true or false end)
    if boxOpen then
        local n
        pcall(function() n = GetInboxNumItems and GetInboxNumItems() end)
        if type(n) == "number" and n <= 0 then return false end
    end
    return has
end

local function SyncMinimapMail()
    pcall(function()
        local f = GetMailIndicator()
        if not f or not f.SetShown then return end
        f:SetShown(ShouldShowMailIcon())
    end)
end

local function SafeReadBody(index)
    local body = ""
    WithMinimapErrorGuard(function()
        local txt = GetInboxText and GetInboxText(index)
        if txt and txt ~= "" then body = txt end
    end)
    return body
end

local function RefreshSoon()
    pcall(function() if CheckInbox then CheckInbox() end end)
    C_Timer.After(0.10, function() Inbox:Populate(); SyncMinimapMail() end)
end

local function DoTake(index)
    -- Taking attachments in the native UI opens (reads) the mail, clearing its
    -- unread flag. We take via AutoLootMailItem without opening, so mark the
    -- mail read as well — otherwise a mail that keeps a text body stays "unread"
    -- and the minimap mail icon never goes out (regression vs the native UI).
    WithMinimapErrorGuard(function()
        if GetInboxText then GetInboxText(index) end
        if AutoLootMailItem then AutoLootMailItem(index) end
    end)
    RefreshSoon()
end

local function DoDelete(index)
    local canDelete = true
    pcall(function()
        if InboxItemCanDelete then canDelete = InboxItemCanDelete(index) and true or false end
    end)
    if canDelete then
        WithMinimapErrorGuard(function() if DeleteInboxItem then DeleteInboxItem(index) end end)
    else
        TM:Print("|cFFFF7878" .. (TM:L("INBOX_CANT_DELETE") or "Courrier non vide.") .. "|r")
    end
    RefreshSoon()
end

local function StartTakeAll()
    if takeTicker then return end
    takeTicker = C_Timer.NewTicker(0.30, function()
        local target = nil
        local num = 0
        pcall(function() num = (GetInboxNumItems and GetInboxNumItems()) or 0 end)
        for index = num, 1, -1 do
            local ok, _, _, _, _, money, cod, _, itemCount = pcall(GetInboxHeaderInfo, index)
            if ok then
                local hasMoney = (tonumber(money) or 0) > 0
                local hasItems = (tonumber(itemCount) or 0) > 0
                local isCOD    = (tonumber(cod) or 0) > 0
                if (hasMoney or hasItems) and not isCOD then target = index; break end
            end
        end
        if target then
            WithMinimapErrorGuard(function()
                if GetInboxText then GetInboxText(target) end
                if AutoLootMailItem then AutoLootMailItem(target) end
            end)
        else
            if takeTicker then takeTicker:Cancel(); takeTicker = nil end
            RefreshSoon()
        end
    end, 40)
end

-- ============================================================
--  Populate the list
-- ============================================================

function Inbox:Populate()
    if not panel then return end
    ReleaseAllRows()

    local searchText = ""
    if panel.search and panel.search.editbox then
        searchText = panel.search.editbox:GetText():lower()
    end

    local data = BuildInboxData()
    local scrollChild = panel.scrollChild
    local yOffset = 0
    local shownCount, unreadCount = 0, 0

    for _, entry in ipairs(data) do
        if not entry.wasRead then unreadCount = unreadCount + 1 end
        if PassesFilters(entry, searchText) then
            local row = AcquireRow(scrollChild)
            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
            row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -yOffset)
            row:SetHeight(ROW_H)
            row._index = entry.index

            row.avatar:Show()
            row.subject:ClearAllPoints()
            row.subject:SetPoint("BOTTOMLEFT", row.avatar, "BOTTOMRIGHT", 8, 1)
            row.subject:SetJustifyH("LEFT")

            local ar, ag, ab = CategoryColor(entry)
            row.accent:SetColorTexture(ar, ag, ab, entry.wasRead and 0.5 or 1.0)
            row.avatar:SetBackdropBorderColor(ar, ag, ab, 0.9)
            row.avatar.initial:SetText((entry.sender ~= "" and entry.sender:sub(1, 1):upper()) or "?")
            row.avatar.initial:SetTextColor(ar, ag, ab)

            if entry.wasRead then row.badge:Hide() else row.badge:Show() end

            row.sender:SetText(entry.sender ~= "" and entry.sender or (TM:L("INBOX_SYSTEM") or "Système"))
            row.sender:SetTextColor(ar, ag, ab)
            row.subject:SetText(entry.subject ~= "" and entry.subject or "—")

            local exTxt, exCol = FormatExpiry(entry.daysLeft)
            row.expiry:SetText(exTxt)
            row.expiry:SetTextColor(unpack(exCol))

            if entry.cod > 0 then
                row.money:SetText("|cFFD99A55C.R.|r " .. (GetCoinTextureString and GetCoinTextureString(entry.cod) or tostring(entry.cod)))
                row.money:Show()
            elseif entry.money > 0 then
                row.money:SetText(GetCoinTextureString and GetCoinTextureString(entry.money) or tostring(entry.money))
                row.money:Show()
            else
                row.money:SetText(""); row.money:Hide()
            end

            local sz = GetIconSize()
            local prevSlot = nil
            for i = 1, 3 do
                local slot = row.icons[i]
                local it = entry.items[i]
                slot:ClearAllPoints()
                if it then
                    slot:SetSize(sz, sz)
                    slot.tex:SetTexture(it.texture)
                    if it.count and it.count > 1 then slot.count:SetText(it.count); slot.count:Show()
                    else slot.count:Hide() end
                    local q = it.quality
                    if q and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q] then
                        local qc = ITEM_QUALITY_COLORS[q]
                        slot:SetBackdropBorderColor(qc.r, qc.g, qc.b, 1)
                    else
                        slot:SetBackdropBorderColor(unpack(UI.COLORS.border))
                    end
                    -- Bottom-aligned so larger icons grow upward into otherwise
                    -- empty space. With money they sit left of it; without money
                    -- they are kept left of the expiry column so a tall icon never
                    -- overlaps the expiry text on the top-right.
                    if not prevSlot then
                        if row.money:IsShown() then
                            slot:SetPoint("BOTTOMRIGHT", row.money, "BOTTOMLEFT", -6, 0)
                        else
                            local ew = (row.expiry:IsShown() and row.expiry:GetStringWidth()) or 0
                            slot:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -(10 + ew + 8), 5)
                        end
                    else
                        slot:SetPoint("BOTTOMRIGHT", prevSlot, "BOTTOMLEFT", -3, 0)
                    end
                    slot:Show()
                    prevSlot = slot
                else
                    slot:Hide()
                end
            end
            row.extra:ClearAllPoints()
            if entry.extra > 0 and prevSlot then
                row.extra:SetPoint("BOTTOMRIGHT", prevSlot, "BOTTOMLEFT", -3, 0)
                row.extra:SetText("+" .. entry.extra)
                row.extra:Show()
            else
                row.extra:Hide()
            end

            -- leftmost element of the attachment cluster (extra text or the
            -- left-most icon), used to keep both text lines clear of it.
            local cluster = (row.extra:IsShown() and row.extra) or prevSlot

            -- subject (bottom line): clear the cluster, then money.
            local subjLeft = cluster or (row.money:IsShown() and row.money) or nil
            if subjLeft then
                row.subject:SetPoint("RIGHT", subjLeft, "LEFT", -6, 0)
            else
                row.subject:SetPoint("RIGHT", row, "RIGHT", -10, 0)
            end

            -- sender (top line): icons can be taller than one text line, so the
            -- sender must clear the cluster too, otherwise just the expiry label.
            local sendLeft = cluster or row.expiry
            row.sender:SetPoint("RIGHT", sendLeft, "LEFT", -6, 0)

            local idx = entry.index
            row:SetScript("OnClick", function() Inbox:ShowReader(idx) end)
            row.btnTake:SetScript("OnClick", function() DoTake(idx) end)
            row.btnTake:SetScript("OnEnter", function(self)
                self:SetBackdropBorderColor(unpack(UI.COLORS.accent))
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(TM:L("INBOX_TAKE") or "Tout prendre", 1, 1, 1)
                GameTooltip:Show()
            end)
            row.btnTake:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(UI.COLORS.border)); GameTooltip:Hide() end)
            row.btnDelete:SetScript("OnClick", function() DoDelete(idx) end)
            row.btnDelete:SetScript("OnEnter", function(self)
                self.txt:SetTextColor(unpack(UI.COLORS.danger))
                self:SetBackdropBorderColor(unpack(UI.COLORS.danger))
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(TM:L("INBOX_DELETE") or "Supprimer", 1, 1, 1)
                GameTooltip:Show()
            end)
            row.btnDelete:SetScript("OnLeave", function(self)
                self.txt:SetTextColor(unpack(UI.COLORS.textDim))
                self:SetBackdropBorderColor(unpack(UI.COLORS.border))
                GameTooltip:Hide()
            end)

            table.insert(activeRows, row)
            yOffset = yOffset + ROW_H
            shownCount = shownCount + 1
        end
    end

    if shownCount == 0 then
        local row = AcquireRow(scrollChild)
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
        row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -yOffset)
        row:SetHeight(48)
        row._index = nil
        row.accent:SetColorTexture(0, 0, 0, 0)
        row.badge:Hide()
        row.avatar:Hide()
        row.expiry:SetText(""); row.money:Hide(); row.extra:Hide()
        for _, s in ipairs(row.icons) do s:Hide() end
        row.sender:SetText("")
        row.subject:ClearAllPoints()
        row.subject:SetPoint("CENTER", row, "CENTER", 0, 0)
        local msg = (#data == 0) and (TM:L("INBOX_EMPTY") or "Aucun courrier")
            or (TM:L("INBOX_NO_MATCH") or "Aucun résultat")
        row.subject:SetText(msg)
        row.subject:SetTextColor(unpack(UI.COLORS.textMuted))
        row:SetScript("OnClick", nil)
        table.insert(activeRows, row)
        yOffset = yOffset + 48
    end

    scrollChild:SetHeight(math.max(yOffset, 1))
    if panel.UpdateScrollbar then panel.UpdateScrollbar() end

    if panel.summary then
        panel.summary:SetText(string.format(
            "%d %s · |cFFCC44FF%d %s|r",
            #data, (TM:L("INBOX_MESSAGES") or "messages"),
            unreadCount, (TM:L("INBOX_UNREAD") or "non lus")))
    end
end

-- ============================================================
--  Filter chips
-- ============================================================

local function CreateChip(parent, label, key)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetHeight(20)
    b:SetBackdrop(UI.BACKDROP)
    b.label = UI:FS(b, "small")
    b.label:SetPoint("CENTER", 0, 0)
    b.label:SetText(label)
    b:SetWidth(math.max(34, b.label:GetStringWidth() + 18))
    b._key = key
    function b:SetActive(a)
        if a then
            b:SetBackdropColor(unpack(UI.COLORS.accent))
            b:SetBackdropBorderColor(unpack(UI.COLORS.accent))
            b.label:SetTextColor(0.10, 0.04, 0.14)
        else
            b:SetBackdropColor(UI.COLORS.bgLight[1], UI.COLORS.bgLight[2], UI.COLORS.bgLight[3], 1)
            b:SetBackdropBorderColor(unpack(UI.COLORS.border))
            b.label:SetTextColor(unpack(UI.COLORS.textDim))
        end
    end
    b:SetActive(false)
    return b
end

-- ============================================================
--  Build the inbox panel inside the given page
-- ============================================================

local function BuildPanel(parent)
    if not parent then return end

    panel = CreateFrame("Frame", "TomoMailInbox", parent)
    panel:SetAllPoints(parent)
    panel:EnableMouse(true)

    -- Search box
    local search = UI:CreateSearchBox(panel, 10)
    search:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -6)
    search:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -6)
    panel.search = search
    search.editbox:SetScript("OnTextChanged", function(_, userInput)
        if userInput then Inbox:Populate() end
    end)
    search.editbox:SetScript("OnEscapePressed", function(self)
        self:SetText(""); self:ClearFocus(); Inbox:Populate()
    end)

    -- Filter chips
    local chipBar = CreateFrame("Frame", nil, panel)
    chipBar:SetPoint("TOPLEFT", search, "BOTTOMLEFT", 0, -8)
    chipBar:SetPoint("TOPRIGHT", search, "BOTTOMRIGHT", 0, -8)
    chipBar:SetHeight(20)

    local chipDefs = {
        { key = "ALL",       label = TM:L("INBOX_FILTER_ALL")     or "Tout" },
        { key = CAT_PLAYER,  label = TM:L("INBOX_FILTER_PLAYERS") or "Joueurs" },
        { key = CAT_AUCTION, label = TM:L("INBOX_FILTER_AH")      or "Hôtel des ventes" },
        { key = CAT_SYSTEM,  label = TM:L("INBOX_FILTER_SYSTEM")  or "Système" },
    }
    local chips = {}
    local xoff = 0
    for i, def in ipairs(chipDefs) do
        local chip = CreateChip(chipBar, def.label, def.key)
        chip:SetPoint("LEFT", chipBar, "LEFT", xoff, 0)
        xoff = xoff + chip:GetWidth() + 5
        chip:SetScript("OnClick", function(self)
            activeFilter = self._key
            for _, c in ipairs(chips) do c:SetActive(c._key == activeFilter) end
            Inbox:Populate()
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end)
        chips[i] = chip
    end
    chips[1]:SetActive(true)
    panel.chips = chips

    local div = panel:CreateTexture(nil, "ARTWORK")
    div:SetPoint("TOPLEFT", chipBar, "BOTTOMLEFT", 0, -6)
    div:SetPoint("TOPRIGHT", chipBar, "BOTTOMRIGHT", 0, -6)
    div:SetHeight(1)
    div:SetColorTexture(unpack(UI.COLORS.borderDim))

    -- Scroll list
    local scrollFrame = CreateFrame("ScrollFrame", "TomoMailInboxScroll", panel)
    scrollFrame:SetPoint("TOPLEFT", div, "BOTTOMLEFT", 0, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 34)
    scrollFrame:EnableMouseWheel(true)

    local scrollChild = CreateFrame("Frame", "TomoMailInboxScrollChild", scrollFrame)
    scrollChild:SetWidth(10)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    panel.scrollChild = scrollChild
    panel.scrollFrame = scrollFrame
    scrollFrame:SetScript("OnSizeChanged", function(_, w) scrollChild:SetWidth(w) end)

    -- Themed scrollbar
    local sb = CreateFrame("Frame", nil, panel)
    sb:SetWidth(4)
    sb:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 7, 0)
    sb:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 7, 0)
    local track = sb:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(UI.COLORS.borderDim[1], UI.COLORS.borderDim[2], UI.COLORS.borderDim[3], 0.8)
    local thumb = CreateFrame("Frame", nil, sb)
    thumb:SetWidth(4)
    thumb:SetHeight(30)
    thumb:SetPoint("TOP", sb, "TOP", 0, 0)
    thumb:EnableMouse(true)
    local thumbTex = thumb:CreateTexture(nil, "ARTWORK")
    thumbTex:SetAllPoints()
    thumbTex:SetColorTexture(UI.COLORS.accent[1], UI.COLORS.accent[2], UI.COLORS.accent[3], 0.8)
    panel.scrollbar = sb

    local function UpdateScrollbar()
        local total   = scrollChild:GetHeight()
        local visible = scrollFrame:GetHeight()
        if total <= visible + 1 or visible <= 0 then sb:Hide(); return end
        sb:Show()
        local thumbH = math.max(24, visible * (visible / total))
        thumb:SetHeight(thumbH)
        local maxScroll = total - visible
        local pct = (maxScroll > 0) and (scrollFrame:GetVerticalScroll() / maxScroll) or 0
        local travel = sb:GetHeight() - thumbH
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", sb, "TOP", 0, -travel * pct)
    end
    panel.UpdateScrollbar = UpdateScrollbar

    local SCROLL_STEP = ROW_H * 2
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = math.max(scrollChild:GetHeight() - self:GetHeight(), 0)
        local cur = self:GetVerticalScroll()
        self:SetVerticalScroll(math.max(0, math.min(cur - delta * SCROLL_STEP, maxScroll)))
        UpdateScrollbar()
    end)

    thumb:SetScript("OnMouseDown", function(self)
        self.dragging = true
        local _, cy = GetCursorPosition()
        self.startCursor = cy / sb:GetEffectiveScale()
        self.startScroll = scrollFrame:GetVerticalScroll()
        thumbTex:SetColorTexture(UI.COLORS.accent[1], UI.COLORS.accent[2], UI.COLORS.accent[3], 1)
    end)
    thumb:SetScript("OnMouseUp", function(self)
        self.dragging = false
        thumbTex:SetColorTexture(UI.COLORS.accent[1], UI.COLORS.accent[2], UI.COLORS.accent[3], 0.8)
    end)
    thumb:SetScript("OnUpdate", function(self)
        if not self.dragging then return end
        local total   = scrollChild:GetHeight()
        local visible = scrollFrame:GetHeight()
        local maxScroll = math.max(total - visible, 0)
        local travel = sb:GetHeight() - self:GetHeight()
        if maxScroll <= 0 or travel <= 0 then return end
        local _, cy = GetCursorPosition()
        cy = cy / sb:GetEffectiveScale()
        local dy = self.startCursor - cy
        local newScroll = math.max(0, math.min(self.startScroll + (dy / travel) * maxScroll, maxScroll))
        scrollFrame:SetVerticalScroll(newScroll)
        UpdateScrollbar()
    end)

    -- Footer
    local footDiv = panel:CreateTexture(nil, "ARTWORK")
    footDiv:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 4, 30)
    footDiv:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 30)
    footDiv:SetHeight(1)
    footDiv:SetColorTexture(unpack(UI.COLORS.borderDim))

    local summary = UI:FS(panel, "small")
    summary:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 8, 9)
    summary:SetTextColor(unpack(UI.COLORS.textMuted))
    panel.summary = summary

    local takeAllBtn = UI:CreateStyledButton(panel, TM:L("INBOX_TAKE_ALL") or "Tout prendre", 110, 22, "bgLight")
    takeAllBtn:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -6, 5)
    takeAllBtn.label:SetTextColor(unpack(UI.COLORS.accent))
    takeAllBtn:SetScript("OnClick", function()
        StartTakeAll()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end)
end

-- ============================================================
--  Reader popup (custom, API-driven body)
-- ============================================================

local READER_SLOT    = 32
local READER_PER_ROW = 10

-- Render the current mail's item attachments as individual, clickable slots so
-- the player can take a single stack (e.g. one of several bulk-bought herb/ore
-- stacks) instead of only "Take all". Returns how many slots are shown.
local function PopulateReaderAttachments(index)
    if not reader or not reader.attachSlots then return 0 end
    local placed = 0
    for j = 1, (ATTACHMENTS_MAX_RECEIVE or 16) do
        local slot = reader.attachSlots[j]
        if not slot then break end
        local iok, _, _, texture, count, quality = pcall(GetInboxItem, index, j)
        if iok and texture then
            slot.icon:SetTexture(texture)
            if count and count > 1 then slot.count:SetText(count); slot.count:Show()
            else slot.count:Hide() end
            if quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] then
                local qc = ITEM_QUALITY_COLORS[quality]
                slot:SetBackdropBorderColor(qc.r, qc.g, qc.b, 1)
            else
                slot:SetBackdropBorderColor(unpack(UI.COLORS.border))
            end
            local rr = math.floor(placed / READER_PER_ROW)
            local cc = placed % READER_PER_ROW
            slot:ClearAllPoints()
            slot:SetPoint("TOPLEFT", reader.attachFrame, "TOPLEFT", cc * (READER_SLOT + 6), -rr * (READER_SLOT + 6))
            slot:Show()
            placed = placed + 1
        else
            slot:Hide()
        end
    end
    local rows = (placed > 0) and (math.floor((placed - 1) / READER_PER_ROW) + 1) or 0
    reader.attachFrame:SetHeight(rows > 0 and (rows * (READER_SLOT + 6)) or 0.001)
    return placed
end

local function MakeReaderSlot(parent, slotNum)
    local slot = CreateFrame("Button", nil, parent, "BackdropTemplate")
    slot:SetSize(READER_SLOT, READER_SLOT)
    slot:SetBackdrop(UI.BACKDROP)
    slot:SetBackdropColor(UI.COLORS.bg[1], UI.COLORS.bg[2], UI.COLORS.bg[3], 1)
    slot:SetBackdropBorderColor(unpack(UI.COLORS.border))
    slot.icon = slot:CreateTexture(nil, "ARTWORK")
    slot.icon:SetPoint("TOPLEFT", 1, -1)
    slot.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    slot.count = UI:FS(slot, "tiny")
    slot.count:SetPoint("BOTTOMRIGHT", -1, 1)
    slot.attachIndex = slotNum

    slot:SetScript("OnClick", function(self)
        local idx = reader and reader._index
        if not idx then return end
        local before = 0
        pcall(function() before = (GetInboxNumItems and GetInboxNumItems()) or 0 end)
        WithMinimapErrorGuard(function()
            if TakeInboxItem then TakeInboxItem(idx, self.attachIndex) end
        end)
        C_Timer.After(0.10, function()
            if not reader then return end
            local after = before
            pcall(function() after = (GetInboxNumItems and GetInboxNumItems()) or 0 end)
            pcall(function() Inbox:Populate() end)
            -- If the mail auto-deleted (its last item was taken) the inbox count
            -- drops and indices shift, so close the reader; otherwise the mail
            -- still exists at the same index, so just refresh its slots.
            if after < before then
                reader:Hide()
            elseif reader._index then
                PopulateReaderAttachments(reader._index)
            end
        end)
    end)
    slot:SetScript("OnEnter", function(self)
        local idx = reader and reader._index
        if not idx then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        pcall(function() GameTooltip:SetInboxItem(idx, self.attachIndex) end)
        GameTooltip:Show()
    end)
    slot:SetScript("OnLeave", function() GameTooltip:Hide() end)
    slot:Hide()
    return slot
end

local function BuildReader()
    reader = UI:CreatePanel(UIParent, "TomoMailReader", 430, 360)
    reader:SetPoint("CENTER")
    reader:SetFrameStrata("FULLSCREEN_DIALOG")
    reader:SetMovable(true)
    reader:RegisterForDrag("LeftButton")
    reader:SetScript("OnDragStart", reader.StartMoving)
    reader:SetScript("OnDragStop", reader.StopMovingOrSizing)
    reader:Hide()
    tinsert(UISpecialFrames, "TomoMailReader")

    reader.title = UI:FS(reader, "title")
    reader.title:SetPoint("TOPLEFT", reader, "TOPLEFT", 14, -12)
    reader.title:SetText("|cFFCC44FFTomo|r|cFFFFFFFFMail|r")

    local close = CreateFrame("Button", nil, reader)
    close:SetSize(18, 18)
    close:SetPoint("TOPRIGHT", reader, "TOPRIGHT", -8, -10)
    close.t = UI:FS(close, "large")
    close.t:SetAllPoints(); close.t:SetText("×"); close.t:SetTextColor(0.4, 0.4, 0.4)
    close:SetScript("OnClick", function() reader:Hide() end)
    close:SetScript("OnEnter", function(self) self.t:SetTextColor(1, 1, 1) end)
    close:SetScript("OnLeave", function(self) self.t:SetTextColor(0.4, 0.4, 0.4) end)

    reader.sender = UI:FS(reader, "normal")
    reader.sender:SetPoint("TOPLEFT", reader, "TOPLEFT", 14, -36)

    reader.subject = UI:FS(reader, "small")
    reader.subject:SetPoint("TOPLEFT", reader, "TOPLEFT", 14, -54)
    reader.subject:SetTextColor(unpack(UI.COLORS.textDim))

    local div = reader:CreateTexture(nil, "ARTWORK")
    div:SetSize(402, 1)
    div:SetPoint("TOPLEFT", reader, "TOPLEFT", 14, -72)
    div:SetColorTexture(unpack(UI.COLORS.borderDim))

    -- Individual attachment slots (click one to take a single item / stack).
    reader.attachFrame = CreateFrame("Frame", nil, reader)
    reader.attachFrame:SetPoint("TOPLEFT", reader, "TOPLEFT", 14, -80)
    reader.attachFrame:SetSize(402, 0.001)
    reader.attachSlots = {}
    for j = 1, (ATTACHMENTS_MAX_RECEIVE or 16) do
        reader.attachSlots[j] = MakeReaderSlot(reader.attachFrame, j)
    end

    local bodyScroll = CreateFrame("ScrollFrame", "TomoMailReaderScroll", reader, "UIPanelScrollFrameTemplate")
    bodyScroll:SetPoint("TOPLEFT", reader.attachFrame, "BOTTOMLEFT", 0, -8)
    bodyScroll:SetPoint("BOTTOMRIGHT", reader, "BOTTOMRIGHT", -16, 44)
    -- Hide the template's gold scrollbar (it showed even with no text and looks
    -- out of place against the dark theme); the body scrolls with the wheel.
    do
        local nm = bodyScroll:GetName()
        local sb = bodyScroll.ScrollBar or (nm and _G[nm .. "ScrollBar"])
        if sb then sb:SetAlpha(0); if sb.EnableMouse then sb:EnableMouse(false) end end
        if nm then
            for _, s in ipairs({ "ScrollBarScrollUpButton", "ScrollBarScrollDownButton", "ScrollBarThumbTexture" }) do
                local b = _G[nm .. s]
                if b then if b.SetAlpha then b:SetAlpha(0) end; if b.EnableMouse then b:EnableMouse(false) end end
            end
        end
        bodyScroll:EnableMouseWheel(true)
        bodyScroll:SetScript("OnMouseWheel", function(self, delta)
            local maxS = self:GetVerticalScrollRange() or 0
            local new = (self:GetVerticalScroll() or 0) - delta * 24
            if new < 0 then new = 0 elseif new > maxS then new = maxS end
            self:SetVerticalScroll(new)
        end)
    end
    local bodyChild = CreateFrame("Frame", nil, bodyScroll)
    bodyChild:SetSize(394, 10)
    bodyScroll:SetScrollChild(bodyChild)
    reader.body = UI:FS(bodyChild, "small")
    reader.body:SetPoint("TOPLEFT", 0, 0)
    reader.body:SetWidth(390)
    reader.body:SetJustifyH("LEFT")
    reader.body:SetJustifyV("TOP")
    reader.bodyChild = bodyChild

    local takeBtn = UI:CreateStyledButton(reader, TM:L("INBOX_TAKE") or "Tout prendre", 110, 26, "bgLight")
    takeBtn:SetPoint("BOTTOMLEFT", reader, "BOTTOMLEFT", 12, 10)
    takeBtn.label:SetTextColor(unpack(UI.COLORS.accent))
    reader.takeBtn = takeBtn

    local replyBtn = UI:CreateStyledButton(reader, TM:L("INBOX_REPLY") or "Répondre", 100, 26, "bgLight")
    replyBtn:SetPoint("LEFT", takeBtn, "RIGHT", 6, 0)
    reader.replyBtn = replyBtn

    local delBtn = UI:CreateStyledButton(reader, TM:L("INBOX_DELETE") or "Supprimer", 100, 26, "dangerBg")
    delBtn:SetPoint("BOTTOMRIGHT", reader, "BOTTOMRIGHT", -12, 10)
    reader.delBtn = delBtn
end

function Inbox:ShowReader(index)
    if not reader then
        local ok, err = pcall(BuildReader)
        if not ok then TM:Print("|cFFFF4444Reader: |r" .. tostring(err)); return end
    end

    local ok, _, _, sender, subject = pcall(GetInboxHeaderInfo, index)
    if not ok then return end
    sender  = sender  or (TM:L("INBOX_SYSTEM") or "Système")
    subject = subject or "—"

    local class = ResolveSenderClass(sender)
    local r, g, b = 0.85, 0.85, 0.85
    if class then r, g, b = TM:ClassColorRGB(class) end
    reader.sender:SetText(sender)
    reader.sender:SetTextColor(r, g, b)
    reader.subject:SetText(subject)

    local body = SafeReadBody(index)
    if body == "" then
        body = "|cFF666666" .. (TM:L("INBOX_NO_TEXT") or "(Aucun texte)") .. "|r"
    end
    reader.body:SetText(body)
    reader.bodyChild:SetHeight(math.max(reader.body:GetStringHeight() + 10, 10))

    reader._index = index
    pcall(function() PopulateReaderAttachments(index) end)

    reader.takeBtn:SetScript("OnClick", function() DoTake(index); reader:Hide() end)
    reader.delBtn:SetScript("OnClick", function() DoDelete(index); reader:Hide() end)
    reader.replyBtn:SetScript("OnClick", function()
        if TM.Window then TM.Window:SelectTab("SEND") end
        TM:SetRecipient(sender)
        reader:Hide()
    end)

    reader:Show()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
    C_Timer.After(0.15, function() Inbox:Populate() end)
end

-- ============================================================
--  Events + module hooks
-- ============================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("MAIL_INBOX_UPDATE")
eventFrame:RegisterEvent("MAIL_SUCCESS")
eventFrame:RegisterEvent("UPDATE_PENDING_MAIL")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function()
    -- Keep the minimap mail indicator in sync on any mail state change, even
    -- when our window is closed (Blizzard's own handler is broken on Midnight).
    SyncMinimapMail()
    if panel and panel:IsVisible() then Inbox:Populate() end
end)

function Inbox:OnInitialize() end

-- Apply a changed icon size to the rows that are currently on screen. Each
-- slot's texture fills the slot, and the cluster / subject / sender anchors are
-- all relative to the slots' own edges, so resizing the slots in place makes the
-- rows reflow automatically — the change is immediate, no /reload required.
-- Pooled (off-screen) rows pick up the new size the next time they render.
function Inbox:ApplyIconSize()
    local sz = GetIconSize()
    for _, row in ipairs(activeRows) do
        if row and row.icons then
            for _, slot in ipairs(row.icons) do
                if slot and slot.SetSize then slot:SetSize(sz, sz) end
            end
        end
    end
end

function Inbox:Mount()
    if panel then return end
    local page = TM.Window and TM.Window:GetInboxPage()
    if not page then return end
    local ok, err = pcall(function() BuildPanel(page) end)
    if not ok then TM:Print("|cFFFF4444Inbox: |r" .. tostring(err)) end
end

function Inbox:OnSelect()
    self:Mount()
    if not panel then return end
    pcall(function() if CheckInbox then CheckInbox() end end)
    self:Populate()
end

function Inbox:OnMailShow()
    if not ModernEnabled() then return end
    if TM.Window then TM.Window:Ensure() end
    self:Mount()
end

function Inbox:OnMailHide()
    if takeTicker then takeTicker:Cancel(); takeTicker = nil end
    if reader then reader:Hide() end
    -- Re-evaluate the minimap icon once the mailbox has closed, in case the
    -- inbox was emptied (Blizzard's own handler can leave it stuck on Midnight).
    if C_Timer and C_Timer.After then C_Timer.After(0.10, SyncMinimapMail) end
end

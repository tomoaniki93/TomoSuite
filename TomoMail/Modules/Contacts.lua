-- TomoMail | Modules/Contacts.lua
-- Custom flyout panel replacing UIDropDownMenu
-- Tabs: Alts · Guild · Recent — with live search

local TM = TomoMail
local UI = TM.UI
local Contacts = {}
TM:RegisterModule("Contacts", Contacts)

-- ============================================================
--  Local state
-- ============================================================

local flyout         = nil
local contactButton  = nil
local isMailOpen     = false
local activeTab      = "GUILD"

-- Guild cache
local guildCache     = {}
local guildCacheTime = 0
local GUILD_CACHE_TTL = 10

-- Row pool
local rowPool = {}
local activeRows = {}

-- ============================================================
--  Guild cache (same logic, kept intact)
-- ============================================================

local function BuildGuildCache()
    guildCache = {}
    if not IsInGuild() then return end

    if C_GuildInfo and C_GuildInfo.GuildRoster then
        C_GuildInfo.GuildRoster()
    end

    local player     = UnitName("player")
    local onlineOnly = TM.db.profile.guildOnlineOnly
    local numMembers = GetNumGuildMembers()

    for i = 1, numMembers do
        local name, _, _, lvl, _, _, _, _, isOnline, _, class = GetGuildRosterInfo(i)
        if name then
            local shortName = strsplit("-", name)
            if shortName ~= player then
                if not onlineOnly or isOnline then
                    local letter = shortName:sub(1, 1):upper()
                    if not guildCache[letter] then
                        guildCache[letter] = {}
                    end
                    table.insert(guildCache[letter], {
                        name   = shortName,
                        level  = lvl or 0,
                        class  = class,
                        online = isOnline,
                    })
                end
            end
        end
    end

    for _, group in pairs(guildCache) do
        table.sort(group, function(a, b)
            if a.online ~= b.online then return a.online end
            return a.name < b.name
        end)
    end

    guildCacheTime = GetTime()
end

local function GetGuildCache()
    if not guildCache or (GetTime() - guildCacheTime) > GUILD_CACHE_TTL then
        BuildGuildCache()
    end
    return guildCache
end

-- ============================================================
--  Data getters for each tab
-- ============================================================

local function GetAltsData()
    local alts    = TM.db.global.alts
    local realm   = GetRealmName()
    local faction = UnitFactionGroup("player")
    local player  = UnitName("player")
    local result  = {}

    for _, entry in ipairs(alts) do
        local p, r, f, lvl, class = strsplit("|", entry)
        if r == realm and f == faction and p ~= player then
            table.insert(result, {
                name   = p,
                level  = tonumber(lvl) or 0,
                class  = class,
                online = false,
                source = "alt",
            })
        end
    end
    table.sort(result, function(a, b) return a.name < b.name end)
    return result
end

local function GetGuildData()
    local cache  = GetGuildCache()
    local result = {}
    local letters = {}

    for letter in pairs(cache) do
        table.insert(letters, letter)
    end
    table.sort(letters)

    for _, letter in ipairs(letters) do
        -- Insert letter header
        table.insert(result, {
            isHeader = true,
            letter   = letter,
            count    = #cache[letter],
        })
        for _, m in ipairs(cache[letter]) do
            table.insert(result, {
                name   = m.name,
                level  = m.level,
                class  = m.class,
                online = m.online,
                source = "guild",
            })
        end
    end
    return result
end

local function GetRecentData()
    local recent = TM.db.profile.recent
    local result = {}

    for _, entry in ipairs(recent) do
        local name = strsplit("|", entry)
        if name and name ~= "" then
            table.insert(result, {
                name   = name,
                level  = 0,
                class  = nil,
                online = false,
                source = "recent",
            })
        end
    end
    return result
end

-- ============================================================
--  Row pool management
-- ============================================================

local ROW_HEIGHT = 22
local HEADER_HEIGHT = 20

local function AcquireRow(scrollChild, isHeader)
    local row = table.remove(rowPool)
    if not row then
        row = CreateFrame("Button", nil, scrollChild)
        row:SetHeight(ROW_HEIGHT)

        row.dot = row:CreateTexture(nil, "ARTWORK")
        row.dot:SetSize(6, 6)
        row.dot:SetPoint("LEFT", row, "LEFT", 10, 0)

        row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.nameText:SetPoint("LEFT", row, "LEFT", 22, 0)
        row.nameText:SetJustifyH("LEFT")

        row.levelText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.levelText:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        row.levelText:SetTextColor(unpack(UI.COLORS.textMuted))

        row.headerText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.headerText:SetPoint("LEFT", row, "LEFT", 10, 0)

        UI:AddRowHighlight(row)
    end

    row:SetParent(scrollChild)
    row:Show()
    return row
end

local function ReleaseAllRows()
    for _, row in ipairs(activeRows) do
        row:Hide()
        row:ClearAllPoints()
        table.insert(rowPool, row)
    end
    wipe(activeRows)
end

-- ============================================================
--  Populate the scroll list
-- ============================================================

local function PopulateList()
    if not flyout then return end

    ReleaseAllRows()

    local searchText = flyout.searchBox.editbox:GetText():lower()
    local data

    if activeTab == "ALTS" then
        data = GetAltsData()
    elseif activeTab == "GUILD" then
        data = GetGuildData()
    elseif activeTab == "RECENT" then
        data = GetRecentData()
    end

    if not data then return end

    local scrollChild = flyout.scrollChild
    local yOffset = 0
    local visibleCount = 0

    for _, entry in ipairs(data) do
        local skip = false

        if entry.isHeader then
            -- Filter: skip header if no members in this letter match
            if searchText ~= "" then
                local hasMatch = false
                local cache = GetGuildCache()
                if cache[entry.letter] then
                    for _, m in ipairs(cache[entry.letter]) do
                        if m.name:lower():find(searchText, 1, true) then
                            hasMatch = true
                            break
                        end
                    end
                end
                if not hasMatch then
                    skip = true
                end
            end

            if not skip then
                local row = AcquireRow(scrollChild, true)
                row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
                row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -yOffset)
                row:SetHeight(HEADER_HEIGHT)
                row:EnableMouse(false)

                row.dot:Hide()
                row.nameText:Hide()
                row.levelText:Hide()
                row.headerText:Show()
                row.headerText:SetText(string.format("|cFFCC44FF%s|r  |cFF555555— %d|r",
                    entry.letter, entry.count))

                table.insert(activeRows, row)
                yOffset = yOffset + HEADER_HEIGHT
            end
        else
            -- Filter by search
            if searchText ~= "" and not entry.name:lower():find(searchText, 1, true) then
                skip = true
            end

            if not skip then
                local row = AcquireRow(scrollChild, false)
                row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
                row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -yOffset)
                row:SetHeight(ROW_HEIGHT)
                row:EnableMouse(true)

                row.headerText:Hide()

                -- Online dot
                row.dot:Show()
                if entry.online then
                    row.dot:SetColorTexture(unpack(UI.COLORS.online))
                else
                    row.dot:SetColorTexture(0.2, 0.2, 0.2, 1)
                end

                -- Name with class color
                row.nameText:Show()
                local r, g, b = TM:ClassColorRGB(entry.class)
                row.nameText:SetTextColor(r, g, b)
                row.nameText:SetText(entry.name)

                -- Level (hide for recents or lvl 0)
                if entry.level and entry.level > 0 then
                    row.levelText:Show()
                    row.levelText:SetText(entry.level)
                else
                    row.levelText:Hide()
                end

                -- Click handler
                local name = entry.name
                row:SetScript("OnClick", function()
                    TM:SetRecipient(name)
                    flyout:Hide()
                end)

                table.insert(activeRows, row)
                yOffset = yOffset + ROW_HEIGHT
                visibleCount = visibleCount + 1
            end
        end
    end

    -- Empty state
    if visibleCount == 0 and not data[1] or (visibleCount == 0) then
        local emptyMsg
        if searchText ~= "" then
            emptyMsg = TM:L("NO_RESULTS") or "Aucun résultat"
        elseif activeTab == "ALTS" then
            emptyMsg = TM:L("NO_ALTS")
        elseif activeTab == "GUILD" then
            emptyMsg = IsInGuild() and TM:L("NO_GUILD_MEMBERS") or TM:L("NO_GUILD")
        elseif activeTab == "RECENT" then
            emptyMsg = TM:L("NO_RECENT")
        end

        if emptyMsg then
            local row = AcquireRow(scrollChild, false)
            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
            row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -yOffset)
            row:SetHeight(30)
            row:EnableMouse(false)
            row.dot:Hide()
            row.levelText:Hide()
            row.headerText:Hide()
            row.nameText:Show()
            row.nameText:SetTextColor(unpack(UI.COLORS.textMuted))
            row.nameText:SetText(emptyMsg)
            table.insert(activeRows, row)
            yOffset = yOffset + 30
        end
    end

    scrollChild:SetHeight(math.max(yOffset, 1))

    -- Update footer stats
    Contacts:UpdateFooter()
end

-- ============================================================
--  Build the flyout panel
-- ============================================================

local FLYOUT_WIDTH  = 360
local FLYOUT_HEIGHT = 480

local function BuildFlyout()
    flyout = UI:CreatePanel(UIParent, "TomoMailFlyout", FLYOUT_WIDTH, FLYOUT_HEIGHT)
    flyout:SetClampedToScreen(true)
    flyout:Hide()

    -- Make closable with Escape
    tinsert(UISpecialFrames, "TomoMailFlyout")

    -- ---- Header bar ----
    local header = flyout:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", flyout, "TOPLEFT", 12, -10)
    header:SetText("|cFFCC44FFTomo|r|cFFFFFFFFMail|r")

    local closeBtn = CreateFrame("Button", nil, flyout)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", flyout, "TOPRIGHT", -8, -8)
    closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeBtn.text:SetAllPoints()
    closeBtn.text:SetText("|cFF555555×|r")
    closeBtn:SetScript("OnClick", function() flyout:Hide() end)
    closeBtn:SetScript("OnEnter", function(self) self.text:SetText("|cFFFFFFFF×|r") end)
    closeBtn:SetScript("OnLeave", function(self) self.text:SetText("|cFF555555×|r") end)

    -- ---- Divider under header ----
    local div1 = flyout:CreateTexture(nil, "ARTWORK")
    div1:SetSize(FLYOUT_WIDTH - 2, 1)
    div1:SetPoint("TOPLEFT", flyout, "TOPLEFT", 1, -28)
    div1:SetColorTexture(unpack(UI.COLORS.borderDim))

    -- ---- Tabs ----
    local tabContainer = CreateFrame("Frame", nil, flyout)
    tabContainer:SetSize(FLYOUT_WIDTH - 24, 30)
    tabContainer:SetPoint("TOPLEFT", flyout, "TOPLEFT", 12, -32)

    local tabs = {}
    local tabDefs = {
        { key = "ALTS",   label = TM:L("MY_ALTS") },
        { key = "GUILD",  label = TM:L("GUILD_MEMBERS") },
        { key = "RECENT", label = TM:L("RECENT") },
    }

    for i, def in ipairs(tabDefs) do
        local tab = UI:CreateTab(tabContainer, def.label, i, #tabDefs)
        tab:SetPoint("TOPLEFT", tabContainer, "TOPLEFT", (i - 1) * (tabContainer:GetWidth() / #tabDefs), 0)
        tab._key = def.key

        tab:SetScript("OnClick", function(self)
            activeTab = self._key
            for _, t in ipairs(tabs) do
                t._active = (t._key == activeTab)
                t:SetActive(t._active)
            end
            PopulateList()
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end)

        tabs[i] = tab
    end
    flyout.tabs = tabs

    -- ---- Search box ----
    local searchContainer = UI:CreateSearchBox(flyout, FLYOUT_WIDTH - 24)
    searchContainer:SetPoint("TOPLEFT", flyout, "TOPLEFT", 12, -66)
    flyout.searchBox = searchContainer

    searchContainer.editbox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            PopulateList()
        end
    end)
    searchContainer.editbox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
        PopulateList()
    end)

    -- ---- Divider under search ----
    local div2 = flyout:CreateTexture(nil, "ARTWORK")
    div2:SetSize(FLYOUT_WIDTH - 2, 1)
    div2:SetPoint("TOPLEFT", flyout, "TOPLEFT", 1, -102)
    div2:SetColorTexture(unpack(UI.COLORS.borderDim))

    -- ---- Scrollable list (custom slim scroll) ----
    local scrollFrame = CreateFrame("ScrollFrame", "TomoMailFlyoutScroll", flyout)
    scrollFrame:SetPoint("TOPLEFT", flyout, "TOPLEFT", 0, -104)
    scrollFrame:SetPoint("BOTTOMRIGHT", flyout, "BOTTOMRIGHT", -8, 34)
    scrollFrame:EnableMouseWheel(true)

    local scrollChild = CreateFrame("Frame", "TomoMailFlyoutScrollChild", scrollFrame)
    scrollChild:SetWidth(FLYOUT_WIDTH - 10)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    flyout.scrollChild = scrollChild

    -- Slim scrollbar track
    local scrollTrack = CreateFrame("Frame", nil, flyout)
    scrollTrack:SetWidth(4)
    scrollTrack:SetPoint("TOPRIGHT", flyout, "TOPRIGHT", -3, -106)
    scrollTrack:SetPoint("BOTTOMRIGHT", flyout, "BOTTOMRIGHT", -3, 36)

    local trackBg = scrollTrack:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    trackBg:SetColorTexture(UI.COLORS.bgLight[1], UI.COLORS.bgLight[2], UI.COLORS.bgLight[3], 0.5)

    -- Slim scrollbar thumb
    local scrollThumb = CreateFrame("Frame", nil, scrollTrack)
    scrollThumb:SetWidth(4)
    scrollThumb:SetHeight(40)
    scrollThumb:SetPoint("TOP", scrollTrack, "TOP", 0, 0)

    local thumbTex = scrollThumb:CreateTexture(nil, "OVERLAY")
    thumbTex:SetAllPoints()
    thumbTex:SetColorTexture(UI.COLORS.accent[1], UI.COLORS.accent[2], UI.COLORS.accent[3], 0.6)
    flyout.scrollThumb = scrollThumb
    flyout.scrollTrack = scrollTrack

    -- Mouse wheel scrolling
    local SCROLL_STEP = ROW_HEIGHT * 3

    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = math.max(scrollChild:GetHeight() - self:GetHeight(), 0)
        local current   = self:GetVerticalScroll()
        local newScroll  = math.max(0, math.min(current - delta * SCROLL_STEP, maxScroll))
        self:SetVerticalScroll(newScroll)
    end)

    -- Update thumb position/size on scroll
    scrollFrame:SetScript("OnScrollRangeChanged", function(self, xRange, yRange)
        if not yRange then yRange = self:GetVerticalScrollRange() end
        local trackH = scrollTrack:GetHeight()
        if yRange > 0 and trackH > 0 then
            local ratio = self:GetHeight() / (self:GetHeight() + yRange)
            local thumbH = math.max(20, trackH * ratio)
            scrollThumb:SetHeight(thumbH)
            scrollThumb:Show()
            scrollTrack:Show()
        else
            scrollThumb:Hide()
            scrollTrack:Hide()
        end
    end)

    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        local yRange = self:GetVerticalScrollRange()
        local trackH = scrollTrack:GetHeight()
        local thumbH = scrollThumb:GetHeight()
        if yRange > 0 and trackH > thumbH then
            local ratio  = offset / yRange
            local travel = trackH - thumbH
            scrollThumb:ClearAllPoints()
            scrollThumb:SetPoint("TOP", scrollTrack, "TOP", 0, -ratio * travel)
        end
    end)

    -- ---- Footer ----
    local footerDiv = flyout:CreateTexture(nil, "ARTWORK")
    footerDiv:SetSize(FLYOUT_WIDTH - 2, 1)
    footerDiv:SetPoint("BOTTOMLEFT", flyout, "BOTTOMLEFT", 1, 32)
    footerDiv:SetColorTexture(unpack(UI.COLORS.borderDim))

    local footerStats = flyout:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    footerStats:SetPoint("BOTTOMLEFT", flyout, "BOTTOMLEFT", 12, 10)
    footerStats:SetTextColor(unpack(UI.COLORS.textMuted))
    flyout.footerStats = footerStats

    local settingsBtn = CreateFrame("Button", nil, flyout)
    settingsBtn:SetSize(60, 20)
    settingsBtn:SetPoint("BOTTOMRIGHT", flyout, "BOTTOMRIGHT", -8, 6)
    local sBtnText = settingsBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sBtnText:SetAllPoints()
    sBtnText:SetJustifyH("RIGHT")
    sBtnText:SetText("|cFF555555" .. TM:L("SETTINGS") .. "|r")
    settingsBtn:SetScript("OnClick", function()
        flyout:Hide()
        if TomoMailConfig and TomoMailConfig.Toggle then
            TomoMailConfig:Toggle()
        end
    end)
    settingsBtn:SetScript("OnEnter", function() sBtnText:SetText("|cFFCC44FF" .. TM:L("SETTINGS") .. "|r") end)
    settingsBtn:SetScript("OnLeave", function() sBtnText:SetText("|cFF555555" .. TM:L("SETTINGS") .. "|r") end)

    -- Close on click outside
    flyout:SetScript("OnShow", function(self)
        -- Reset search
        self.searchBox.editbox:SetText("")
    end)
end

-- ============================================================
--  Update footer stats
-- ============================================================

function Contacts:UpdateFooter()
    if not flyout or not flyout.footerStats then return end

    if activeTab == "GUILD" then
        local cache = GetGuildCache()
        local total, online = 0, 0
        for _, members in pairs(cache) do
            total = total + #members
            for _, m in ipairs(members) do
                if m.online then online = online + 1 end
            end
        end
        flyout.footerStats:SetText(string.format("|cFF00FF66%d|r en ligne · %d total", online, total))
    elseif activeTab == "ALTS" then
        local alts = GetAltsData()
        flyout.footerStats:SetText(string.format("%d personnage(s)", #alts))
    elseif activeTab == "RECENT" then
        local recent = TM.db.profile.recent
        flyout.footerStats:SetText(string.format("%d / %d récents", #recent, TM.db.profile.maxRecent))
    end

    -- Update tab counts
    if flyout.tabs then
        flyout.tabs[1]:SetCount(#GetAltsData())

        local cache = GetGuildCache()
        local gTotal = 0
        for _, members in pairs(cache) do
            gTotal = gTotal + #members
        end
        flyout.tabs[2]:SetCount(gTotal)
        flyout.tabs[3]:SetCount(#TM.db.profile.recent)
    end
end

-- ============================================================
--  Refresh tabs visual state
-- ============================================================

local function RefreshTabs()
    if not flyout or not flyout.tabs then return end
    for _, t in ipairs(flyout.tabs) do
        t._active = (t._key == activeTab)
        t:SetActive(t._active)
    end
end

-- ============================================================
--  Module API
-- ============================================================

function Contacts:OnInitialize() end

function Contacts:OnMailShow()
    isMailOpen = true
    guildCacheTime = 0
    self:CreateUI()
end

function Contacts:OnMailHide()
    isMailOpen = false
    if flyout then flyout:Hide() end
end

-- ============================================================
--  Create the contact button on the mail frame
-- ============================================================

function Contacts:CreateUI()
    if not contactButton then
        contactButton = CreateFrame("Button", "TomoMailContactButton", SendMailFrame)
        contactButton:SetSize(26, 26)
        contactButton:SetPoint("LEFT", SendMailNameEditBox, "RIGHT", 2, 0)

        -- Use standard Blizzard textures (proven to work)
        contactButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
        contactButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Round", "ADD")
        contactButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")

        contactButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("|cFFCC44FFTomoMail|r")
            GameTooltip:AddLine(TM:L("CONTACTS"), 1, 1, 1)
            GameTooltip:Show()
        end)
        contactButton:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        contactButton:SetScript("OnClick", function(self)
            Contacts:ToggleFlyout(self)
        end)
    end

    contactButton:Show()

    if not flyout then
        local ok, err = pcall(BuildFlyout)
        if not ok then
            TM:Print("|cFFFF4444Erreur flyout:|r " .. tostring(err))
        end
    end
end

-- ============================================================
--  Toggle flyout
-- ============================================================

function Contacts:ToggleFlyout(anchor)
    if not flyout then return end

    if flyout:IsShown() then
        flyout:Hide()
        return
    end

    -- Invalidate guild cache
    guildCacheTime = 0

    -- Position flush to the right of the visible mail frame
    flyout:ClearAllPoints()
    flyout:SetPoint("TOPLEFT", SendMailFrame, "TOPRIGHT", -12, -2)

    -- Set default tab and refresh
    RefreshTabs()
    PopulateList()
    flyout:Show()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
end

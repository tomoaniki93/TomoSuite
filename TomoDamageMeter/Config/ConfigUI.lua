local ADDON_NAME, ns = ...
local L = ns.L

----------------------------------------------------------------------
-- Settings Panel (Tabbed)
----------------------------------------------------------------------

local settingsFrame = nil

-- Helper: get display name for a window's current meter type
local function GetWindowTabName(winIndex)
    local win = ns.windows[winIndex]
    if not win then return string.format(L["SETTINGS_TAB_WINDOW"], winIndex) end
    local meterType = win.GetMeterType()
    local info = ns.TYPE_INFO[meterType]
    if info then
        return L[info.key] or info.key
    end
    return string.format(L["SETTINGS_TAB_WINDOW"], winIndex)
end

local function CreateSettingsPanel()
    local frame = CreateFrame("Frame", "TomoDamageMeterSettings", UIParent, "BackdropTemplate")
    frame:SetSize(340, 520)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)

    frame:SetBackdrop({
        bgFile = ns.FLAT,
        edgeFile = ns.FLAT,
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.00, 0.00, 0.00, 0.88)
    frame:SetBackdropBorderColor(ns.BORDER_COLOR[1], ns.BORDER_COLOR[2], ns.BORDER_COLOR[3], ns.BORDER_COLOR[4])

    -- Title
    local title = frame:CreateFontString(nil, "ARTWORK")
    title:SetFont(ns.GetFont(), 13, "OUTLINE")
    title:SetTextColor(ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3])
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText(L["SETTINGS_TITLE"])

    -- Close button (texture)
    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", -6, -6)
    local closeIcon = closeBtn:CreateTexture(nil, "ARTWORK")
    closeIcon:SetTexture(ns.TEX_CLOSE)
    closeIcon:SetSize(10, 10)
    closeIcon:SetPoint("CENTER")
    closeIcon:SetVertexColor(unpack(ns.TEXT_MUTED))
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    closeBtn:SetScript("OnEnter", function() closeIcon:SetVertexColor(1, 1, 1) end)
    closeBtn:SetScript("OnLeave", function() closeIcon:SetVertexColor(unpack(ns.TEXT_MUTED)) end)

    ----------------------------------------------------------------------
    -- Tab Bar
    ----------------------------------------------------------------------

    local TAB_HEIGHT = 22
    local TAB_PAD = 2
    local tabBar = CreateFrame("Frame", nil, frame)
    tabBar:SetPoint("TOPLEFT", 12, -30)
    tabBar:SetPoint("TOPRIGHT", -12, -30)
    tabBar:SetHeight(TAB_HEIGHT)

    -- Tab separator line
    local tabSep = frame:CreateTexture(nil, "ARTWORK")
    tabSep:SetTexture(ns.FLAT)
    tabSep:SetVertexColor(ns.BORDER_COLOR[1], ns.BORDER_COLOR[2], ns.BORDER_COLOR[3], 0.5)
    tabSep:SetHeight(1)
    tabSep:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, 0)
    tabSep:SetPoint("TOPRIGHT", tabBar, "BOTTOMRIGHT", 0, 0)

    -- Content area (below tabs)
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", tabSep, "BOTTOMLEFT", 0, -6)
    content:SetPoint("BOTTOMRIGHT", -12, 12)

    -- Tab system
    local tabs = {}
    local tabContents = {}
    local activeTab = nil

    local function SetActiveTab(index)
        if activeTab == index then return end
        -- Deactivate previous
        if activeTab and tabs[activeTab] then
            tabs[activeTab].bg:SetVertexColor(0.05, 0.08, 0.14, 0.70)
            tabs[activeTab].text:SetTextColor(unpack(ns.TEXT_MUTED))
        end
        if activeTab and tabContents[activeTab] then
            tabContents[activeTab]:Hide()
        end
        -- Activate new
        activeTab = index
        if tabs[index] then
            tabs[index].bg:SetVertexColor(ns.ACCENT[1] * 0.3, ns.ACCENT[2] * 0.3, ns.ACCENT[3] * 0.3, 0.90)
            tabs[index].text:SetTextColor(ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3])
        end
        if tabContents[index] then
            tabContents[index]:Show()
        end
    end

    local function CreateTab(index, labelText)
        local tab = CreateFrame("Button", nil, tabBar)
        tab:SetHeight(TAB_HEIGHT)

        local bg = tab:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture(ns.FLAT)
        bg:SetVertexColor(0.05, 0.08, 0.14, 0.70)
        bg:SetAllPoints()

        local text = tab:CreateFontString(nil, "ARTWORK")
        text:SetFont(ns.GetFont(), 10, "OUTLINE")
        text:SetTextColor(unpack(ns.TEXT_MUTED))
        text:SetPoint("CENTER", 0, 0)
        text:SetText(labelText)

        local hl = tab:CreateTexture(nil, "HIGHLIGHT")
        hl:SetTexture(ns.FLAT)
        hl:SetVertexColor(1, 1, 1, 0.06)
        hl:SetAllPoints()

        tab.bg = bg
        tab.text = text

        tab:SetScript("OnClick", function()
            SetActiveTab(index)
        end)

        return tab
    end

    local function CreateContentFrame()
        local c = CreateFrame("Frame", nil, content)
        c:SetAllPoints(content)
        c:Hide()
        return c
    end

    ----------------------------------------------------------------------
    -- Build General Tab Content
    ----------------------------------------------------------------------

    local function BuildGeneralContent(parent)
        local yOff = 0
        local function AddWidget(widget, height)
            widget:SetParent(parent)
            widget:ClearAllPoints()
            widget:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -yOff)
            widget:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
            yOff = yOff + (height or 50) + 6
        end

        local function AddSection(text)
            local fs = parent:CreateFontString(nil, "ARTWORK")
            fs:SetFont(ns.GetFont(), 11, "OUTLINE")
            fs:SetTextColor(ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3])
            fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -yOff)
            fs:SetText(text)
            yOff = yOff + 18
        end

        -- Appearance
        AddSection(L["SETTINGS_APPEARANCE"])

        local fontSlider = ns.Widgets.CreateSlider(parent, L["SETTINGS_FONT_SIZE"],
            8, 16, 1,
            function() return ns.db.fontSize end,
            function(val)
                ns.db.fontSize = val
                ns.ClearCharWidthCache()
                for _, win in ipairs(ns.windows) do
                    if win.RefreshFonts then win.RefreshFonts() end
                    win.Refresh()
                end
            end)
        AddWidget(fontSlider, 50)

        local barSlider = ns.Widgets.CreateSlider(parent, L["SETTINGS_BAR_HEIGHT"],
            14, 32, 1,
            function() return ns.db.barHeight end,
            function(val)
                ns.db.barHeight = val
                for _, win in ipairs(ns.windows) do
                    if win.RefreshBarHeight then win.RefreshBarHeight() end
                end
            end)
        AddWidget(barSlider, 50)

        local bgSlider = ns.Widgets.CreateSlider(parent, L["SETTINGS_BG_OPACITY"],
            0, 1, 0.05,
            function() return ns.db.bgAlpha end,
            function(val)
                ns.db.bgAlpha = val
                for _, win in ipairs(ns.windows) do
                    if win.SetBGAlpha then win.SetBGAlpha(val) end
                end
            end)
        AddWidget(bgSlider, 50)

        local oocSlider = ns.Widgets.CreateSlider(parent, L["SETTINGS_OOC_OPACITY"],
            0.1, 1, 0.05,
            function() return ns.db.oocAlpha end,
            function(val)
                ns.db.oocAlpha = val
                if not ns.inCombat then
                    for _, win in ipairs(ns.windows) do
                        win.SetCombatAlpha(false)
                    end
                end
            end)
        AddWidget(oocSlider, 50)

        -- General
        AddSection(L["SETTINGS_GENERAL"])

        local realmCB = ns.Widgets.CreateCheckbox(parent, L["SETTINGS_STRIP_REALM"],
            function() return ns.db.stripRealm end,
            function(val) ns.db.stripRealm = val; ns.Refresh() end)
        AddWidget(realmCB, 24)

        local classCB = ns.Widgets.CreateCheckbox(parent, L["SETTINGS_USE_CLASS_COLOR"],
            function() return ns.db.accentUseClassColor end,
            function(val)
                ns.db.accentUseClassColor = val
                ns.ApplyAccentColor()
                for _, win in ipairs(ns.windows) do
                    if win.RefreshAccentColor then win.RefreshAccentColor() end
                end
            end)
        AddWidget(classCB, 24)

        local autoResetCB = ns.Widgets.CreateCheckbox(parent, L["SETTINGS_AUTO_RESET_INSTANCE"],
            function() return ns.db.autoResetOnInstance end,
            function(val) ns.db.autoResetOnInstance = val end)
        AddWidget(autoResetCB, 24)

        -- Report
        AddSection(L["REPORT"])

        local channelOptions = {
            { value = "SAY",     label = L["REPORT_CHANNEL_SAY"] },
            { value = "PARTY",   label = L["REPORT_CHANNEL_PARTY"] },
            { value = "RAID",    label = L["REPORT_CHANNEL_RAID"] },
            { value = "GUILD",   label = L["REPORT_CHANNEL_GUILD"] },
            { value = "WHISPER", label = L["REPORT_CHANNEL_WHISPER"] },
        }
        local channelDD = ns.Widgets.CreateDropdown(parent, L["SETTINGS_REPORT_CHANNEL"],
            channelOptions,
            function() return ns.db.reportChannel end,
            function(val) ns.db.reportChannel = val end)
        AddWidget(channelDD, 30)

        local linesSlider = ns.Widgets.CreateSlider(parent, L["SETTINGS_REPORT_LINES"],
            1, 20, 1,
            function() return ns.db.reportLines end,
            function(val) ns.db.reportLines = val end)
        AddWidget(linesSlider, 50)
    end

    ----------------------------------------------------------------------
    -- Build Window Tab Content
    ----------------------------------------------------------------------

    local function BuildWindowContent(parent, winIndex)
        local yOff = 0
        local function AddWidget(widget, height)
            widget:SetParent(parent)
            widget:ClearAllPoints()
            widget:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -yOff)
            widget:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
            yOff = yOff + (height or 50) + 6
        end

        local function AddSection(text)
            local fs = parent:CreateFontString(nil, "ARTWORK")
            fs:SetFont(ns.GetFont(), 11, "OUTLINE")
            fs:SetTextColor(ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3])
            fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -yOff)
            fs:SetText(text)
            yOff = yOff + 18
        end

        AddSection(string.format(L["SETTINGS_TAB_WINDOW"], winIndex))

        -- Meter Type dropdown
        local meterOptions = {}
        for _, cat in ipairs(ns.METER_CATEGORIES) do
            for _, t in ipairs(cat.types) do
                meterOptions[#meterOptions + 1] = {
                    value = t.type,
                    label = L[t.key] or t.key,
                }
            end
        end
        local meterDD = ns.Widgets.CreateDropdown(parent, L["SETTINGS_METER_TYPE"],
            meterOptions,
            function()
                local win = ns.windows[winIndex]
                return win and win.GetMeterType() or Enum.DamageMeterType.Dps
            end,
            function(val)
                local win = ns.windows[winIndex]
                if not win then return end
                win.SetMeterType(val)
                -- Update tab name
                C_Timer.After(0, function()
                    if tabs[winIndex + 1] then
                        tabs[winIndex + 1].text:SetText(GetWindowTabName(winIndex))
                    end
                end)
            end)
        AddWidget(meterDD, 30)

        -- Session Type dropdown
        local sessionOptions = {}
        for _, opt in ipairs(ns.SESSION_OPTIONS) do
            sessionOptions[#sessionOptions + 1] = {
                value = opt.type,
                label = L[opt.key] or opt.key,
            }
        end
        local sessionDD = ns.Widgets.CreateDropdown(parent, L["SETTINGS_SESSION_TYPE"],
            sessionOptions,
            function()
                local win = ns.windows[winIndex]
                return win and win.GetSessionType() or Enum.DamageMeterSessionType.Current
            end,
            function(val)
                local win = ns.windows[winIndex]
                if not win then return end
                win.SetSessionType(val)
            end)
        AddWidget(sessionDD, 30)

        -- Locked checkbox
        local lockCB = ns.Widgets.CreateCheckbox(parent, L["SETTINGS_LOCKED"],
            function()
                local win = ns.windows[winIndex]
                return win and win.cfg.locked or false
            end,
            function(val)
                local win = ns.windows[winIndex]
                if not win then return end
                win.cfg.locked = val
            end)
        AddWidget(lockCB, 24)
    end

    ----------------------------------------------------------------------
    -- Rebuild Tabs
    ----------------------------------------------------------------------

    local function RebuildTabs()
        -- Clear existing tabs and content
        for _, tab in ipairs(tabs) do
            tab:Hide()
        end
        for _, c in ipairs(tabContents) do
            c:Hide()
        end
        wipe(tabs)
        wipe(tabContents)
        activeTab = nil

        -- Tab 1: General
        tabs[1] = CreateTab(1, L["SETTINGS_TAB_GENERAL"])
        tabContents[1] = CreateContentFrame()
        BuildGeneralContent(tabContents[1])

        -- One tab per window
        for i = 1, #ns.windows do
            local tabIndex = i + 1
            local tabName = GetWindowTabName(i)
            tabs[tabIndex] = CreateTab(tabIndex, tabName)
            tabContents[tabIndex] = CreateContentFrame()
            BuildWindowContent(tabContents[tabIndex], i)
        end

        -- Add/Remove window buttons as last tab-like controls
        local windowMgmtIndex = #ns.windows + 2

        -- Layout tabs
        local xOff = 0
        for i, tab in ipairs(tabs) do
            tab:ClearAllPoints()
            tab:SetPoint("TOPLEFT", tabBar, "TOPLEFT", xOff, 0)
            local textWidth = tab.text:GetStringWidth()
            tab:SetWidth(textWidth + 16)
            tab:Show()
            xOff = xOff + tab:GetWidth() + TAB_PAD
        end

        -- Add window management: + and - buttons in the tab bar
        if not frame._addTabBtn then
            local addBtn = CreateFrame("Button", nil, tabBar)
            addBtn:SetHeight(TAB_HEIGHT)
            addBtn:SetWidth(26)
            local addBG = addBtn:CreateTexture(nil, "BACKGROUND")
            addBG:SetTexture(ns.FLAT)
            addBG:SetVertexColor(0.05, 0.12, 0.20, 0.70)
            addBG:SetAllPoints()
            local addText = addBtn:CreateFontString(nil, "ARTWORK")
            addText:SetFont(ns.GetFont(), 11, "OUTLINE")
            addText:SetTextColor(unpack(ns.TEXT_PRIMARY))
            addText:SetPoint("CENTER")
            addText:SetText("+")
            local addHL = addBtn:CreateTexture(nil, "HIGHLIGHT")
            addHL:SetTexture(ns.FLAT); addHL:SetVertexColor(1, 1, 1, 0.08)
            addHL:SetAllPoints()
            addBtn:SetScript("OnClick", function()
                if #ns.windows >= ns.MAX_WINDOWS then return end
                ns.CreateNewWindow()
                RebuildTabs()
                SetActiveTab(#ns.windows + 1)
            end)
            frame._addTabBtn = addBtn
            frame._addTabText = addText

            local removeBtn = CreateFrame("Button", nil, tabBar)
            removeBtn:SetHeight(TAB_HEIGHT)
            removeBtn:SetWidth(26)
            local removeBG = removeBtn:CreateTexture(nil, "BACKGROUND")
            removeBG:SetTexture(ns.FLAT)
            removeBG:SetVertexColor(0.05, 0.12, 0.20, 0.70)
            removeBG:SetAllPoints()
            local removeText = removeBtn:CreateFontString(nil, "ARTWORK")
            removeText:SetFont(ns.GetFont(), 11, "OUTLINE")
            removeText:SetTextColor(unpack(ns.TEXT_PRIMARY))
            removeText:SetPoint("CENTER")
            removeText:SetText("-")
            local removeHL = removeBtn:CreateTexture(nil, "HIGHLIGHT")
            removeHL:SetTexture(ns.FLAT); removeHL:SetVertexColor(1, 1, 1, 0.08)
            removeHL:SetAllPoints()
            removeBtn:SetScript("OnClick", function()
                if #ns.windows <= 1 then return end
                ns.RemoveWindow()
                RebuildTabs()
                local newActive = math.min(activeTab or 1, #tabs)
                SetActiveTab(newActive)
            end)
            frame._removeTabBtn = removeBtn
            frame._removeTabText = removeText
        end

        -- Update +/- button colors based on state
        if #ns.windows >= ns.MAX_WINDOWS then
            frame._addTabText:SetTextColor(unpack(ns.TEXT_MUTED))
        else
            frame._addTabText:SetTextColor(unpack(ns.TEXT_PRIMARY))
        end
        if #ns.windows <= 1 then
            frame._removeTabText:SetTextColor(unpack(ns.TEXT_MUTED))
        else
            frame._removeTabText:SetTextColor(unpack(ns.TEXT_PRIMARY))
        end

        -- Position +/- buttons after tabs
        frame._addTabBtn:ClearAllPoints()
        frame._addTabBtn:SetPoint("TOPLEFT", tabBar, "TOPLEFT", xOff, 0)
        frame._addTabBtn:Show()
        xOff = xOff + frame._addTabBtn:GetWidth() + TAB_PAD

        frame._removeTabBtn:ClearAllPoints()
        frame._removeTabBtn:SetPoint("TOPLEFT", tabBar, "TOPLEFT", xOff, 0)
        frame._removeTabBtn:Show()

        -- Activate first tab by default
        SetActiveTab(1)
    end

    frame.RebuildTabs = RebuildTabs
    RebuildTabs()

    frame:Hide()
    return frame
end

function ns.ToggleSettings()
    if not settingsFrame then
        settingsFrame = CreateSettingsPanel()
    end
    -- Rebuild tabs each time we open to reflect current window state
    if not settingsFrame:IsShown() then
        settingsFrame.RebuildTabs()
    end
    settingsFrame:SetShown(not settingsFrame:IsShown())
end
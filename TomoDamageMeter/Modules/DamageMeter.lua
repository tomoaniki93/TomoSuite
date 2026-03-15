local ADDON_NAME, ns = ...
local L = ns.L

----------------------------------------------------------------------
-- Window Factory
----------------------------------------------------------------------

local windowCounter = 0

function ns.CreateMeterWindow(cfg)
    windowCounter = windowCounter + 1

    local state = {
        cfg = cfg,
        meterType = cfg.meterType,
        sessionType = cfg.sessionType,
        dataGeneration = 0,
        elements = {},
    }

    ----------------------------------------------------------------------
    -- Main Frame
    ----------------------------------------------------------------------

    state.window = CreateFrame("Frame", "TomoDamageMeterFrame" .. windowCounter, UIParent)
    local window = state.window
    window:SetSize(cfg.width, cfg.height)
    window:SetPoint(cfg.point, UIParent, cfg.relPoint, cfg.x, cfg.y)
    window:SetMovable(true)
    window:SetResizable(true)
    window:SetResizeBounds(200, ns.HEADER_COMBINED + 4 * 18, 600, 500)
    window:SetClampedToScreen(true)
    window:SetFrameStrata("MEDIUM")
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")

    -- Clamp on first frame
    C_Timer.After(0, function()
        local left = window:GetLeft()
        local top = window:GetTop()
        local w = window:GetWidth()
        local h = window:GetHeight()
        if not left or not top then return end
        local screenW = GetScreenWidth()
        local screenH = GetScreenHeight()
        local clamped = false
        if left < 0 then left = 0; clamped = true end
        if left + w > screenW then left = screenW - w; clamped = true end
        if top > screenH then top = screenH; clamped = true end
        if top - h < 0 then top = h; clamped = true end
        if clamped then
            window:ClearAllPoints()
            window:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        end
    end)

    -- Drag handling
    window:SetScript("OnDragStart", function(self)
        if cfg.locked then return end
        self:StartMoving()
    end)
    window:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save
        local left = self:GetLeft()
        local top = self:GetTop()
        if left and top then
            cfg.point = "TOPLEFT"
            cfg.relPoint = "BOTTOMLEFT"
            cfg.x = left
            cfg.y = top
        end
        cfg.width = self:GetWidth()
        cfg.height = self:GetHeight()
    end)

    -- Propagate drag from children
    local function MakeDraggable(child)
        child:RegisterForDrag("LeftButton")
        child:SetScript("OnDragStart", function()
            window:GetScript("OnDragStart")(window)
        end)
        child:SetScript("OnDragStop", function()
            window:GetScript("OnDragStop")(window)
        end)
    end

    -- Background
    local windowBG = window:CreateTexture(nil, "BACKGROUND", nil, -1)
    windowBG:SetTexture(ns.FLAT)
    windowBG:SetVertexColor(ns.BG[1], ns.BG[2], ns.BG[3], ns.db and ns.db.bgAlpha or ns.BG[4])
    windowBG:SetAllPoints(window)

    ----------------------------------------------------------------------
    -- Borders (subtle 1px)
    ----------------------------------------------------------------------

    local borderColor = ns.BORDER_COLOR
    local function MakeBorder(anchor1, frame1, rel, anchor2, frame2, rel2, width, height)
        local t = window:CreateTexture(nil, "OVERLAY")
        t:SetTexture(ns.FLAT)
        t:SetVertexColor(unpack(borderColor))
        if width then t:SetWidth(width) end
        if height then t:SetHeight(height) end
        t:SetPoint(anchor1, frame1, rel)
        if anchor2 then t:SetPoint(anchor2, frame2, rel2) end
        return t
    end
    -- Top
    local topBorder = window:CreateTexture(nil, "OVERLAY")
    topBorder:SetTexture(ns.FLAT); topBorder:SetVertexColor(unpack(borderColor))
    topBorder:SetHeight(1); topBorder:SetPoint("TOPLEFT"); topBorder:SetPoint("TOPRIGHT")
    -- Bottom
    local bottomBorder = window:CreateTexture(nil, "OVERLAY")
    bottomBorder:SetTexture(ns.FLAT); bottomBorder:SetVertexColor(unpack(borderColor))
    bottomBorder:SetHeight(1); bottomBorder:SetPoint("BOTTOMLEFT"); bottomBorder:SetPoint("BOTTOMRIGHT")
    -- Left
    local leftBorder = window:CreateTexture(nil, "OVERLAY")
    leftBorder:SetTexture(ns.FLAT); leftBorder:SetVertexColor(unpack(borderColor))
    leftBorder:SetWidth(1); leftBorder:SetPoint("TOPLEFT"); leftBorder:SetPoint("BOTTOMLEFT")
    -- Right
    local rightBorder = window:CreateTexture(nil, "OVERLAY")
    rightBorder:SetTexture(ns.FLAT); rightBorder:SetVertexColor(unpack(borderColor))
    rightBorder:SetWidth(1); rightBorder:SetPoint("TOPRIGHT"); rightBorder:SetPoint("BOTTOMRIGHT")

    ----------------------------------------------------------------------
    -- Sub-Header (session strip)
    ----------------------------------------------------------------------

    local headerLevel = window:GetFrameLevel() + 1

    local subHeader = CreateFrame("Button", nil, window)
    subHeader:SetFrameLevel(headerLevel)
    subHeader:SetPoint("TOPLEFT", window, "TOPLEFT", 0, -1)
    subHeader:SetPoint("TOPRIGHT", window, "TOPRIGHT", 0, -1)
    subHeader:SetHeight(ns.SUBHEADER_HEIGHT)
    MakeDraggable(subHeader)

    local subHeaderBG = window:CreateTexture(nil, "BACKGROUND")
    subHeaderBG:SetTexture(ns.FLAT); subHeaderBG:SetVertexColor(unpack(ns.HEADER_BG))
    subHeaderBG:SetPoint("TOPLEFT", subHeader); subHeaderBG:SetPoint("BOTTOMRIGHT", subHeader)

    local subHeaderHL = window:CreateTexture(nil, "BACKGROUND", nil, 1)
    subHeaderHL:SetTexture(ns.FLAT); subHeaderHL:SetVertexColor(unpack(ns.HEADER_HOVER_BG))
    subHeaderHL:SetPoint("TOPLEFT", subHeader); subHeaderHL:SetPoint("BOTTOMRIGHT", subHeader)
    subHeaderHL:Hide()

    -- Separator between subheader and breadcrumb header
    local headerSep = window:CreateTexture(nil, "OVERLAY")
    headerSep:SetTexture(ns.FLAT); headerSep:SetVertexColor(unpack(ns.BORDER_COLOR))
    headerSep:SetHeight(1)
    headerSep:SetPoint("TOPLEFT", subHeader, "BOTTOMLEFT")
    headerSep:SetPoint("TOPRIGHT", subHeader, "BOTTOMRIGHT")

    -- Combat timer (right side of subheader)
    local timerFS = subHeader:CreateFontString(nil, "ARTWORK")
    timerFS:SetFont(ns.GetFont(), ns.BAR_FONT_SIZE, "OUTLINE")
    timerFS:SetTextColor(unpack(ns.TEXT_SECONDARY))
    timerFS:SetJustifyH("RIGHT")
    timerFS:SetPoint("RIGHT", subHeader, "RIGHT", -ns.TEXT_PAD, ns.GetFontNudge())

    -- Session text (centered)
    local sessionText = subHeader:CreateFontString(nil, "ARTWORK")
    sessionText:SetFont(ns.GetFont(), ns.BAR_FONT_SIZE, "OUTLINE")
    sessionText:SetTextColor(unpack(ns.TEXT_SECONDARY))
    sessionText:SetPoint("CENTER", subHeader, "CENTER", 0, ns.GetFontNudge())
    sessionText:SetJustifyH("CENTER")
    sessionText:SetWordWrap(false)

    subHeader:SetScript("OnEnter", function()
        subHeaderHL:Show()
        sessionText:SetTextColor(1, 1, 1)
        timerFS:SetTextColor(1, 1, 1)
    end)
    subHeader:SetScript("OnLeave", function()
        subHeaderHL:Hide()
        sessionText:SetTextColor(unpack(ns.TEXT_SECONDARY))
        if ns.inCombat then
            timerFS:SetTextColor(ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3])
        else
            timerFS:SetTextColor(unpack(ns.TEXT_SECONDARY))
        end
    end)

    -- Session cycling on click
    subHeader:SetScript("OnClick", function()
        local currentIdx = 1
        for i, opt in ipairs(ns.SESSION_OPTIONS) do
            if opt.type == state.sessionType then currentIdx = i; break end
        end
        local nextIdx = (currentIdx % #ns.SESSION_OPTIONS) + 1
        state.sessionType = ns.SESSION_OPTIONS[nextIdx].type
        state.dataGeneration = state.dataGeneration + 1
        if ns.HideSpellBreakdown then ns.HideSpellBreakdown() end
        state.CollectData()
        state.UpdateHeader()
    end)

    ----------------------------------------------------------------------
    -- Breadcrumb Header
    ----------------------------------------------------------------------

    local header = CreateFrame("Frame", nil, window)
    header:SetFrameLevel(headerLevel)
    header:SetPoint("TOPLEFT", headerSep, "BOTTOMLEFT")
    header:SetPoint("TOPRIGHT", headerSep, "BOTTOMRIGHT")
    header:SetHeight(ns.HEADER_TOTAL)

    local headerBG = window:CreateTexture(nil, "BACKGROUND")
    headerBG:SetTexture(ns.FLAT); headerBG:SetVertexColor(unpack(ns.HEADER_BG))
    headerBG:SetPoint("TOPLEFT", header); headerBG:SetPoint("BOTTOMRIGHT", header)

    local headerSep2 = window:CreateTexture(nil, "OVERLAY")
    headerSep2:SetTexture(ns.FLAT); headerSep2:SetVertexColor(unpack(ns.BORDER_COLOR))
    headerSep2:SetHeight(0.8)
    headerSep2:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 1, 0)
    headerSep2:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", -1, 0)

    -- Category button
    local catBtn = CreateFrame("Button", nil, header)
    catBtn:SetFrameLevel(headerLevel)
    catBtn:SetPoint("TOPLEFT", header, "TOPLEFT")
    catBtn:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT")
    MakeDraggable(catBtn)

    local catText = catBtn:CreateFontString(nil, "ARTWORK")
    catText:SetFont(ns.GetFont(), 11, "OUTLINE")
    catText:SetTextColor(unpack(ns.TEXT_SECONDARY))
    catText:SetPoint("LEFT", ns.TEXT_PAD, ns.GetFontNudge())

    local catHL = catBtn:CreateTexture(nil, "BACKGROUND")
    catHL:SetTexture(ns.FLAT); catHL:SetVertexColor(unpack(ns.HEADER_HOVER_BG))
    catHL:SetAllPoints(); catHL:Hide()

    catBtn:SetScript("OnEnter", function() catHL:Show(); catText:SetTextColor(1, 1, 1) end)
    catBtn:SetScript("OnLeave", function() catHL:Hide(); catText:SetTextColor(unpack(ns.TEXT_SECONDARY)) end)

    -- Chevron separator (texture)
    local sep = header:CreateTexture(nil, "ARTWORK")
    sep:SetTexture(ns.TEX_CHEVRON)
    sep:SetSize(6, 6)
    sep:SetVertexColor(ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3], 0.5)

    -- Type button
    local typeBtn = CreateFrame("Button", nil, header)
    typeBtn:SetFrameLevel(headerLevel)
    typeBtn:SetPoint("TOP", header, "TOP")
    typeBtn:SetPoint("BOTTOM", header, "BOTTOM")
    MakeDraggable(typeBtn)

    local typeText = typeBtn:CreateFontString(nil, "ARTWORK")
    typeText:SetFont(ns.GetFont(), 11, "OUTLINE")
    typeText:SetTextColor(unpack(ns.ACCENT))
    typeText:SetPoint("LEFT", ns.TEXT_PAD, ns.GetFontNudge())

    local typeHL = typeBtn:CreateTexture(nil, "BACKGROUND")
    typeHL:SetTexture(ns.FLAT)
    typeHL:SetVertexColor(ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3], 0.15)
    typeHL:SetAllPoints(); typeHL:Hide()

    typeBtn:SetScript("OnEnter", function() typeHL:Show() end)
    typeBtn:SetScript("OnLeave", function() typeHL:Hide() end)

    -- Header icon buttons factory (texture-based)
    local ICON_SIZE = 10
    local function MakeHeaderBtn(anchorTo, texPath)
        local btn = CreateFrame("Button", nil, header)
        btn:SetFrameLevel(headerLevel)
        btn:SetSize(ns.HEADER_HEIGHT, ns.HEADER_HEIGHT)
        if anchorTo then
            btn:SetPoint("TOPRIGHT", anchorTo, "TOPLEFT")
            btn:SetPoint("BOTTOMRIGHT", anchorTo, "BOTTOMLEFT")
        else
            btn:SetPoint("TOPRIGHT", header, "TOPRIGHT")
            btn:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT")
        end
        MakeDraggable(btn)

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetTexture(texPath)
        icon:SetSize(ICON_SIZE, ICON_SIZE)
        icon:SetPoint("CENTER", 0, 0)
        icon:SetVertexColor(unpack(ns.TEXT_MUTED))
        btn._icon = icon

        local hl = btn:CreateTexture(nil, "BACKGROUND")
        hl:SetTexture(ns.FLAT); hl:SetVertexColor(unpack(ns.HEADER_HOVER_BG))
        hl:SetAllPoints(); hl:Hide()
        btn._hl = hl

        btn:SetScript("OnEnter", function() hl:Show(); icon:SetVertexColor(1, 1, 1) end)
        btn:SetScript("OnLeave", function() hl:Hide(); icon:SetVertexColor(unpack(ns.TEXT_MUTED)) end)
        return btn
    end

    -- Reset button (rightmost)
    local resetBtn = MakeHeaderBtn(nil, ns.TEX_RESET)
    resetBtn:SetScript("OnClick", function()
        C_DamageMeter.ResetAllCombatSessions()
    end)

    -- Report button
    local reportBtn = MakeHeaderBtn(resetBtn, ns.TEX_REPORT)
    reportBtn:SetScript("OnClick", function()
        local snap = ns.SnapshotReportData(state.meterType, state.sessionType)
        if not snap then
            print(L["ADDON_PREFIX"] .. L["REPORT_NO_DATA"])
            return
        end
        local channel = ns.db.reportChannel or "SAY"
        local lines = ns.db.reportLines or 5
        ns.SendReport(snap, channel, lines)
    end)

    -- Lock button
    local lockBtn = MakeHeaderBtn(reportBtn, ns.TEX_LOCK)
    local function UpdateLockIcon()
        if cfg.locked then
            lockBtn._icon:SetTexture(ns.TEX_LOCK)
            lockBtn._icon:SetVertexColor(ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3])
        else
            lockBtn._icon:SetTexture(ns.TEX_LOCK_OPEN)
            lockBtn._icon:SetVertexColor(unpack(ns.TEXT_MUTED))
        end
    end
    UpdateLockIcon()
    lockBtn:SetScript("OnClick", function()
        cfg.locked = not cfg.locked
        UpdateLockIcon()
    end)
    lockBtn:SetScript("OnEnter", function() lockBtn._hl:Show(); lockBtn._icon:SetVertexColor(1, 1, 1) end)
    lockBtn:SetScript("OnLeave", function() lockBtn._hl:Hide(); UpdateLockIcon() end)

    -- Details button (spell breakdown)
    local detailsBtn = MakeHeaderBtn(lockBtn, ns.TEX_DETAILS)
    detailsBtn:SetScript("OnClick", function()
        if ns.ShowSpellBreakdown then
            ns.ShowSpellBreakdown(nil, nil, state.meterType, state.sessionType, nil)
        end
    end)

    -- Gear button (settings)
    local gearBtn = MakeHeaderBtn(detailsBtn, ns.TEX_GEAR)
    gearBtn:SetScript("OnClick", function()
        if InCombatLockdown() then
            print(L["ADDON_PREFIX"] .. L["COMBAT_SETTINGS_UNAVAILABLE"])
            return
        end
        if ns.ToggleSettings then
            ns.ToggleSettings()
        end
    end)

    ----------------------------------------------------------------------
    -- Category / Type Menus (click handlers)
    ----------------------------------------------------------------------

    catBtn:SetScript("OnClick", function()
        -- Cycle through enabled categories
        local info = ns.TYPE_INFO[state.meterType]
        local currentCat = info and info.catIdx or 1
        local nextCat = ns.GetNextEnabledCatIdx(currentCat)
        if not nextCat or nextCat == currentCat then return end
        local newType = ns.METER_CATEGORIES[nextCat].types[1].type
        state.meterType = newType
        state.dataGeneration = state.dataGeneration + 1
        if ns.HideSpellBreakdown then ns.HideSpellBreakdown() end
        state.CollectData()
        state.UpdateHeader()
    end)

    typeBtn:SetScript("OnClick", function()
        -- Cycle through types within current category
        local info = ns.TYPE_INFO[state.meterType]
        if not info then return end
        local cat = ns.METER_CATEGORIES[info.catIdx]
        local currentIdx = 1
        for i, t in ipairs(cat.types) do
            if t.type == state.meterType then currentIdx = i; break end
        end
        local nextIdx = (currentIdx % #cat.types) + 1
        state.meterType = cat.types[nextIdx].type
        state.dataGeneration = state.dataGeneration + 1
        if ns.HideSpellBreakdown then ns.HideSpellBreakdown() end
        state.CollectData()
        state.UpdateHeader()
    end)

    ----------------------------------------------------------------------
    -- Vertical Action Strip (right edge)
    ----------------------------------------------------------------------

    local STRIP_W = ns.STRIP_WIDTH
    local actionStrip = CreateFrame("Frame", nil, window)
    actionStrip:SetFrameLevel(headerLevel + 1)
    actionStrip:SetWidth(STRIP_W)
    actionStrip:SetPoint("TOPRIGHT", headerSep2, "BOTTOMRIGHT")
    actionStrip:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT")

    local stripBG = actionStrip:CreateTexture(nil, "BACKGROUND")
    stripBG:SetTexture(ns.FLAT); stripBG:SetVertexColor(0.04, 0.08, 0.14, 0.60)
    stripBG:SetAllPoints()

    local stripSep = actionStrip:CreateTexture(nil, "OVERLAY")
    stripSep:SetTexture(ns.FLAT); stripSep:SetVertexColor(unpack(ns.BORDER_COLOR))
    stripSep:SetWidth(1)
    stripSep:SetPoint("TOPLEFT", actionStrip, "TOPLEFT")
    stripSep:SetPoint("BOTTOMLEFT", actionStrip, "BOTTOMLEFT")

    ----------------------------------------------------------------------
    -- Resize Handle (bottom-right corner)
    ----------------------------------------------------------------------

    local resizeHandle = CreateFrame("Button", nil, window)
    resizeHandle:SetSize(16, 16)
    resizeHandle:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT")
    resizeHandle:SetFrameLevel(window:GetFrameLevel() + 10)

    -- Subtle grip texture
    local gripTex = resizeHandle:CreateTexture(nil, "OVERLAY")
    gripTex:SetTexture(ns.FLAT)
    gripTex:SetVertexColor(0.4, 0.4, 0.43, 0.5)
    gripTex:SetSize(6, 6)
    gripTex:SetPoint("BOTTOMRIGHT", -3, 3)

    resizeHandle:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not cfg.locked then
            window:StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeHandle:SetScript("OnMouseUp", function()
        window:StopMovingOrSizing()
        cfg.width = window:GetWidth()
        cfg.height = window:GetHeight()
    end)
    resizeHandle:SetScript("OnEnter", function()
        gripTex:SetVertexColor(0.7, 0.7, 0.73, 0.8)
    end)
    resizeHandle:SetScript("OnLeave", function()
        gripTex:SetVertexColor(0.4, 0.4, 0.43, 0.5)
    end)

    ----------------------------------------------------------------------
    -- ScrollBox + Bar Entries
    ----------------------------------------------------------------------

    local scrollBox = CreateFrame("Frame", nil, window, "WowScrollBoxList")

    local scrollBar = CreateFrame("EventFrame", nil, window, "MinimalScrollBar")
    scrollBar:SetPoint("TOPRIGHT", actionStrip, "TOPLEFT", -1, 0)
    scrollBar:SetPoint("BOTTOMRIGHT", actionStrip, "BOTTOMLEFT", -1, -1)
    scrollBar:SetWidth(ns.SCROLLBAR_WIDTH)

    -- Style the scrollbar
    do
        if scrollBar.Back then scrollBar.Back:SetAlpha(0) end
        if scrollBar.Forward then scrollBar.Forward:SetAlpha(0) end
        local track = scrollBar.Track
        if track then
            track:ClearAllPoints()
            track:SetPoint("TOPLEFT", 0, 0)
            track:SetPoint("BOTTOMRIGHT", 0, 0)
            for _, key in ipairs({"Begin", "Middle", "End"}) do
                local tex = track[key]
                if tex then tex:SetAlpha(0) end
            end
            local thumb = track.Thumb
            if thumb then
                for _, key in ipairs({"Begin", "Middle", "End"}) do
                    local tex = thumb[key]
                    if tex then tex:SetAlpha(0) end
                end
                local thumbBG = thumb:CreateTexture(nil, "ARTWORK")
                thumbBG:SetTexture(ns.FLAT)
                thumbBG:SetVertexColor(ns.SCROLLBAR_THUMB[1], ns.SCROLLBAR_THUMB[2], ns.SCROLLBAR_THUMB[3], 0.7)
                thumbBG:SetPoint("TOPLEFT", 0, -1)
                thumbBG:SetPoint("BOTTOMRIGHT", 0, 1)
                thumb:HookScript("OnEnter", function()
                    thumbBG:SetVertexColor(0.55, 0.55, 0.60, 0.9)
                end)
                thumb:HookScript("OnLeave", function()
                    thumbBG:SetVertexColor(ns.SCROLLBAR_THUMB[1], ns.SCROLLBAR_THUMB[2], ns.SCROLLBAR_THUMB[3], 0.7)
                end)
            end
        end
    end

    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(ns.GetBarHeight())
    view:SetPadding(0, 0, 0, 0, 0)

    local dataProvider = CreateDataProvider()

    ----------------------------------------------------------------------
    -- Element Initializer (bar entries)
    ----------------------------------------------------------------------

    view:SetElementInitializer("Button", function(button, elementData)
        if not button.bar then
            button:SetHeight(ns.GetBarHeight())
            button:EnableMouse(true)

            -- Spec icon
            local iconFrame = button:CreateTexture(nil, "ARTWORK")
            iconFrame:SetPoint("TOPLEFT", 0, 0)
            iconFrame:SetPoint("BOTTOMLEFT", 0, ns.BAR_SPACING)
            iconFrame:SetWidth(ns.GetBarHeight() - ns.BAR_SPACING)
            iconFrame:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            button.icon = iconFrame

            -- Status bar
            local bar = CreateFrame("StatusBar", nil, button)
            bar:SetStatusBarTexture(ns.FLAT)
            button.bar = bar

            -- Name
            local nameFS = bar:CreateFontString(nil, "OVERLAY")
            nameFS:SetFont(ns.GetFont(), ns.BAR_FONT_SIZE, "OUTLINE")
            nameFS:SetJustifyH("LEFT")
            nameFS:SetWordWrap(false)
            nameFS:SetShadowOffset(1, -1)
            nameFS:SetShadowColor(0, 0, 0, 0.4)
            button.nameFS = nameFS

            -- Value columns
            local function MakeValueFS(parent)
                local fs = parent:CreateFontString(nil, "OVERLAY")
                fs:SetFont(ns.GetFont(), ns.BAR_FONT_SIZE, "OUTLINE")
                fs:SetJustifyH("RIGHT")
                fs:SetShadowOffset(1, -1)
                fs:SetShadowColor(0, 0, 0, 0.4)
                return fs
            end
            button.rateFS = MakeValueFS(bar)
            button.totalFS = MakeValueFS(bar)
            button.pctFS = MakeValueFS(bar)

            -- Hover highlight
            local hl = button:CreateTexture(nil, "HIGHLIGHT")
            hl:SetTexture(ns.FLAT)
            hl:SetVertexColor(1, 1, 1, 0.08)
            hl:SetAllPoints()

            button.fill = bar:GetStatusBarTexture()
            button:HookScript("OnEnter", function(self)
                if self.fill then self.fill:SetAlpha(1) end
                if self.icon then self.icon:SetAlpha(1) end
            end)
            button:HookScript("OnLeave", function(self)
                if self.fill then self.fill:SetAlpha(ns.BAR_ALPHA) end
                if self.icon then self.icon:SetAlpha(ns.ICON_ALPHA) end
            end)

            MakeDraggable(button)

            -- Click: open spell breakdown for this player
            button:SetScript("OnClick", function(self, btn)
                if btn == "LeftButton" and self._elementData then
                    local ed = self._elementData
                    if ed.sourceGUID and not issecretvalue(ed.sourceGUID) then
                        local playerName = (not issecretvalue(ed.name) and ns.db.stripRealm)
                            and ns.StripRealm(ed.name) or (not issecretvalue(ed.name) and ed.name or "?")
                        if ns.ShowSpellBreakdown then
                            ns.ShowSpellBreakdown(playerName, ed.sourceGUID, state.meterType, state.sessionType, ed.classFilename)
                        end
                    end
                end
            end)
        end

        -- Store elementData reference for click handler
        button._elementData = elementData

        -- Update with data
        UpdateButton(button, elementData)
    end)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    -- Managed scrollbar anchors
    local scrollBoxAnchorsWithBar = {
        CreateAnchor("TOPLEFT", headerSep2, "BOTTOMLEFT", 0, 0),
        CreateAnchor("BOTTOMRIGHT", actionStrip, "BOTTOMLEFT", -(ns.SCROLLBAR_WIDTH + 2), 0),
    }
    local scrollBoxAnchorsWithoutBar = {
        CreateAnchor("TOPLEFT", headerSep2, "BOTTOMLEFT", 0, 0),
        CreateAnchor("BOTTOMRIGHT", actionStrip, "BOTTOMLEFT", 0, 0),
    }
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(scrollBox, scrollBar,
        scrollBoxAnchorsWithBar, scrollBoxAnchorsWithoutBar)

    scrollBox:SetDataProvider(dataProvider)

    ----------------------------------------------------------------------
    -- UpdateButton
    ----------------------------------------------------------------------

    function UpdateButton(button, elementData)
        -- Class color
        local color = RAID_CLASS_COLORS[elementData.classFilename]
        local r, g, b = 0.5, 0.5, 0.5
        if color then r, g, b = color.r, color.g, color.b end
        button.bar:SetStatusBarColor(r, g, b, 1.0)

        local fill = button.bar:GetStatusBarTexture()
        fill:SetGradient("HORIZONTAL",
            CreateColor(r * 0.7, g * 0.7, b * 0.7, 1),
            CreateColor(r * 0.3, g * 0.3, b * 0.3, 1))
        fill:SetAlpha(ns.BAR_ALPHA)
        button.icon:SetAlpha(ns.ICON_ALPHA)

        if button:IsMouseOver() then
            fill:SetAlpha(1)
            button.icon:SetAlpha(1)
        end

        -- Bar fill values
        local maxVal = elementData.maxAmount
        if not maxVal or (not issecretvalue(maxVal) and maxVal <= 0) then
            maxVal = 1
        end
        button.bar:SetMinMaxValues(0, maxVal)
        button.bar:SetValue(elementData.totalAmount or 0)

        -- Name
        button.nameFS:SetText(ns.db.stripRealm and ns.StripRealm(elementData.name) or elementData.name or "")

        -- Column values
        ns.PopulateColumnValues(button, elementData)

        -- Text colors
        button.nameFS:SetTextColor(unpack(ns.TEXT_PRIMARY))
        button.rateFS:SetTextColor(unpack(ns.TEXT_PRIMARY))
        button.totalFS:SetTextColor(unpack(ns.TEXT_PRIMARY))
        button.pctFS:SetTextColor(unpack(ns.TEXT_PRIMARY))

        -- Icon + bar anchoring
        button.bar:ClearAllPoints()
        button.nameFS:ClearAllPoints()
        if elementData.specIconID and not issecretvalue(elementData.specIconID)
            and elementData.specIconID > 0 then
            button.icon:SetTexture(elementData.specIconID)
            button.icon:Show()
            local iconSpace = ns.GetBarHeight() - ns.BAR_SPACING
            button.bar:SetPoint("TOPLEFT", iconSpace, 0)
            button.bar:SetPoint("BOTTOMRIGHT", 0, ns.BAR_SPACING)
            button.nameFS:SetPoint("LEFT", button.bar, "LEFT", 4, ns.GetFontNudge())
        else
            button.icon:Hide()
            button.bar:SetPoint("TOPLEFT", 0, 0)
            button.bar:SetPoint("BOTTOMRIGHT", 0, ns.BAR_SPACING)
            button.nameFS:SetPoint("LEFT", button.bar, "LEFT", 6, ns.GetFontNudge())
        end

        local prevFS = ns.AnchorColumns(button)
        if prevFS then
            button.nameFS:SetPoint("RIGHT", prevFS, "LEFT", -4, 0)
        else
            button.nameFS:SetPoint("RIGHT", button.bar, "RIGHT", -6, 0)
        end

        -- Bar grow animation on generation change
        if button._dataGen ~= state.dataGeneration then
            button._dataGen = state.dataGeneration
            local aFill = button.bar:GetStatusBarTexture()
            if not aFill._growAnim then
                local ag = aFill:CreateAnimationGroup()
                local scale = ag:CreateAnimation("Scale")
                scale:SetScaleFrom(0, 1)
                scale:SetScaleTo(1, 1)
                scale:SetOrigin("LEFT", 0, 0)
                scale:SetDuration(0.2)
                scale:SetSmoothing("OUT")
                aFill._growAnim = ag
            end
            aFill._growAnim:Stop()
            aFill._growAnim:Play()
        end
    end

    ----------------------------------------------------------------------
    -- Data Collection
    ----------------------------------------------------------------------

    function state.CollectData()
        local session = C_DamageMeter.GetCombatSessionFromType(state.sessionType, state.meterType)
        dataProvider:Flush()

        if not session or issecretvalue(session) then return end
        local sources = session.combatSources
        if not sources or #sources == 0 then return end

        -- Session total for percentage
        local sessionTotal = 0
        if not issecretvalue(sources[1].totalAmount) then
            for _, s in ipairs(sources) do
                if not issecretvalue(s.totalAmount) then
                    sessionTotal = sessionTotal + s.totalAmount
                end
            end
        end

        -- Max value for bar scaling
        local maxAmount = sources[1].totalAmount

        local isAction = ns.ACTIONS_TYPES[state.meterType] or false
        local maxEntries = isAction and 5 or #sources
        local elements = {}
        for i, source in ipairs(sources) do
            if i > maxEntries then break end
            elements[#elements + 1] = {
                name = source.name,
                classFilename = source.classFilename,
                specIconID = source.specIconID,
                totalAmount = source.totalAmount,
                amountPerSecond = source.amountPerSecond,
                maxAmount = maxAmount,
                sessionTotal = sessionTotal,
                sourceGUID = source.sourceGUID,
                isLocalPlayer = source.isLocalPlayer,
                isActionType = isAction,
            }
        end

        dataProvider:InsertTable(elements)
    end

    -- Throttled refresh
    local refreshPending = false
    function state.ScheduleRefresh()
        if refreshPending then return end
        refreshPending = true
        C_Timer.After(0, function()
            refreshPending = false
            state.CollectData()
        end)
    end

    ----------------------------------------------------------------------
    -- Header Update
    ----------------------------------------------------------------------

    function state.UpdateHeader()
        local info = ns.TYPE_INFO[state.meterType]
        if not info then return end

        local catName = L[info.catName] or info.catName
        local typeName = L[info.key] or info.key
        local sessKey = ns.SESSION_KEYS[state.sessionType]
        local sessionName = sessKey and L[sessKey] or L["CURRENT"]

        catText:SetText(catName)
        typeText:SetText(typeName)
        sessionText:SetText(sessionName)

        -- Size category button to fit text
        local catWidth = catText:GetStringWidth() + ns.TEXT_PAD * 2
        catBtn:SetWidth(catWidth)

        -- Position chevron after category
        sep:ClearAllPoints()
        sep:SetPoint("LEFT", catBtn, "RIGHT", 2, ns.GetFontNudge())

        -- Position type button after chevron
        typeBtn:ClearAllPoints()
        typeBtn:SetPoint("TOPLEFT", sep, "TOPRIGHT", 2, 0)
        typeBtn:SetPoint("BOTTOM", header, "BOTTOM")
        local typeWidth = typeText:GetStringWidth() + ns.TEXT_PAD * 2
        typeBtn:SetWidth(typeWidth)
    end

    ----------------------------------------------------------------------
    -- Timer Update
    ----------------------------------------------------------------------

    function state.UpdateTimer()
        local session = C_DamageMeter.GetCombatSessionFromType(state.sessionType, state.meterType)
        if session and not issecretvalue(session) and session.duration then
            local seconds = session.duration
            if not issecretvalue(seconds) then
                timerFS:SetText(ns.FormatTimer(seconds))
                if ns.inCombat then
                    timerFS:SetTextColor(ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3])
                else
                    timerFS:SetTextColor(unpack(ns.TEXT_SECONDARY))
                end
                return
            end
        end
        timerFS:SetText("")
    end

    ----------------------------------------------------------------------
    -- Return window interface
    ----------------------------------------------------------------------

    local win = {
        frame = window,
        cfg = cfg,
        BumpGeneration = function() state.dataGeneration = state.dataGeneration + 1 end,
        Refresh = state.ScheduleRefresh,
        UpdateTimer = function() state.UpdateTimer() end,
        UpdateHeader = function() state.UpdateHeader() end,
        SetMeterType = function(meterType)
            state.meterType = meterType
            cfg.meterType = meterType
            state.dataGeneration = state.dataGeneration + 1
            if ns.HideSpellBreakdown then ns.HideSpellBreakdown() end
            state.CollectData()
            state.UpdateHeader()
        end,
        SetSessionType = function(sessionType)
            state.sessionType = sessionType
            cfg.sessionType = sessionType
            state.dataGeneration = state.dataGeneration + 1
            if ns.HideSpellBreakdown then ns.HideSpellBreakdown() end
            state.CollectData()
            state.UpdateHeader()
        end,
        GetMeterType = function() return state.meterType end,
        GetSessionType = function() return state.sessionType end,
        SetCombatAlpha = function(inCombat)
            local oocAlpha = ns.db and ns.db.oocAlpha or 1
            if inCombat then
                window:SetAlpha(1)
            else
                window:SetAlpha(oocAlpha)
            end
        end,
        SavePosition = function()
            local left = window:GetLeft()
            local top = window:GetTop()
            if left and top then
                cfg.point = "TOPLEFT"
                cfg.relPoint = "BOTTOMLEFT"
                cfg.x = left
                cfg.y = top
            end
            cfg.width = window:GetWidth()
            cfg.height = window:GetHeight()
            cfg.meterType = state.meterType
            cfg.sessionType = state.sessionType
        end,
        SetBGAlpha = function(alpha)
            windowBG:SetVertexColor(ns.BG[1], ns.BG[2], ns.BG[3], alpha)
        end,
        RefreshAccentColor = function()
            local a1, a2, a3 = ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3]
            sep:SetVertexColor(a1, a2, a3, 0.5)
            typeText:SetTextColor(a1, a2, a3, ns.ACCENT[4])
            typeHL:SetVertexColor(a1, a2, a3, 0.15)
            UpdateLockIcon()
        end,
        RefreshFonts = function()
            local fs = ns.GetFontSize()
            local font = ns.GetFont()
            local nudge = ns.GetFontNudge()
            for _, button in scrollBox:EnumerateFrames() do
                if button.nameFS then
                    button.nameFS:SetFont(font, fs, "OUTLINE")
                    button.rateFS:SetFont(font, fs, "OUTLINE")
                    button.totalFS:SetFont(font, fs, "OUTLINE")
                    button.pctFS:SetFont(font, fs, "OUTLINE")
                    local prevFS = ns.AnchorColumns(button)
                    button.nameFS:ClearAllPoints()
                    local pad = button.icon:IsShown() and 4 or 6
                    button.nameFS:SetPoint("LEFT", button.bar, "LEFT", pad, nudge)
                    if prevFS then
                        button.nameFS:SetPoint("RIGHT", prevFS, "LEFT", -4, 0)
                    else
                        button.nameFS:SetPoint("RIGHT", button.bar, "RIGHT", -6, 0)
                    end
                end
            end
            catText:SetFont(font, 11, "OUTLINE")
            typeText:SetFont(font, 11, "OUTLINE")
            timerFS:SetFont(font, ns.BAR_FONT_SIZE, "OUTLINE")
            sessionText:SetFont(font, ns.BAR_FONT_SIZE, "OUTLINE")
            catText:SetPoint("LEFT", ns.TEXT_PAD, nudge)
            typeText:SetPoint("LEFT", ns.TEXT_PAD, nudge)
            sessionText:SetPoint("CENTER", subHeader, "CENTER", 0, nudge)
            timerFS:SetPoint("RIGHT", subHeader, "RIGHT", -ns.TEXT_PAD, nudge)
            state.UpdateHeader()
        end,
        RefreshBarHeight = function()
            local bh = ns.GetBarHeight()
            view:SetElementExtent(bh)
            for _, button in scrollBox:EnumerateFrames() do
                if button.bar then
                    button:SetHeight(bh)
                    button.icon:SetWidth(bh - ns.BAR_SPACING)
                end
            end
            state.CollectData()
        end,
    }

    return win
end
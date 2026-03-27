local ADDON_NAME, ns = ...
local L = ns.L

----------------------------------------------------------------------
-- SpellBreakdown: standalone window with player selector + spell list
----------------------------------------------------------------------

local WINDOW_WIDTH   = 420
local WINDOW_HEIGHT  = 520
local HEADER_HEIGHT  = 26
local PLAYER_STRIP_H = 22
local COLHEAD_HEIGHT = 16
local SPELL_BAR_H    = 20
local SPELL_BAR_SP   = 1
local ICON_PAD       = 2
local TEXT_PAD        = 6
local BORDER_SIZE    = 1
local RANK_WIDTH     = 22

-- Column widths
local COL_PCT_W      = 46
local COL_PERSEC_W   = 50
local COL_TOTAL_W    = 60

----------------------------------------------------------------------
-- Singleton
----------------------------------------------------------------------

local breakdownFrame = nil

-- Current state
local currentGUID = nil
local currentMeterType = nil
local currentSessionType = nil
local playerButtons = {}

local function EnsureWindow()
    if breakdownFrame then return breakdownFrame end

    --------------------------------------------------------------------------
    -- Main Frame
    --------------------------------------------------------------------------

    local frame = CreateFrame("Frame", "TomoDMSpellBreakdown", UIParent, "BackdropTemplate")
    frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetResizeBounds(360, 300, 600, 800)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    frame:SetBackdrop({
        bgFile   = ns.FLAT,
        edgeFile = ns.FLAT,
        edgeSize = BORDER_SIZE,
    })
    frame:SetBackdropColor(ns.BG[1], ns.BG[2], ns.BG[3], ns.db and ns.db.bgAlpha or ns.BG[4])
    frame:SetBackdropBorderColor(ns.BORDER_COLOR[1], ns.BORDER_COLOR[2], ns.BORDER_COLOR[3], ns.BORDER_COLOR[4])

    tinsert(UISpecialFrames, "TomoDMSpellBreakdown")

    --------------------------------------------------------------------------
    -- Header (title + close)
    --------------------------------------------------------------------------

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", BORDER_SIZE, -BORDER_SIZE)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -BORDER_SIZE, -BORDER_SIZE)
    header:SetHeight(HEADER_HEIGHT)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() frame:StartMoving() end)
    header:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    local headerBG = header:CreateTexture(nil, "BACKGROUND")
    headerBG:SetTexture(ns.FLAT)
    headerBG:SetVertexColor(unpack(ns.HEADER_BG))
    headerBG:SetAllPoints()

    local headerSep = frame:CreateTexture(nil, "OVERLAY")
    headerSep:SetTexture(ns.FLAT)
    headerSep:SetVertexColor(unpack(ns.BORDER_COLOR))
    headerSep:SetHeight(1)
    headerSep:SetPoint("TOPLEFT", header, "BOTTOMLEFT")
    headerSep:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT")

    -- Details icon in header
    local detailsIcon = header:CreateTexture(nil, "ARTWORK")
    detailsIcon:SetTexture(ns.TEX_DETAILS)
    detailsIcon:SetSize(12, 12)
    detailsIcon:SetPoint("LEFT", header, "LEFT", TEXT_PAD, 0)
    detailsIcon:SetVertexColor(ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3])

    -- Title
    local titleFS = header:CreateFontString(nil, "ARTWORK")
    titleFS:SetFont(ns.GetFont(), 12, "OUTLINE")
    titleFS:SetTextColor(ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3])
    titleFS:SetPoint("LEFT", detailsIcon, "RIGHT", 6, ns.GetFontNudge())
    titleFS:SetText(L["SPELL_BREAKDOWN"])

    -- Meter type label (right of title)
    local typeFS = header:CreateFontString(nil, "ARTWORK")
    typeFS:SetFont(ns.GetFont(), 10, "OUTLINE")
    typeFS:SetTextColor(unpack(ns.TEXT_SECONDARY))
    typeFS:SetPoint("LEFT", titleFS, "RIGHT", 8, 0)
    frame._typeFS = typeFS

    -- Close button
    local closeBtn = CreateFrame("Button", nil, header)
    closeBtn:SetSize(HEADER_HEIGHT, HEADER_HEIGHT)
    closeBtn:SetPoint("TOPRIGHT", header, "TOPRIGHT")
    closeBtn:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT")
    local closeIcon = closeBtn:CreateTexture(nil, "ARTWORK")
    closeIcon:SetTexture(ns.TEX_CLOSE)
    closeIcon:SetSize(10, 10)
    closeIcon:SetPoint("CENTER")
    closeIcon:SetVertexColor(unpack(ns.TEXT_MUTED))
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    closeBtn:SetScript("OnEnter", function() closeIcon:SetVertexColor(1, 1, 1) end)
    closeBtn:SetScript("OnLeave", function() closeIcon:SetVertexColor(unpack(ns.TEXT_MUTED)) end)
    local closeHL = closeBtn:CreateTexture(nil, "HIGHLIGHT")
    closeHL:SetTexture(ns.FLAT)
    closeHL:SetVertexColor(1, 1, 1, 0.06)
    closeHL:SetAllPoints()

    --------------------------------------------------------------------------
    -- Player Strip (horizontal row of class-colored name buttons)
    --------------------------------------------------------------------------

    local playerStrip = CreateFrame("Frame", nil, frame)
    playerStrip:SetPoint("TOPLEFT", headerSep, "BOTTOMLEFT", BORDER_SIZE, 0)
    playerStrip:SetPoint("TOPRIGHT", headerSep, "BOTTOMRIGHT", -BORDER_SIZE, 0)
    playerStrip:SetHeight(PLAYER_STRIP_H)

    local stripBG = playerStrip:CreateTexture(nil, "BACKGROUND")
    stripBG:SetTexture(ns.FLAT)
    stripBG:SetVertexColor(0.03, 0.06, 0.12, 1)
    stripBG:SetAllPoints()

    local stripSep = frame:CreateTexture(nil, "OVERLAY")
    stripSep:SetTexture(ns.FLAT)
    stripSep:SetVertexColor(unpack(ns.BORDER_COLOR))
    stripSep:SetHeight(0.8)
    stripSep:SetPoint("TOPLEFT", playerStrip, "BOTTOMLEFT")
    stripSep:SetPoint("TOPRIGHT", playerStrip, "BOTTOMRIGHT")

    frame._playerStrip = playerStrip

    --------------------------------------------------------------------------
    -- Column Header Bar
    --------------------------------------------------------------------------

    local colHeader = CreateFrame("Frame", nil, frame)
    colHeader:SetPoint("TOPLEFT", stripSep, "BOTTOMLEFT", 0, 0)
    colHeader:SetPoint("TOPRIGHT", stripSep, "BOTTOMRIGHT", 0, 0)
    colHeader:SetHeight(COLHEAD_HEIGHT)

    local colHeaderBG = colHeader:CreateTexture(nil, "BACKGROUND")
    colHeaderBG:SetTexture(ns.FLAT)
    colHeaderBG:SetVertexColor(0.05, 0.08, 0.14, 0.80)
    colHeaderBG:SetAllPoints()

    local colHeaderSep = frame:CreateTexture(nil, "OVERLAY")
    colHeaderSep:SetTexture(ns.FLAT)
    colHeaderSep:SetVertexColor(unpack(ns.BORDER_COLOR))
    colHeaderSep:SetHeight(0.8)
    colHeaderSep:SetPoint("TOPLEFT", colHeader, "BOTTOMLEFT", 1, 0)
    colHeaderSep:SetPoint("TOPRIGHT", colHeader, "BOTTOMRIGHT", -1, 0)

    local function MakeColLabel(parent, text, width, anchorTo)
        local fs = parent:CreateFontString(nil, "ARTWORK")
        fs:SetFont(ns.GetFont(), 9, "OUTLINE")
        fs:SetTextColor(unpack(ns.TEXT_MUTED))
        fs:SetJustifyH("RIGHT")
        fs:SetWidth(width)
        if anchorTo then
            fs:SetPoint("RIGHT", anchorTo, "LEFT", -4, 0)
        else
            fs:SetPoint("RIGHT", parent, "RIGHT", -TEXT_PAD, 0)
        end
        fs:SetText(text)
        return fs
    end

    local colPct    = MakeColLabel(colHeader, "%",                     COL_PCT_W,    nil)
    local colPerSec = MakeColLabel(colHeader, "/s",                    COL_PERSEC_W, colPct)
    local colTotal  = MakeColLabel(colHeader, L["BREAKDOWN_COL_TOTAL"], COL_TOTAL_W,  colPerSec)

    local colSpell = colHeader:CreateFontString(nil, "ARTWORK")
    colSpell:SetFont(ns.GetFont(), 9, "OUTLINE")
    colSpell:SetTextColor(unpack(ns.TEXT_MUTED))
    colSpell:SetJustifyH("LEFT")
    colSpell:SetPoint("LEFT", colHeader, "LEFT", RANK_WIDTH + SPELL_BAR_H + ICON_PAD + TEXT_PAD + 4, 0)
    colSpell:SetPoint("RIGHT", colTotal, "LEFT", -4, 0)
    colSpell:SetText(L["BREAKDOWN_COL_SPELL"])

    --------------------------------------------------------------------------
    -- Resize Handle
    --------------------------------------------------------------------------

    local resizeHandle = CreateFrame("Button", nil, frame)
    resizeHandle:SetSize(16, 16)
    resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
    resizeHandle:SetFrameLevel(frame:GetFrameLevel() + 10)
    local gripTex = resizeHandle:CreateTexture(nil, "OVERLAY")
    gripTex:SetTexture(ns.FLAT)
    gripTex:SetVertexColor(0.4, 0.4, 0.43, 0.5)
    gripTex:SetSize(6, 6)
    gripTex:SetPoint("BOTTOMRIGHT", -3, 3)
    resizeHandle:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then frame:StartSizing("BOTTOMRIGHT") end
    end)
    resizeHandle:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)
    resizeHandle:SetScript("OnEnter", function() gripTex:SetVertexColor(0.7, 0.7, 0.73, 0.8) end)
    resizeHandle:SetScript("OnLeave", function() gripTex:SetVertexColor(0.4, 0.4, 0.43, 0.5) end)

    --------------------------------------------------------------------------
    -- Spell ScrollBox
    --------------------------------------------------------------------------

    local spellScroll = CreateFrame("Frame", nil, frame, "WowScrollBoxList")

    local spellScrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    spellScrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -(BORDER_SIZE + 1), -(HEADER_HEIGHT + PLAYER_STRIP_H + COLHEAD_HEIGHT + 3))
    spellScrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(BORDER_SIZE + 1), BORDER_SIZE)
    spellScrollBar:SetWidth(ns.SCROLLBAR_WIDTH)

    -- Style scrollbar
    do
        if spellScrollBar.Back then spellScrollBar.Back:SetAlpha(0) end
        if spellScrollBar.Forward then spellScrollBar.Forward:SetAlpha(0) end
        local track = spellScrollBar.Track
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
    view:SetElementExtent(SPELL_BAR_H + SPELL_BAR_SP)
    view:SetPadding(0, 0, 0, 0, 0)

    local dataProvider = CreateDataProvider()
    frame._dataProvider = dataProvider

    --------------------------------------------------------------------------
    -- Spell bar element initializer
    --------------------------------------------------------------------------

    view:SetElementInitializer("Frame", function(button, data)
        if not button._init then
            button:SetHeight(SPELL_BAR_H + SPELL_BAR_SP)

            local rankFS = button:CreateFontString(nil, "ARTWORK")
            rankFS:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
            rankFS:SetTextColor(unpack(ns.TEXT_MUTED))
            rankFS:SetJustifyH("RIGHT")
            rankFS:SetWidth(RANK_WIDTH)
            rankFS:SetPoint("LEFT", 2, ns.GetFontNudge())
            button._rankFS = rankFS

            local icon = button:CreateTexture(nil, "ARTWORK")
            icon:SetPoint("LEFT", rankFS, "RIGHT", 2, 0)
            icon:SetSize(SPELL_BAR_H - 2, SPELL_BAR_H - 2)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            button._icon = icon

            local bar = CreateFrame("StatusBar", nil, button)
            bar:SetStatusBarTexture(ns.FLAT)
            bar:SetPoint("TOPLEFT", icon, "TOPRIGHT", ICON_PAD, 0)
            bar:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, SPELL_BAR_SP)
            button._bar = bar

            local spellNameFS = bar:CreateFontString(nil, "OVERLAY")
            spellNameFS:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
            spellNameFS:SetJustifyH("LEFT")
            spellNameFS:SetWordWrap(false)
            spellNameFS:SetShadowOffset(1, -1)
            spellNameFS:SetShadowColor(0, 0, 0, 0.4)
            button._nameFS = spellNameFS

            local totalFS = bar:CreateFontString(nil, "OVERLAY")
            totalFS:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
            totalFS:SetJustifyH("RIGHT")
            totalFS:SetShadowOffset(1, -1)
            totalFS:SetShadowColor(0, 0, 0, 0.4)
            button._totalFS = totalFS

            local perSecFS = bar:CreateFontString(nil, "OVERLAY")
            perSecFS:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
            perSecFS:SetJustifyH("RIGHT")
            perSecFS:SetTextColor(unpack(ns.TEXT_SECONDARY))
            perSecFS:SetShadowOffset(1, -1)
            perSecFS:SetShadowColor(0, 0, 0, 0.4)
            button._perSecFS = perSecFS

            local pctFS = bar:CreateFontString(nil, "OVERLAY")
            pctFS:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
            pctFS:SetJustifyH("RIGHT")
            pctFS:SetShadowOffset(1, -1)
            pctFS:SetShadowColor(0, 0, 0, 0.4)
            button._pctFS = pctFS

            local hl = button:CreateTexture(nil, "HIGHLIGHT")
            hl:SetTexture(ns.FLAT)
            hl:SetVertexColor(1, 1, 1, 0.08)
            hl:SetAllPoints()

            button._init = true
        end

        local nudge = ns.GetFontNudge()

        button._rankFS:SetText(data.rank .. ".")
        button._icon:SetTexture(data.icon or 134400)

        local r, g, b = ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3]
        if data.classColor then
            r, g, b = data.classColor.r, data.classColor.g, data.classColor.b
        end
        button._bar:SetStatusBarColor(r, g, b, 1)
        local fill = button._bar:GetStatusBarTexture()
        fill:SetGradient("HORIZONTAL",
            CreateColor(r * 0.7, g * 0.7, b * 0.7, 1),
            CreateColor(r * 0.25, g * 0.25, b * 0.25, 1))
        fill:SetAlpha(ns.BAR_ALPHA)

        button._bar:SetMinMaxValues(0, data.maxTotal or 1)
        button._bar:SetValue(data.total or 0)

        button._nameFS:SetText(data.name or "?")
        button._nameFS:SetTextColor(unpack(ns.TEXT_PRIMARY))

        button._pctFS:SetText(string.format("%.1f%%", data.pct or 0))
        button._pctFS:SetTextColor(r, g, b)

        button._totalFS:SetText(ns.FormatNumber(data.total or 0, "1dec"))
        button._totalFS:SetTextColor(unpack(ns.TEXT_PRIMARY))

        if data.perSec and not issecretvalue(data.perSec) and data.perSec > 0 then
            button._perSecFS:SetText(ns.FormatNumber(data.perSec, "1dec"))
        else
            button._perSecFS:SetText("-")
        end

        button._pctFS:ClearAllPoints()
        button._pctFS:SetPoint("RIGHT", button._bar, "RIGHT", -TEXT_PAD, nudge)
        button._pctFS:SetWidth(COL_PCT_W)

        button._perSecFS:ClearAllPoints()
        button._perSecFS:SetPoint("RIGHT", button._pctFS, "LEFT", -4, 0)
        button._perSecFS:SetWidth(COL_PERSEC_W)

        button._totalFS:ClearAllPoints()
        button._totalFS:SetPoint("RIGHT", button._perSecFS, "LEFT", -4, 0)
        button._totalFS:SetWidth(COL_TOTAL_W)

        button._nameFS:ClearAllPoints()
        button._nameFS:SetPoint("LEFT", button._bar, "LEFT", TEXT_PAD, nudge)
        button._nameFS:SetPoint("RIGHT", button._totalFS, "LEFT", -4, 0)
    end)

    ScrollUtil.InitScrollBoxListWithScrollBar(spellScroll, spellScrollBar, view)

    local anchorsWithBar = {
        CreateAnchor("TOPLEFT", colHeaderSep, "BOTTOMLEFT", BORDER_SIZE, 0),
        CreateAnchor("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(ns.SCROLLBAR_WIDTH + BORDER_SIZE + 2), BORDER_SIZE),
    }
    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", colHeaderSep, "BOTTOMLEFT", BORDER_SIZE, 0),
        CreateAnchor("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -BORDER_SIZE, BORDER_SIZE),
    }
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(spellScroll, spellScrollBar,
        anchorsWithBar, anchorsWithoutBar)

    spellScroll:SetDataProvider(dataProvider)

    -- No data text
    local noDataFS = frame:CreateFontString(nil, "ARTWORK")
    noDataFS:SetFont(ns.GetFont(), 11, "OUTLINE")
    noDataFS:SetTextColor(unpack(ns.TEXT_MUTED))
    noDataFS:SetPoint("CENTER", spellScroll, "CENTER", 0, 0)
    noDataFS:SetText(L["NO_DATA"])
    noDataFS:Hide()
    frame._noDataFS = noDataFS

    frame:Hide()
    breakdownFrame = frame
    return frame
end

----------------------------------------------------------------------
-- Player Strip: build clickable buttons from current session
----------------------------------------------------------------------

local function BuildPlayerStrip(frame, meterType, sessionType, selectedGUID)
    local strip = frame._playerStrip

    -- Hide old buttons
    for _, btn in ipairs(playerButtons) do
        btn:Hide()
    end
    wipe(playerButtons)

    -- Get session data for player list
    local session = C_DamageMeter.GetCombatSessionFromType(sessionType, meterType)
    if not session or issecretvalue(session) then return nil end
    local sources = session.combatSources
    if not sources or #sources == 0 then return nil end

    local xOff = 4
    local firstGUID = nil

    for i, source in ipairs(sources) do
        local name = source.name
        local guid = source.sourceGUID
        local classFile = source.classFilename

        if not name or issecretvalue(name) then name = "?" end
        if issecretvalue(guid) then guid = nil end

        if guid then
            if not firstGUID then firstGUID = guid end

            local btn = playerButtons[i]
            if not btn then
                btn = CreateFrame("Button", nil, strip)
                btn:SetHeight(PLAYER_STRIP_H - 4)
                playerButtons[i] = btn

                local bg = btn:CreateTexture(nil, "BACKGROUND")
                bg:SetTexture(ns.FLAT)
                bg:SetAllPoints()
                btn._bg = bg

                local text = btn:CreateFontString(nil, "ARTWORK")
                text:SetFont(ns.GetFont(), 9, "OUTLINE")
                text:SetPoint("CENTER", 0, 0)
                text:SetWordWrap(false)
                btn._text = text

                local hl = btn:CreateTexture(nil, "HIGHLIGHT")
                hl:SetTexture(ns.FLAT)
                hl:SetVertexColor(1, 1, 1, 0.08)
                hl:SetAllPoints()
            end

            local shortName = ns.StripRealm(name) or name
            btn._text:SetText(shortName)

            local cc = classFile and RAID_CLASS_COLORS[classFile]
            local isSelected = (guid == selectedGUID)

            if isSelected then
                btn._bg:SetVertexColor(
                    cc and cc.r * 0.3 or ns.ACCENT[1] * 0.3,
                    cc and cc.g * 0.3 or ns.ACCENT[2] * 0.3,
                    cc and cc.b * 0.3 or ns.ACCENT[3] * 0.3, 0.90)
                btn._text:SetTextColor(cc and cc.r or 1, cc and cc.g or 1, cc and cc.b or 1)
            else
                btn._bg:SetVertexColor(0.05, 0.08, 0.14, 0.70)
                btn._text:SetTextColor(unpack(ns.TEXT_MUTED))
            end

            -- Store data for click
            btn._guid = guid
            btn._classFile = classFile
            btn._playerName = shortName

            btn:SetScript("OnClick", function(self)
                local pName = self._playerName
                local pGUID = self._guid
                local pClass = self._classFile
                ns.ShowSpellBreakdown(pName, pGUID, currentMeterType, currentSessionType, pClass)
            end)

            local textW = btn._text:GetStringWidth()
            btn:SetWidth(math.max(textW + 12, 40))
            btn:ClearAllPoints()
            btn:SetPoint("LEFT", strip, "LEFT", xOff, 0)
            btn:Show()

            xOff = xOff + btn:GetWidth() + 2
        end
    end

    return firstGUID
end

----------------------------------------------------------------------
-- Populate spell list for a given player
----------------------------------------------------------------------

local function PopulateSpells(frame, sourceGUID, meterType, sessionType, classFilename)
    local classColor = classFilename and RAID_CLASS_COLORS[classFilename]

    local spells, grandTotal = ns.GetSpellBreakdown(sessionType, meterType, sourceGUID)

    frame._dataProvider:Flush()

    if not spells or #spells == 0 then
        frame._noDataFS:Show()
        frame:Show()
        return
    end

    frame._noDataFS:Hide()

    local maxTotal = spells[1].total
    local elements = {}
    for i, spell in ipairs(spells) do
        elements[#elements + 1] = {
            rank       = i,
            name       = spell.name,
            icon       = spell.icon,
            total      = spell.total,
            perSec     = spell.perSec,
            pct        = spell.pct,
            maxTotal   = maxTotal,
            classColor = classColor,
        }
    end
    frame._dataProvider:InsertTable(elements)
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

function ns.ShowSpellBreakdown(playerName, sourceGUID, meterType, sessionType, classFilename)
    local frame = EnsureWindow()

    -- Apply opacity
    frame:SetAlpha(ns.db and ns.db.breakdownAlpha or 0.85)

    currentMeterType = meterType
    currentSessionType = sessionType

    -- Update meter type label
    local info = ns.TYPE_INFO[meterType]
    if info then
        frame._typeFS:SetText("— " .. (L[info.key] or info.key))
    else
        frame._typeFS:SetText("")
    end

    -- Build player strip and auto-select first if no GUID given
    local firstGUID = BuildPlayerStrip(frame, meterType, sessionType, sourceGUID)

    if not sourceGUID then
        sourceGUID = firstGUID
        -- Find classFilename for first player
        if sourceGUID then
            local session = C_DamageMeter.GetCombatSessionFromType(sessionType, meterType)
            if session and not issecretvalue(session) and session.combatSources then
                for _, src in ipairs(session.combatSources) do
                    if src.sourceGUID == sourceGUID then
                        classFilename = src.classFilename
                        playerName = ns.StripRealm(src.name) or src.name
                        break
                    end
                end
            end
        end
    end

    currentGUID = sourceGUID

    if not sourceGUID then
        frame._dataProvider:Flush()
        frame._noDataFS:Show()
        frame:Show()
        return
    end

    -- Refresh player strip highlighting
    BuildPlayerStrip(frame, meterType, sessionType, sourceGUID)

    -- Populate spell list
    PopulateSpells(frame, sourceGUID, meterType, sessionType, classFilename)

    frame:Show()
end

function ns.HideSpellBreakdown()
    if breakdownFrame then
        breakdownFrame:Hide()
        breakdownFrame._dataProvider:Flush()
    end
end

function ns.ApplyBreakdownAlpha()
    if breakdownFrame then
        local alpha = ns.db and ns.db.breakdownAlpha or 0.85
        breakdownFrame:SetAlpha(alpha)
    end
end

----------------------------------------------------------------------
-- ShowTargetSpells: open breakdown for an enemy target in a segment.
-- Uses GetCombatSessionSourceFromID + sourceCreatureID (no GUID needed).
----------------------------------------------------------------------

function ns.ShowTargetSpells(targetName, sourceCreatureID, sessionID)
    local frame = EnsureWindow()

    frame:SetAlpha(ns.db and ns.db.breakdownAlpha or 0.85)
    currentMeterType = Enum.DamageMeterType.DamageDone
    currentSessionType = nil

    -- Update header labels
    frame._typeFS:SetText("— " .. (targetName or L["ENEMY_DAMAGE"]))

    -- Hide player strip (not applicable for segment view)
    for _, btn in ipairs(playerButtons) do btn:Hide() end

    local playerGUID = UnitGUID("player")
    currentGUID = playerGUID

    -- Fetch the player's spell breakdown for this segment via DamageDone
    local spells, grandTotal
    if sessionID and playerGUID then
        spells, grandTotal = ns.GetSpellBreakdownBySegment(
            sessionID, Enum.DamageMeterType.DamageDone, playerGUID)
    end

    -- Get player class for bar coloring
    local _, classFile = UnitClass("player")
    local classColor = classFile and RAID_CLASS_COLORS[classFile]

    frame._dataProvider:Flush()

    if not spells or #spells == 0 then
        frame._noDataFS:Show()
        frame:Show()
        return
    end

    frame._noDataFS:Hide()

    local maxTotal = spells[1].total
    local elements = {}
    for i, spell in ipairs(spells) do
        elements[#elements + 1] = {
            rank       = i,
            name       = spell.name,
            icon       = spell.icon,
            total      = spell.total,
            perSec     = spell.perSec,
            pct        = spell.pct,
            maxTotal   = maxTotal,
            classColor = classColor,
        }
    end
    frame._dataProvider:InsertTable(elements)
    frame:Show()
end

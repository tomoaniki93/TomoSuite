local ADDON_NAME, ns = ...

----------------------------------------------------------------------
-- Number Formatting
----------------------------------------------------------------------

-- Custom breakpoints for AbbreviateNumbers (compact / no decimals)
local BREAKPOINTS_SHORT = {
    { breakpoint = 1000000000, significandDivisor = 1000000000, fractionDivisor = 1, abbreviation = "B", abbreviationIsGlobal = false },
    { breakpoint = 1000000,    significandDivisor = 1000000,    fractionDivisor = 1, abbreviation = "M", abbreviationIsGlobal = false },
    { breakpoint = 1000,       significandDivisor = 1000,       fractionDivisor = 1, abbreviation = "K", abbreviationIsGlobal = false },
    { breakpoint = 1,          significandDivisor = 1,          fractionDivisor = 1, abbreviation = "",  abbreviationIsGlobal = false },
}
local OPTS_SHORT = { breakpointData = BREAKPOINTS_SHORT }

-- 1-decimal
local BREAKPOINTS_1DEC = {
    { breakpoint = 1000000000, significandDivisor = 100000000, fractionDivisor = 10, abbreviation = "B", abbreviationIsGlobal = false },
    { breakpoint = 1000000,    significandDivisor = 100000,    fractionDivisor = 10, abbreviation = "M", abbreviationIsGlobal = false },
    { breakpoint = 1000,       significandDivisor = 100,       fractionDivisor = 10, abbreviation = "K", abbreviationIsGlobal = false },
    { breakpoint = 1,          significandDivisor = 0.1,       fractionDivisor = 10, abbreviation = "",  abbreviationIsGlobal = false },
}
local OPTS_1DEC = { breakpointData = BREAKPOINTS_1DEC }

-- 2-decimal
local BREAKPOINTS_2DEC = {
    { breakpoint = 1000000000, significandDivisor = 10000000, fractionDivisor = 100, abbreviation = "B", abbreviationIsGlobal = false },
    { breakpoint = 1000000,    significandDivisor = 10000,    fractionDivisor = 100, abbreviation = "M", abbreviationIsGlobal = false },
    { breakpoint = 1000,       significandDivisor = 10,       fractionDivisor = 100, abbreviation = "K", abbreviationIsGlobal = false },
    { breakpoint = 1,          significandDivisor = 0.01,      fractionDivisor = 100, abbreviation = "",  abbreviationIsGlobal = false },
}
local OPTS_2DEC = { breakpointData = BREAKPOINTS_2DEC }

function ns.FormatNumber(value, fmt)
    -- Sub-1000 values: handle explicitly for consistent precision
    if not issecretvalue(value) and value < 1000 then
        if fmt == "short" then
            return tostring(math.floor(value + 0.5))
        elseif fmt == "1dec" then
            return string.format("%.1f", value)
        elseif fmt == "2dec" then
            return string.format("%.2f", value)
        else -- "full"
            return string.format("%.1f", value)
        end
    end
    if fmt == "short" then
        return AbbreviateNumbers(value, OPTS_SHORT)
    elseif fmt == "1dec" then
        return AbbreviateNumbers(value, OPTS_1DEC)
    elseif fmt == "2dec" then
        return AbbreviateNumbers(value, OPTS_2DEC)
    else
        return AbbreviateLargeNumbers(value)
    end
end

----------------------------------------------------------------------
-- Column width measurement
----------------------------------------------------------------------

local FORMAT_CHARS = {
    short = 4,
    ["1dec"] = 6,
    ["2dec"] = 8,
    full  = 7,
    int   = 4,
    dec   = 6,
}

-- Extra chars for the total column (parentheses)
local TOTAL_EXTRA_CHARS = 2

local charWidthCache = {}
local measureFS = nil

local function GetCharWidth(fontSize)
    local fontPath = ns.db and ns.db.fontPath or ns.FONT
    local key = fontPath .. ":" .. fontSize
    if charWidthCache[key] then return charWidthCache[key] end
    if not measureFS then
        measureFS = UIParent:CreateFontString(nil, "ARTWORK")
    end
    measureFS:SetFont(fontPath, fontSize, "OUTLINE")
    measureFS:SetText("0000000000")
    local w = measureFS:GetStringWidth()
    local cw = w / 10
    charWidthCache[key] = cw
    return cw
end

function ns.ClearCharWidthCache()
    charWidthCache = {}
end

local COL_PAD = 4

local function ColPixelWidth(chars, fontSize)
    return math.ceil(chars * GetCharWidth(fontSize)) + COL_PAD
end

----------------------------------------------------------------------
-- Timer formatting
----------------------------------------------------------------------

function ns.FormatTimer(seconds)
    if not seconds or seconds <= 0 then return "" end
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    if m > 0 then
        return string.format("%d:%02d", m, s)
    else
        return string.format("0:%02d", s)
    end
end

----------------------------------------------------------------------
-- Strip realm from "Name-Server"
----------------------------------------------------------------------

function ns.StripRealm(name)
    if not name then return name end
    if issecretvalue(name) then return name end
    local short = name:match("^([^%-]+)")
    return short or name
end

----------------------------------------------------------------------
-- Column value population
----------------------------------------------------------------------

-- Actions category types: display as simple integer count
ns.ACTIONS_TYPES = {
    [Enum.DamageMeterType.Interrupts] = true,
    [Enum.DamageMeterType.Dispels] = true,
    [Enum.DamageMeterType.Deaths] = true,
}

function ns.PopulateColumnValues(button, elementData)
    local total = elementData.totalAmount or 0
    local rate = elementData.amountPerSecond
    local sessionTotal = elementData.sessionTotal

    -- Actions category: show only integer total with trailing dot
    if elementData.isActionType then
        button.rateFS:SetText("")
        button.rateFS:Hide()
        button.totalFS:SetText("")
        button.totalFS:Hide()
        button.pctFS:SetText("")
        button.pctFS:Hide()

        if not button.actionFS then
            local fs = button.bar:CreateFontString(nil, "OVERLAY")
            fs:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
            fs:SetJustifyH("RIGHT")
            fs:SetShadowOffset(1, -1)
            fs:SetShadowColor(0, 0, 0, 0.4)
            button.actionFS = fs
        end
        button.actionFS:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
        -- totalAmount est une valeur taintée (issue du combat log de l'addon).
        -- Quand le ScrollBox appelle cet initialiseur via secureexecuterange,
        -- toute arithmétique sur une valeur taintée lève un LUA_WARNING.
        -- On doit vérifier issecretvalue avant tout math.floor / opérateur.
        if issecretvalue(total) then
            button.actionFS:SetText("-")
        else
            button.actionFS:SetText(string.format("%d.", math.floor(total + 0.5)))
        end
        button.actionFS:SetTextColor(unpack(ns.TEXT_PRIMARY))
        button.actionFS:ClearAllPoints()
        button.actionFS:SetPoint("RIGHT", button.bar, "RIGHT", -6, ns.GetFontNudge())
        button.actionFS:Show()
        return
    end

    -- Hide actionFS if it was created from a previous Actions view
    if button.actionFS then
        button.actionFS:Hide()
    end

    local fsMap = { rate = button.rateFS, total = button.totalFS, pct = button.pctFS }
    for _, col in ipairs(ns.db.columns) do
        local fs = fsMap[col.key]
        if col.show and col.key == "rate" and rate then
            fs:SetText(ns.FormatNumber(rate, col.fmt))
            fs:Show()
        elseif col.show and col.key == "total" then
            fs:SetText("(" .. ns.FormatNumber(total, col.fmt) .. ")")
            fs:Show()
        elseif col.show and col.key == "pct" and not issecretvalue(total)
            and sessionTotal and not issecretvalue(sessionTotal) and sessionTotal > 0 then
            local pctFmt = col.fmt == "dec" and "%.1f%%" or "%d%%"
            fs:SetText(string.format(pctFmt, total / sessionTotal * 100))
            fs:Show()
        elseif col.show and col.key == "pct" then
            fs:SetText("-")
            fs:Show()
        else
            fs:SetText("")
            fs:Hide()
        end
    end
end

----------------------------------------------------------------------
-- Column anchoring
----------------------------------------------------------------------

function ns.AnchorColumns(button)
    button.pctFS:ClearAllPoints()
    button.totalFS:ClearAllPoints()
    button.rateFS:ClearAllPoints()

    -- Actions mode: actionFS is the only right-side element
    if button.actionFS and button.actionFS:IsShown() then
        return button.actionFS
    end

    local fontSize = ns.GetFontSize()
    local fsMap = { rate = button.rateFS, total = button.totalFS, pct = button.pctFS }
    local prevFS = nil
    for i = #ns.db.columns, 1, -1 do
        local col = ns.db.columns[i]
        if col.show then
            local fs = fsMap[col.key]
            local chars = FORMAT_CHARS[col.fmt] or 6
            if col.key == "total" then chars = chars + TOTAL_EXTRA_CHARS end
            fs:SetWidth(ColPixelWidth(chars, fontSize))
            if not prevFS then
                fs:SetPoint("RIGHT", button.bar, "RIGHT", -4, ns.GetFontNudge())
            else
                fs:SetPoint("RIGHT", prevFS, "LEFT", -2, 0)
            end
            prevFS = fs
        end
    end
    return prevFS
end

----------------------------------------------------------------------
-- Report to chat: data snapshot
----------------------------------------------------------------------

function ns.SnapshotReportData(meterType, sessionType)
    local L = ns.L
    local session = C_DamageMeter.GetCombatSessionFromType(sessionType, meterType)
    if not session or issecretvalue(session) then return nil end
    local sources = session.combatSources
    if not sources or #sources == 0 then return nil end

    local first = sources[1]
    if issecretvalue(first.name) or issecretvalue(first.totalAmount) then
        return nil
    end

    local info = ns.TYPE_INFO[meterType]
    local typeName = info and L[info.key] or "Unknown"
    local sessKey = ns.SESSION_KEYS[sessionType]
    local sessionName = sessKey and L[sessKey] or L["CURRENT"]
    local header = string.format(L["REPORT_HEADER"], typeName, sessionName)

    local isRate = ns.RATE_PRIMARY[meterType]
    local lines = {}
    for i, source in ipairs(sources) do
        if issecretvalue(source.name) or issecretvalue(source.totalAmount) then
            break
        end
        local name = ns.StripRealm(source.name) or "Unknown"
        local value = isRate and source.amountPerSecond or source.totalAmount
        local formatted = ns.FormatNumber(value, "1dec")
        lines[#lines + 1] = i .. ". " .. formatted .. "  " .. name
    end

    return { header = header, lines = lines }
end

----------------------------------------------------------------------
-- Report to chat: send helper
----------------------------------------------------------------------

function ns.SendReport(snapshot, channel, maxLines)
    local L = ns.L
    local lines = snapshot.lines
    if maxLines > 0 and maxLines < #lines then
        lines = { unpack(lines, 1, maxLines) }
    end

    if channel == "DEBUG" then
        print(L["ADDON_PREFIX"] .. snapshot.header)
        for _, line in ipairs(lines) do
            print(L["ADDON_PREFIX"] .. line)
        end
    else
        local target = nil
        if channel == "WHISPER" then
            target = UnitIsPlayer("target") and GetUnitName("target", true) or nil
            if not target or target == "" then
                print(L["ADDON_PREFIX"] .. L["REPORT_NO_TARGET"])
                return
            end
        end
        SendChatMessage(snapshot.header, channel, nil, target)
        for _, line in ipairs(lines) do
            SendChatMessage(line, channel, nil, target)
        end
    end
end
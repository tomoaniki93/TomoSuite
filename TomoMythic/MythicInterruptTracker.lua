-- TomoMythic / MythicInterruptTracker.lua
-- Mythic+ Interrupt Tracker — integrated into TomoMythic (TM table)
-- Tracks party interrupt cooldowns in Mythic+ dungeons.
-- All game logic from the original standalone MythicInterruptTracker is preserved;
-- only the UI layer, config system, font/texture handling, SavedVariables and
-- initialisation have been refactored to use TM's shared architecture.

local _, TM = ...

local MSG_PREFIX  = "MIT"
local MIT_VERSION = "12.1"

------------------------------------------------------------
-- Spell data (all interrupt spells, multiple per class/spec)
------------------------------------------------------------
local ALL_INTERRUPTS = {
    [6552]    = { name = "Pummel",             cd = 15, icon = 132938  },
    [1766]    = { name = "Kick",               cd = 15, icon = 132219  },
    [2139]    = { name = "Counterspell",        cd = 24, icon = 135856  },
    [57994]   = { name = "Wind Shear",          cd = 12, icon = 136018  },
    [106839]  = { name = "Skull Bash",          cd = 15, icon = 236946  },
    [78675]   = { name = "Solar Beam",          cd = 60, icon = 236748  },
    [47528]   = { name = "Mind Freeze",         cd = 15, icon = 237527  },
    [96231]   = { name = "Rebuke",              cd = 15, icon = 523893  },
    [183752]  = { name = "Disrupt",             cd = 15, icon = 1305153 },
    [116705]  = { name = "Spear Hand Strike",   cd = 15, icon = 608940  },
    [15487]   = { name = "Silence",             cd = 45, icon = 458230  },
    [147362]  = { name = "Counter Shot",        cd = 24, icon = 249170  },
    [187707]  = { name = "Muzzle",              cd = 15, icon = 1376045 },
    [19647]   = { name = "Spell Lock",          cd = 24, icon = 136174  },
    [132409]  = { name = "Spell Lock",          cd = 24, icon = 136174  },
    [119914]  = { name = "Axe Toss",            cd = 30, icon = "Interface\\Icons\\ability_warrior_titansgrip" },
    [1276467] = { name = "Fel Ravager",         cd = 25, icon = "Interface\\Icons\\spell_shadow_summonfelhunter" },
    [351338]  = { name = "Quell",               cd = 20, icon = 4622469 },
}

local CLASS_INTERRUPT_LIST = {
    WARRIOR     = { 6552 },
    ROGUE       = { 1766 },
    MAGE        = { 2139 },
    SHAMAN      = { 57994 },
    DRUID       = { 106839, 78675 },
    DEATHKNIGHT = { 47528 },
    PALADIN     = { 96231 },
    DEMONHUNTER = { 183752 },
    MONK        = { 116705 },
    PRIEST      = { 15487 },
    HUNTER      = { 147362, 187707 },
    WARLOCK     = { 19647, 132409, 119914 },
    EVOKER      = { 351338 },
}

local CLASS_COLORS = {
    WARRIOR     = { 0.78, 0.61, 0.43 },
    ROGUE       = { 1.00, 0.96, 0.41 },
    MAGE        = { 0.41, 0.80, 0.94 },
    SHAMAN      = { 0.00, 0.44, 0.87 },
    DRUID       = { 1.00, 0.49, 0.04 },
    DEATHKNIGHT = { 0.77, 0.12, 0.23 },
    PALADIN     = { 0.96, 0.55, 0.73 },
    DEMONHUNTER = { 0.64, 0.19, 0.79 },
    MONK        = { 0.00, 1.00, 0.59 },
    PRIEST      = { 1.00, 1.00, 1.00 },
    HUNTER      = { 0.67, 0.83, 0.45 },
    WARLOCK     = { 0.58, 0.51, 0.79 },
    EVOKER      = { 0.20, 0.58, 0.50 },
}

-- Spec IDs where the class primary interrupt is replaced by a spec-specific one.
-- [specID] = spellID
local SPEC_INTERRUPT_OVERRIDES = {
    -- Beast Mastery Hunter uses Counter Shot (ranged spec default)
    [253] = 147362,
    -- Marksmanship Hunter uses Counter Shot
    [254] = 147362,
    -- Survival Hunter uses Muzzle (melee)
    [255] = 187707,
    -- Demonology Warlock primary is the Felhunter Spell Lock
    [266] = 19647,
}

-- Spec IDs with NO primary interrupt (or only situational/AoE interrupts).
-- [specID] = true
local SPEC_NO_INTERRUPT = {
    -- Balance Druid: Solar Beam is AoE and talent-gated; skip as "primary"
    [102] = true,
}

-- Talents that reduce a specific interrupt's cooldown.
-- [talentSpellID] = { interrupt = spellID, reduction = seconds }
local CD_REDUCTION_TALENTS = {
    -- Improved Counterspell (Mage): -4 s on Counterspell
    -- [321] = { interrupt = 2139, reduction = 4 },
}

-- Talents that grant extra charges or reset the CD on a successful kick.
-- [talentSpellID] = true
local CD_ON_KICK_TALENTS = {
    -- (none in TWW base, but reserved for future talent data)
}

-- Extra interrupt spells available to certain specs beyond the class default.
-- [specID] = { spellID, ... }
local SPEC_EXTRA_KICKS = {
    -- Guardian Druid gets both Skull Bash AND Solar Beam
    [104] = { 106839, 78675 },
    -- Restoration Druid has Solar Beam
    [105] = { 78675 },
    -- Demonology Warlock: Felhunter Spell Lock + Grimoire Spell Lock + Axe Toss
    [266] = { 19647, 132409, 119914 },
}

-- Aliased spell IDs (e.g. Grimoire of Service Spell Lock counts as normal Spell Lock)
local SPELL_ALIASES = {
    [132409]  = 19647,   -- Grimoire Spell Lock  → Spell Lock
}

------------------------------------------------------------
-- TM.MIT sub-table (all module state stored here)
------------------------------------------------------------
TM.MIT = TM.MIT or {}
local MIT = TM.MIT

MIT.bars          = {}    -- [unit] = barFrame
MIT.mainFrame     = nil
MIT.configPanel   = nil
MIT.playerData    = {}    -- [unit] = { name, shortName, class, spellID, cd, expires, ready, lastKick }
MIT.testMode      = false
MIT.spyMode       = false
MIT.debugMode     = false
MIT.ticker        = nil
MIT.inspectQueue  = {}
MIT.inspectPending = false
MIT.nameplates    = {}    -- [unit] = { name, guid }

------------------------------------------------------------
-- Taint-laundering frames (MUST stay as top-level CreateFrame calls)
-- Created at file-load time so WoW's taint scanner sees them as "clean" frames.
------------------------------------------------------------
local launderBar    = CreateFrame("StatusBar")
local launderSlider = CreateFrame("Slider")
local onValueChangedResult = nil   -- stores last slider callback value

launderBar:Hide()
launderSlider:Hide()

-- Taint-safe bar value setter: copy value through the launder frame to avoid
-- tainting secure code paths when called from event handlers.
launderBar:SetScript("OnValueChanged", function(_, v)
    onValueChangedResult = v
end)

------------------------------------------------------------
-- Party watcher frames (MUST stay as top-level CreateFrame calls)
-- WoW requires these to exist in the global frame list from load time.
------------------------------------------------------------
local partyFrames    = {}
local partyPetFrames = {}
for i = 1, 4 do
    partyFrames[i]    = CreateFrame("Frame")
    partyPetFrames[i] = CreateFrame("Frame")
    partyFrames[i]:Hide()
    partyPetFrames[i]:Hide()
end

------------------------------------------------------------
-- Internal helpers
------------------------------------------------------------

local BAR_TEXTURE = "Interface\\Buttons\\WHITE8x8"

local function MITDebug(msg)
    if MIT.debugMode then
        print("|cFF888888[MIT Debug]|r " .. tostring(msg))
    end
end

local function ResolveAlias(spellID)
    if type(spellID) ~= "number" then return nil end
    return SPELL_ALIASES[spellID] or spellID
end

local function GetPrimaryInterruptForClass(class)
    local list = CLASS_INTERRUPT_LIST[class]
    return list and list[1] or nil
end

local function GetInterruptCD(spellID)
    local info = ALL_INTERRUPTS[spellID]
    return info and info.cd or 15
end

local function GetInterruptName(spellID)
    local info = ALL_INTERRUPTS[spellID]
    return info and info.name or "Interrupt"
end

local function GetInterruptIcon(spellID)
    local info = ALL_INTERRUPTS[spellID]
    return info and info.icon or nil
end

------------------------------------------------------------
-- Visibility logic
------------------------------------------------------------

local function ShouldShowFrame()
    if not TM.db then return false end
    if not TM.db.showInterrupt then return false end
    local _, instanceType = IsInInstance()
    return instanceType == "party"
end

------------------------------------------------------------
-- Player data management
------------------------------------------------------------

local function GetBestInterruptForUnit(unit)
    local class = select(2, UnitClass(unit))
    if not class then return nil end
    -- Check spec override
    local specID = 0
    if GetInspectSpecialization then
        specID = GetInspectSpecialization(unit) or 0
    end
    if specID > 0 then
        if SPEC_NO_INTERRUPT[specID] then
            -- May have secondary (e.g. Balance has Solar Beam as secondary)
            local list = CLASS_INTERRUPT_LIST[class]
            if list and #list > 1 then return list[2] end
            return nil
        end
        if SPEC_INTERRUPT_OVERRIDES[specID] then
            return SPEC_INTERRUPT_OVERRIDES[specID]
        end
    end
    return GetPrimaryInterruptForClass(class)
end

local function InitPlayerData(unit)
    if not UnitExists(unit) then return nil end
    local name, realm = UnitName(unit)
    if not name then return nil end
    local _, classFile = UnitClass(unit)
    if not classFile then return nil end
    local fullName = (realm and realm ~= "") and (name .. "-" .. realm) or name
    local spellID  = GetPrimaryInterruptForClass(classFile)
    local cd       = spellID and GetInterruptCD(spellID) or 15
    local data = {
        name      = fullName,
        shortName = name,
        class     = classFile,
        specID    = 0,
        spellID   = spellID,
        cd        = cd,
        expires   = 0,
        ready     = true,
        lastKick  = 0,
    }
    MIT.playerData[unit] = data
    return data
end

------------------------------------------------------------
-- Nameplate / mob interrupt correlation
------------------------------------------------------------

local function OnNameplateAdded(unit)
    if not unit then return end
    MIT.nameplates[unit] = {
        name = UnitName(unit),
        guid = UnitGUID(unit),
    }
    MITDebug("Nameplate added: " .. unit .. " = " .. (UnitName(unit) or "?"))
end

local function OnNameplateRemoved(unit)
    if not unit then return end
    MIT.nameplates[unit] = nil
end

-- Determine if a spellcast on a nameplate unit represents an interrupt target.
-- Returns the casting unit name if it is currently casting an interruptible spell.
local function GetInterruptTargetName(nameplateUnit)
    if not nameplateUnit or not UnitExists(nameplateUnit) then return nil end
    local _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(nameplateUnit)
    if notInterruptible == false then
        return UnitName(nameplateUnit)
    end
    local _, _, _, _, _, _, notInterruptible2 = UnitChannelInfo(nameplateUnit)
    if notInterruptible2 == false then
        return UnitName(nameplateUnit)
    end
    return nil
end

------------------------------------------------------------
-- Addon message sync
------------------------------------------------------------

local function SendMIT(msg)
    if not IsInGroup() then return end
    local channel = IsInRaid() and "RAID" or "PARTY"
    if C_ChatInfo then
        C_ChatInfo.SendAddonMessage(MSG_PREFIX, msg, channel)
    else
        SendAddonMessage(MSG_PREFIX, msg, channel)  -- legacy API fallback
    end
end

local function OnAddonMessage(prefix, message, channel, sender)
    if prefix ~= MSG_PREFIX then return end
    MITDebug("AddonMsg from " .. tostring(sender) .. ": " .. tostring(message))

    -- KICK:<spellID>:<expires>  — another MIT user reporting a kick
    local spellIDStr, expiresStr = message:match("^KICK:(%d+):([%d%.]+)$")
    if spellIDStr and expiresStr then
        local spellID = tonumber(spellIDStr)
        local expires = tonumber(expiresStr)
        for unit, data in pairs(MIT.playerData) do
            if data.shortName == sender or data.name == sender then
                data.spellID  = spellID
                data.expires  = expires
                data.ready    = false
                data.lastKick = expires - GetInterruptCD(spellID)
                TM:MIT_RefreshBars()
                break
            end
        end
        return
    end

    -- VER:<version>  — version handshake
    local ver = message:match("^VER:(.+)$")
    if ver then
        MITDebug("Remote MIT version: " .. ver)
        return
    end

    -- SPY: spy-mode echo of someone else using MIT
    if MIT.spyMode and message:match("^SPY:") then
        local info = message:sub(5)
        print("|cFF55B400[MIT Spy]|r " .. tostring(sender) .. ": " .. info)
    end
end

------------------------------------------------------------
-- Inspect queue
------------------------------------------------------------

local INSPECT_DELAY = 1.5

local function ProcessInspectQueue()
    if MIT.inspectPending then return end
    if #MIT.inspectQueue == 0 then return end
    local unit = table.remove(MIT.inspectQueue, 1)
    if not UnitExists(unit) then
        C_Timer.After(0, ProcessInspectQueue)
        return
    end
    if not CanInspect(unit) then
        -- Re-queue once, may not be in range yet
        table.insert(MIT.inspectQueue, unit)
        return
    end
    MIT.inspectPending = true
    NotifyInspect(unit)
    MITDebug("Inspecting: " .. (UnitName(unit) or unit))
end

local function QueueInspect(unit)
    if not unit or unit == "player" then return end
    for _, u in ipairs(MIT.inspectQueue) do
        if u == unit then return end
    end
    table.insert(MIT.inspectQueue, unit)
    C_Timer.After(INSPECT_DELAY, ProcessInspectQueue)
end

local function OnInspectReady(guid)
    MIT.inspectPending = false
    -- Match GUID to a tracked unit
    for _, unit in ipairs({"party1","party2","party3","party4"}) do
        if UnitGUID(unit) == guid then
            local data = MIT.playerData[unit]
            if data then
                local specID = GetInspectSpecialization and GetInspectSpecialization(unit) or 0
                data.specID = specID
                -- Refine spell based on spec
                local newSpell = GetBestInterruptForUnit(unit)
                if newSpell then
                    data.spellID = newSpell
                    data.cd      = GetInterruptCD(newSpell)
                    MITDebug("Inspect done: " .. unit .. " spec=" .. specID
                        .. " => " .. GetInterruptName(newSpell))
                end
                TM:MIT_RefreshBars()
            end
            break
        end
    end
    -- Continue queue
    if #MIT.inspectQueue > 0 then
        C_Timer.After(INSPECT_DELAY, ProcessInspectQueue)
    end
end

------------------------------------------------------------
-- Party watcher registration
------------------------------------------------------------

local function RegisterPartyWatchers()
    for i = 1, 4 do
        local unit    = "party" .. i
        local petUnit = "partypet" .. i
        -- We use the pre-created top-level frames; register unit-change events
        -- so we can re-inspect when a member's spell/aura state changes.
        partyFrames[i]:RegisterUnitEvent("UNIT_AURA", unit)
        partyPetFrames[i]:RegisterUnitEvent("UNIT_PET", unit)
        partyFrames[i]:SetScript("OnEvent", function(_, event, u)
            if event == "UNIT_AURA" then
                -- Aura change could indicate a debuff that modifies CD; refresh display
                if MIT.playerData[unit] then TM:MIT_RefreshBars() end
            end
        end)
        partyPetFrames[i]:SetScript("OnEvent", function(_, event, u)
            if event == "UNIT_PET" then
                -- Warlock pet change may affect Spell Lock availability
                local data = MIT.playerData[unit]
                if data and data.class == "WARLOCK" then
                    QueueInspect(unit)
                end
            end
        end)
    end
end

------------------------------------------------------------
-- Update all party members (roster scan)
------------------------------------------------------------

local function UpdatePartyMembers()
    if MIT.testMode then return end
    MIT.playerData = {}
    local units = {"player"}
    for i = 1, GetNumSubgroupMembers() do
        units[#units+1] = "party" .. i
    end
    for _, unit in ipairs(units) do
        if UnitExists(unit) then
            InitPlayerData(unit)
            if unit ~= "player" then
                QueueInspect(unit)
            end
        end
    end
    TM:MIT_LayoutFrame()
end

------------------------------------------------------------
-- Cooldown tracking
------------------------------------------------------------

local function OnSpellCastSucceeded(unit, _, spellID)
    if type(spellID) ~= "number" then return end
    spellID = ResolveAlias(spellID)
    if not ALL_INTERRUPTS[spellID] then return end

    -- Locate the data entry for this unit
    local data = MIT.playerData[unit]
    if not data then
        -- Fallback: match by name (e.g. if unit token changes)
        local targetName = UnitName(unit)
        for u, d in pairs(MIT.playerData) do
            if d.shortName == targetName then
                data = d; unit = u; break
            end
        end
    end
    if not data then return end

    local cd = data.cd or GetInterruptCD(spellID)
    data.spellID  = spellID
    data.expires  = GetTime() + cd
    data.ready    = false
    data.lastKick = GetTime()

    MITDebug((data.name or unit) .. " used " .. GetInterruptName(spellID)
        .. " (cd=" .. cd .. "s)")

    -- Sync to group via addon message if we are the caster
    if unit == "player" then
        SendMIT("KICK:" .. spellID .. ":" .. data.expires)
        if MIT.spyMode then
            SendMIT("SPY:" .. (data.shortName or "?") .. " kicked with "
                .. GetInterruptName(spellID))
        end
    end

    TM:MIT_RefreshBars()
end

local function UpdateCooldowns()
    if not TM.db or not TM.db.interrupt then return end
    local now = GetTime()
    local changed = false
    for unit, data in pairs(MIT.playerData) do
        if not data.ready and data.expires > 0 and now >= data.expires then
            data.ready   = true
            data.expires = 0
            changed = true
        end
    end
    if changed then TM:MIT_RefreshBars() end
end

------------------------------------------------------------
-- Test mode
------------------------------------------------------------

local function StartTestMode()
    MIT.testMode = true
    local testPlayers = {
        { name = "WarriorTest",  class = "WARRIOR",     spellID = 6552  },
        { name = "RogueTest",    class = "ROGUE",       spellID = 1766  },
        { name = "MageTest",     class = "MAGE",        spellID = 2139  },
        { name = "ShamanTest",   class = "SHAMAN",      spellID = 57994 },
        { name = "DKTest",       class = "DEATHKNIGHT", spellID = 47528 },
    }
    local now = GetTime()
    MIT.playerData = {}
    for i, tp in ipairs(testPlayers) do
        local unit = i == 1 and "player" or ("party" .. (i - 1))
        local cd   = GetInterruptCD(tp.spellID)
        MIT.playerData[unit] = {
            name      = tp.name,
            shortName = tp.name,
            class     = tp.class,
            specID    = 0,
            spellID   = tp.spellID,
            cd        = cd,
            expires   = (i % 2 == 0) and (now + cd * 0.5) or 0,
            ready     = (i % 2 ~= 0),
            lastKick  = 0,
        }
    end
    TM:MIT_LayoutFrame()
    if MIT.mainFrame then MIT.mainFrame:Show() end
    print("|cFF55B400[MIT]|r Test mode |cFFFFFF00ON|r — fake interrupt bars shown.")
end

local function StopTestMode()
    MIT.testMode = false
    UpdatePartyMembers()
    print("|cFF55B400[MIT]|r Test mode |cFFCC3322OFF|r.")
end

------------------------------------------------------------
-- UI: bar rows
------------------------------------------------------------

local function CreateBarRow(parent, unit)
    local db = TM.db.interrupt
    local W  = (db.frameWidth or 220) - 6
    local H  = db.barHeight  or 28
    local C  = TM.C

    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(W, H)

    -- Track background
    TM:MakeBG(row, unpack(C.BAR_TRACK))

    -- Class-coloured fill (shows how much of CD has elapsed)
    local fill = CreateFrame("StatusBar", nil, row)
    fill:SetStatusBarTexture(BAR_TEXTURE)
    fill:SetMinMaxValues(0, 1)
    fill:SetValue(1)
    fill:SetAllPoints(row)
    fill:SetStatusBarColor(0.5, 0.5, 0.5, 0.85)
    row.fill = fill

    -- Spell icon (on fill at OVERLAY so class colour doesn't tint it)
    local icon = fill:CreateTexture(nil, "OVERLAY")
    icon:SetSize(H - 4, H - 4)
    icon:SetPoint("LEFT", row, "LEFT", 2, 0)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.icon = icon

    -- Player name (parented to fill so it renders above the class-coloured bar)
    local nameFS = TM:MakeFS(fill, (db.nameFontSize ~= 0 and db.nameFontSize or 11),
        "OUTLINE", "LEFT", row, H + 2, 0)
    nameFS:SetWidth(W - H - 50)
    nameFS:SetJustifyH("LEFT")
    nameFS:SetTextColor(unpack(C.TEXT_WHITE))
    row.nameFS = nameFS

    -- CD / ready text (right aligned, parented to fill)
    local cdFS = TM:MakeFS(fill, (db.readyFontSize ~= 0 and db.readyFontSize or 10),
        "OUTLINE", "RIGHT", row, -3, 0)
    row.cdFS = cdFS

    -- 1px border lines
    TM:MakeLineBorders(row, unpack(C.BORDER))

    -- Smooth per-frame fill update when on cooldown
    row:SetScript("OnUpdate", function(self)
        local data = MIT.playerData[self.unit]
        if not data or data.ready or not data.spellID then return end
        local remaining = math.max(0, data.expires - GetTime())
        local frac = 1 - (remaining / math.max(1, data.cd))
        self.fill:SetValue(frac)
        if remaining > 0 then
            self.cdFS:SetText(string.format("|cFFFF4422%.1fs|r", remaining))
        else
            self.cdFS:SetText("|cFF55DD22" .. TM.L.INTERRUPT_READY .. "|r")
            data.ready   = true
            data.expires = 0
            self.fill:SetValue(1)
        end
    end)

    row.unit = unit
    return row
end

------------------------------------------------------------
-- UI: main frame layout
------------------------------------------------------------

function TM:MIT_BuildFrame()
    if MIT.mainFrame then return end
    local db = TM.db.interrupt
    local C  = self.C
    local W  = db.frameWidth or 220

    local F = CreateFrame("Frame", "TomoMythicInterruptFrame", UIParent)
    MIT.mainFrame = F
    F:SetSize(W, 60)
    F:SetFrameStrata("MEDIUM")
    F:SetFrameLevel(60)
    F:SetClampedToScreen(true)
    F:SetAlpha(db.alpha or 0.9)

    -- Restore saved position (if any)
    if db.posAnchor then
        F:SetPoint(db.posAnchor, UIParent, db.posRelTo or db.posAnchor,
            db.posX or -400, db.posY or 0)
    else
        F:SetPoint("CENTER", UIParent, "CENTER", -400, 0)
    end

    -- Background
    self:MakeBG(F, unpack(C.BG))

    -- Left accent strip
    local accent = F:CreateTexture(nil, "ARTWORK")
    accent:SetWidth(3)
    accent:SetPoint("TOPLEFT",    F, "TOPLEFT",    0, 0)
    accent:SetPoint("BOTTOMLEFT", F, "BOTTOMLEFT", 0, 0)
    accent:SetColorTexture(unpack(C.ACCENT))
    F._mitAccent = accent

    -- Border
    self:MakeLineBorders(F, unpack(C.BORDER))

    -- Title bar (optional)
    F.titleHeight = 0
    if db.showTitle then
        local titleBG = F:CreateTexture(nil, "BACKGROUND")
        titleBG:SetSize(W, 20)
        titleBG:SetPoint("TOPLEFT", F, "TOPLEFT", 0, 0)
        titleBG:SetColorTexture(unpack(C.BG_HEADER))
        F.titleBG = titleBG

        local titleFS = self:MakeFS(F, 11, "OUTLINE", "TOPLEFT", nil, 8, -4)
        titleFS:SetText("|cFF55B400Interrupts|r")
        titleFS:SetTextColor(unpack(C.TEXT_WHITE))
        F.titleFS = titleFS

        local sep = F:CreateTexture(nil, "ARTWORK")
        sep:SetHeight(1)
        sep:SetPoint("TOPLEFT",  F, "TOPLEFT",  0, -20)
        sep:SetPoint("TOPRIGHT", F, "TOPRIGHT", 0, -20)
        sep:SetColorTexture(unpack(C.ACCENT))
        F.titleSep = sep

        F.titleHeight = 21
    end

    -- Dragging
    if not db.locked then
        F:SetMovable(true)
        F:EnableMouse(true)
        F:RegisterForDrag("LeftButton")
    end
    F:SetScript("OnDragStart", function(s)
        if not db.locked then s:StartMoving() end
    end)
    F:SetScript("OnDragStop", function(s)
        s:StopMovingOrSizing()
        local a, _, ra, x, y = s:GetPoint()
        db.posAnchor = a
        db.posRelTo  = ra
        db.posX      = math.floor(x * 10 + 0.5) / 10
        db.posY      = math.floor(y * 10 + 0.5) / 10
    end)

    F:Hide()  -- hidden until PLAYER_ENTERING_WORLD
    self:MIT_LayoutFrame()
end

function TM:MIT_LayoutFrame()
    if not MIT.mainFrame then return end
    local F  = MIT.mainFrame
    local db = TM.db.interrupt
    local W  = db.frameWidth or 220
    local H  = db.barHeight  or 28
    local C  = self.C
    local GAP = 1
    local titleH = F.titleHeight or 0

    F:SetWidth(W)

    -- Collect active units
    local units = {"player"}
    for i = 1, GetNumSubgroupMembers() do
        units[#units+1] = "party" .. i
    end

    -- Remove old bar rows
    for _, bar in pairs(MIT.bars) do
        bar:Hide()
        bar:SetParent(nil)
    end
    MIT.bars = {}

    local count  = 0
    local yStart = -(titleH + GAP)
    local dir    = db.growUp and 1 or -1

    for _, unit in ipairs(units) do
        local data = MIT.playerData[unit]
        if data and UnitExists(unit) then
            local bar = CreateBarRow(F, unit)
            bar:SetWidth(W - 6)
            bar:SetHeight(H)
            local yOff = db.growUp
                and (math.abs(yStart) + count * (H + GAP))
                or  (yStart - count * (H + GAP))
            if db.growUp then
                bar:SetPoint("BOTTOMLEFT", F, "BOTTOMLEFT", 3, yOff)
            else
                bar:SetPoint("TOPLEFT",    F, "TOPLEFT",    3, yOff)
            end
            bar:Show()
            MIT.bars[unit] = bar
            count = count + 1
        end
    end

    local totalH = titleH + GAP + count * (H + GAP) + GAP
    F:SetHeight(math.max(24, totalH))
    self:MIT_RefreshBars()
end

function TM:MIT_RefreshBars()
    if not MIT.mainFrame then return end
    local db  = TM.db.interrupt
    local now = GetTime()
    local C   = self.C

    for unit, bar in pairs(MIT.bars) do
        local data = MIT.playerData[unit]
        if not data or not UnitExists(unit) then
            bar:Hide()
        else
            bar:Show()

            -- Icon
            local icon = data.spellID and GetInterruptIcon(data.spellID)
                or "Interface\\Icons\\Spell_Frost_IceShock"
            bar.icon:SetTexture(icon)

            -- Class colour for fill bar
            local cc = CLASS_COLORS[data.class] or {0.7, 0.7, 0.7}
            bar.fill:SetStatusBarColor(cc[1], cc[2], cc[3], 0.85)

            -- Name (short, no realm)
            bar.nameFS:SetText(data.shortName or data.name or unit)

            if data.ready or (not data.spellID) then
                -- Ready
                bar.fill:SetValue(1)
                if db.showReady then
                    bar.cdFS:SetText("|cFF55DD22" .. TM.L.INTERRUPT_READY .. "|r")
                else
                    bar.cdFS:SetText("")
                end
            else
                -- On cooldown
                local remaining = math.max(0, data.expires - now)
                local frac      = 1 - (remaining / math.max(1, data.cd))
                bar.fill:SetValue(frac)
                if remaining > 0 then
                    bar.cdFS:SetText(string.format("|cFFFF4422%.0fs|r", remaining))
                else
                    bar.cdFS:SetText("|cFF55DD22" .. TM.L.INTERRUPT_READY .. "|r")
                    data.ready   = true
                    data.expires = 0
                end
            end
        end
    end
end

------------------------------------------------------------
-- Config panel
------------------------------------------------------------

local function BuildConfigPanel()
    if MIT.configPanel then return MIT.configPanel end
    local C  = TM.C
    local db = TM.db.interrupt
    local W, H = 285, 390

    local P = CreateFrame("Frame", "TomoMythicInterruptConfig", UIParent, "BackdropTemplate")
    MIT.configPanel = P
    P:SetSize(W, H)
    P:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    P:SetFrameStrata("HIGH")
    P:SetFrameLevel(200)
    P:SetMovable(true)
    P:EnableMouse(true)
    P:RegisterForDrag("LeftButton")
    P:SetClampedToScreen(true)
    P:SetScript("OnDragStart", function(s) s:StartMoving() end)
    P:SetScript("OnDragStop",  function(s) s:StopMovingOrSizing() end)
    P:Hide()

    P:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    P:SetBackdropColor(0, 0, 0, 0.90)
    P:SetBackdropBorderColor(unpack(C.BORDER))

    -- Left accent strip
    local accent = P:CreateTexture(nil, "ARTWORK")
    accent:SetWidth(3)
    accent:SetPoint("TOPLEFT",    P, "TOPLEFT",    0, 0)
    accent:SetPoint("BOTTOMLEFT", P, "BOTTOMLEFT", 0, 0)
    accent:SetColorTexture(unpack(C.ACCENT))

    -- Header bar
    local hdrBG = P:CreateTexture(nil, "BACKGROUND")
    hdrBG:SetSize(W, 30)
    hdrBG:SetPoint("TOPLEFT", P, "TOPLEFT", 0, 0)
    hdrBG:SetColorTexture(unpack(C.BG_HEADER))

    local titleFS = TM:MakeFS(P, 13, "OUTLINE")
    titleFS:SetPoint("LEFT", P, "TOPLEFT", 10, -15)
    titleFS:SetText("|cFF55B400Interrupt|r |cFF3377CCTracker|r  "
        .. "|cFF445566v" .. MIT_VERSION .. "|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, P)
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("TOPRIGHT", P, "TOPRIGHT", -4, -4)
    local closeX = TM:MakeFS(closeBtn, 13, "OUTLINE")
    closeX:SetPoint("CENTER")
    closeX:SetText("|cFFCC3322✕|r")
    closeBtn:SetScript("OnClick", function() P:Hide() end)

    -- Section header helper
    local function SectionHdr(text, yOff)
        local lbl = TM:MakeFS(P, 10, "OUTLINE")
        lbl:SetPoint("TOPLEFT", P, "TOPLEFT", 10, yOff)
        lbl:SetText("|cFF3377CC" .. text:upper() .. "|r")
        local line = P:CreateTexture(nil, "ARTWORK")
        line:SetSize(W - 12, 1)
        line:SetPoint("TOPLEFT", P, "TOPLEFT", 8, yOff - 13)
        line:SetColorTexture(0.15, 0.32, 0.55, 0.60)
    end

    -- Checkbox helper
    local function CB(label, yOff, key, onChange)
        local cb = CreateFrame("CheckButton", nil, P, "UICheckButtonTemplate")
        cb:SetSize(18, 18)
        cb:SetPoint("TOPLEFT", P, "TOPLEFT", 10, yOff)
        cb:SetChecked(db[key] ~= false)
        local lbl = TM:MakeFS(P, 11, "OUTLINE")
        lbl:SetPoint("LEFT", cb, "RIGHT", 3, 0)
        lbl:SetText(label)
        lbl:SetTextColor(unpack(C.TEXT_WHITE))
        cb:SetScript("OnClick", function(self)
            db[key] = (self:GetChecked() == true)
            if onChange then onChange(db[key]) end
        end)
        return cb
    end

    -- Slider helper
    local slCount = 0
    local function Sl(label, yOff, minV, maxV, step, key, fmt, onChange)
        local lbl = TM:MakeFS(P, 10, "OUTLINE")
        lbl:SetPoint("TOPLEFT", P, "TOPLEFT", 10, yOff)
        lbl:SetText(label)
        lbl:SetTextColor(unpack(C.TEXT_GREY))
        slCount = slCount + 1
        local slName = "TMIntSlider" .. slCount
        local sl = CreateFrame("Slider", slName, P, "OptionsSliderTemplate")
        sl:SetSize(W - 60, 14)
        sl:SetPoint("TOPLEFT", P, "TOPLEFT", 10, yOff - 17)
        sl:SetMinMaxValues(minV, maxV)
        sl:SetValueStep(step)
        sl:SetObeyStepOnDrag(true)
        sl:SetValue(db[key] or minV)
        local lowL  = _G[slName .. "Low"]
        local highL = _G[slName .. "High"]
        if lowL  then lowL:SetText( fmt and string.format(fmt, minV) or minV) end
        if highL then highL:SetText(fmt and string.format(fmt, maxV) or maxV) end
        local valLbl = TM:MakeFS(P, 10, "OUTLINE")
        valLbl:SetPoint("LEFT", sl, "RIGHT", 4, 0)
        valLbl:SetText(fmt and string.format(fmt, db[key] or minV) or tostring(db[key] or minV))
        valLbl:SetTextColor(unpack(C.TEXT_GREEN))
        sl:SetScript("OnValueChanged", function(self, val)
            val = math.floor(val / step + 0.5) * step
            db[key] = val
            valLbl:SetText(fmt and string.format(fmt, val) or tostring(val))
            if onChange then onChange(val) end
        end)
        return sl
    end

    -- Button helper
    local function Btn(label, yOff, xOff, onClick)
        local b = CreateFrame("Button", nil, P, "BackdropTemplate")
        b:SetSize(120, 20)
        b:SetPoint("TOPLEFT", P, "TOPLEFT", xOff or 10, yOff)
        b:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8",
            edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })
        b:SetBackdropColor(0.05, 0.12, 0.26, 0.92)
        b:SetBackdropBorderColor(unpack(C.BORDER_BLUE or C.BORDER))
        local fs = TM:MakeFS(b, 11, "OUTLINE")
        fs:SetPoint("CENTER"); fs:SetText(label)
        fs:SetTextColor(unpack(C.TEXT_WHITE))
        b:SetScript("OnEnter", function(s) s:SetBackdropColor(0.10, 0.22, 0.44, 0.95) end)
        b:SetScript("OnLeave", function(s) s:SetBackdropColor(0.05, 0.12, 0.26, 0.92) end)
        b:SetScript("OnClick", onClick)
        return b
    end

    -- Layout
    local y = -38
    SectionHdr("DISPLAY", y) ; y = y - 20
    CB("Show title bar", y, "showTitle", function(v)
        local F = MIT.mainFrame
        if F then
            if F.titleBG  then F.titleBG:SetShown(v) end
            if F.titleFS  then F.titleFS:SetShown(v) end
            if F.titleSep then F.titleSep:SetShown(v) end
            F.titleHeight = v and 21 or 0
            TM:MIT_LayoutFrame()
        end
    end) ; y = y - 24
    CB("Grow upward",    y, "growUp",    function() TM:MIT_LayoutFrame() end) ; y = y - 24
    CB(TM.L.CFG_SHOW_READY, y, "showReady", function() TM:MIT_RefreshBars() end) ; y = y - 34

    SectionHdr("SHOW IN...", y) ; y = y - 20
    CB("Dungeon (M+)",   y, "showInDungeon",   nil) ; y = y - 24
    CB("Raid",           y, "showInRaid",      nil) ; y = y - 24
    CB("Open World",     y, "showInOpenWorld", nil) ; y = y - 24
    CB("Arena",          y, "showInArena",     nil) ; y = y - 24
    CB("Battleground",   y, "showInBG",        nil) ; y = y - 34

    SectionHdr("FRAME", y) ; y = y - 20
    CB("Locked", y, "locked", function(v)
        local F = MIT.mainFrame
        if F then
            F:SetMovable(not v)
            F:EnableMouse(not v)
        end
    end) ; y = y - 30

    Sl("Alpha", y, 0.1, 1.0, 0.05, "alpha", "%.2f", function(v)
        if MIT.mainFrame then MIT.mainFrame:SetAlpha(v) end
    end)
    y = y - 46

    Sl("Bar height", y, 16, 40, 1, "barHeight", "%dpx", function()
        TM:MIT_LayoutFrame()
    end)
    y = y - 46

    SectionHdr("ACTIONS", y) ; y = y - 24
    Btn("Test mode",  y,  10, function() TM:InterruptCommand("test")   end)
    Btn("Spy mode",   y, 148, function() TM:InterruptCommand("spy")    end)

    -- Version footer
    local ver = TM:MakeFS(P, 9, "OUTLINE")
    ver:SetPoint("BOTTOMRIGHT", P, "BOTTOMRIGHT", -8, 6)
    ver:SetText("|cFF334455TomoMythic — MIT v" .. MIT_VERSION .. "|r")

    return P
end

------------------------------------------------------------
-- Slash command integration  (/tmt interrupt [subcmd])
------------------------------------------------------------

function TM:InterruptCommand(sub)
    sub = strtrim(sub or ""):lower()
    if sub == "" then
        -- Toggle config panel
        local P = MIT.configPanel or BuildConfigPanel()
        if P:IsShown() then P:Hide() else P:Show() end

    elseif sub == "show" then
        if MIT.mainFrame then MIT.mainFrame:Show() end

    elseif sub == "hide" then
        if MIT.mainFrame then MIT.mainFrame:Hide() end

    elseif sub == "lock" then
        TM.db.interrupt.locked = true
        if MIT.mainFrame then
            MIT.mainFrame:SetMovable(false); MIT.mainFrame:EnableMouse(false)
        end
        print("|cFF55B400[MIT]|r Frame |cFFFF8822locked|r.")

    elseif sub == "unlock" then
        TM.db.interrupt.locked = false
        if MIT.mainFrame then
            MIT.mainFrame:SetMovable(true)
            MIT.mainFrame:EnableMouse(true)
            MIT.mainFrame:RegisterForDrag("LeftButton")
        end
        print("|cFF55B400[MIT]|r Frame |cFF55DD22unlocked|r.")

    elseif sub == "test" then
        if MIT.testMode then StopTestMode() else StartTestMode() end

    elseif sub == "spy" then
        MIT.spyMode = not MIT.spyMode
        print("|cFF55B400[MIT]|r Spy mode " .. (MIT.spyMode and "|cFFFFFF00ON|r" or "|cFFCC3322OFF|r") .. ".")

    elseif sub == "debug" then
        MIT.debugMode = not MIT.debugMode
        print("|cFF55B400[MIT]|r Debug mode " .. (MIT.debugMode and "|cFFFFFF00ON|r" or "|cFFCC3322OFF|r") .. ".")

    elseif sub == "help" then
        print("|cFF55B400[MIT]|r Usage:  /tmt interrupt [show|hide|lock|unlock|test|spy|debug|help]")

    else
        print("|cFF55B400[MIT]|r Unknown subcommand '" .. sub .. "'. Try /tmt interrupt help")
    end
end

------------------------------------------------------------
-- Internal event frame (separate from TomoMythic's main EF)
------------------------------------------------------------

local MIT_EF = CreateFrame("Frame")

MIT_EF:SetScript("OnEvent", function(_, event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        OnSpellCastSucceeded(unit, _, spellID)

    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        OnAddonMessage(prefix, message, channel, sender)

    elseif event == "SPELL_UPDATE_COOLDOWN" then
        UpdateCooldowns()

    elseif event == "SPELLS_CHANGED" then
        -- Re-detect player's interrupt spell after a spellbook change
        local data = MIT.playerData["player"]
        if data then
            local class = select(2, UnitClass("player"))
            local spellID = GetPrimaryInterruptForClass(class)
            if spellID then
                data.spellID = spellID
                data.cd      = GetInterruptCD(spellID)
            end
        end

    elseif event == "INSPECT_READY" then
        local guid = ...
        OnInspectReady(guid)

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        local unit = ...
        if unit == "player" then
            local data = MIT.playerData["player"]
            if data then
                local class = select(2, UnitClass("player"))
                local spellID = GetPrimaryInterruptForClass(class)
                if spellID then
                    data.spellID = spellID
                    data.cd      = GetInterruptCD(spellID)
                    TM:MIT_RefreshBars()
                end
            end
        else
            QueueInspect(unit)
        end

    elseif event == "UNIT_PET" then
        -- Handled via partyPetFrames; nothing needed globally here

    elseif event == "ROLE_CHANGED_INFORM"
        or event == "GROUP_ROSTER_UPDATE" then
        C_Timer.After(0.5, UpdatePartyMembers)

    elseif event == "PLAYER_ENTERING_WORLD" then
        TM:OnInterruptEnterWorld()

    elseif event == "NAME_PLATE_UNIT_ADDED" then
        local unit = ...
        OnNameplateAdded(unit)

    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local unit = ...
        OnNameplateRemoved(unit)
    end
end)

------------------------------------------------------------
-- Public API called from Events.lua
------------------------------------------------------------

function TM:OnInterruptEnterWorld()
    if not MIT.mainFrame then return end
    if ShouldShowFrame() then
        MIT_EF:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        MIT_EF:RegisterEvent("CHAT_MSG_ADDON")
        MIT_EF:RegisterEvent("SPELL_UPDATE_COOLDOWN")
        MIT_EF:RegisterEvent("SPELLS_CHANGED")
        MIT_EF:RegisterEvent("INSPECT_READY")
        MIT_EF:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        MIT_EF:RegisterEvent("UNIT_PET")
        MIT_EF:RegisterEvent("ROLE_CHANGED_INFORM")
        MIT_EF:RegisterEvent("GROUP_ROSTER_UPDATE")
        MIT_EF:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        MIT_EF:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
        if not MIT.testMode then UpdatePartyMembers() end
        MIT.mainFrame:Show()
    else
        MIT_EF:UnregisterAllEvents()
        MIT_EF:RegisterEvent("PLAYER_ENTERING_WORLD")
        MIT.mainFrame:Hide()
    end
end

function TM:SetInterruptTrackerEnabled(enabled)
    if enabled then
        if not MIT.mainFrame then
            self:InitInterruptTracker()
        end
        self:OnInterruptEnterWorld()
    else
        if MIT.mainFrame then
            MIT.mainFrame:Hide()
        end
    end
end

function TM:InitInterruptTracker()
    -- Register addon message prefix for inter-addon sync
    if C_ChatInfo then
        C_ChatInfo.RegisterAddonMessagePrefix(MSG_PREFIX)
    else
        RegisterAddonMessagePrefix(MSG_PREFIX)  -- legacy fallback
    end

    -- Register all interrupt-tracker-specific events on the internal frame
    MIT_EF:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    MIT_EF:RegisterEvent("CHAT_MSG_ADDON")
    MIT_EF:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    MIT_EF:RegisterEvent("SPELLS_CHANGED")
    MIT_EF:RegisterEvent("INSPECT_READY")
    MIT_EF:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    MIT_EF:RegisterEvent("UNIT_PET")
    MIT_EF:RegisterEvent("ROLE_CHANGED_INFORM")
    MIT_EF:RegisterEvent("GROUP_ROSTER_UPDATE")
    MIT_EF:RegisterEvent("PLAYER_ENTERING_WORLD")
    MIT_EF:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    MIT_EF:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

    -- Attach party watcher scripts
    RegisterPartyWatchers()

    -- Detect player class and primary interrupt
    local _, class = UnitClass("player")
    local spellID  = GetPrimaryInterruptForClass(class)
    MITDebug("Player class=" .. tostring(class)
        .. "  interrupt=" .. tostring(spellID and GetInterruptName(spellID) or "none"))

    -- Build the UI frame
    self:MIT_BuildFrame()

    -- Start update ticker
    if not MIT.ticker then
        MIT.ticker = C_Timer.NewTicker(0.5, UpdateCooldowns)
    end

    -- Announce version to group
    SendMIT("VER:" .. MIT_VERSION)
end
local ADDON_NAME, ns = ...

----------------------------------------------------------------------
-- SpellTracker: lightweight CLEU parser for per-spell breakdowns
----------------------------------------------------------------------
-- Tracks outgoing damage and healing per source GUID per spell.
-- Pet damage/healing is attributed to the pet's owner.
-- Data is consumed by the SpellBreakdown UI.
----------------------------------------------------------------------

local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local GetSpellInfo = C_Spell and C_Spell.GetSpellInfo or GetSpellInfo
local UnitGUID = UnitGUID
local MELEE_STRING = MELEE or "Melee"

----------------------------------------------------------------------
-- Data Store
----------------------------------------------------------------------
-- ns.spellStore.damage[guid][spellID] = { total, hits, crits, name, icon }
-- ns.spellStore.healing[guid][spellID] = { total, hits, crits, name, icon }

ns.spellStore = {
    damage  = {},
    healing = {},
}

local dmg  = ns.spellStore.damage
local heal = ns.spellStore.healing

----------------------------------------------------------------------
-- Pet → Owner Resolution
----------------------------------------------------------------------

local petToOwner = {}  -- petGUID → ownerGUID

-- Scan group roster to build pet→owner map from unit IDs
local function ScanGroupPets()
    -- Player's own pet
    local playerGUID = UnitGUID("player")
    local petGUID = UnitGUID("pet")
    if petGUID and playerGUID then
        petToOwner[petGUID] = playerGUID
    end

    -- Party/raid members' pets
    local prefix, count
    if IsInRaid() then
        prefix, count = "raid", GetNumGroupMembers()
    elseif IsInGroup() then
        prefix, count = "party", GetNumGroupMembers() - 1
    else
        return
    end

    for i = 1, count do
        local unitID = prefix .. i
        local memberGUID = UnitGUID(unitID)
        local memberPetGUID = UnitGUID(unitID .. "pet")
        if memberGUID and memberPetGUID then
            petToOwner[memberPetGUID] = memberGUID
        end
    end
end

-- Resolve a GUID to its owner if it's a known pet, otherwise return itself
local function ResolveOwner(guid)
    return petToOwner[guid] or guid
end

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

local function GetSpellDetails(spellID)
    if spellID == 1 then
        return MELEE_STRING, 132223 -- default melee icon
    end
    local info = GetSpellInfo and GetSpellInfo(spellID)
    if info then
        return info.name or ("Spell " .. spellID), info.iconID or 134400
    end
    return "Spell " .. spellID, 134400
end

local function Record(store, guid, spellID, amount, isCrit)
    if not guid or guid == "" then return end
    if not spellID or not amount then return end
    if issecretvalue and (issecretvalue(amount) or issecretvalue(spellID)) then return end
    if amount <= 0 then return end

    -- Resolve pet → owner
    guid = ResolveOwner(guid)

    local byGUID = store[guid]
    if not byGUID then
        byGUID = {}
        store[guid] = byGUID
    end

    local entry = byGUID[spellID]
    if not entry then
        local name, icon = GetSpellDetails(spellID)
        entry = { total = 0, hits = 0, crits = 0, name = name, icon = icon }
        byGUID[spellID] = entry
    end

    entry.total = entry.total + amount
    entry.hits  = entry.hits + 1
    if isCrit then
        entry.crits = entry.crits + 1
    end
end

----------------------------------------------------------------------
-- CLEU Dispatcher
----------------------------------------------------------------------

-- Damage events
local DAMAGE_EVENTS = {
    SPELL_DAMAGE           = true,
    SPELL_PERIODIC_DAMAGE  = true,
    RANGE_DAMAGE           = true,
    DAMAGE_SHIELD          = true,
}

-- Healing events
local HEAL_EVENTS = {
    SPELL_HEAL             = true,
    SPELL_PERIODIC_HEAL    = true,
}

local function OnCombatLogEvent()
    local timestamp, token, hideCaster,
          sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
          destGUID,   destName,   destFlags,   destRaidFlags,
          arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19,
          arg20, arg21, arg22, arg23, arg24 = CombatLogGetCurrentEventInfo()

    -- Only track friendly sources (players + pets in our group)
    if not sourceFlags then return end
    local affiliation = bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MASK)
    if affiliation ~= COMBATLOG_OBJECT_AFFILIATION_MINE
       and affiliation ~= COMBATLOG_OBJECT_AFFILIATION_PARTY
       and affiliation ~= COMBATLOG_OBJECT_AFFILIATION_RAID then
        return
    end

    -- Track SPELL_SUMMON for pet→owner mapping
    if token == "SPELL_SUMMON" then
        if sourceGUID and destGUID then
            petToOwner[destGUID] = ResolveOwner(sourceGUID)
        end
        return
    end

    if token == "SWING_DAMAGE" then
        -- SWING_DAMAGE: amount=arg12, critical=arg18
        local amount = arg12 or 0
        local isCrit = arg18
        Record(dmg, sourceGUID, 1, amount, isCrit)

    elseif DAMAGE_EVENTS[token] then
        -- SPELL_DAMAGE etc: spellID=arg12, amount=arg15, critical=arg21
        local spellID = arg12
        local amount  = arg15 or 0
        local isCrit  = arg21
        Record(dmg, sourceGUID, spellID, amount, isCrit)

    elseif HEAL_EVENTS[token] then
        -- SPELL_HEAL: spellID=arg12, amount=arg15, overhealing=arg16, critical=arg18
        local spellID   = arg12
        local amount    = arg15 or 0
        local overheal  = arg16 or 0
        local isCrit    = arg18
        -- Track effective healing (minus overhealing)
        local effective = amount - overheal
        if effective > 0 then
            Record(heal, sourceGUID, spellID, effective, isCrit)
        end
    end
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

--- Returns a sorted array of spell entries for a GUID in the given category.
--- @param category string "damage" or "healing"
--- @param guid string source GUID
--- @return table|nil sortedSpells, number grandTotal
function ns.GetSpellBreakdown(category, guid)
    local store = ns.spellStore[category]
    if not store then return nil end
    local byGUID = store[guid]
    if not byGUID then return nil end

    local sorted = {}
    local grandTotal = 0
    for spellID, entry in pairs(byGUID) do
        sorted[#sorted + 1] = {
            spellID = spellID,
            total   = entry.total,
            hits    = entry.hits,
            crits   = entry.crits,
            name    = entry.name,
            icon    = entry.icon,
        }
        grandTotal = grandTotal + entry.total
    end

    table.sort(sorted, function(a, b) return a.total > b.total end)

    for _, entry in ipairs(sorted) do
        entry.pct = grandTotal > 0 and (entry.total / grandTotal * 100) or 0
    end

    return sorted, grandTotal
end

--- Returns the appropriate category string for a given DamageMeterType.
function ns.GetSpellCategory(meterType)
    if meterType == Enum.DamageMeterType.Dps
       or meterType == Enum.DamageMeterType.DamageTaken
       or meterType == Enum.DamageMeterType.AvoidableDamageTaken
       or meterType == Enum.DamageMeterType.EnemyDamageTaken then
        return "damage"
    elseif meterType == Enum.DamageMeterType.Hps
       or meterType == Enum.DamageMeterType.Absorbs then
        return "healing"
    end
    return nil -- Actions types don't have spell breakdown
end

----------------------------------------------------------------------
-- Reset
----------------------------------------------------------------------

function ns.ResetSpellData()
    wipe(ns.spellStore.damage)
    wipe(ns.spellStore.healing)
    wipe(petToOwner)
    dmg  = ns.spellStore.damage
    heal = ns.spellStore.healing
    ScanGroupPets() -- rebuild pet map from current roster
end

----------------------------------------------------------------------
-- Event Frame
----------------------------------------------------------------------

-- The addon depends on the protected Blizzard_DamageMeter, which taints
-- every frame created at file-load time.  C_Timer.After(0, ...) defers
-- execution to a clean, untainted context so CreateFrame + RegisterEvent
-- both succeed without propagating taint.

C_Timer.After(0, function()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    frame:RegisterEvent("DAMAGE_METER_RESET")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("UNIT_PET")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            OnCombatLogEvent()
        elseif event == "DAMAGE_METER_RESET" then
            ns.ResetSpellData()
        elseif event == "GROUP_ROSTER_UPDATE"
            or event == "UNIT_PET"
            or event == "PLAYER_ENTERING_WORLD" then
            ScanGroupPets()
        end
    end)
    ScanGroupPets()
end)

local ADDON_NAME, ns = ...

----------------------------------------------------------------------
-- SpellBridge: queries C_DamageMeter for per-spell breakdown data
----------------------------------------------------------------------
-- Uses C_DamageMeter.GetCombatSessionSourceFromType() which returns
-- a combatSpells array for a given source GUID.  No CLEU needed.
----------------------------------------------------------------------

local GetSpellInfo = C_Spell and C_Spell.GetSpellInfo or GetSpellInfo

local function GetSpellIcon(spellID)
    if not spellID or spellID == 0 then return 134400 end
    if issecretvalue and issecretvalue(spellID) then return 134400 end
    local info = GetSpellInfo(spellID)
    if info then
        return info.iconID or 134400
    end
    return 134400
end

local function GetSpellName(spellID)
    if not spellID or spellID == 0 then return "?" end
    if issecretvalue and issecretvalue(spellID) then return "?" end
    local info = GetSpellInfo(spellID)
    if info then
        return info.name or ("Spell " .. spellID)
    end
    return "Spell " .. spellID
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

--- Returns a sorted array of spell entries for a GUID in the current session.
--- @param sessionType number Enum.DamageMeterSessionType
--- @param meterType number Enum.DamageMeterType
--- @param sourceGUID string
--- @return table|nil sortedSpells, number grandTotal
function ns.GetSpellBreakdown(sessionType, meterType, sourceGUID)
    if not C_DamageMeter or not C_DamageMeter.GetCombatSessionSourceFromType then
        return nil, 0
    end

    local spellData = C_DamageMeter.GetCombatSessionSourceFromType(sessionType, meterType, sourceGUID)
    if not spellData or issecretvalue(spellData) then return nil, 0 end

    local combatSpells = spellData.combatSpells
    if not combatSpells or #combatSpells == 0 then return nil, 0 end

    local sorted = {}
    local grandTotal = 0

    for _, spell in ipairs(combatSpells) do
        local spellID     = spell.spellID
        local totalAmount = spell.totalAmount or 0

        -- Skip secret/invalid values
        if not issecretvalue(spellID) and not issecretvalue(totalAmount) and totalAmount > 0 then
            sorted[#sorted + 1] = {
                spellID = spellID,
                total   = totalAmount,
                perSec  = spell.amountPerSecond,
                name    = GetSpellName(spellID),
                icon    = GetSpellIcon(spellID),
            }
            grandTotal = grandTotal + totalAmount
        end
    end

    table.sort(sorted, function(a, b) return a.total > b.total end)

    for _, entry in ipairs(sorted) do
        entry.pct = grandTotal > 0 and (entry.total / grandTotal * 100) or 0
    end

    return sorted, grandTotal
end

--- Returns true if the meter type supports spell breakdown.
function ns.HasSpellBreakdown(meterType)
    -- Actions types (Interrupts, Dispels, Deaths) also have per-spell data
    return meterType ~= nil
end

--- Stub: no external data to reset anymore
function ns.ResetSpellData()
    -- No-op: C_DamageMeter handles its own data lifecycle
end

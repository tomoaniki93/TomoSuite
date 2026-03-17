-- =====================================
-- Modules/HoTTracker.lua
-- Tracks HoT (Heal over Time) auras from ALL healers on group members
-- Shows Blizzard spell icons
-- =====================================

TGF_HoTTracker = {}
local HT = TGF_HoTTracker

-- =====================================
-- KNOWN HEALER HOTS (spell IDs)
-- These are the major HoTs from each healer spec.
-- Blizzard icon textures are fetched via C_Spell.GetSpellTexture().
-- =====================================

local TRACKED_HOTS = {
    -- Druid Restoration
    [774]    = true,  -- Rejuvenation
    [8936]   = true,  -- Regrowth (HoT component)
    [33763]  = true,  -- Lifebloom
    [48438]  = true,  -- Wild Growth
    [155777] = true,  -- Rejuvenation (Germination)
    [207386] = true,  -- Spring Blossoms
    [102352] = true,  -- Cenarion Ward
    [200389] = true,  -- Cultivation

    -- Priest Holy
    [139]    = true,  -- Renew
    [41635]  = true,  -- Prayer of Mending
    [77489]  = true,  -- Echo of Light

    -- Priest Discipline
    [194384] = true,  -- Atonement
    [17]     = true,  -- Power Word: Shield

    -- Paladin Holy
    [287280] = true,  -- Glimmer of Light
    [223306] = true,  -- Bestow Faith
    [388007] = true,  -- Blessing of Summer (HoT)
    [156910] = true,  -- Beacon of Faith
    [53563]  = true,  -- Beacon of Light

    -- Shaman Restoration
    [61295]  = true,  -- Riptide
    [382024] = true,  -- Earthliving Weapon (HoT)
    [157503] = true,  -- Cloudburst (tracking)

    -- Monk Mistweaver
    [119611] = true,  -- Renewing Mist
    [116849] = true,  -- Life Cocoon
    [124682] = true,  -- Enveloping Mist
    [191840] = true,  -- Essence Font (HoT)
    [325209] = true,  -- Enveloping Breath

    -- Evoker Preservation
    [355941] = true,  -- Dream Breath
    [363502] = true,  -- Dream Flight
    [366155] = true,  -- Reversion
    [376788] = true,  -- Call of Ysera
    [373267] = true,  -- Lifebind
    [364343] = true,  -- Echo
}

--- Scan a unit for active HoTs from any group healer
--- @param unit string
--- @param maxHots number
--- @return table hots Array of { spellID, icon, duration, expirationTime, source }
function HT.GetUnitHoTs(unit, maxHots)
    maxHots = maxHots or 4
    local hots = {}
    if not UnitExists(unit) then return hots end

    for i = 1, 40 do
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
        if not auraData then break end

        local spellID = auraData.spellId
        if spellID and TRACKED_HOTS[spellID] then
            -- Only track HoTs from group members (including player)
            local source = auraData.sourceUnit
            if source and (UnitInParty(source) or UnitInRaid(source) or UnitIsUnit(source, "player")) then
                local icon = auraData.icon or C_Spell.GetSpellTexture(spellID)
                table.insert(hots, {
                    spellID        = spellID,
                    icon           = icon,
                    duration       = auraData.duration or 0,
                    expirationTime = auraData.expirationTime or 0,
                    source         = source,
                    stacks         = auraData.applications or 0,
                })
                if #hots >= maxHots then break end
            end
        end
    end

    return hots
end

-- =====================================
-- HOT ICON CONTAINER
-- Creates a row of small spell icons on a unit frame
-- =====================================

function HT.CreateHoTContainer(parent, maxIcons, iconSize)
    maxIcons = maxIcons or 4
    iconSize = iconSize or 16

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(maxIcons * (iconSize + 2), iconSize)
    container:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 2, 2)
    container:SetFrameLevel(parent:GetFrameLevel() + 6)

    container.icons = {}

    for i = 1, maxIcons do
        local btn = CreateFrame("Frame", nil, container)
        btn:SetSize(iconSize, iconSize)
        btn:SetPoint("LEFT", (i - 1) * (iconSize + 2), 0)

        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Trim icon borders
        btn.texture = tex

        -- No cooldown overlay — just show icon + our own duration text
        btn.cooldown = nil

        -- Border (4 thin edges around the icon)
        local borderTop = btn:CreateTexture(nil, "OVERLAY")
        borderTop:SetHeight(1)
        borderTop:SetPoint("TOPLEFT", -1, 1)
        borderTop:SetPoint("TOPRIGHT", 1, 1)
        borderTop:SetColorTexture(0, 0, 0, 1)

        local borderBottom = btn:CreateTexture(nil, "OVERLAY")
        borderBottom:SetHeight(1)
        borderBottom:SetPoint("BOTTOMLEFT", -1, -1)
        borderBottom:SetPoint("BOTTOMRIGHT", 1, -1)
        borderBottom:SetColorTexture(0, 0, 0, 1)

        local borderLeft = btn:CreateTexture(nil, "OVERLAY")
        borderLeft:SetWidth(1)
        borderLeft:SetPoint("TOPLEFT", -1, 1)
        borderLeft:SetPoint("BOTTOMLEFT", -1, -1)
        borderLeft:SetColorTexture(0, 0, 0, 1)

        local borderRight = btn:CreateTexture(nil, "OVERLAY")
        borderRight:SetWidth(1)
        borderRight:SetPoint("TOPRIGHT", 1, 1)
        borderRight:SetPoint("BOTTOMRIGHT", 1, -1)
        borderRight:SetColorTexture(0, 0, 0, 1)

        -- Stack count
        local stackText = btn:CreateFontString(nil, "OVERLAY")
        stackText:SetFont(TGF_GetFontPath("Expressway"), 8, "OUTLINE")
        stackText:SetPoint("BOTTOMRIGHT", 1, -1)
        stackText:SetTextColor(1, 1, 1)
        stackText:SetText("")
        btn.stackText = stackText

        -- Duration text
        local durationText = btn:CreateFontString(nil, "OVERLAY")
        durationText:SetFont(TGF_GetFontPath("Expressway"), 8, "OUTLINE")
        durationText:SetPoint("CENTER", 0, 0)
        durationText:SetTextColor(1, 1, 1)
        durationText:SetText("")
        btn.durationText = durationText

        btn:Hide()
        container.icons[i] = btn
    end

    --- Update the HoT icons for a unit
    function container:UpdateForUnit(unit, settings)
        if not settings or not settings.showHots then
            for _, icon in ipairs(self.icons) do icon:Hide() end
            return
        end

        local hots = HT.GetUnitHoTs(unit, settings.maxHots or #self.icons)
        local fontSize = settings.hotFontSize or 8

        for i, icon in ipairs(self.icons) do
            if i <= #hots then
                local hotData = hots[i]
                icon.texture:SetTexture(hotData.icon)
                icon:SetSize(settings.hotIconSize or 16, settings.hotIconSize or 16)

                -- Update font sizes
                icon.stackText:SetFont(TGF_GetFontPath("Expressway"), fontSize, "OUTLINE")
                if icon.durationText then
                    icon.durationText:SetFont(TGF_GetFontPath("Expressway"), fontSize, "OUTLINE")
                end

                -- Update duration text (no cooldown overlay)
                if hotData.duration and hotData.duration > 0 and hotData.expirationTime and hotData.expirationTime > 0 then
                    if icon.durationText then
                        local remaining = hotData.expirationTime - GetTime()
                        if remaining > 0 then
                            icon.durationText:SetText(math.floor(remaining))
                        else
                            icon.durationText:SetText("")
                        end
                    end
                else
                    if icon.durationText then icon.durationText:SetText("") end
                end

                -- Stack count
                if hotData.stacks and hotData.stacks > 1 then
                    icon.stackText:SetText(hotData.stacks)
                else
                    icon.stackText:SetText("")
                end

                icon:Show()
            else
                icon:Hide()
            end
        end
    end

    function container:UpdateIconSize(size)
        for i, icon in ipairs(self.icons) do
            icon:SetSize(size, size)
            icon:SetPoint("LEFT", (i - 1) * (size + 2), 0)
        end
        self:SetSize(#self.icons * (size + 2), size)
    end

    return container
end

-- =====================================
-- Modules/UnitFrame.lua
-- Core secure unit frame creation for TomoGroupFrame
-- Creates individual unit buttons with health bar, name, HP%, 
-- role icon, raid icon, dispel overlay, HoT icons
-- =====================================
--
-- TWW SECRET NUMBER STRATEGY (same as oUF / TomoMod):
-- StatusBar:SetMinMaxValues() and SetValue() are C-side
-- widget methods that accept "secret numbers" natively.
-- For text display, use C-side functions:
--   SetFormattedText()        — C-side FontString method
--   UnitHealthPercent()       — TWW API (returns normal number)
-- NO tonumber(), NO pcall(), NO Lua arithmetic on health values.
-- =====================================

TGF_UnitFrame = {}
local UF = TGF_UnitFrame

local ADDON_PATH = "Interface\\AddOns\\TomoGroupFrame\\"

-- =====================================
-- CREATE UNIT BUTTON
-- =====================================

--- Create a single unit frame button
--- @param unitID string e.g. "party1", "raid15"
--- @param parent Frame
--- @param settings table The party or raid settings table
--- @return Frame button
function UF.CreateUnitButton(unitID, parent, settings)
    local name = "TGF_" .. unitID

    -- SecureUnitButton for click-casting compatibility
    local btn = CreateFrame("Button", name, parent, "SecureUnitButtonTemplate, BackdropTemplate")
    btn:SetSize(settings.width or 160, settings.height or 44)
    btn.unit = unitID
    btn:SetAttribute("unit", unitID)
    btn:SetAttribute("type1", "target")     -- Left-click = target
    btn:SetAttribute("type2", "togglemenu") -- Right-click = menu

    RegisterUnitWatch(btn)

    -- =====================================
    -- BACKDROP (dark background + border)
    -- =====================================
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = settings.borderSize or 1,
    })
    btn:SetBackdropColor(0.05, 0.05, 0.07, settings.bgAlpha or 0.85)
    btn:SetBackdropBorderColor(0.12, 0.12, 0.15, 1)

    -- =====================================
    -- HEALTH BAR
    -- =====================================
    local powerH = (settings.showPowerBar and settings.powerHeight) or 0
    local healthH = (settings.height or 44) - powerH - 2  -- 2px for borders

    local healthBar = CreateFrame("StatusBar", name .. "_Health", btn)
    healthBar:SetPoint("TOPLEFT", 1, -1)
    healthBar:SetPoint("TOPRIGHT", -1, -1)
    healthBar:SetHeight(healthH)
    healthBar:SetMinMaxValues(0, 1)
    healthBar:SetValue(1)
    TGF_Bar.SetTexture(healthBar, settings.barTexture)
    btn.healthBar = healthBar

    -- Health bar background
    local healthBg = healthBar:CreateTexture(nil, "BACKGROUND")
    healthBg:SetAllPoints()
    healthBg:SetTexture(TGF_GetBarTexturePath("Flat"))
    healthBg:SetVertexColor(0.08, 0.08, 0.10, 0.9)
    btn.healthBg = healthBg

    -- =====================================
    -- POWER BAR (optional)
    -- =====================================
    if settings.showPowerBar and powerH > 0 then
        local powerBar = CreateFrame("StatusBar", name .. "_Power", btn)
        powerBar:SetPoint("BOTTOMLEFT", 1, 1)
        powerBar:SetPoint("BOTTOMRIGHT", -1, 1)
        powerBar:SetHeight(powerH)
        powerBar:SetMinMaxValues(0, 1)
        powerBar:SetValue(1)
        TGF_Bar.SetTexture(powerBar, settings.barTexture)
        btn.powerBar = powerBar

        local powerBg = powerBar:CreateTexture(nil, "BACKGROUND")
        powerBg:SetAllPoints()
        powerBg:SetTexture(TGF_GetBarTexturePath("Flat"))
        powerBg:SetVertexColor(0.05, 0.05, 0.07, 0.9)
        btn.powerBg = powerBg
    end

    local isPartyLayout = (settings.layout == "party")

    -- =====================================
    -- NAME TEXT
    -- =====================================
    local nameText = healthBar:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(TGF_GetFontPath(settings.nameFont or "Poppins"), settings.nameFontSize or 11, "OUTLINE")
    nameText:SetWordWrap(false)
    nameText:SetTextColor(1, 1, 1)

    if isPartyLayout then
        -- Party: name top-center
        nameText:SetPoint("TOP", healthBar, "TOP", 0, -2)
        nameText:SetPoint("LEFT", 18, 0)
        nameText:SetPoint("RIGHT", -4, 0)
        nameText:SetJustifyH("CENTER")
    else
        -- Raid / default: name left
        nameText:SetPoint("LEFT", 6, 2)
        nameText:SetPoint("RIGHT", -30, 2)
        nameText:SetJustifyH("LEFT")
    end
    btn.nameText = nameText

    -- =====================================
    -- HP PERCENTAGE TEXT
    -- =====================================
    local hpText = healthBar:CreateFontString(nil, "OVERLAY")
    hpText:SetFont(TGF_GetFontPath(settings.hpFont or "Expressway"), settings.hpFontSize or 12, "OUTLINE")
    hpText:SetTextColor(1, 1, 1)

    if isPartyLayout then
        -- Blizzard style: HP% right-aligned
        hpText:SetPoint("RIGHT", healthBar, "RIGHT", -6, 0)
        hpText:SetJustifyH("RIGHT")
    else
        -- Raid / default: HP right
        hpText:SetPoint("RIGHT", -4, 0)
        hpText:SetJustifyH("RIGHT")
    end
    btn.hpText = hpText

    -- =====================================
    -- ROLE ICON
    -- =====================================
    if settings.showRoleIcon then
        local roleIcon = healthBar:CreateTexture(nil, "OVERLAY")
        roleIcon:SetSize(12, 12)

        if isPartyLayout then
            -- Party: role icon top-left
            roleIcon:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 3, -2)
        else
            -- Raid / default: top-left corner
            roleIcon:SetPoint("TOPLEFT", 3, -2)
        end
        roleIcon:Hide()
        btn.roleIcon = roleIcon
    end

    -- =====================================
    -- RAID TARGET ICON (skull, star, etc.)
    -- =====================================
    if settings.showRaidIcon then
        local raidIcon = healthBar:CreateTexture(nil, "OVERLAY")
        raidIcon:SetSize(16, 16)
        raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")

        if isPartyLayout then
            -- Party: raid marker top-left
            raidIcon:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 2, -2)
        else
            -- Raid / default: top center
            raidIcon:SetPoint("TOP", healthBar, "TOP", 0, -2)
        end
        raidIcon:Hide()
        btn.raidIcon = raidIcon
    end

    -- =====================================
    -- DEAD / OFFLINE OVERLAY
    -- =====================================
    local statusText = healthBar:CreateFontString(nil, "OVERLAY")
    statusText:SetFont(TGF_GetFontPath("PoppinsBold"), settings.nameFontSize or 11, "OUTLINE")
    statusText:SetPoint("CENTER")
    statusText:SetTextColor(0.9, 0.2, 0.2)
    statusText:SetText("")
    btn.statusText = statusText

    -- =====================================
    -- DISPEL OVERLAY
    -- =====================================
    btn.dispelOverlay = TGF_DispelTracker.CreateDispelOverlay(btn, settings.dispelBorderSize or 2)

    -- =====================================
    -- HOT ICONS
    -- =====================================
    btn.hotContainer = TGF_HoTTracker.CreateHoTContainer(btn, settings.maxHots or 4, settings.hotIconSize or 16)

    -- =====================================
    -- HIGHLIGHT ON HOVER
    -- =====================================
    local highlight = btn:CreateTexture(nil, "OVERLAY", nil, 7)
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.06)
    highlight:Hide()
    btn.highlight = highlight

    btn:SetScript("OnEnter", function(self)
        self.highlight:Show()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.unit then
            GameTooltip:SetUnit(self.unit)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function(self)
        self.highlight:Hide()
        GameTooltip:Hide()
    end)

    -- Store settings reference
    btn.settings = settings

    return btn
end

-- =====================================
-- UPDATE FUNCTIONS
-- =====================================

function UF.UpdateHealth(btn)
    local unit = btn.unit
    if not unit or not UnitExists(unit) then return end

    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)

    -- C-side widget methods — accept secret numbers natively (TWW taint-safe)
    btn.healthBar:SetMinMaxValues(0, maxHealth)
    btn.healthBar:SetValue(health)

    -- HP text: 100% C-side chain — zero Lua arithmetic on secret values
    -- UnitHealthPercent(unit, true, ScaleTo100) returns 0-100 scale in TWW
    -- SetFormattedText() is C-side and accepts secret numbers natively
    if btn.hpText and btn.settings.showHpPercent then
        btn.hpText:SetFormattedText("%d%%", UnitHealthPercent(unit, true, ScaleTo100))
    end

    -- Class color on health bar + dim class color for deficit (Blizzard style)
    if btn.settings.useClassColor and UnitIsPlayer(unit) then
        local r, g, b = TGF_Utils.GetClassColor(unit)
        btn.healthBar:SetStatusBarColor(r, g, b)
        if btn.healthBg then
            btn.healthBg:SetVertexColor(r * 0.15, g * 0.15, b * 0.15, 0.9)
        end
    else
        btn.healthBar:SetStatusBarColor(0.2, 0.8, 0.2)
        if btn.healthBg then
            btn.healthBg:SetVertexColor(0.03, 0.12, 0.03, 0.9)
        end
    end
end

function UF.UpdatePower(btn)
    if not btn.powerBar then return end
    local unit = btn.unit
    if not unit or not UnitExists(unit) then return end

    local power = UnitPower(unit)
    local maxPower = UnitPowerMax(unit)

    -- C-side: SetMinMaxValues/SetValue accept secret numbers.
    -- Don't compare maxPower in Lua (could be tainted).
    -- A zero-max bar is just visually empty — no harm.
    btn.powerBar:Show()
    btn.powerBar:SetMinMaxValues(0, maxPower)
    btn.powerBar:SetValue(power)

    local powerType = UnitPowerType(unit)
    local r, g, b = TGF_Utils.GetPowerColor(powerType)
    btn.powerBar:SetStatusBarColor(r, g, b)
end

function UF.UpdateName(btn)
    local unit = btn.unit
    if not unit or not UnitExists(unit) then return end
    if not btn.nameText then return end

    local name = UnitName(unit)
    if btn.settings.showName then
        name = TGF_Utils.TruncateName(name, btn.settings.nameTruncateLen or 12)
        btn.nameText:SetText(name)

        -- Blizzard style: white name text (class color on bar only)
        btn.nameText:SetTextColor(1, 1, 1)
    else
        btn.nameText:SetText("")
    end
end

function UF.UpdateRole(btn)
    if not btn.roleIcon then return end
    local unit = btn.unit
    if not unit or not UnitExists(unit) then
        btn.roleIcon:Hide()
        return
    end

    local role = UnitGroupRolesAssigned(unit)
    local atlas = TGF_Utils.ROLE_ICONS[role]
    if atlas then
        btn.roleIcon:SetAtlas(atlas)
        btn.roleIcon:Show()
    else
        btn.roleIcon:Hide()
    end
end

function UF.UpdateRaidIcon(btn)
    if not btn.raidIcon then return end
    local unit = btn.unit
    if not unit or not UnitExists(unit) then
        btn.raidIcon:Hide()
        return
    end

    local idx = GetRaidTargetIndex(unit)
    if idx then
        SetRaidTargetIconTexture(btn.raidIcon, idx)
        btn.raidIcon:Show()
    else
        btn.raidIcon:Hide()
    end
end

function UF.UpdateStatus(btn)
    local unit = btn.unit
    if not unit or not UnitExists(unit) then
        btn.statusText:SetText("")
        return
    end

    if UnitIsDeadOrGhost(unit) then
        btn.statusText:SetText(TGF_L["status_dead"])
        btn.statusText:SetTextColor(0.9, 0.2, 0.2)
        btn.healthBar:SetValue(0)
        if btn.healthBg then
            btn.healthBg:SetVertexColor(0.15, 0.05, 0.05, 0.9)
        end
        if btn.hpText then btn.hpText:SetText("") end
    elseif not UnitIsConnected(unit) then
        btn.statusText:SetText(TGF_L["status_offline"])
        btn.statusText:SetTextColor(0.5, 0.5, 0.5)
        btn.healthBar:SetValue(0)
        if btn.healthBg then
            btn.healthBg:SetVertexColor(0.1, 0.1, 0.1, 0.9)
        end
        if btn.hpText then btn.hpText:SetText("") end
    else
        btn.statusText:SetText("")
    end
end

function UF.UpdateRange(btn)
    local unit = btn.unit
    if not unit or not UnitExists(unit) then return end

    -- TWW: UnitInRange() returns a secret boolean — can't compare in Lua.
    -- UnitIsVisible() is NOT tainted and covers ~100yd range (good enough for group frames).
    -- For "player" unit, always in range.
    if UnitIsUnit(unit, "player") then
        btn:SetAlpha(1)
        return
    end

    if UnitIsVisible(unit) and UnitIsConnected(unit) then
        btn:SetAlpha(1)
    else
        btn:SetAlpha(btn.settings.rangeAlpha or 0.45)
    end
end

--- Full update of a unit button
function UF.UpdateAll(btn)
    if not btn or not btn.unit then return end
    UF.UpdateHealth(btn)
    UF.UpdatePower(btn)
    UF.UpdateName(btn)
    UF.UpdateRole(btn)
    UF.UpdateRaidIcon(btn)
    UF.UpdateStatus(btn)
    UF.UpdateRange(btn)
    btn.dispelOverlay:UpdateForUnit(btn.unit, btn.settings)
    btn.hotContainer:UpdateForUnit(btn.unit, btn.settings)
end

-- =====================================
-- Config/Panels/Party.lua — Party Frames Settings
-- =====================================

local W = TGF_Widgets
local L = TGF_L
local T = W.Theme

function TGF_ConfigPanel_Party(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local db = TomoGroupFrameDB.party

    -- =====================================
    -- QUICK ACTIONS
    -- =====================================
    local _, ny = W.CreateButton(c, "Test Mode", 160, y, function()
        TGF_PartyFrames.ToggleTestMode()
    end); y = ny

    local _, ny = W.CreateButton(c, "Unlock / Lock", 160, y, function()
        TGF_PartyFrames.ToggleLock()
    end); y = ny

    local _, ny = W.CreateSeparator(c, y); y = ny

    -- =====================================
    -- GENERAL
    -- =====================================
    local _, ny = W.CreateSectionHeader(c, L["section_party_general"], y); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_enabled"], db.enabled, y, function(val)
        db.enabled = val
    end); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_use_class_color"], db.useClassColor, y, function(val)
        db.useClassColor = val
        TGF_PartyFrames.Refresh()
    end); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_show_role_icon"], db.showRoleIcon, y, function(val)
        db.showRoleIcon = val
    end); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_show_raid_icon"], db.showRaidIcon, y, function(val)
        db.showRaidIcon = val
    end); y = ny

    -- =====================================
    -- LAYOUT
    -- =====================================
    local _, ny = W.CreateSeparator(c, y); y = ny
    local _, ny = W.CreateSectionHeader(c, L["section_party_layout"], y); y = ny

    local _, ny = W.CreateSlider(c, L["opt_width"], 80, 300, 1, db.width, y, function(val)
        db.width = val
        TGF_PartyFrames.Refresh()
    end); y = ny

    local _, ny = W.CreateSlider(c, L["opt_height"], 24, 80, 1, db.height, y, function(val)
        db.height = val
        TGF_PartyFrames.Refresh()
    end); y = ny

    local _, ny = W.CreateSlider(c, L["opt_spacing"], 0, 10, 1, db.spacing, y, function(val)
        db.spacing = val
        TGF_PartyFrames.Refresh()
    end); y = ny

    local growOptions = {
        { key = "DOWN",  label = L["grow_down"] },
        { key = "UP",    label = L["grow_up"] },
        { key = "RIGHT", label = L["grow_right"] },
        { key = "LEFT",  label = L["grow_left"] },
    }
    local _, ny = W.CreateDropdown(c, L["opt_grow_direction"], growOptions, db.growDirection, y, function(val)
        db.growDirection = val
        TGF_PartyFrames.Refresh()
    end); y = ny

    -- =====================================
    -- HEALTH BARS
    -- =====================================
    local _, ny = W.CreateSeparator(c, y); y = ny
    local _, ny = W.CreateSectionHeader(c, L["section_party_bars"], y); y = ny

    local barOptions = {}
    for _, bt in ipairs(TGF_BarTextures) do
        table.insert(barOptions, { key = bt.key, label = bt.label })
    end
    local _, ny = W.CreateDropdown(c, L["opt_bar_texture"], barOptions, db.barTexture, y, function(val)
        db.barTexture = val
        TGF_PartyFrames.Refresh()
    end); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_show_power_bar"], db.showPowerBar, y, function(val)
        db.showPowerBar = val
    end); y = ny

    local _, ny = W.CreateSlider(c, L["opt_power_height"], 2, 12, 1, db.powerHeight, y, function(val)
        db.powerHeight = val
    end); y = ny

    local _, ny = W.CreateSlider(c, L["opt_range_alpha"], 0.1, 1.0, 0.05, db.rangeAlpha, y, function(val)
        db.rangeAlpha = val
    end); y = ny

    -- =====================================
    -- TEXT & FONTS
    -- =====================================
    local _, ny = W.CreateSeparator(c, y); y = ny
    local _, ny = W.CreateSectionHeader(c, L["section_party_text"], y); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_show_name"], db.showName, y, function(val)
        db.showName = val
        TGF_PartyFrames.Refresh()
    end); y = ny

    local _, ny = W.CreateSlider(c, L["opt_name_truncate"], 4, 24, 1, db.nameTruncateLen, y, function(val)
        db.nameTruncateLen = val
    end); y = ny

    local fontOptions = {}
    for _, f in ipairs(TGF_Fonts) do
        table.insert(fontOptions, { key = f.key, label = f.label })
    end

    local _, ny = W.CreateDropdown(c, L["opt_name_font"], fontOptions, db.nameFont, y, function(val)
        db.nameFont = val
        TGF_PartyFrames.Refresh()
    end); y = ny

    local _, ny = W.CreateSlider(c, L["opt_font_size"] .. " (Name)", 8, 18, 1, db.nameFontSize, y, function(val)
        db.nameFontSize = val
        TGF_PartyFrames.Refresh()
    end); y = ny

    -- =====================================
    -- DISPEL
    -- =====================================
    local _, ny = W.CreateSeparator(c, y); y = ny
    local _, ny = W.CreateSectionHeader(c, L["section_party_dispel"], y); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_show_dispel"], db.showDispel, y, function(val)
        db.showDispel = val
    end); y = ny

    local _, ny = W.CreateSlider(c, L["opt_dispel_border_size"], 1, 5, 1, db.dispelBorderSize, y, function(val)
        db.dispelBorderSize = val
    end); y = ny

    -- =====================================
    -- HOTS
    -- =====================================
    local _, ny = W.CreateSeparator(c, y); y = ny
    local _, ny = W.CreateSectionHeader(c, L["section_party_hots"], y); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_show_hots"], db.showHots, y, function(val)
        db.showHots = val
    end); y = ny

    local _, ny = W.CreateSlider(c, L["opt_hot_icon_size"], 10, 32, 1, db.hotIconSize, y, function(val)
        db.hotIconSize = val
        TGF_PartyFrames.Refresh()
    end); y = ny

    local _, ny = W.CreateSlider(c, L["opt_hot_font_size"], 6, 16, 1, db.hotFontSize, y, function(val)
        db.hotFontSize = val
        TGF_PartyFrames.Refresh()
    end); y = ny

    local _, ny = W.CreateSlider(c, L["opt_max_hots"], 1, 8, 1, db.maxHots, y, function(val)
        db.maxHots = val
    end); y = ny

    y = y - 20
    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

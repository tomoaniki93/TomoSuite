-- =====================================
-- Config/Panels/Raid.lua — Raid Frames Settings
-- =====================================

local W = TGF_Widgets
local L = TGF_L
local T = W.Theme

function TGF_ConfigPanel_Raid(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local db = TomoGroupFrameDB.raid

    -- =====================================
    -- QUICK ACTIONS
    -- =====================================
    local testSizeOptions = {
        { key = "10", label = "10 Players" },
        { key = "15", label = "15 Players" },
        { key = "20", label = "20 Players" },
        { key = "25", label = "25 Players" },
        { key = "30", label = "30 Players" },
        { key = "40", label = "40 Players" },
    }
    local _, ny = W.CreateDropdown(c, "Test Raid Size", testSizeOptions, tostring(TGF_RaidFrames.GetTestSize()), y, function(val)
        TGF_RaidFrames.SetTestSize(tonumber(val))
    end); y = ny

    local _, ny = W.CreateButton(c, "Test Mode (Raid)", 180, y, function()
        TGF_RaidFrames.ToggleTestMode()
    end); y = ny

    local _, ny = W.CreateButton(c, "Unlock / Lock", 160, y, function()
        TGF_RaidFrames.ToggleLock()
    end); y = ny

    local _, ny = W.CreateSeparator(c, y); y = ny

    -- GENERAL
    local _, ny = W.CreateSectionHeader(c, L["section_raid_general"], y); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_raid_enabled"], db.enabled, y, function(val)
        db.enabled = val
    end); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_use_class_color"], db.useClassColor, y, function(val)
        db.useClassColor = val
        TGF_RaidFrames.Refresh()
    end); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_show_role_icon"], db.showRoleIcon, y, function(val)
        db.showRoleIcon = val
    end); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_sort_by_role"], db.sortByRole, y, function(val)
        db.sortByRole = val
    end); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_show_group_labels"], db.showGroupLabels, y, function(val)
        db.showGroupLabels = val
        TGF_RaidFrames.Refresh()
    end); y = ny

    -- LAYOUT
    local _, ny = W.CreateSeparator(c, y); y = ny
    local _, ny = W.CreateSectionHeader(c, L["section_raid_layout"], y); y = ny

    local _, ny = W.CreateSlider(c, L["opt_raid_width"], 50, 200, 1, db.width, y, function(val)
        db.width = val
        TGF_RaidFrames.Refresh()
    end); y = ny

    local _, ny = W.CreateSlider(c, L["opt_raid_height"], 20, 60, 1, db.height, y, function(val)
        db.height = val
        TGF_RaidFrames.Refresh()
    end); y = ny

    local _, ny = W.CreateSlider(c, L["opt_spacing"], 0, 10, 1, db.spacing, y, function(val)
        db.spacing = val
        TGF_RaidFrames.Refresh()
    end); y = ny

    local _, ny = W.CreateSlider(c, L["opt_groups_per_row"], 1, 8, 1, db.groupsPerRow, y, function(val)
        db.groupsPerRow = val
        TGF_RaidFrames.Refresh()
    end); y = ny

    -- BAR TEXTURE
    local _, ny = W.CreateSeparator(c, y); y = ny
    local _, ny = W.CreateSectionHeader(c, L["section_party_bars"], y); y = ny

    local barOptions = {}
    for _, bt in ipairs(TGF_BarTextures) do
        table.insert(barOptions, { key = bt.key, label = bt.label })
    end
    local _, ny = W.CreateDropdown(c, L["opt_bar_texture"], barOptions, db.barTexture, y, function(val)
        db.barTexture = val
        TGF_RaidFrames.Refresh()
    end); y = ny

    local _, ny = W.CreateSlider(c, L["opt_range_alpha"], 0.1, 1.0, 0.05, db.rangeAlpha, y, function(val)
        db.rangeAlpha = val
    end); y = ny

    -- TEXT
    local _, ny = W.CreateSeparator(c, y); y = ny
    local _, ny = W.CreateSectionHeader(c, L["section_party_text"], y); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_show_name"], db.showName, y, function(val)
        db.showName = val
        TGF_RaidFrames.Refresh()
    end); y = ny

    local _, ny = W.CreateSlider(c, L["opt_name_truncate"], 4, 16, 1, db.nameTruncateLen, y, function(val)
        db.nameTruncateLen = val
    end); y = ny

    local fontOptions = {}
    for _, f in ipairs(TGF_Fonts) do
        table.insert(fontOptions, { key = f.key, label = f.label })
    end

    local _, ny = W.CreateDropdown(c, L["opt_name_font"], fontOptions, db.nameFont, y, function(val)
        db.nameFont = val
        TGF_RaidFrames.Refresh()
    end); y = ny

    local _, ny = W.CreateSlider(c, L["opt_font_size"] .. " (Name)", 7, 14, 1, db.nameFontSize, y, function(val)
        db.nameFontSize = val
        TGF_RaidFrames.Refresh()
    end); y = ny

    -- DISPEL
    local _, ny = W.CreateSeparator(c, y); y = ny
    local _, ny = W.CreateSectionHeader(c, L["section_party_dispel"], y); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_show_dispel"], db.showDispel, y, function(val)
        db.showDispel = val
    end); y = ny

    local _, ny = W.CreateSlider(c, L["opt_dispel_border_size"], 1, 5, 1, db.dispelBorderSize, y, function(val)
        db.dispelBorderSize = val
    end); y = ny

    -- HOTS
    local _, ny = W.CreateSeparator(c, y); y = ny
    local _, ny = W.CreateSectionHeader(c, L["section_party_hots"], y); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_show_hots"], db.showHots, y, function(val)
        db.showHots = val
    end); y = ny

    local _, ny = W.CreateSlider(c, L["opt_hot_icon_size"], 8, 24, 1, db.hotIconSize, y, function(val)
        db.hotIconSize = val
        TGF_RaidFrames.Refresh()
    end); y = ny

    local _, ny = W.CreateSlider(c, L["opt_hot_font_size"], 6, 14, 1, db.hotFontSize, y, function(val)
        db.hotFontSize = val
        TGF_RaidFrames.Refresh()
    end); y = ny

    local _, ny = W.CreateSlider(c, L["opt_max_hots"], 1, 6, 1, db.maxHots, y, function(val)
        db.maxHots = val
    end); y = ny

    y = y - 20
    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

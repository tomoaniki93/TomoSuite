-- =====================================
-- Core/Database.lua — Defaults & DB Management
-- =====================================

local ADDON_PATH = "Interface\\AddOns\\TomoGroupFrame\\"
local FONT       = ADDON_PATH .. "Assets\\Fonts\\Poppins-Medium.ttf"
local BAR_PATH   = ADDON_PATH .. "Assets\\Textures\\Bars\\"

-- =====================================
-- BAR TEXTURES REGISTRY
-- =====================================

TGF_BarTextures = {
    { key = "Flat",        label = "Flat",        path = BAR_PATH .. "Flat.tga" },
    { key = "Gradient",    label = "Gradient",    path = BAR_PATH .. "Gradient.tga" },
    { key = "Glossy",      label = "Glossy",      path = BAR_PATH .. "Glossy.tga" },
    { key = "Striped",     label = "Striped",     path = BAR_PATH .. "Striped.tga" },
    { key = "Smooth",      label = "Smooth",      path = BAR_PATH .. "Smooth.tga" },
    { key = "Minimalist",  label = "Minimalist",  path = BAR_PATH .. "Minimalist.tga" },
}

-- =====================================
-- FONTS REGISTRY
-- =====================================

TGF_Fonts = {
    { key = "Poppins",     label = "Poppins",              path = ADDON_PATH .. "Assets\\Fonts\\Poppins-Medium.ttf" },
    { key = "PoppinsBold", label = "Poppins Bold",         path = ADDON_PATH .. "Assets\\Fonts\\Poppins-SemiBold.ttf" },
    { key = "Expressway",  label = "Expressway",           path = ADDON_PATH .. "Assets\\Fonts\\Expressway.TTF" },
    { key = "Accidental",  label = "Accidental Presidency", path = ADDON_PATH .. "Assets\\Fonts\\accidental_pres.ttf" },
}

function TGF_GetBarTexturePath(key)
    for _, t in ipairs(TGF_BarTextures) do
        if t.key == key then return t.path end
    end
    return TGF_BarTextures[1].path
end

function TGF_GetFontPath(key)
    for _, f in ipairs(TGF_Fonts) do
        if f.key == key then return f.path end
    end
    return TGF_Fonts[1].path
end

-- =====================================
-- DEFAULTS
-- =====================================

TGF_Defaults = {
    -- =====================
    -- PARTY FRAMES
    -- =====================
    party = {
        enabled         = true,
        layout          = "party",  -- "party" or "raid" (controls element positioning)
        width           = 160,
        height          = 44,
        spacing         = 2,
        growDirection    = "DOWN",      -- DOWN, UP, RIGHT, LEFT
        barTexture      = "Gradient",
        useClassColor   = true,
        showName        = true,
        nameTruncateLen = 12,
        showHpPercent   = false,
        nameFont        = "Poppins",
        nameFontSize    = 11,
        hpFont          = "Expressway",
        hpFontSize      = 12,
        showPowerBar    = true,
        powerHeight     = 4,
        showRoleIcon    = true,
        showRaidIcon    = true,
        rangeAlpha      = 0.45,
        bgAlpha         = 0.85,
        borderSize      = 1,

        -- Dispel highlight
        showDispel      = true,
        dispelBorderSize = 2,
        dispelColors    = {
            Magic   = { r = 0.20, g = 0.60, b = 1.00 },
            Curse   = { r = 0.60, g = 0.00, b = 1.00 },
            Disease = { r = 0.60, g = 0.40, b = 0.00 },
            Poison  = { r = 0.00, g = 0.60, b = 0.00 },
        },

        -- HoT tracking
        showHots        = true,
        hotIconSize     = 24,
        hotFontSize     = 10,
        maxHots         = 4,

        -- Position (draggable)
        position = {
            point         = "LEFT",
            relativePoint = "LEFT",
            x             = 20,
            y             = 0,
        },
    },

    -- =====================
    -- RAID FRAMES
    -- =====================
    raid = {
        enabled         = true,
        width           = 80,
        height          = 40,
        spacing         = 2,
        groupSpacing    = 8,
        growDirection    = "DOWN",
        barTexture      = "Gradient",
        useClassColor   = true,
        showName        = true,
        nameTruncateLen = 8,
        showHpPercent   = true,
        nameFont        = "Poppins",
        nameFontSize    = 9,
        hpFont          = "Expressway",
        hpFontSize      = 10,
        showPowerBar    = false,
        powerHeight     = 3,
        showRoleIcon    = true,
        showRaidIcon    = true,
        rangeAlpha      = 0.45,
        bgAlpha         = 0.85,
        borderSize      = 1,
        groupsPerRow    = 5,
        sortByRole      = true,
        showGroupLabels = true,
        compactMode     = false,

        -- Dispel highlight
        showDispel      = true,
        dispelBorderSize = 2,
        dispelColors    = {
            Magic   = { r = 0.20, g = 0.60, b = 1.00 },
            Curse   = { r = 0.60, g = 0.00, b = 1.00 },
            Disease = { r = 0.60, g = 0.40, b = 0.00 },
            Poison  = { r = 0.00, g = 0.60, b = 0.00 },
        },

        -- HoT tracking
        showHots        = true,
        hotIconSize     = 14,
        hotFontSize     = 8,
        maxHots         = 3,

        -- Position per raid size (each size can be placed independently)
        positions = {
            ["10"] = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 20, y = -40 },
            ["15"] = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 20, y = -40 },
            ["20"] = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 20, y = -40 },
            ["25"] = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 20, y = -40 },
            ["30"] = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 20, y = -40 },
            ["40"] = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 20, y = -40 },
        },

        -- Legacy single position (fallback)
        position = {
            point         = "TOPLEFT",
            relativePoint = "TOPLEFT",
            x             = 20,
            y             = -40,
        },
    },
}

-- =====================================
-- DB FUNCTIONS
-- =====================================

function TGF_InitDatabase()
    if not TomoGroupFrameDB then
        TomoGroupFrameDB = {}
    end
    TGF_MergeTables(TomoGroupFrameDB, TGF_Defaults)
end

function TGF_ResetDatabase()
    TomoGroupFrameDB = CopyTable(TGF_Defaults)
    print("|cffCC44FFTomo|r|cffFFFFFFGroupFrame|r " .. TGF_L["msg_db_reset"])
end

function TGF_ResetModule(moduleName)
    if TGF_Defaults[moduleName] then
        TomoGroupFrameDB[moduleName] = CopyTable(TGF_Defaults[moduleName])
        print("|cffCC44FFTomo|r|cffFFFFFFGroupFrame|r " .. string.format(TGF_L["msg_module_reset"], moduleName))
    end
end

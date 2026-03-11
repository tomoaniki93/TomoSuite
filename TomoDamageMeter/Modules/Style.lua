local ADDON_NAME, ns = ...

----------------------------------------------------------------------
-- Style: Colors, Textures, Layout Constants
----------------------------------------------------------------------

ns.FLAT = "Interface\\BUTTONS\\WHITE8X8"

local ADDON_PATH = "Interface\\AddOns\\TomoDamageMeter\\"
local ADDON_TEX  = ADDON_PATH .. "Assets\\Textures\\"

-- Icon textures (32x32 white TGA, colorable via SetVertexColor)
ns.TEX_GEAR      = ADDON_TEX .. "gear"
ns.TEX_CLOSE     = ADDON_TEX .. "close"
ns.TEX_RESET     = ADDON_TEX .. "reset"
ns.TEX_REPORT    = ADDON_TEX .. "report"
ns.TEX_LOCK      = ADDON_TEX .. "lock"
ns.TEX_LOCK_OPEN = ADDON_TEX .. "lock-open"
ns.TEX_CHEVRON   = ADDON_TEX .. "chevron"

-- Tomo palette (dark, clean)
ns.BG              = { 0.04, 0.04, 0.05, 0.70 }
ns.HEADER_BG       = { 0.07, 0.07, 0.09, 0.75 }
ns.BORDER_COLOR     = { 0.0, 0.0, 0.0, 0.7 }
ns.DEFAULT_ACCENT   = { 0.82, 0.71, 0.33 }       -- gold
ns.ACCENT           = { 0.82, 0.71, 0.33, 0.8 }

-- Text
ns.TEXT_PRIMARY     = { 1.0, 1.0, 1.0 }
ns.TEXT_SECONDARY   = { 0.55, 0.55, 0.58 }
ns.TEXT_LABEL       = { 0.75, 0.75, 0.78 }
ns.TEXT_MUTED       = { 0.40, 0.40, 0.43 }

-- Interactive
ns.HOVER_BG         = { 0.30, 0.30, 0.33, 0.40 }
ns.HEADER_HOVER_BG  = { 0.30, 0.30, 0.33, 0.40 }
ns.BAR_ALPHA        = 0.4
ns.ICON_ALPHA       = 0.7

-- Category colors (header label tint)
ns.CAT_DAMAGE       = { 1.00, 0.40, 0.35 }
ns.CAT_HEALING      = { 0.30, 0.90, 0.40 }
ns.CAT_ACTIONS      = { 0.40, 0.70, 1.00 }

-- Scrollbar
ns.SCROLLBAR_TRACK  = { 0.10, 0.10, 0.12, 0.4 }
ns.SCROLLBAR_THUMB  = { 0.35, 0.35, 0.40, 0.7 }

-- Layout
ns.HEADER_HEIGHT    = 20
ns.SUBHEADER_HEIGHT = 16
ns.HEADER_TOTAL     = 20
ns.HEADER_COMBINED  = 20 + 16 + 1  -- header + subheader + separator
ns.HEADER_PAD_TOP   = 0
ns.HEADER_PAD_Y     = 0
ns.HEADER_PAD_X     = 6
ns.TEXT_PAD          = 6
ns.BAR_HEIGHT       = 21
ns.BAR_SPACING      = 1
ns.BORDER_WIDTH     = 1
ns.CONTENT_INSET    = 3
ns.SCROLLBAR_WIDTH  = 6
ns.STRIP_WIDTH      = 18

-- Font defaults
ns.FONT_SIZE        = 12
ns.BAR_FONT_SIZE    = 10

-- Default font (uses game built-in; can be overridden in DB)
ns.FONT = "Fonts\\FRIZQT__.TTF"
ns.HEADER_FONT = ns.FONT

----------------------------------------------------------------------
-- Font accessor (DB override)
----------------------------------------------------------------------

function ns.GetFont()
    return ns.db and ns.db.fontPath or ns.FONT
end

function ns.GetFontSize()
    return ns.db and ns.db.fontSize or ns.BAR_FONT_SIZE
end

function ns.GetBarHeight()
    return ns.db and ns.db.barHeight or ns.BAR_HEIGHT
end

function ns.GetFontNudge()
    return ns.db and ns.db.fontNudge or 0
end
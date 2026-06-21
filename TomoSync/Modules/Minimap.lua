-- TomoSync | Modules/Minimap.lua
-- Bouton minicarte autonome (sans LibDBIcon) : deplacable autour de la
-- minicarte, position sauvegardee au compte. Clic gauche = fenetre,
-- clic droit = parametres. Look pourpre plat via masque circulaire.

local TS = TomoSync
local UI = TS.UI
local MM = {}
TS:RegisterModule("Minimap", MM)

local ADDON_ICON = "Interface\\Icons\\Spell_nzinsanity_desynchronized"
local CIRCLE_MASK = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"

local button

local function Atan2(y, x)
    if math.atan2 then return math.atan2(y, x) end
    return math.atan(y, x)
end

-- Place le bouton sur le bord de la minicarte selon l'angle sauvegarde.
local function UpdatePosition()
    if not button then return end
    local angle = math.rad(TS.account.minimap.angle or 215)
    local r = (Minimap:GetWidth() / 2)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
end

-- Suit le curseur pendant le glissement (recalcule l'angle).
local function OnDragUpdate()
    local mx, my = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    local px, py = GetCursorPosition()
    if not (mx and px) then return end
    px, py = px / scale, py / scale
    TS.account.minimap.angle = math.deg(Atan2(py - my, px - mx))
    UpdatePosition()
end

function MM:OnInitialize()
    if not (TS.account and TS.account.minimap) then return end
    if button then return end

    button = CreateFrame("Button", "TomoSyncMinimapButton", Minimap)
    button:SetSize(30, 30)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    -- Anneau pourpre (cercle plein masque en rond)
    local maskRing = button:CreateMaskTexture()
    maskRing:SetTexture(CIRCLE_MASK)
    maskRing:SetAllPoints(button)

    local ring = UI.Solid(button, "BACKGROUND")
    ring:SetAllPoints(button)
    local p = UI.PURPLE
    ring:SetVertexColor(p[1], p[2], p[3], 1)
    ring:AddMaskTexture(maskRing)

    -- Icone circulaire (plus petite -> laisse apparaitre un lisere pourpre)
    local maskIcon = button:CreateMaskTexture()
    maskIcon:SetTexture(CIRCLE_MASK)
    maskIcon:SetSize(24, 24)
    maskIcon:SetPoint("CENTER")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("CENTER")
    icon:SetTexture(ADDON_ICON)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:AddMaskTexture(maskIcon)

    -- Surbrillance au survol
    local hl = UI.Solid(button, "HIGHLIGHT")
    hl:SetAllPoints(button)
    hl:SetVertexColor(1, 1, 1, 0.18)
    hl:AddMaskTexture(maskRing)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            if TomoSyncConfig and TomoSyncConfig.Toggle then TomoSyncConfig:Toggle() end
        else
            local br = TS.modules["Browser"]
            if br and br.Toggle then br:Toggle() end
        end
    end)
    button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", OnDragUpdate) end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cFFCC44FFTomo|r|cFFFFFFFFSync|r")
        GameTooltip:AddLine(TS:L("MM_LEFT"), 0.8, 0.8, 0.8)
        GameTooltip:AddLine(TS:L("MM_RIGHT"), 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    UpdatePosition()
    MM:UpdateShown()
end

-- Applique l'etat affiche/masque
function MM:UpdateShown()
    if not button then return end
    if TS.account.minimap.hide then button:Hide() else button:Show() end
end

function MM:SetHidden(hide)
    if not (TS.account and TS.account.minimap) then return end
    TS.account.minimap.hide = hide and true or false
    MM:UpdateShown()
end

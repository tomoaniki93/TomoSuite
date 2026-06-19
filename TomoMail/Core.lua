-- TomoMail | Core.lua
-- Point d'entrée principal de l'addon

local ADDON_NAME = "TomoMail"
local L          = TomoMailLocale

-- ============================================================
--  Namespace global
-- ============================================================
TomoMail = {
    version = "2.1.9",
    modules = {},
    db      = nil,
}

local TM = TomoMail

-- ============================================================
--  Utilitaires publics
-- ============================================================

function TM:RegisterModule(name, obj)
    self.modules[name] = obj
    obj.name = name
end

function TM:ClassColor(class)
    if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        return string.format("|cFF%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
    end
    return "|cFFFFFFFF"
end

function TM:ClassColorRGB(class)
    if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        return c.r, c.g, c.b
    end
    return 1, 1, 1
end

function TM:L(key)
    return (L and L[key]) or key
end

function TM:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFCC44FFTomoMail|r " .. (msg or ""))
end

function TM:SetRecipient(name)
    if SendMailNameEditBox then
        SendMailNameEditBox:SetText(name)
        SendMailNameEditBox:SetFocus()
        self:AddRecent(name)
    end
end

-- ============================================================
--  Gestion de la base de données
-- ============================================================

local function MergeDefaults(target, defaults)
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            if type(target[k]) ~= "table" then
                target[k] = {}
            end
            MergeDefaults(target[k], v)
        elseif target[k] == nil then
            target[k] = v
        end
    end
end

local function InitDB()
    if type(TomoMailDB) ~= "table" then
        TomoMailDB = {}
    end
    if type(TomoMailDB.global) ~= "table"  then TomoMailDB.global  = {} end
    if type(TomoMailDB.profiles) ~= "table" then TomoMailDB.profiles = {} end

    MergeDefaults(TomoMailDB.global, TomoMailDB_Defaults.global)

    local profileKey = UnitName("player") .. "-" .. GetRealmName()
    if type(TomoMailDB.profiles[profileKey]) ~= "table" then
        TomoMailDB.profiles[profileKey] = {}
    end
    MergeDefaults(TomoMailDB.profiles[profileKey], TomoMailDB_Defaults.profile)

    TM.db = {
        global  = TomoMailDB.global,
        profile = TomoMailDB.profiles[profileKey],
    }
end

-- ============================================================
--  Gestion des récents
-- ============================================================

function TM:AddRecent(name)
    if not name or name == "" then return end
    local realm   = GetRealmName()
    local faction = UnitFactionGroup("player") or "Neutral"
    local entry   = name .. "|" .. realm .. "|" .. faction

    local recent = self.db.profile.recent
    for i = #recent, 1, -1 do
        local n = strsplit("|", recent[i])
        if n == name then
            table.remove(recent, i)
        end
    end
    table.insert(recent, 1, entry)
    local max = self.db.profile.maxRecent or 10
    while #recent > max do
        table.remove(recent)
    end
end

-- ============================================================
--  Frame principale & événements
-- ============================================================

local frame = CreateFrame("Frame", "TomoMailFrame")

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("MAIL_SEND_SUCCESS")
frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == ADDON_NAME then
            InitDB()
            for _, mod in pairs(TM.modules) do
                if mod.OnInitialize then mod:OnInitialize() end
            end
            TM:Print("v" .. TM.version .. " chargé. Tapez |cFFCC44FF/tml|r pour les options.")
            frame:UnregisterEvent("ADDON_LOADED")
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        TM:RegisterCurrentChar()
        for _, mod in pairs(TM.modules) do
            if mod.OnEnteringWorld then mod:OnEnteringWorld() end
        end

    elseif event == "MAIL_SEND_SUCCESS" then
        local recipient = SendMailNameEditBox and SendMailNameEditBox:GetText() or ""
        if recipient ~= "" then
            TM:AddRecent(recipient)
        end
        for _, mod in pairs(TM.modules) do
            if mod.OnMailSent then mod:OnMailSent(recipient) end
        end

    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
        local paneType = ...
        if paneType == Enum.PlayerInteractionType.MailInfo then
            for _, mod in pairs(TM.modules) do
                if mod.OnMailShow then mod:OnMailShow() end
            end
        end

    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
        local paneType = ...
        if paneType == Enum.PlayerInteractionType.MailInfo then
            for _, mod in pairs(TM.modules) do
                if mod.OnMailHide then mod:OnMailHide() end
            end
        end
    end
end)

-- ============================================================
--  Enregistrement du personnage courant
-- ============================================================

function TM:RegisterCurrentChar()
    local realm   = GetRealmName()
    local faction = UnitFactionGroup("player")
    local player  = UnitName("player")
    local level   = UnitLevel("player")
    local _, class = UnitClass("player")
    if not realm or not faction or not player or not level or not class then return end

    local entry = table.concat({ player, realm, faction, level, class }, "|")
    local alts  = self.db.global.alts

    for i = #alts, 1, -1 do
        local p, r, f = strsplit("|", alts[i])
        if p == player and r == realm and f == faction then
            table.remove(alts, i)
        end
    end
    table.insert(alts, entry)
end

-- ============================================================
--  Commande slash
-- ============================================================

SLASH_TOMOMAIL1 = "/tml"
SLASH_TOMOMAIL2 = "/tomomail"

SlashCmdList["TOMOMAIL"] = function(msg)
    if TomoMailConfig and TomoMailConfig.Toggle then
        TomoMailConfig:Toggle()
    end
end

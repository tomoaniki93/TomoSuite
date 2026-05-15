-- TomoMail | Modules/QuickSend.lua
-- Redesigned autocomplete with match highlighting and source tags

local TM = TomoMail
local UI = TM.UI
local QuickSend = {}
TM:RegisterModule("QuickSend", QuickSend)

-- ============================================================
--  Local state
-- ============================================================

local cachedNames   = nil
local lastCacheTime = 0
local CACHE_TTL     = 5

-- ============================================================
--  Build name cache with source info
-- ============================================================

local function BuildNameCache()
    cachedNames = {}
    local realm   = GetRealmName()
    local faction = UnitFactionGroup("player")
    local player  = UnitName("player")

    -- Alts
    local alts = TM.db.global.alts
    for _, entry in ipairs(alts) do
        local p, r, f, lvl, class = strsplit("|", entry)
        if r == realm and f == faction and p ~= player then
            cachedNames[p:lower()] = { name = p, source = "alt", class = class }
        end
    end

    -- Guild
    if IsInGuild() then
        local numMembers = GetNumGuildMembers()
        for i = 1, numMembers do
            local name, _, _, _, _, _, _, _, _, _, class = GetGuildRosterInfo(i)
            if name then
                local shortName = strsplit("-", name)
                if shortName ~= player then
                    local key = shortName:lower()
                    if not cachedNames[key] then
                        cachedNames[key] = { name = shortName, source = "guild", class = class }
                    end
                end
            end
        end
    end

    -- Recents (add only if not already present)
    local recent = TM.db.profile.recent
    for _, entry in ipairs(recent) do
        local rName = strsplit("|", entry)
        if rName and rName ~= "" then
            local key = rName:lower()
            if not cachedNames[key] then
                cachedNames[key] = { name = rName, source = "recent", class = nil }
            end
        end
    end

    lastCacheTime = GetTime()
end

local function GetNameCache()
    if not cachedNames or (GetTime() - lastCacheTime) > CACHE_TTL then
        BuildNameCache()
    end
    return cachedNames
end

-- ============================================================
--  Module API
-- ============================================================

function QuickSend:OnInitialize() end

function QuickSend:OnMailShow()
    if TM.db.profile.useAutocomplete then
        self:EnableAutocomplete()
    end
    cachedNames = nil
end

function QuickSend:OnMailHide()
    self:DisableAutocomplete()
    if self.suggestionFrame then
        self.suggestionFrame:Hide()
    end
end

function QuickSend:EnableAutocomplete()
    if self._hooked then return end
    self._hooked = true
    self._autocompleteEnabled = true

    SendMailNameEditBox:HookScript("OnTextChanged", function(editbox, userInput)
        if not userInput then return end
        QuickSend:OnRecipientChanged(editbox)
    end)

    SendMailNameEditBox:HookScript("OnEditFocusGained", function(editbox)
        QuickSend:OnRecipientChanged(editbox)
    end)

    SendMailNameEditBox:HookScript("OnEditFocusLost", function()
        -- Delay hide so click on suggestion can fire
        C_Timer.After(0.15, function()
            if QuickSend.suggestionFrame then
                QuickSend.suggestionFrame:Hide()
            end
        end)
    end)
end

function QuickSend:DisableAutocomplete()
    self._autocompleteEnabled = false
end

-- ============================================================
--  Suggestion frame
-- ============================================================

local MAX_SUGGESTIONS = 8

local function GetOrCreateSuggestionFrame()
    if QuickSend.suggestionFrame then return QuickSend.suggestionFrame end

    local sf = CreateFrame("Frame", "TomoMailSuggestions", UIParent, "BackdropTemplate")
    sf:SetBackdrop(UI.BACKDROP)
    sf:SetBackdropColor(unpack(UI.COLORS.bg))
    sf:SetBackdropBorderColor(unpack(UI.COLORS.border))
    sf:SetFrameStrata("TOOLTIP")
    sf:EnableMouse(true)
    sf:Hide()

    sf.buttons = {}
    for i = 1, MAX_SUGGESTIONS do
        local btn = CreateFrame("Button", nil, sf)
        btn:SetHeight(22)

        UI:AddRowHighlight(btn)

        -- Name text (will contain colored match)
        btn.nameText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.nameText:SetPoint("LEFT", btn, "LEFT", 10, 0)
        btn.nameText:SetJustifyH("LEFT")

        -- Source tag
        btn.tag = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.tag:SetPoint("RIGHT", btn, "RIGHT", -10, 0)

        btn:SetScript("OnClick", function(self)
            local name = self._suggestName
            if name then
                SendMailNameEditBox:SetText(name)
                SendMailNameEditBox:SetCursorPosition(#name)
                sf:Hide()
            end
        end)
        btn:Hide()

        sf.buttons[i] = btn
    end

    QuickSend.suggestionFrame = sf
    return sf
end

-- ============================================================
--  Source tag colors
-- ============================================================

local SOURCE_LABELS = {
    alt    = { text = "alt",    color = "|cFF9966FF" },
    guild  = { text = "guilde", color = "|cFF44AAFF" },
    recent = { text = "récent", color = "|cFFAAAAAA" },
}

-- ============================================================
--  Populate suggestions
-- ============================================================

function QuickSend:OnRecipientChanged(editbox)
    if not TM.db.profile.useAutocomplete then return end
    if self._autocompleteEnabled == false then return end

    local text = editbox:GetText()
    if not text or #text < 2 then
        local sf = GetOrCreateSuggestionFrame()
        sf:Hide()
        return
    end

    local lower   = text:lower()
    local cache   = GetNameCache()
    local matches = {}

    for k, info in pairs(cache) do
        if k:sub(1, #lower) == lower and k ~= lower then
            table.insert(matches, info)
            if #matches >= MAX_SUGGESTIONS then break end
        end
    end
    table.sort(matches, function(a, b) return a.name < b.name end)

    local sf = GetOrCreateSuggestionFrame()

    if #matches == 0 then
        sf:Hide()
        return
    end

    -- Position under the editbox
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT", editbox, "BOTTOMLEFT", -2, -2)
    sf:SetWidth(editbox:GetWidth() + 40)
    sf:SetHeight(#matches * 22 + 4)

    for i, btn in ipairs(sf.buttons) do
        local info = matches[i]
        if info then
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", sf, "TOPLEFT", 1, -2 - (i - 1) * 22)
            btn:SetPoint("TOPRIGHT", sf, "TOPRIGHT", -1, -2 - (i - 1) * 22)

            -- Build highlighted name: matched part in purple, rest in normal
            local matchLen = #text
            local matchPart = info.name:sub(1, matchLen)
            local restPart  = info.name:sub(matchLen + 1)

            local r, g, b = TM:ClassColorRGB(info.class)
            local classHex = string.format("|cFF%02x%02x%02x", r * 255, g * 255, b * 255)

            btn.nameText:SetText("|cFFCC44FF" .. matchPart .. "|r" .. classHex .. restPart .. "|r")

            -- Source tag
            local src = SOURCE_LABELS[info.source] or SOURCE_LABELS.recent
            btn.tag:SetText(src.color .. src.text .. "|r")

            btn._suggestName = info.name
            btn:Show()
        else
            btn._suggestName = nil
            btn:Hide()
        end
    end

    sf:Show()
end

-- Close on send
hooksecurefunc("SendMailFrame_SendMail", function()
    if QuickSend.suggestionFrame then
        QuickSend.suggestionFrame:Hide()
    end
end)

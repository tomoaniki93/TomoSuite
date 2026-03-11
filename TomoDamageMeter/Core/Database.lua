local ADDON_NAME, ns = ...

----------------------------------------------------------------------
-- SavedVariables & Events
----------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        -- Hide Blizzard's built-in damage meter UI (data collection stays active)
        C_CVar.SetCVar("damageMeterEnabled", "0")

        TomoDamageMeterDB = TomoDamageMeterDB or {}
        ns.db = TomoDamageMeterDB

        -- Global defaults
        if ns.db.stripRealm == nil then ns.db.stripRealm = true end
        ns.db.fontSize   = ns.db.fontSize   or ns.BAR_FONT_SIZE
        ns.db.barHeight  = ns.db.barHeight  or ns.BAR_HEIGHT
        ns.db.fontNudge  = ns.db.fontNudge  or 0
        ns.db.fontPath   = ns.db.fontPath   or ns.FONT
        ns.db.bgAlpha    = ns.db.bgAlpha    or ns.BG[4]
        ns.db.oocAlpha   = ns.db.oocAlpha   or 1
        ns.db.accentColor = ns.db.accentColor or { ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3] }
        ns.db.reportChannel = ns.db.reportChannel or "SAY"
        ns.db.reportLines   = ns.db.reportLines   or 5

        ns.ApplyAccentColor()

        -- Column config
        if not ns.db.columns then
            ns.db.columns = CopyTable(ns.DEFAULT_COLUMNS)
        end
        for _, col in ipairs(ns.db.columns) do
            if not col.fmt then
                local defaults = { rate = "full", total = "full", pct = "int" }
                col.fmt = defaults[col.key] or "full"
            end
        end

        -- Window config (single window for now)
        if not ns.db.window then
            ns.db.window = {}
        end
        local cfg = ns.db.window
        for k, v in pairs(ns.DEFAULTS) do
            if cfg[k] == nil then cfg[k] = type(v) == "table" and CopyTable(v) or v end
        end

        -- Create the main window
        local win = ns.CreateMeterWindow(cfg)
        table.insert(ns.windows, win)
        win.Refresh()
        C_Timer.After(0, win.UpdateHeader)

    elseif event == "PLAYER_LOGOUT" then
        if ns.db and ns.windows[1] then
            ns.windows[1].SavePosition()
        end
    end
end)

----------------------------------------------------------------------
-- Combat Events
----------------------------------------------------------------------

local dmEventFrame = CreateFrame("Frame")
dmEventFrame:RegisterEvent("DAMAGE_METER_COMBAT_SESSION_UPDATED")
dmEventFrame:RegisterEvent("DAMAGE_METER_CURRENT_SESSION_UPDATED")
dmEventFrame:RegisterEvent("DAMAGE_METER_RESET")
dmEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
dmEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

local timerTicker = nil

dmEventFrame:SetScript("OnEvent", function(self, event)
    if event == "DAMAGE_METER_RESET" then
        for _, win in ipairs(ns.windows) do
            win.BumpGeneration()
            win.Refresh()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        ns.inCombat = true
        for _, win in ipairs(ns.windows) do
            win.SetCombatAlpha(true)
        end
        if not timerTicker then
            timerTicker = C_Timer.NewTicker(1, function()
                for _, win in ipairs(ns.windows) do win.UpdateTimer() end
            end)
        end
        for _, win in ipairs(ns.windows) do win.UpdateTimer() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        ns.inCombat = false
        for _, win in ipairs(ns.windows) do
            win.SetCombatAlpha(false)
        end
        if timerTicker then timerTicker:Cancel(); timerTicker = nil end
        for _, win in ipairs(ns.windows) do win.UpdateTimer() end
        -- Re-render: names are no longer secret
        for _, win in ipairs(ns.windows) do win.Refresh() end
    else
        for _, win in ipairs(ns.windows) do win.Refresh() end
    end
end)

----------------------------------------------------------------------
-- Slash Commands
----------------------------------------------------------------------

SLASH_TDM1 = "/tdm"
SLASH_TDM2 = "/tomodm"
SlashCmdList["TDM"] = function(msg)
    local L = ns.L
    if msg == "reset" then
        C_DamageMeter.ResetAllCombatSessions()
        print(L["ADDON_PREFIX"] .. L["CMD_RESET"])
    elseif msg == "lock" then
        for _, win in ipairs(ns.windows) do
            win.cfg.locked = not win.cfg.locked
        end
        local locked = ns.windows[1] and ns.windows[1].cfg.locked
        print(L["ADDON_PREFIX"] .. (locked and L["CMD_LOCKED"] or L["CMD_UNLOCKED"]))
    elseif msg == "toggle" then
        for _, win in ipairs(ns.windows) do
            win.frame:SetShown(not win.frame:IsShown())
        end
    elseif msg == "help" then
        print(L["ADDON_PREFIX"] .. L["CMD_HELP_HEADER"])
        print(L["CMD_HELP_TOGGLE"])
        print(L["CMD_HELP_TOGGLE_VIS"])
        print(L["CMD_HELP_RESET"])
        print(L["CMD_HELP_LOCK"])
        print(L["CMD_HELP_HELP"])
    else
        if ns.ToggleSettings then
            ns.ToggleSettings()
        end
    end
end
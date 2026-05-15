-- TomoMail | English Locale (default fallback)
TomoMailLocale = TomoMailLocale or {}

local defaults = {
    ADDON_NAME          = "TomoMail",
    CONTACTS            = "Contacts",
    MY_ALTS             = "My Chars",
    GUILD_MEMBERS       = "Guild",
    RECENT              = "Recent",
    NO_ALTS             = "No other characters registered yet",
    NO_GUILD            = "You are not in a guild",
    NO_GUILD_MEMBERS    = "No members available",
    NO_RECENT           = "No recent recipients",
    NO_RESULTS          = "No results",
    ALL_ALTS            = "Send to all alts",
    ALL_ALTS_CONFIRM    = "Send this mail to all your alts?",
    SEND_TO             = "Send to %s",
    SETTINGS            = "Settings",
    CLOSE               = "Close",

    -- Config sections
    CFG_SECTION_DISPLAY  = "DISPLAY",
    CFG_SECTION_BEHAVIOR = "BEHAVIOR",

    CFG_TITLE           = "TomoMail — Settings",
    CFG_SHOW_ALTS       = "My characters",
    CFG_SHOW_ALTS_TT    = "Show your other characters in the dropdown menu.",
    CFG_SHOW_ALTS_SUB   = "Same server / faction alts",
    CFG_SHOW_GUILD      = "Guild members",
    CFG_SHOW_GUILD_TT   = "Show your guild members in the dropdown menu.",
    CFG_SHOW_GUILD_SUB  = "A-Z directory with status",
    CFG_SHOW_RECENT     = "Recent recipients",
    CFG_SHOW_RECENT_TT  = "Show the last 10 recipients in the dropdown menu.",
    CFG_MAX_RECENT      = "Recent to keep",
    CFG_MAX_RECENT_TT   = "Maximum number of recent recipients to remember.",
    CFG_GUILD_ONLINE    = "Online only",
    CFG_GUILD_ONLINE_TT = "Only show currently online guild members.",
    CFG_AUTOCOMPLETE    = "Autocomplete",
    CFG_AUTOCOMPLETE_TT = "Enable name autocomplete in the recipient field.",
    CFG_AUTOCOMPLETE_SUB = "Suggestions in the To: field",
    CFG_SECTION_APPEARANCE = "APPEARANCE",
    CFG_SKIN_ENABLED    = "Dark theme",
    CFG_SKIN_ENABLED_SUB = "Reskin the mailbox UI",
    CFG_SKIN_RELOAD     = "Reload required (/reload).",
    CFG_MAIL_SCALE      = "Interface scale",
    CFG_CLEAR_RECENT    = "Recent",
    CFG_CLEAR_ALTS      = "Alts",
    CFG_RECENT_CLEARED  = "Recent history cleared.",
    CFG_ALTS_CLEARED    = "Alt list cleared.",

    MAIL_SENT           = "Mail sent to %s!",
    ALT_REGISTERED      = "Character registered: %s",
    QS_SUBJECT_EMPTY    = "Please enter a subject.",
    QS_BODY_EMPTY       = "Please enter a message body.",
    QS_SENDING          = "Sending to all alts... (%d/%d)",
    QS_DONE             = "Mail sent to %d character(s)!",
}

for k, v in pairs(defaults) do
    if TomoMailLocale[k] == nil then
        TomoMailLocale[k] = v
    end
end

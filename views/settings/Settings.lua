local _ = require("gettext")

local getAISettings = require("views/settings/SettingsAI")
local getRunnerSettings = require("views/settings/SettingsRunner")
local getSyncSettings = require("views/settings/SettingsSync")

function GetSettings(instance)
    return {
        {
            text = _("Preserve notes: Yes"),
            callback = function()
                Alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Match threshold: 90%"),
            callback = function()
                Alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("AI assisted matching: Disabled"),
            sub_item_table = getAISettings(instance),
            callback = function()
                Alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("External runner: Enabled"),
            sub_item_table = getRunnerSettings(instance),
            callback = function()
                Alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Sync settings: Disabled"),
            sub_item_table = getSyncSettings(instance),
            callback = function()
                Alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Clear cache"),
            callback = function()
                Alert("Not implemented yet.")
                return true
            end,
        },
    }
end

return GetSettings
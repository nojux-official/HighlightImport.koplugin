local _ = require("gettext")

local getAISettings = require("views/settings/SettingsAI")
-- local getRunnerSettings = require("views/settings/SettingsRunner")
-- local getSyncSettings = require("views/settings/SettingsSync")

function getSettings(instance)
    return {
        {
            text = _("Preserve notes: Yes"),
            callback = function()
                alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Match threshold: 90%"),
            callback = function()
                alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("AI assisted matching: Disabled"),
            sub_item_table = getAISettings(instance),
            callback = function()
                alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("External runner: Enabled"),
            callback = function()
                alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Sync settings: Disabled"),
            callback = function()
                alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Clear cache"),
            callback = function()
                alert("Not implemented yet.")
                return true
            end,
        },
    }
end

return getSettings
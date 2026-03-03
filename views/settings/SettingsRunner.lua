local _ = require("gettext")

function GetRunnerSettings(instance)
    return {
        {
            text = _("Enabled: Yes"),
            callback = function()
                Alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Address"),
            callback = function()
                Alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Token"),
            callback = function()
                Alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Max retries: 3"),
            callback = function()
                Alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Test connection"),
            callback = function()
                Alert("Not implemented yet.")
                return true
            end,
        },
    }
end

return GetRunnerSettings
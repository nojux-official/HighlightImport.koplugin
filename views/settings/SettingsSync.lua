local _ = require("gettext")

function GetRunnerSettings(instance)
    return {
        {
            text = _("Enabled: No"),
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
            text = _("Password"),
            callback = function()
                Alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Ping every: 300 seconds"),
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
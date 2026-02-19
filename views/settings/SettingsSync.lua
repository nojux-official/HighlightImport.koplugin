local _ = require("gettext")

function getRunnerSettings(instance)
    return {
        {
            text = _("Enabled: No"),
            callback = function()
                alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Address"),
            callback = function()
                alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Password"),
            callback = function()
                alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Ping every: 300 seconds"),
            callback = function()
                alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Test connection"),
            callback = function()
                alert("Not implemented yet.")
                return true
            end,
        },
    }
end

return getRunnerSettings
local _ = require("gettext")

function getRunnerSettings(instance)
    return {
        {
            text = _("Enabled: Yes"),
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
            text = _("Token"),
            callback = function()
                alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Max retries: 3"),
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
local _ = require("gettext")

function GetAISettings(instance)
    return {
        {
            text = _("Enabled: No"),
            callback = function()
                Alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Openrouter token"),
            callback = function()
                Alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Model"),
            callback = function()
                Alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Threshold: 90%"),
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
        {
            text = _("Stats"),
            callback = function()
                Alert("Not implemented yet.")
                return true
            end,
        },
    }
end

return GetAISettings
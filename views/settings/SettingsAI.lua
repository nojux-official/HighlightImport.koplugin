local _ = require("gettext")

function getAISettings(instance)
    return {
        {
            text = _("Enabled: No"),
            callback = function()
                alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Openrouter token"),
            callback = function()
                alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Model"),
            callback = function()
                alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Threshold: 90%"),
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
        {
            text = _("Stats"),
            callback = function()
                alert("Not implemented yet.")
                return true
            end,
        },
    }
end

return getAISettings
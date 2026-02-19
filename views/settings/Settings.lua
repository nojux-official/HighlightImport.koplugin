local _ = require("gettext")

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
local _ = require("gettext")
local modal = require("components.Modal")

function ImportsView()
    modal(_("Import selection"), {})
end

return ImportsView
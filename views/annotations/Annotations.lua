local _ = require("gettext")
local modal = require("components.Modal")

function AnnotationsView()
    modal(_("Annotations (file)"), {})
end

return AnnotationsView
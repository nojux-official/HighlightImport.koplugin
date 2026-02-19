local _ = require("gettext")
local modal = require("components.Modal")

function PotentialMatches()
    modal(_("Failed targets"), {})
end

return PotentialMatches
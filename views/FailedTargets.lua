local _ = require("gettext")
local UIManager = require("ui/uimanager")
local Modal = require("components.Modal")

function FailedTargetsView()
    local modal = Modal(_("Failed targets"), {})
    UIManager:show(modal)

end

return FailedTargetsView
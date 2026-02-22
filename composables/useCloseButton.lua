local _ = require("gettext")

local UIManager = require("ui/uimanager")

return function(ctx)
    UIManager:close(ctx.parent)
end
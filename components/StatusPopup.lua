local UIManager = require("ui/uimanager")
local Popup = require("components.Popup")
local useCloseButton = require("composables/useCloseButton")


return function(content, ctx)

    if ctx == nil then ctx = {} end

    local buttons = {
        { text = "Close", callback = function() useCloseButton(ctx) end }, 
    }

    local popup = Popup("Import status", content, buttons)
    ctx["parent"] = popup

    return popup
end


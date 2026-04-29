local UIManager = require("ui/uimanager")
local Popup = require("components.Popup")
local useCloseButton = require("composables/useCloseButton")


return function(content, ctx)

    if ctx == nil then ctx = {} end

    local buttons = {
        { text = "Close", callback = function() useCloseButton(ctx) end },
    }

    -- During an active import show a Cancel button
    if not ctx.finished and ctx.cancelFunc then
        table.insert(buttons, 1, {
            text = "Cancel",
            callback = function()
                ctx.cancelFunc()
                useCloseButton(ctx)
            end,
        })
    end

    local popup = Popup("Import status", content, buttons)
    ctx["parent"] = popup

    return popup
end


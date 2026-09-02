local UIManager = require("ui/uimanager")
local Popup = require("components.Popup")
local useCloseButton = require("composables/useCloseButton")
local FailedTargetsView = require("views.FailedTargets")


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

    -- When finished with failures, offer a "View failed" button
    if ctx.finished and ctx.targets then
        local failed = {}
        for _, t in ipairs(ctx.targets) do
            if t.status == "failed" then
                failed[#failed + 1] = t
            end
        end
        if #failed > 0 then
            table.insert(buttons, 1, {
                text = string.format("View failed (%d)", #failed),
                callback = function()
                    useCloseButton(ctx)
                    UIManager:nextTick(function()
                        FailedTargetsView(failed)
                    end)
                end,
            })
        end
    end

    local popup = Popup("Import status", content, buttons)
    ctx["parent"] = popup

    return popup
end


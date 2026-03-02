local ITargetStatus = require("interfaces.ITargetStatus")
local StatusPopup = require("components.StatusPopup")
local UIManager = require("ui/uimanager")


function calculateStats (ctx)
    ctx.total = 0
    ctx.succeeded=0
    ctx.skipped=0
    ctx.failed=0
    ctx.remaining=0
    for idx, target in ipairs(ctx.targets) do

        if target.status == ITargetStatus.SELECTED then 
            ctx.remaining = ctx.remaining + 1 
            ctx.total = ctx.total + 1
        end
        if target.status == ITargetStatus.ALGORITHM_RESOLVED then
            ctx.succeeded = ctx.succeeded + 1
            ctx.total = ctx.total + 1
        end
        if target.status == ITargetStatus.FAILED then
            ctx.failed = ctx.failed + 1
            ctx.total = ctx.total + 1
        end
    end
end

local function recreateStatusPopup(ctx)
    if ctx == nil then return end

    if ctx.popup then
        UIManager:close(ctx.popup)
    end
    
    calculateStats(ctx)
    local content = string.format([[
Importing from %s
Status: %s
Succeeded: %d / %d
Failed: %d
Remaining: %d]],
ctx.file_path, (ctx.finished ~= nil and ctx.finished) and 'finished' or 'in progress',
ctx.succeeded, ctx.total,
ctx.failed, ctx.remaining
)
    ctx.popup = StatusPopup(content, ctx)
    UIManager:show(ctx.popup)
    return ctx.popup
end



return recreateStatusPopup
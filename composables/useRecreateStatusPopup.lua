local ITargetStatus = require("interfaces.ITargetStatus")
local StatusPopup = require("components.StatusPopup")
local UIManager = require("ui/uimanager")


function calculateStats(ctx)
    ctx.total = 0
    ctx.succeeded = 0
    ctx.notes_added = 0
    ctx.skipped = 0
    ctx.failed = 0
    ctx.failed_with_notes = 0
    ctx.remaining = 0
    ctx.cancelled = 0
    for _, target in ipairs(ctx.targets) do
        if target.status == ITargetStatus.SELECTED then
            ctx.remaining = ctx.remaining + 1
            ctx.total = ctx.total + 1
        end
        if target.status == ITargetStatus.ALGORITHM_RESOLVED then
            ctx.succeeded = ctx.succeeded + 1
            ctx.total = ctx.total + 1
            if target.note then ctx.notes_added = ctx.notes_added + 1 end
        end
        if target.status == ITargetStatus.FAILED then
            ctx.failed = ctx.failed + 1
            ctx.total = ctx.total + 1
            if target.note then ctx.failed_with_notes = ctx.failed_with_notes + 1 end
        end
        if target.status == ITargetStatus.SKIPPED then
            ctx.skipped = ctx.skipped + 1
            ctx.total = ctx.total + 1
        end
        if target.status == ITargetStatus.CANCELLED then
            ctx.cancelled = ctx.cancelled + 1
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
    local status = (ctx.finished ~= nil and ctx.finished) and "finished" or "in progress"
    local filename = (ctx.file_path or ""):match("([^/]+)$") or ctx.file_path or ""

    local lines = {
        string.format("File: %s", filename),
        string.format("Status: %s", status),
        string.format("Highlights: %d / %d", ctx.succeeded, ctx.total),
    }
    if ctx.notes_added > 0 then
        lines[#lines + 1] = string.format("Notes attached: %d", ctx.notes_added)
    end
    if ctx.failed > 0 then
        if ctx.failed_with_notes > 0 then
            lines[#lines + 1] = string.format("Failed: %d (%d had notes)", ctx.failed, ctx.failed_with_notes)
        else
            lines[#lines + 1] = string.format("Failed: %d", ctx.failed)
        end
    end
    if ctx.skipped > 0 then
        lines[#lines + 1] = string.format("Skipped: %d", ctx.skipped)
    end
    if ctx.cancelled and ctx.cancelled > 0 then
        lines[#lines + 1] = string.format("Cancelled: %d", ctx.cancelled)
    end
    if ctx.remaining > 0 then
        lines[#lines + 1] = string.format("Remaining: %d", ctx.remaining)
    end
    if ctx.unmatched_path then
        local uf = ctx.unmatched_path:match("([^/]+)$") or ctx.unmatched_path
        lines[#lines + 1] = string.format("Unmatched saved: %s", uf)
    end

    ctx.popup = StatusPopup(table.concat(lines, "\n"), ctx)
    UIManager:show(ctx.popup)
    return ctx.popup
end



return recreateStatusPopup

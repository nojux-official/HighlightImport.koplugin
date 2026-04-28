local _ = require("gettext")
local logger = require("logger")
local RapidJSON = require("rapidjson")
local ITargetStatus = require("interfaces.ITargetStatus")
local UIManager = require("ui/uimanager")

local useRecreateStatusPopup = require("composables.useRecreateStatusPopup")

local Document = require("services.Document")

return function (instance)

    local doc = Document:new(instance)

    logger.dbg(string.format("HighlighitImport: Local matching algorithm starting. Clippings: %d", #instance.targets))

    if not doc:IsDocReady() then return end

    -- ReaderUI instance and ReaderSearch
    if not instance.ui then error("No ReaderUI instance running") end
    local search = instance.ui.search

    instance.cancel_import = false

    local ctx = {
        file_path = instance.file_path,
        targets = instance.targets,
        finished = false,
        cancelFunc = function()
            instance.cancel_import = true
        end,
    }
    ctx.popup = useRecreateStatusPopup(ctx)

    for idx, target in ipairs(instance.targets) do
        -- Check cancellation before each target
        if instance.cancel_import then
            instance.targets[idx].status = ITargetStatus.CANCELLED
            for i = idx + 1, #instance.targets do
                if instance.targets[i].status == ITargetStatus.SELECTED then
                    instance.targets[i].status = ITargetStatus.CANCELLED
                end
            end
            logger.dbg("HighlightImport: import cancelled by user")
            break
        end

        if target.status ~= ITargetStatus.SELECTED then goto continueInner end

        if idx % 10 == 0 then
            useRecreateStatusPopup(ctx)
            UIManager:forceRePaint()
        end

        local serialized = RapidJSON.encode(target.annotation, { indent = true })
        logger.dbg("Entry: " .. tostring(serialized))

        logger.dbg("HighlightImport: Processing " .. target.annotation)
        -- direction=0, no regex, case_insensitive
        local res = search:searchFromCurrent(target.annotation, 0, false, true)

        if not res or #res == 0 then
            logger.dbg("HighlightImport: Failed to find match: " .. target.annotation)
            instance.targets[idx].status = ITargetStatus.FAILED
            goto continueInner
        end
        local xpointer_start = res[1].start
        local xpointer_end = res[1]["end"]
        if xpointer_end == nil then
            logger.dbg("HighlightImport: Failed to find end pointer for: " .. target.annotation)
            instance.targets[idx].status = ITargetStatus.FAILED
            goto continueInner
        end
        logger.dbg("HighlightImport: Found text at: " .. xpointer_start .. " to " .. xpointer_end)

        doc:CreateHighlightFromXPointer(xpointer_start, xpointer_end, target.annotation)

        instance.targets[idx].status = ITargetStatus.ALGORITHM_RESOLVED

        ::continueInner::
    end

    ctx.finished = true
    useRecreateStatusPopup(ctx)
    UIManager:forceRePaint()

    logger.dbg("HighlightImport: algorithm finished.")

end

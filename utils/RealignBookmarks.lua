local _ = require("gettext")
local logger = require("logger")
local UIManager = require("ui/uimanager")

local useRecreateStatusPopup = require("composables.useRecreateStatusPopup")

return function(instance)
    --[=====[
    Realign bookmarks algorithm:
    1. Scan KOReader's annotations (bookmarks/highlights)
    2. For each highlight annotation, search for the text in the document
    3. Capture the new pos0 and pos1 positions
    4. Overwrite the original bookmark positions
    --]=====]

    logger.dbg("HighlightImport: Realign bookmarks algorithm starting.")

    if not instance.ui then
        error("No ReaderUI instance running")
    end

    local search = instance.ui.search
    local annotation_module = instance.ui.annotation

    if not annotation_module or not annotation_module.annotations then
        logger.warn("HighlightImport: No annotations found in document.")
        return
    end

    local annotations = annotation_module.annotations

    logger.dbg(string.format("HighlightImport: Processing %d annotations for realignment.", #annotations))

    local ctx = {}
    ctx.file_path = instance.file_path or "Current Document"
    ctx.targets = {}
    ctx.finished = false

    local realigned_count = 0
    local skipped_count = 0
    local failed_count = 0

    for idx, annotation in ipairs(annotations) do
        -- Skip page bookmarks
        if not annotation.drawer then
            skipped_count = skipped_count + 1
            goto continueInner
        end

        -- Skip if no text to search for
        if not annotation.text or annotation.text == "" then
            logger.dbg("HighlightImport: Skipping annotation with empty text at index " .. idx)
            skipped_count = skipped_count + 1
            goto continueInner
        end

        logger.dbg("HighlightImport: Processing annotation: " .. annotation.text:sub(1, 50) .. "...")

        -- direction=0, no regex, case_insensitive
        local res = search:searchFromCurrent(annotation.text, 0, false, true)

        if not res or #res == 0 then
            logger.dbg("HighlightImport: Failed to find match for annotation: " .. annotation.text:sub(1, 50))
            failed_count = failed_count + 1
            goto continueInner
        end

        local new_pos0 = res[1].start
        local new_pos1 = res[1]["end"]

        logger.dbg(string.format("HighlightImport: Found text at: %s to %s", tostring(new_pos0), tostring(new_pos1)))

        annotation.pos0 = new_pos0
        annotation.pos1 = new_pos1
        annotation.page = new_pos0 -- page field also uses pos0 for rolling documents

        realigned_count = realigned_count + 1

        if (idx % 5 == 0) or (idx == #annotations) then
            ctx.targets = {
                { status = "info", annotation = string.format("Processed: %d/%d", idx, #annotations) },
                { status = "info", annotation = string.format("Realigned: %d", realigned_count) },
                { status = "info", annotation = string.format("Failed: %d", failed_count) },
                { status = "info", annotation = string.format("Skipped: %d", skipped_count) },
            }
            if idx == #annotations then
                ctx.finished = true
            end
            useRecreateStatusPopup(ctx)
            UIManager:forceRePaint()
        end

        ::continueInner::
    end

    -- Sort annotations after position changes
    if realigned_count > 0 then
        annotation_module:sortItems(annotations)
        -- Mark document as modified so changes will be saved
        instance.ui.doc_settings:saveSetting("annotations", annotations)
        logger.dbg("HighlightImport: Annotations saved after realignment.")
    end

    logger.dbg(string.format(
        "HighlightImport: Realign finished. Realigned: %d, Failed: %d, Skipped: %d",
        realigned_count, failed_count, skipped_count
    ))

    return {
        realigned = realigned_count,
        failed = failed_count,
        skipped = skipped_count
    }
end

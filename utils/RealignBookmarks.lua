local _ = require("gettext")
local logger = require("logger")
local Alert = require("components.Alert")

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

    local document = instance.ui.document
    local annotation_module = instance.ui.annotation

    if not annotation_module or not annotation_module.annotations then
        logger.warn("HighlightImport: No annotations found in document.")
        return
    end

    local annotations = annotation_module.annotations

    logger.dbg(string.format("HighlightImport: Processing %d annotations for realignment.", #annotations))

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

        if #annotation.text > 200 then
            logger.dbg("HighlightImport: Skipping long annotation (length: " .. #annotation.text .. ")")
            skipped_count = skipped_count + 1
            goto continueInner
        end

        logger.dbg("HighlightImport: Processing annotation: " .. annotation.text:sub(1, 50) .. "...")

        -- Use findAllText: pattern, case_insensitive, nb_context_words, max_hits, regex
        local res = document:findAllText(annotation.text, true, 0, 1, false)

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

        ::continueInner::
    end

    -- Sort annotations after position changes
    if realigned_count > 0 then
        -- Filter out annotations with invalid positions before sorting
        local valid_annotations = {}
        for _, ann in ipairs(annotations) do
            if ann.pos0 and ann.pos1 and type(ann.pos0) ~= "table" and type(ann.pos1) ~= "table" then
                table.insert(valid_annotations, ann)
            else
                logger.warn("HighlightImport: Filtering out annotation with invalid position data")
            end
        end

        -- If we have valid annotations, sort and save them
        if #valid_annotations > 0 then
            local success, err = pcall(function()
                annotation_module:sortItems(valid_annotations)
            end)
            
            if not success then
                logger.warn("HighlightImport: Sorting failed, keeping annotations unsorted: " .. tostring(err))
            end
            
            annotation_module.annotations = valid_annotations
            instance.ui.doc_settings:saveSetting("annotations", valid_annotations)
            logger.dbg("HighlightImport: Annotations saved after realignment.")
        else
            logger.warn("HighlightImport: No valid annotations to save after filtering")
        end
    end

    logger.dbg(string.format(
        "HighlightImport: Realign finished. Realigned: %d, Failed: %d, Skipped: %d",
        realigned_count, failed_count, skipped_count
    ))

    Alert(string.format(
        "Realignment complete! Please reopen your document!\n\nRealigned: %d\nFailed: %d\nSkipped: %d",
        realigned_count, failed_count, skipped_count
    ))

    return {
        realigned = realigned_count,
        failed = failed_count,
        skipped = skipped_count
    }
end

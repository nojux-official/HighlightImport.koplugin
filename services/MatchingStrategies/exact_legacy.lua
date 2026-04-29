local _ = require("gettext")
local logger = require("logger")
local RapidJSON = require("rapidjson")
local ITargetStatus = require("interfaces.ITargetStatus")
local UIManager = require("ui/uimanager")

local useRecreateStatusPopup = require("composables.useRecreateStatusPopup")

local Document = require("services.Document")

return function (instance)

    
    local doc = Document:new(instance)

    logger.dbg(string.format("HighlightImport: Local matching algorithm is starting. Clippings: %d", #instance.targets))

    if not doc:IsDocReady() then return end


    if not instance.ui then error("No ReaderUI instance running") end  
    local search = instance.ui.search
    local has_pages = instance.ui.document.info.has_pages

    
    local ctx = {}
    ctx.file_path = instance.file_path
    ctx.targets = instance.targets
    ctx.finished = false
    ctx.popup = useRecreateStatusPopup(ctx)
    
    -- Log file for debugging (written next to the clippings file)
    local log_dir = instance.file_path:match("(.*/)")
    local log_path = log_dir and (log_dir .. "highlight_import.log") or nil
    local log_file = log_path and io.open(log_path, "w") or nil
    local function log(msg)
        local ts = os.date("%H:%M:%S")
        local line = string.format("[%s] %s", ts, msg)
        logger.dbg("HighlightImport: " .. line)
        if log_file then log_file:write(line .. "\n") end
    end

    log("Starting exact legacy algorithm")
    
    for idx, target in ipairs(instance.targets) do
        if target.status ~= ITargetStatus.SELECTED then goto continueInner end

        if (idx % 3 == 0) then
            useRecreateStatusPopup(ctx)
            UIManager:forceRePaint()
        end


        logger.dbg("HighlightImport: Processing " .. target.annotation)

        -- search_text, case_insensitive, findall_nb_context_words, findall_max_hits, use_regex
        local res = instance.ui.document:findAllText(target.annotation, true, 5, 2048, false)

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
        
        doc:CreateHighlightFromXPointer(xpointer_start, xpointer_end, target.annotation, target.note)

        instance.targets[idx].status = ITargetStatus.ALGORITHM_RESOLVED

        ::continueInner::
    end
    
    -- Collect failed targets for post-processing (options A and B).
    local failed = {}
    for _, t in ipairs(instance.targets) do
        if t.status == ITargetStatus.FAILED then failed[#failed + 1] = t end
    end

    -- Option A: save unmatched highlights to a text file next to the clippings file.
    if G_reader_settings:isTrue("highlight_import_save_unmatched_file")
            and #failed > 0 and log_dir then
        local up = log_dir .. "highlight_import_unmatched.txt"
        local uf = io.open(up, "w")
        if uf then
            uf:write(string.format("Unmatched highlights (%d) — %s\n", #failed, os.date("%Y-%m-%d %H:%M")))
            uf:write(string.rep("-", 60) .. "\n\n")
            for _, t in ipairs(failed) do
                uf:write(string.format("[p.%s]\n%s\n", tostring(t.page), t.annotation))
                if t.note then uf:write(string.format("  Note: %s\n", t.note)) end
                uf:write("\n")
            end
            uf:close()
            ctx.unmatched_path = up
            log(string.format("Unmatched file written to %s", up))
        end
    end

    -- Option B: create an in-book annotation near the start of the book with all
    -- unmatched items as a note.
    if G_reader_settings:isTrue("highlight_import_note_in_book") and #failed > 0 then
        if has_pages then instance.ui.paging:gotoPage(1) end
        -- Try progressively shorter/simpler strings until we get a valid anchor.
        local anchor_res
        for _, probe in ipairs({ "the ", "and ", "a ", "I " }) do
            anchor_res = search:searchFromCurrent(probe, 0, false, false)
            if anchor_res and #anchor_res > 0 then break end
        end
        local axp_start = anchor_res and #anchor_res > 0 and anchor_res[1].start
        local axp_end   = anchor_res and #anchor_res > 0 and anchor_res[1]["end"]
        if axp_start then
            local lines = { string.format("Unmatched highlights (%d):", #failed) }
            for _, t in ipairs(failed) do
                lines[#lines + 1] = string.format("[p.%s] %s", tostring(t.page), t.annotation)
                if t.note then lines[#lines + 1] = "  Note: " .. t.note end
            end
            local label = string.format("[Unmatched: %d — see note]", #failed)
            doc:CreateHighlightFromXPointer(axp_start, axp_end, label, table.concat(lines, "\n"))
            log(string.format("In-book unmatched note created at %s", axp_start))
        else
            log("[WARN] Option B: could not find a valid anchor — note not created")
        end
    end

    ctx.finished = true
    useRecreateStatusPopup(ctx)
    UIManager:forceRePaint()
    
    -- instance.merge:merge()

    log(string.format("Exact legacy algorithm finished. Log written to %s", log_path or "(none)"))
    if log_file then log_file:close(); log_file = nil end

end


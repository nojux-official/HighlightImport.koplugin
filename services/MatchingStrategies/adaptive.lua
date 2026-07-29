local _ = require("gettext")
local logger = require("logger")
local ITargetStatus = require("interfaces.ITargetStatus")
local UIManager = require("ui/uimanager")

local useRecreateStatusPopup = require("composables.useRecreateStatusPopup")
local Document = require("services.Document")

return function (instance)

    local doc = Document:new(instance)

    logger.dbg(string.format("HighlightImport: Local matching starting. Targets: %d", #instance.targets))

    if not doc:IsDocReady() then return end
    if not instance.ui then error("No ReaderUI instance running") end

    local search = instance.ui.search
    local has_pages = instance.ui.document.info.has_pages

    -- Build set of existing highlight texts to skip duplicates on re-import
    local existing = {}
    if instance.ui.annotation and instance.ui.annotation.annotations then
        for _, ann in ipairs(instance.ui.annotation.annotations) do
            if ann.text then existing[ann.text] = true end
        end
    end

    -- Sort by page ascending. Extract first number from range strings like "42-43".
    table.sort(instance.targets, function(a, b)
        local pa = tonumber(tostring(a.page or ""):match("^(%d+)")) or 0
        local pb = tonumber(tostring(b.page or ""):match("^(%d+)")) or 0
        return pa < pb
    end)

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

    local n_existing = 0
    for _ in pairs(existing) do n_existing = n_existing + 1 end
    log(string.format("Starting import. Targets: %d, Existing highlights: %d",
        #instance.targets, n_existing))

    -- Truncate a string safely at a UTF-8 character boundary.
    -- Lua's string.sub works on bytes, which can split multi-byte characters
    -- (e.g. "á" = 2 bytes, "—" = 3 bytes), producing invalid UTF-8 that the
    -- search engine silently fails to match.
    local function utf8_sub(s, max_bytes)
        if #s <= max_bytes then return s end
        local i = max_bytes
        -- Walk back until we are at the start of a UTF-8 character.
        -- Continuation bytes have the form 10xxxxxx (0x80–0xBF).
        while i > 0 and s:byte(i) >= 0x80 and s:byte(i) <= 0xBF do
            i = i - 1
        end
        -- Also skip the leading byte of a multi-byte sequence if it would be orphaned.
        if i > 0 and s:byte(i) >= 0x80 then i = i - 1 end
        return s:sub(1, i)
    end

    -- Normalize curly/smart typography to ASCII equivalents.
    -- Used as a fallback when the exact text fails to match, which happens when
    -- the Kindle edition used smart quotes/dashes but the EPUB uses plain ASCII.
    local function normalize_typography(s)
        s = s:gsub("\xe2\x80\x98", "'")   -- U+2018 left single quote
        s = s:gsub("\xe2\x80\x99", "'")   -- U+2019 right single quote / apostrophe
        s = s:gsub("\xe2\x80\x9c", '"')   -- U+201C left double quote
        s = s:gsub("\xe2\x80\x9d", '"')   -- U+201D right double quote
        s = s:gsub("\xe2\x80\x93", " - ")  -- U+2013 en-dash  (common in "word – word" spacing)
        s = s:gsub("\xe2\x80\x94", " - ") -- U+2014 em-dash  (common in "word—word" or "word — word")
        s = s:gsub("\xe2\x80\xa6", "...") -- U+2026 ellipsis
        s = s:gsub("%s%s+", " ")          -- collapse double-spaces left by "word – word" → "word  -  word"
        return s
    end

    -- Remove em/en-dashes and surrounding spaces used for dialogue attribution.
    -- Portuguese Kindle books use " — Palavra" (space + em-dash + space) at the
    -- start of dialogue lines. Some EPUB editions represent the same text differently.
    -- This produces a version with dashes stripped so the search can find the
    -- underlying prose without the typographic dash character.
    local function strip_dashes(s)
        -- Remove leading "— " or "– " patterns (dialogue openers)
        s = s:gsub("^\xe2\x80\x94%s*", "")  -- leading em-dash + optional space
        s = s:gsub("^\xe2\x80\x93%s*", "")  -- leading en-dash + optional space
        -- Remove inline " — " and " – " patterns
        s = s:gsub("%s*\xe2\x80\x94%s*", " ")
        s = s:gsub("%s*\xe2\x80\x93%s*", " ")
        s = s:gsub("%s+", " ")
        return s:match("^%s*(.-)%s*$") or s
    end

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

    -- Track xpointers already used this run to avoid duplicate highlights
    -- from different full-length annotations that share the same truncated query.
    local used_xpointers = {}

    -- Record the first successfully matched xpointer pair for use as an anchor
    -- when creating an in-book note (option B).  Targets are sorted by page, so
    -- the first match is near the beginning of the book.
    local first_xp_start, first_xp_end

    for idx, target in ipairs(instance.targets) do
        -- Check cancellation before each target
        if instance.cancel_import then
            instance.targets[idx].status = ITargetStatus.CANCELLED
            -- Mark all remaining SELECTED targets as cancelled too
            for i = idx + 1, #instance.targets do
                if instance.targets[i].status == ITargetStatus.SELECTED then
                    instance.targets[i].status = ITargetStatus.CANCELLED
                end
            end
            log("Import cancelled by user")
            break
        end

        if target.status ~= ITargetStatus.SELECTED then goto continue end

        if idx % 10 == 0 then
            useRecreateStatusPopup(ctx)
            UIManager:forceRePaint()
        end

        -- Skip if this highlight already exists in the document
        if existing[target.annotation] then
            log(string.format("[SKIP existing] %s", target.annotation))
            instance.targets[idx].status = ITargetStatus.SKIPPED
            goto continue
        end

        -- Navigate to the target page so searchFromCurrent finds the right occurrence
        if target.page and has_pages then
            instance.ui.paging:gotoPage(tonumber(target.page))
        end

        -- Truncate very long highlights to avoid search engine memory pressure.
        -- Use utf8_sub to avoid splitting multi-byte characters (á, ã, ê, —, etc.)
        -- which would produce invalid UTF-8 that the search engine silently rejects.
        local query = utf8_sub(target.annotation, 150)
        log(string.format("[SEARCH p.%s] %s", tostring(target.page), query))
        local res = search:searchFromCurrent(query, 0, false, true)

        -- Fallback: if exact match failed, retry with ASCII-normalized typography.
        -- Handles the common case where Kindle used smart quotes/dashes but EPUB uses plain ones.
        local query_norm = normalize_typography(query)
        if (not res or #res == 0) and query_norm ~= query then
            log("[RETRY normalized]")
            res = search:searchFromCurrent(query_norm, 0, false, true)
        end

        -- Fallback: progressive prefix shortening for edition differences.
        -- When mobi and EPUB have slightly different wording in the tail of a passage,
        -- a shorter prefix is more likely to match exactly.
        -- We try 80 chars then 50 chars (using the normalized form as base).
        -- Only fires when the full-length attempts above all failed.
        if not res or #res == 0 then
            local base = query_norm  -- already normalized; same as query if no special chars
            for _, len in ipairs({ 80, 50 }) do
                local prefix = utf8_sub(base, len)
                if #prefix < #base then
                    log(string.format("[RETRY prefix-%d]", len))
                    res = search:searchFromCurrent(prefix, 0, false, true)
                    if res and #res > 0 then break end
                end
            end
        end

        -- Fallback: backward search (direction=1).
        -- When the reading cursor is ahead of the target text, a forward search must
        -- wrap all the way around the book, which can hit KOReader's internal iteration
        -- limit on large EPUBs and give up before finding early content.
        -- A backward search finds text *before* the cursor immediately, no wrap needed.
        if not res or #res == 0 then
            log("[RETRY backward]")
            local base = query_norm
            res = search:searchFromCurrent(base, 1, false, true)
            if not res or #res == 0 then
                local p80 = utf8_sub(base, 80)
                if #p80 < #base then
                    res = search:searchFromCurrent(p80, 1, false, true)
                end
            end
            if not res or #res == 0 then
                local p50 = utf8_sub(base, 50)
                if #p50 < #base then
                    res = search:searchFromCurrent(p50, 1, false, true)
                end
            end
        end

        -- Fallback: strip em/en-dashes and retry.
        -- Dialogue lines in Portuguese Kindle books often start with "— Palavra"
        -- (U+2014 + space). Some EPUB editions omit the dash entirely or use a
        -- different encoding, causing all dash-containing highlights to fail.
        if not res or #res == 0 then
            local stripped = strip_dashes(query_norm)
            if stripped ~= query_norm and #stripped >= 10 then
                log("[RETRY strip-dashes]")
                res = search:searchFromCurrent(stripped, 0, false, true)
                if not res or #res == 0 then
                    local p80 = utf8_sub(stripped, 80)
                    if #p80 < #stripped then res = search:searchFromCurrent(p80, 0, false, true) end
                end
                if not res or #res == 0 then
                    local p50 = utf8_sub(stripped, 50)
                    if #p50 < #stripped then res = search:searchFromCurrent(p50, 0, false, true) end
                end
                -- Also try backward
                if not res or #res == 0 then
                    res = search:searchFromCurrent(stripped, 1, false, true)
                end
            end
        end

        -- Fallback: try the text segment at/after the first em/en-dash.
        -- Kindle clippings sometimes capture text from the end of one paragraph
        -- joined to the start of the next (e.g. "claro. — Então às cinco").
        -- The EPUB has these as separate paragraphs: the second paragraph often
        -- STARTS with the dash ("— Então às cinco"), so we must search for the
        -- dash-inclusive version AND the dash-stripped version.
        if not res or #res == 0 then
            local raw_dash_pos = query:find("\xe2\x80\x94", 1, true)
                              or query:find("\xe2\x80\x93", 1, true)
            if raw_dash_pos then
                -- 1) Include the dash: "— Então às cinco, e de sobrecasaca."
                --    This matches EPUBs where the paragraph starts with the dash.
                local with_dash = query:sub(raw_dash_pos):match("^%s*(.-)%s*$")
                -- 2) Exclude the dash (skip the 3-byte sequence + space)
                local after_raw = query:sub(raw_dash_pos + 3):match("^%s*(.-)%s*$")
                for _, probe in ipairs({ with_dash, after_raw }) do
                    if probe and #probe >= 10 and (not res or #res == 0) then
                        log(string.format("[RETRY around-dash] %s", utf8_sub(probe, 60)))
                        res = search:searchFromCurrent(probe, 0, false, true)
                        if not res or #res == 0 then
                            res = search:searchFromCurrent(probe, 1, false, true)
                        end
                        -- also try shorter prefix of this probe
                        if not res or #res == 0 then
                            local p80 = utf8_sub(probe, 80)
                            if #p80 < #probe then
                                res = search:searchFromCurrent(p80, 0, false, true)
                                if not res or #res == 0 then
                                    res = search:searchFromCurrent(p80, 1, false, true)
                                end
                            end
                        end
                    end
                end
            end
            -- Also try via the normalized form (dash replaced with " - ")
            if not res or #res == 0 then
                local dash_start = query_norm:find(" - ", 1, true)
                if dash_start then
                    -- normalized "- " prefix version
                    local with_dash_norm = query_norm:sub(dash_start + 1):match("^%s*(.-)%s*$")
                    local after_dash_norm = query_norm:sub(dash_start + 3):match("^%s*(.-)%s*$")
                    for _, probe in ipairs({ with_dash_norm, after_dash_norm }) do
                        if probe and #probe >= 10 and (not res or #res == 0) then
                            log(string.format("[RETRY norm-dash] %s", utf8_sub(probe, 60)))
                            res = search:searchFromCurrent(probe, 0, false, true)
                            if not res or #res == 0 then
                                res = search:searchFromCurrent(probe, 1, false, true)
                            end
                        end
                    end
                end
            end
        end

        -- Fallback: split annotation by newline and try each line independently.
        -- The Kindle stores multi-paragraph selections joined with literal \n characters.
        -- KOReader's search engine works within individual EPUB paragraph elements, so
        -- a query containing \n will NEVER match across paragraphs.
        -- Strategy: try each non-empty line as a standalone query (forward + backward).
        -- This is the primary fix for cross-paragraph highlights like:
        --   "claro.\n— Então às cinco, e de sobrecasaca."
        -- where "claro." is one paragraph and "— Então às cinco..." is another.
        if (not res or #res == 0) and target.annotation:find("\n", 1, true) then
            local lines_list = {}
            for ln in (target.annotation .. "\n"):gmatch("([^\n]*)\n") do
                ln = ln:match("^%s*(.-)%s*$") or ""
                if #ln >= 15 then
                    lines_list[#lines_list + 1] = ln
                end
            end
            for _, ln in ipairs(lines_list) do
                if not res or #res == 0 then
                    local ln_norm = normalize_typography(ln)
                    log(string.format("[RETRY newline-split] %s", utf8_sub(ln_norm, 60)))
                    res = search:searchFromCurrent(ln_norm, 0, false, true)
                    if not res or #res == 0 then
                        res = search:searchFromCurrent(ln_norm, 1, false, true)
                    end
                    -- also try shorter prefixes of this line
                    if not res or #res == 0 then
                        local p80 = utf8_sub(ln_norm, 80)
                        if #p80 < #ln_norm then
                            res = search:searchFromCurrent(p80, 0, false, true)
                            if not res or #res == 0 then
                                res = search:searchFromCurrent(p80, 1, false, true)
                            end
                        end
                    end
                    if not res or #res == 0 then
                        local p50 = utf8_sub(ln_norm, 50)
                        if #p50 < #ln_norm then
                            res = search:searchFromCurrent(p50, 0, false, true)
                            if not res or #res == 0 then
                                res = search:searchFromCurrent(p50, 1, false, true)
                            end
                        end
                    end
                    -- also try strip-dashes variant of this line
                    if not res or #res == 0 then
                        local ln_stripped = strip_dashes(ln_norm)
                        if ln_stripped ~= ln_norm and #ln_stripped >= 10 then
                            res = search:searchFromCurrent(ln_stripped, 0, false, true)
                            if not res or #res == 0 then
                                res = search:searchFromCurrent(ln_stripped, 1, false, true)
                            end
                        end
                    end
                end
            end
        end

        -- Fallback: short prefix (first ~40 bytes) to handle cross-paragraph clippings.
        -- The Kindle records multi-paragraph selections as a single joined string.
        -- The KOReader search engine operates within individual EPUB paragraph elements,
        -- so a string that spans two paragraphs will NEVER match as a whole.
        -- Searching for only the first portion (which lives entirely in the first paragraph)
        -- works around this fundamental limitation.
        -- This fires regardless of whether dashes are involved.
        if not res or #res == 0 then
            -- First try: everything before the first sentence-ending punctuation
            -- followed by a space (captures "claro." from "claro. — Então...").
            local first_sentence = query_norm:match("^(.+[%.!%?])[%s%-]") or
                                   query_norm:match("^(.+[%.!%?])$")
            if first_sentence then
                first_sentence = first_sentence:match("^%s*(.-)%s*$") or first_sentence
            end
            -- Fallback: take the first 40 UTF-8-safe bytes as the prefix
            local short_prefix = utf8_sub(query_norm, 40)
            -- Use the shorter of the two as long as it's meaningful (≥ 10 chars)
            for _, probe in ipairs({ first_sentence, short_prefix }) do
                if probe and #probe >= 10 and (not res or #res == 0) then
                    log(string.format("[RETRY short-prefix] %s", probe))
                    res = search:searchFromCurrent(probe, 0, false, true)
                    if not res or #res == 0 then
                        res = search:searchFromCurrent(probe, 1, false, true)
                    end
                end
            end
        end

        -- Fallback: strip wrapping quotation marks and retry with prefixes.
        -- Kindle mobi often wraps blockquotes/phrases in curly quotes that the EPUB omits.
        -- e.g. '\u201cAll desire is a desire for being,\u201d' → 'All desire is a desire for being,'
        -- After typography normalization the leading char is a plain " or '.
        if not res or #res == 0 then
            local first = query_norm:sub(1, 1)
            if first == '"' or first == "'" then
                -- strip leading quote; strip trailing quote (and optional . or ,) if present
                local inner = query_norm:sub(2):gsub('["\']%s*[.,]?%s*$', ""):match("^%s*(.-)%s*$")
                if inner and #inner >= 20 then
                    log("[RETRY no-outer-quote]")
                    res = search:searchFromCurrent(inner, 0, false, true)
                    if not res or #res == 0 then
                        local p80 = utf8_sub(inner, 80)
                        if #p80 < #inner then res = search:searchFromCurrent(p80, 0, false, true) end
                    end
                    if not res or #res == 0 then
                        local p50 = utf8_sub(inner, 50)
                        if #p50 < #inner then res = search:searchFromCurrent(p50, 0, false, true) end
                    end
                end
            end
        end

        if not res or #res == 0 then
            local note_flag = target.note and " [had note]" or ""
            log(string.format("[FAIL%s] no match in document for: %s", note_flag, target.annotation))
            instance.targets[idx].status = ITargetStatus.FAILED
            goto continue
        end

        local xpointer_start = res[1].start
        local xpointer_end = res[1]["end"]
        local xp_key = xpointer_start .. "|" .. xpointer_end

        -- Skip if a previous (longer) annotation already claimed this exact location
        if used_xpointers[xp_key] then
            log(string.format("[SKIP dup xpointer] %s", target.annotation))
            instance.targets[idx].status = ITargetStatus.SKIPPED
            goto continue
        end
        used_xpointers[xp_key] = true

        log(string.format("[OK] %s → %s", xpointer_start, xpointer_end))

        if not first_xp_start then
            first_xp_start = xpointer_start
            first_xp_end   = xpointer_end
        end

        doc:CreateHighlightFromXPointer(xpointer_start, xpointer_end, target.annotation, target.note)
        instance.targets[idx].status = ITargetStatus.ALGORITHM_RESOLVED

        

        ::continue::
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
    --
    -- We need a fresh xpointer (not reused from an imported highlight, which KOReader
    -- would silently reject as a duplicate position).  Strategy:
    --   Paged (PDF): jump to page 1 then search forward for a very common word.
    --   EPUB: the import loop leaves the cursor near the last searched page (end of book).
    --         A forward search wraps around and lands near the beginning of the book.
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
        -- Last resort: fall back to the first successfully matched xpointer.
        if not axp_start then axp_start = first_xp_start; axp_end = first_xp_end end
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

    -- Final status popup (must come after A/B so unmatched_path is set before display).
    ctx.finished = true
    useRecreateStatusPopup(ctx)
    UIManager:forceRePaint()

    log(string.format("Import finished. Log written to %s", log_path or "(none)"))
    if log_file then log_file:close(); log_file = nil end
end

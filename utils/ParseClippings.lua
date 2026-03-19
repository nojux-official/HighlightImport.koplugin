local _ = require("gettext")
local MyClipping = require("services.MyClipping")
local logger = require("logger")
local ITargetStatus = require("interfaces.ITargetStatus")

return function(instance)

    -- Cache: skip re-parse if file and manual selection haven't changed
    if instance._cached_file_path == instance.file_path
        and instance._cached_manual_book == (instance.manual_book or "")
        and #instance.targets > 0 then
        return instance.targets
    end
    instance._cached_file_path  = instance.file_path
    instance._cached_manual_book = instance.manual_book or ""
    instance.targets        = {}
    instance.available_books = nil  -- reset on every fresh parse

    -- ------------------------------------------------------------------ helpers

    -- Strip author/number noise and normalise subtitle separators.
    -- "Eight Dates: Subtitle (Author)"  → "eight dates  subtitle"
    -- "Eight Dates_ Subtitle - Author"  → "eight dates  subtitle"
    local function bare_title(s)
        s = (s or ""):lower():match("^%s*(.-)%s*$")
        s = s:gsub("%s*%b()%s*$", "")    -- remove trailing (...)
        s = s:gsub("%s*%-%s*.+$", "")    -- remove " - anything" (author / series)
        s = s:match("^%s*(.-)%s*$")
        s = s:gsub("[:%_]", " ")         -- colon / underscore → space (filename subs)
        s = s:gsub("%s+", " "):match("^%s*(.-)%s*$")
        return s
    end

    -- Fuzzy title match — three layers:
    --   1. Exact (after normalisation)
    --   2. Prefix: shorter ≥ 8 chars and is a leading substring of the longer
    --   3. Word overlap: ≥ 3 words in shorter, ≥ 70 % appear in the longer
    -- This handles: missing/different subtitle, more/fewer words, edition variants.
    local function titles_match(a, b)
        if a == b then return true end
        if a == "" or b == "" then return false end

        local short, long = a, b
        if #a > #b then short, long = b, a end

        -- prefix check
        if #short >= 8 and long:sub(1, #short) == short then
            return true
        end

        -- word-overlap check
        local sw, lw = {}, {}
        for w in short:gmatch("%S+") do sw[w] = true end
        for w in  long:gmatch("%S+") do lw[w] = true end
        local total, matched = 0, 0
        for w in pairs(sw) do
            total = total + 1
            if lw[w] then matched = matched + 1 end
        end
        return total >= 3 and (matched / total) >= 0.7
    end

    -- --------------------------------------------------------- current book filter

    local current_bare = ""
    if instance.manual_book and instance.manual_book ~= "" then
        -- User manually selected a book from the picker
        current_bare = bare_title(instance.manual_book)
    elseif instance.ui and instance.ui.document and instance.ui.document.info then
        local raw = instance.ui.document.info.title or ""
        if raw == "" and instance.ui.document.file then
            raw = instance.ui.document.file:match("([^/]+)%.[^%.]+$") or ""
        end
        current_bare = bare_title(raw)
    end

    -- --------------------------------------------------------- build_targets helper
    -- Populates instance.targets from a clippings table.
    -- match_func(bare_clipping_title, current_bare) → bool
    local function build_targets(clippings, match_func)
        local all_items = {}

        for title, booknotes in pairs(clippings) do
            if type(booknotes) ~= "table" or #booknotes == 0 then goto c_collect end
            if current_bare ~= "" and not match_func(bare_title(title), current_bare) then
                goto c_collect
            end
            for _, entry in ipairs(booknotes) do
                local item = entry[1]
                if item and item.text ~= "" then
                    all_items[#all_items + 1] = { title = title, item = item }
                end
            end
            ::c_collect::
        end

        -- Time-based note pairing: for each note, find the closest preceding
        -- highlight on the same page (smallest non-negative time delta).
        local note_for_text = {}
        for _, ni in ipairs(all_items) do
            if ni.item.sort ~= "note" then goto c_note end
            local note = ni.item
            if not note.time then goto c_note end

            local best, best_diff = nil, math.huge
            for _, hi in ipairs(all_items) do
                if hi.item.sort == "highlight"
                    and hi.title == ni.title
                    and tostring(hi.item.page) == tostring(note.page)
                    and hi.item.time then
                    local diff = note.time - hi.item.time
                    if diff >= 0 and diff < best_diff then
                        best_diff = diff
                        best = hi.item
                    end
                end
            end
            if best then note_for_text[best.text] = note.text end
            ::c_note::
        end

        -- Build deduplicated highlight targets with paired notes.
        local seen = {}
        for _, ni in ipairs(all_items) do
            local item = ni.item
            if item.sort ~= "highlight" or seen[item.text] then goto c_target end
            seen[item.text] = true
            instance.targets[#instance.targets + 1] = {
                annotation = item.text,
                note       = note_for_text[item.text],
                page       = item.page,
                book       = ni.title,
                status     = ITargetStatus.ADDED,
            }
            ::c_target::
        end
    end

    -- ----------------------------------------------------------------- Pass 1
    -- Strict exact match — only loads the matching book into memory.
    local clippings = instance.parser:parseFile(instance.file_path, current_bare)
    if type(clippings) == "table" then
        build_targets(clippings, function(a, b) return a == b end)
    end
    clippings = nil
    collectgarbage()

    -- ----------------------------------------------------------------- Pass 2
    -- Fuzzy match on all books — runs only when pass 1 finds nothing.
    -- Also collects all book titles so the UI can offer a manual picker.
    if #instance.targets == 0 and current_bare ~= "" then
        local all_clippings = instance.parser:parseFile(instance.file_path, nil)
        if type(all_clippings) == "table" then

            build_targets(all_clippings, titles_match)

            -- Collect titles for the manual picker regardless of fuzzy result
            instance.available_books = {}
            for title in pairs(all_clippings) do
                instance.available_books[#instance.available_books + 1] = title
            end
            table.sort(instance.available_books)

            all_clippings = nil
            collectgarbage()
        end
    end

    logger.dbg(string.format(
        "HighlightImport: %d highlights for '%s'.",
        #instance.targets,
        current_bare ~= "" and current_bare or "(all books)"))

    return instance.targets
end

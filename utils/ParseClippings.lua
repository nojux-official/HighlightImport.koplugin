local _ = require("gettext")
local MyClipping = require("services.MyClipping")
local logger = require("logger")

local ITargetStatus = require("interfaces.ITargetStatus")

-- Return the first clippings title whose bare form matches bare_current,
-- either exactly or as a substring of the other (handles subtitle variants).
local function findBestTitle(clippings, bare_current, parser)
    for title in pairs(clippings) do
        local bt = parser:bareTitle(title)
        if bt == bare_current then return title end
        if bt ~= "" and (bt:find(bare_current, 1, true) or bare_current:find(bt, 1, true)) then
            return title
        end
    end
    return nil
end

return function (instance)

    instance.targets = {}

    -- If the user manually selected a source book via FilePick, use it directly.
    if instance.manual_book and instance.manual_book ~= "" then
        -- Cache so we don't re-parse on every tiny UI refresh
        if instance._cached_file_path   == instance.file_path and
           instance._cached_manual_book == instance.manual_book and
           instance._cached_clippings   ~= nil then
            -- reuse cached result (fall through to item collection below)
        else
            logger.dbg("HighlightImport: Using manual book selection → " .. instance.manual_book)
            local all = instance.parser:parseFile(instance.file_path, "")
            -- Keep only the manually selected title
            for k in pairs(all) do
                if k ~= instance.manual_book then all[k] = nil end
            end
            instance._cached_clippings   = all
            instance._cached_file_path   = instance.file_path
            instance._cached_manual_book = instance.manual_book
        end

        local clippings = instance._cached_clippings
        if type(clippings) ~= "table" then return end

        local all_items = {}
        for title, booknotes in pairs(clippings) do
            if type(booknotes) == "table" and #booknotes > 0 then
                for _, entry in ipairs(booknotes) do
                    if entry[1] and entry[1].text ~= "" then
                        all_items[#all_items + 1] = {
                            title = title,
                            sort  = entry[1].sort,
                            text  = entry[1].text,
                            page  = entry[1].page,
                            time  = entry[1].time,
                        }
                    end
                end
            end
        end

        local function get_page_num(page)
            return tonumber(tostring(page or ""):match("^(%d+)")) or 0
        end

        local note_for_text = {}
        for _, note_item in ipairs(all_items) do
            if note_item.sort == "note" and note_item.time then
                local best, best_diff = nil, math.huge
                local note_page_num = get_page_num(note_item.page)
                for _, h_item in ipairs(all_items) do
                    if h_item.sort == "highlight"
                        and h_item.title == note_item.title
                        and get_page_num(h_item.page) == note_page_num
                        and h_item.time then
                        local diff = note_item.time - h_item.time
                        if diff >= 0 and diff < best_diff then
                            best_diff = diff
                            best = h_item
                        end
                    end
                end
                if best then note_for_text[best.text] = note_item.text end
            end
        end

        local seen = {}
        for _, item in ipairs(all_items) do
            if item.sort == "highlight" and not seen[item.text] then
                seen[item.text] = true
                instance.targets[#instance.targets + 1] = {
                    annotation = item.text,
                    note       = note_for_text[item.text],
                    page       = item.page,
                    status     = ITargetStatus.ADDED,
                }
            end
        end

        logger.dbg(string.format("HighlightImport: Parsed %d clippings (manual book).", #instance.targets))
        return instance.targets
    end

    -- ── Automatic matching (no manual selection) ──────────────────────────────

    -- Determine the current book title for filtering
    local bare_current = ""
    if instance.ui and instance.ui.doc_props then
        local title, _ = instance.parser:getTitleAuthor(
            instance.ui.document.file, instance.ui.doc_props)
        bare_current = instance.parser:bareTitle(title or "")
    end

    -- Parse file: pass the bare title so MyClipping skips non-matching books.
    -- Falls back to no filter (parse all) when title is unknown.
    local clippings = instance.parser:parseFile(instance.file_path, bare_current)

    if type(clippings) ~= "table" then return end

    -- If the exact/bare filter matched nothing, try fuzzy matching.
    if next(clippings) == nil and bare_current ~= "" then
        logger.dbg("HighlightImport: No exact title match, attempting fuzzy search")
        local all_clippings = instance.parser:parseFile(instance.file_path, "")
        local matched = findBestTitle(all_clippings, bare_current, instance.parser)
        if matched then
            logger.dbg("HighlightImport: Fuzzy match → " .. matched)
            -- Discard non-matching books in-place to free their memory
            for k in pairs(all_clippings) do
                if k ~= matched then all_clippings[k] = nil end
            end
        else
            logger.dbg("HighlightImport: No fuzzy match found, using all clippings")
        end
        clippings = all_clippings
    end

    -- Collect all highlights and notes with their metadata
    local all_items = {}
    for title, booknotes in pairs(clippings) do
        if type(booknotes) == "table" and #booknotes > 0 then
            for _, entry in ipairs(booknotes) do
                if entry[1] and entry[1].text ~= "" then
                    all_items[#all_items + 1] = {
                        title = title,
                        sort = entry[1].sort,
                        text = entry[1].text,
                        page = entry[1].page,
                        time = entry[1].time,
                    }
                end
            end
        end
    end

    local function get_page_num(page)
        return tonumber(tostring(page or ""):match("^(%d+)")) or 0
    end

    -- Time-based note pairing: for each note, find the closest preceding
    -- highlight on the same page (smallest non-negative time delta)
    local note_for_text = {}
    for _, note_item in ipairs(all_items) do
        if note_item.sort == "note" and note_item.time then
            local best, best_diff = nil, math.huge
            local note_page_num = get_page_num(note_item.page)
            for _, h_item in ipairs(all_items) do
                if h_item.sort == "highlight"
                    and h_item.title == note_item.title
                    and get_page_num(h_item.page) == note_page_num
                    and h_item.time then
                    local diff = note_item.time - h_item.time
                    if diff >= 0 and diff < best_diff then
                        best_diff = diff
                        best = h_item
                    end
                end
            end
            if best then
                note_for_text[best.text] = note_item.text
            end
        end
    end

    -- Build targets from highlights with matched notes
    local seen = {}
    for _, item in ipairs(all_items) do
        if item.sort == "highlight" and not seen[item.text] then
            seen[item.text] = true
            instance.targets[#instance.targets + 1] = {
                annotation = item.text,
                note       = note_for_text[item.text],
                page       = item.page,
                status     = ITargetStatus.ADDED,
            }
        end
    end

    logger.dbg(string.format("HighlightImport: Parsed %d clippings.",  #instance.targets))

    return instance.targets
end

local _ = require("gettext")
local MyClipping = require("services.MyClipping")
local logger = require("logger")

local ITargetStatus = require("interfaces.ITargetStatus")

return function (instance)

    instance.targets = {}

    local clippings = instance.parser:parseFile(instance.file_path)

    if type(clippings) ~= "table" then return end
    
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
                note = note_for_text[item.text],
                status = ITargetStatus.ADDED
            }
        end
    end

    logger.dbg(string.format("HighlightImport: Parsed %d clippings.",  #instance.targets))

    return instance.targets
end
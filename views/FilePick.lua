local _ = require("gettext")
local logger = require("logger")
local UIManager = require("ui/uimanager")
local MyClipping = require("services.MyClipping")
local Modal = require("components.Modal")
local ButtonTable = require("ui/widget/buttontable")
local useCloseButton = require("composables.useCloseButton")
local Alert = require("components.Alert")

-- Parse the clippings file and return a sorted list of unique book titles.
local function getAvailableBooks(file_path, parser)
    if not file_path or file_path == "" then
        return {}
    end
    local all_clippings = parser:parseFile(file_path, "")
    local books = {}
    for title, booknotes in pairs(all_clippings) do
        -- only include books that actually have at least one highlight
        local count = 0
        if type(booknotes) == "table" then
            for _, entry in ipairs(booknotes) do
                if entry[1] and entry[1].text and entry[1].text ~= "" then
                    count = count + 1
                end
            end
        end
        if count > 0 then
            books[#books + 1] = { title = title, count = count }
        end
    end
    table.sort(books, function(a, b) return a.title < b.title end)
    return books
end

function FilePick(instance)
    if not instance.file_path or instance.file_path == "" then
        Alert(_("No clippings file selected. Please select a file first."))
        return
    end

    local books = instance.available_books
    if not books then
        books = getAvailableBooks(instance.file_path, instance.parser)
        instance.available_books = books
    end

    if #books == 0 then
        Alert(_("No highlights found in the selected file."))
        return
    end

    local ctx = {}

    local function recreate(page)
        if not page then page = 1 end

        local modalEntries = {}
        for _, book in ipairs(books) do
            local selected = (instance.manual_book == book.title)
            local prefix = selected and "[ * ] " or "[   ] "
            local entry_title = book.title
            modalEntries[#modalEntries + 1] = {
                text = string.format("%s%s  (%d)", prefix, entry_title, book.count),
                callback = function()
                    if instance.manual_book == book.title then
                        -- deselect: go back to automatic matching
                        instance.manual_book = nil
                        logger.dbg("HighlightImport: manual_book cleared (auto-match)")
                    else
                        instance.manual_book = book.title
                        logger.dbg("HighlightImport: manual_book set → " .. book.title)
                    end
                    -- Invalidate cached parse result so next Import re-reads with new selection
                    instance.targets = {}
                    instance._cached_file_path   = nil
                    instance._cached_manual_book = nil

                    local pg = ctx["modalRef"] and ctx["modalRef"].page or 1
                    UIManager:close(ctx["modalRef"])
                    recreate(pg)
                end,
            }
        end

        -- Clear selection button
        if instance.manual_book then
            modalEntries[#modalEntries + 1] = {
                text = _("[ Clear selection — use automatic matching ]"),
                callback = function()
                    instance.manual_book = nil
                    instance.targets = {}
                    instance._cached_file_path   = nil
                    instance._cached_manual_book = nil
                    logger.dbg("HighlightImport: manual_book cleared")
                    UIManager:close(ctx["modalRef"])
                    recreate(1)
                end,
            }
        end

        local buttonTable = ButtonTable:new{
            buttons = {{
                { text = _("Close"), callback = function() useCloseButton(ctx) end },
            }}
        }

        local title_str = _("Select source book")
        if instance.manual_book then
            local short = instance.manual_book:sub(1, 40)
            if #instance.manual_book > 40 then short = short .. "…" end
            title_str = title_str .. ": " .. short
        end

        local modal = Modal(title_str, modalEntries, buttonTable)
        ctx["modalRef"] = modal
        ctx["parent"]   = modal

        UIManager:show(modal)
        modal:onGotoPage(page)
        logger.dbg("HighlightImport: FilePick modal opened with " .. #books .. " books")
    end

    recreate()
end

return FilePick

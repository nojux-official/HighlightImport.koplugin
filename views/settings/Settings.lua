local _ = require("gettext")

function GetSettings(instance)
    return {
        {
            text = _("On fail: save unmatched to file"),
            checked_func = function()
                return G_reader_settings:isTrue("highlight_import_save_unmatched_file")
            end,
            callback = function()
                G_reader_settings:saveSetting("highlight_import_save_unmatched_file",
                    not G_reader_settings:isTrue("highlight_import_save_unmatched_file"))
            end,
            keep_menu_open = true,
        },
        {
            text = _("On fail: add note in book"),
            checked_func = function()
                return G_reader_settings:isTrue("highlight_import_note_in_book")
            end,
            callback = function()
                G_reader_settings:saveSetting("highlight_import_note_in_book",
                    not G_reader_settings:isTrue("highlight_import_note_in_book"))
            end,
            keep_menu_open = true,
        },
    }
end

return GetSettings
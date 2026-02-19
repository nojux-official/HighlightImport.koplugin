local _ = require("gettext")

return function (instance)
    return {
        text = _("Highlight Import"),
        sorting_hint = "typeset", -- or tools
        sub_item_table = {
            {
                text = _("Select file"),
                -- keep_menu_open = true,
                callback = function()
                    instance:chooseFile()
                end,
            },
            {
                text_func = function()
                    return instance.file_path ~= "" and ">Import<" or "Import"
                end,
                callback = function()
                    if(instance.file_path == "") then
                        instance:chooseFile()
                    end
                    instance:alert("Importing from: "..instance.file_path)

                    instance:import(instance.file_path)
                    return true
                end,
            },
            {
                text =  _("Status"),
                callback = function()
                    -- highlights on document (no need to show)
                    -- highlights on clippings but not on document (to be imported)
                    -- highlights on clippings (but cannot be mapped to document)
                    -- imported highlights (they intersect between documents and the clippings)
                    -- scanning progress
                    -- stats, diagram, etc.

                    return true
                end,
            },
            {
                text = _("Settings"),
                callback = function()
                    return true
                end,
            },
            {
                text = _("About"),
                keep_menu_open = true,
                callback = function()
                    UIManager:show(InfoMessage:new{
                        text = _("A plugin to import your highlights from various formats. Check the plugin Github repo for more info."),
                    })
                end,
            },
        },
    }
end
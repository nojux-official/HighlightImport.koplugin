function HighlightImport:addToMainMenu(menu_items)
    menu_items.higligh_import_plugin = {
        text = _("Highlight Import"),
        sorting_hint = "typeset", -- or tools
        sub_item_table ={
            {
                text = _("Select file"),
                -- keep_menu_open = true,
                callback = function()
                    self:chooseFile()
                end,
            },
            {
                text_func = function()
                    return self.file_path ~= "" and ">Import<" or "Import"
                end,
                callback = function()
                    if(self.file_path == "") then
                        self:chooseFile()
                    end
                    self:alert("Importing from: "..self.file_path)

                    self:import(self.file_path)
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
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local _ = require("gettext")


local fileSelector = require("components/fileSelector")
local alert = require("components/alert")

function getMenu(instance)
    return {
        text = _("Highlight Import"),
        sorting_hint = "typeset", -- or tools
        sub_item_table = {
            {
                text = _("Select file"),
                -- keep_menu_open = true,
                callback = function()
                    fileSelector(instance)
                end,
            },
            {
                text_func = function()
                    return instance.file_path ~= "" and ">Import<" or "Import"
                end,
                callback = function()
                    if(instance.file_path == "") then
                        alert("Select the source file first.")
                        return true
                    else
                        alert("Importing from: "..instance.file_path)
                        -- instance:import(instance.file_path)
                    end
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
                    alert("Not implemented yet.")
                    return true
                end,
            },
            {
                text = _("Browse file highlights"),
                callback = function()
                    alert("Not implemented yet.")
                    return true
                end,
            },
            {
                text = _("Failed matches"),
                callback = function()
                    alert("Not implemented yet.")
                    return true
                end,
            },
            {
                text = _("Settings"),
                callback = function()
                    alert("Not implemented yet.")
                    return true
                end,
            },
            {
                text = _("About"),
                keep_menu_open = true,
                callback = function()
                    alert("A plugin to import your highlights from various formats. Check the plugin Github repo for more info.")
                end,
            },
        },
    }
end

return getMenu
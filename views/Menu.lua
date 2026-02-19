local _ = require("gettext")

local ImportsView = require("views.Imports")
local AnnotationsView = require("views.annotations.Annotations")
local FailedTargetsView = require("views.FailedTargets")
local getSettings = require("views.settings.Settings")
local fileSelector = require("components.fileSelector")
local Alert = require("components.Alert")
local Popup = require("components.Popup")


function GetMenu(instance)
    return
    {
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
            callback = ImportsView
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
                Popup("Import status", [[
Importing from /ff/dsd/.../book.txt
Status: in progress
Suceeded: 100
Skipped: 15
Failed: 2
Remaining: 50
Elapsed time: 20 s

]])
                -- alert("Not implemented yet.")
                return true
            end,
        },
        {
            text = _("Browse file highlights"),
            callback = AnnotationsView
        },
        {
            text = _("Failed matches"),
            callback = FailedTargetsView
        },
        {
            text = _("Settings"),
            keep_menu_open = true,
            sub_item_table = getSettings(instance)
        },
        {
            text = _("About"),
            keep_menu_open = true,
            callback = function()
                Alert("A plugin to import your highlights from various formats. Check the plugin Github repo for more info.")
            end,
        },
    }
end

return GetMenu
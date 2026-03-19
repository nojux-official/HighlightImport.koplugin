local PathChooser = require("ui/widget/pathchooser")
local UIManager = require("ui/uimanager")


function fileSelector(instance)
    local path_chooser = PathChooser:new{
        select_directory = false,
        path = (instance.last_path ~= "" and instance.last_path) or "/mnt/us/documents",
        onConfirm = function(file_path)
            instance.file_path           = file_path
            instance.last_path           = file_path:match("(.*)/")
            -- A new clippings file means any previous manual book choice is stale.
            instance.manual_book         = nil
            instance._cached_file_path   = nil
            instance._cached_manual_book = nil
            instance.targets             = {}
            instance.available_books     = nil
            G_reader_settings:saveSetting("highlight_import_file_path", file_path)
            G_reader_settings:saveSetting("highlight_import_last_path", instance.last_path)
        end
    }
    UIManager:show(path_chooser)
end

return fileSelector
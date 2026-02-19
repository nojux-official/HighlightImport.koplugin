local PathChooser = require("ui/widget/pathchooser")
local UIManager = require("ui/uimanager")


function fileSelector(instance)
    local path_chooser = PathChooser:new{
        select_directory = false,
        path = instance.last_path,
        onConfirm = function(file_path)
            instance.file_path = file_path
            instance.last_path = file_path:match("(.*)/")
            if instance.last_path == "" then instance.last_path = "/" end
        end
    }
    UIManager:show(path_chooser)
end

return fileSelector
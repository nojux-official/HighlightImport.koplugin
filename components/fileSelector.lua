local PathChooser = require("ui/widget/pathchooser")
local UIManager = require("ui/uimanager")

function HighlightImport:chooseFile()
    local path_chooser = PathChooser:new{
        select_directory = false,
        path = self.last_path,
        onConfirm = function(file_path)
            self.file_path = file_path
            self.last_path = file_path:match("(.*)/")
            if self.last_path == "" then self.last_path = "/" end
        end
    }
    UIManager:show(path_chooser)
end
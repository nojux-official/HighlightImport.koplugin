local _ = require("gettext")

local UIManager = require("ui/uimanager")

return function(dialog)
    return
    {  
        { text = "Background", callback = function() UIManager:close(dialog) end },
        { text = "Browse", callback = function() UIManager:close(dialog) end },
        { text = "Cancel", callback = function() UIManager:close(dialog) end }, 
    }
end
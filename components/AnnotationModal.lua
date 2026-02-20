local _ = require("gettext")
local UIManager = require("ui/uimanager")  
local TextViewer = require("ui/widget/textviewer")  

-- local Size = require("ui/size")  
-- local Device = require("device")
-- local Font = require("ui/font")
-- local Screen = Device.screen

function AnnotationModal(title, content, prev_item, next_item, current, total)
    if not prev_item then prev_item = "" end
    if not next_item then next_item = "" end
    if not current then current = 0 end
    if not total then total=1 end
    

    local textviewer = TextViewer:new{  
        title = title,  
        text = content,  
        text_type = "bookmark", -- "general", "code"
        buttons_table = {  
            {  
                {text = "◁", enabled = current > 1, callback = prev_item},  
                {text = "▷", enabled = current < total, callback = next_item},  
                {text = "▷", enabled = current < total, callback = next_item},  
            },
            {  
                {text = "◁", enabled = current > 1, callback = prev_item},  
                {text = "▷", enabled = current < total, callback = next_item},  
                {text = "▷", enabled = current < total, callback = next_item},  
            }    
        }  
    }  
    UIManager:show(textviewer)
end

return AnnotationModal
local _ = require("gettext")
local Menu = require("ui/widget/menu")  
local UIManager = require("ui/uimanager")  
local Size = require("ui/size")  
local Device = require("device")
local Font = require("ui/font")
local Screen = Device.screen

function Modal(title, content)
    
    local content = Menu:new{  
        items = content,  
        width = math.floor(Screen:getWidth() * 0.8),  
        face = Font:getFace("infofont"),  
    }  

    
    local menu = Menu:new{  
        title = title,  
        item_table = {  
            {text = "Item 1"},  
            {text = "Item 2"},  
            -- ... more items  
        },  
        items_per_page = 10,  
        covers_fullscreen = true,  
        is_borderless = true,  
        is_popout = false,  
    }  
    UIManager:show(menu)

end

return Modal
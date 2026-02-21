local _ = require("gettext")
local Device = require("device")
local Screen = Device.screen

local UIManager = require("ui/uimanager")  
local ButtonTable = require("ui/widget/buttontable")
local Size = require("ui/size")  
local Font = require("ui/font")
local Menu = require("components.MenuWidget")


function Modal(title, items)
        
    local menu = Menu:new{  
        title = title,  
        item_table = items,  
        button_table = ButtonTable:new{  
            buttons = {{
                {text="Import all", callback=function() end},
                {text="Import selected", callback=function() end},
                {text="Toggle browsing", callback=function() end},
            }}
        },
        items_per_page = 10,  
        covers_fullscreen = true,  
        is_borderless = true,  
        is_popout = false,
    }  
    return menu
end

return Modal
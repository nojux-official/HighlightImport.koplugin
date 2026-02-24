local _ = require("gettext")
local Device = require("device")
local Screen = Device.screen

local UIManager = require("ui/uimanager")  
local ButtonTable = require("ui/widget/buttontable")
local Size = require("ui/size")  
local Font = require("ui/font")
local Menu = require("components.MenuWidget")


function Modal(title, items, buttonTable)
    if(buttonTable == nil) then
        buttonTable = ButtonTable:new{ buttons = {} }
    end

    ctx = {}
        
    local menu = Menu:new{  
        title = title,  
        item_table = items,  
        button_table = buttonTable,
        items_per_page = 10,  
        covers_fullscreen = true,  
        is_borderless = true,  
        is_popout = false,
    }  

    ctx.parent = menu

    return menu
end

return Modal
local _ = require("gettext")
local ButtonDialog = require("ui/widget/buttondialog")  
local UIManager = require("ui/uimanager")  
local TextBoxWidget = require("ui/widget/textboxwidget")  
local VerticalGroup = require("ui/widget/verticalgroup")  
local Size = require("ui/size")  
local Device = require("device")
local Font = require("ui/font")
local Screen = Device.screen

function Popup(title, content, buttons)
    
    local content = VerticalGroup:new{  
        TextBoxWidget:new{  
            text = content,  
            width = math.floor(Screen:getWidth() * 0.8),  
            face = Font:getFace("infofont"),  
        },  
    }  

    local popupDialog = ButtonDialog:new{  
        title = title,  
        _added_widgets = { content },  
        buttons = { buttons },  
        modal = true,  
        dismissable = true,  
    }
    return popupDialog

end

return Popup
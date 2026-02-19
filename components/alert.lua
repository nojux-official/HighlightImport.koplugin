local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")

function HighlightImport:alert(msg)

    local sample
    sample = InfoMessage:new{
        text = _(msg),
        show_icon = false,
        timeout = 5,
    }
    UIManager:show(sample)
end
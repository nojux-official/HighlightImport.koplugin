local _ = require("gettext")
local ParseClippings = require("utils.ParseClippings")

local logger = require("logger")

local UIManager = require("ui/uimanager")
local AnnotationView = require("views.annotations.Annotation")
local Alert = require("components.Alert")
local Modal = require("components.Modal")

function AnnotationsView(instance)

    ParseClippings(instance)

    local modalEntries = {}

    for idx, target in ipairs(instance.targets) do
    
        modalEntries[#modalEntries + 1] = {
            text = target.annotation,
            callback = function()  
                AnnotationView(instance, idx)
            end
        }
    end

    local modal = Modal(_("Annotations (file)"), modalEntries)
    UIManager:show(modal)
end

return AnnotationsView
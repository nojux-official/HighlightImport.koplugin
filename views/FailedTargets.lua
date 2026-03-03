local _ = require("gettext")
local logger = require("logger")
local ITargetStatus = require("interfaces.ITargetStatus")
local ParseClippings = require("utils.ParseClippings")


local UIManager = require("ui/uimanager")
local AnnotationView = require("views.annotations.Annotation")
local Alert = require("components.Alert")
local Modal = require("components.Modal")


function FailedTargetsView(instance)
    local modal = Modal(_("Failed targets"), {})

    -- ParseClippings(instance)
    if instance.targets == nil then 
        instance.targets = {}
        Alert(_("No targets found in the file."))
        return
    end

    local modalEntries = {}

    for idx, target in ipairs(instance.targets) do
        if target.status ~= ITargetStatus.FAILED then
            goto continue
        end
        
        modalEntries[#modalEntries + 1] = {
            text = target.annotation
        }

        ::continue::
    end

    local modal = Modal(_("Annotations (file)"), modalEntries)
    UIManager:show(modal)


end

return FailedTargetsView
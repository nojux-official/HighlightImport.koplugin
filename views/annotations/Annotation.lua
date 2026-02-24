local _ = require("gettext")
local ParseClippings = require("utils.ParseClippings")


local AnnotationModal = require("components.AnnotationModal")

function AnnotationView(instance, idx)
    if idx == nil then idx = 1 end

    ParseClippings(instance)



    AnnotationModal(_("Browse"), _(instance.targets[idx].annotation), "", "", idx, #instance.targets)
end

return AnnotationView
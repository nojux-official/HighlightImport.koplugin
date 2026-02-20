local _ = require("gettext")
local MyClipping = require("services.MyClipping")
local logger = require("logger")


local UIManager = require("ui/uimanager")
local AnnotationView = require("views.annotations.Annotation")
local Alert = require("components.Alert")
local modal = require("components.Modal")

function ImportsView(instance)



    local modalEntries = {}
    
    local clippings = instance.parser:parseFile(instance.file_path)

    if type(clippings) ~= "table" then return end
    
    for _title, booknotes in pairs(clippings) do
        if type(booknotes) ~= "table" or #booknotes == 0 then
        else
            for _, entry in ipairs(booknotes) do
                if entry[1].sort == "highlight" then 
                    local query = entry[1].text
                    modalEntries[#modalEntries + 1] = {
                        text = query,
                        callback = function()  
                            Alert("Clicked: " .. query)
                        end,
                    }
                end
            end
        end
    end

    modal(_("Annotations (file)"), modalEntries)
end

return ImportsView
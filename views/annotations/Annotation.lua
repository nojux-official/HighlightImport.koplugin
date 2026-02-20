local _ = require("gettext")
local MyClipping = require("services.MyClipping")

local AnnotationModal = require("components.AnnotationModal")

function AnnotationView(instance)

    -- local modalEntries = {}
    
    -- local clippings = instance.parser:parseFile(instance.file_path)

    -- if type(clippings) ~= "table" then return end
    
    -- for _title, booknotes in pairs(clippings) do
    --     if type(booknotes) ~= "table" or #booknotes == 0 then
    --     else
    --         for _, entry in ipairs(booknotes) do
    --             if entry[1].sort == "highlight" then 
    --                 local query = entry[1].text
    --                 modalEntries[#modalEntries + 1] = { text = query }
    --             end
    --         end
    --     end
    -- end
            
    --  MyClipping:getClippingsFromBook(clippings, instance.file_path)


    AnnotationModal(_("Browse"), _("Sample Annotation Text"), "", "", 1, 1)
end

return AnnotationView
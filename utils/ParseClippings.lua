local _ = require("gettext")
local MyClipping = require("services.MyClipping")
local logger = require("logger")

local ITargetStatus = require("interfaces.ITargetStatus")

return function (instance)
    if(not instance.targets == nil) then return instance.targets end

    instance.targets = {}

    local clippings = instance.parser:parseFile(instance.file_path)

    if type(clippings) ~= "table" then return end
    
    for _title, booknotes in pairs(clippings) do
        if type(booknotes) ~= "table" or #booknotes == 0 then
        else
            for _, entry in ipairs(booknotes) do
                if entry[1].sort == "highlight" then 
                    local query = entry[1].text
                    instance.targets[#instance.targets + 1] = {
                        annotation = query,
                        status = ITargetStatus.ADDED
                    }
                end
            end
        end
    end

    logger.dbg(string.format("HighlightImport: Parsed %d clippings.",  #instance.targets))


    return instance.targets
end
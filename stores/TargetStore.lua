local Annotation = require("interfaces.Annotation")
local ITargetStatus = require("interfaces.ITargetStatus")
local logger = require("logger")


local TargetStore = {
    data = {},
    db = nil,
    parser = nil,
}

function TargetStore:new(o)
    if o == nil then o = {} end
    setmetatable(o, self)
    self.__index = self
    return o
end

function TargetStore:loadFromClippings(file_path)
    local clippings = self.parser:parseFile(file_path)

    if type(clippings) ~= "table" then return end
    for _title, booknotes in pairs(clippings) do
        if type(booknotes) ~= "table" or #booknotes == 0 then
        else
            for _, entry in ipairs(booknotes) do
                if entry[1].sort == "highlight" then 
                    local query = entry[1].text
                    self.data[#self.data + 1] = {
                        highlight = query,
                        status = ITargetStatus.ADDED
                    }
                end
            end
        end
    end

    logger.dbg(string.format("HighlightImport: Parsed %d clippings.",  #self.data))
end

-- function TargetStore:add(annotation)
-- end

-- function TargetStore:remove(annotation)
-- end

function TargetStore:commit()
    -- for idx, value in ipairs(self.targets) do
    
    self.db:postCollection("annotation", {
        highlight = "higlight",
        status = "1",
        note = "note1",
        pos1 = "pos1",
        pos2 = "pos2"
    })
    -- }

end

-- function TargetStore:revert()

return TargetStore
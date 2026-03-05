local Annotation = require("interfaces.Annotation")
local ITargetStatus = require("interfaces.ITargetStatus")

local TargetStore = {
    db = nil,
    targets = {},
    parser = nil,
}

function TargetStore:extend(subclass_prototype)
    local o = subclass_prototype or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function TargetStore:new(instance, o)
    o = self:extend(o)
    if o.init then o:init(instance) end
    return o
end

function TargetStore:init(instance)
    self.db = instance.db
    self.parser = instance.parser
end

function TargetStore:loadFromClippings()
    self.targets = {}

    local clippings = self.parser:parseFile(instance.file_path)

    if type(clippings) ~= "table" then return end
    for _title, booknotes in pairs(clippings) do
        if type(booknotes) ~= "table" or #booknotes == 0 then
        else
            for _, entry in ipairs(booknotes) do
                if entry[1].sort == "highlight" then 
                    local query = entry[1].text
                    self.targets[#self.targets + 1] = {
                        highlight = query,
                        status = ITargetStatus.ADDED
                    }
                end
            end
        end
    end

    logger.dbg(string.format("HighlightImport: Parsed %d clippings.",  #instance.targets))


    return instance.targets
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
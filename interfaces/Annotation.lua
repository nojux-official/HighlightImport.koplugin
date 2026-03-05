local Annotation = {
    id = nil,
    status = nil,
    highlight = nil,
    pos1 = nil,
    pos2 = nil,
    
}

function Annotation:extend(subclass_prototype)
    local o = subclass_prototype or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Annotation:new(o)
    o = self:extend(o)
    if o.init then o:init() end
    return o
end

function Annotation:init()
end

return Annotation
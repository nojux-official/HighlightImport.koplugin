local MyClipping = require("clip")
local Math = require("optmath")

local _ = require("gettext")
local logger = require("logger")

local Document = {}

function Document:new(instance)
    local obj = {instance = instance}
    setmetatable(obj, self)
    self.__index = self
    return obj
end


function Document:IsDocReady()
    return self.instance.document and true or false
end

function Document:GetLastPercent()
    if self.instance.ui.document.info.has_pages then
        return Math.roundPercent(self.instance.ui.paging:getLastPercent())
    else
        return Math.roundPercent(self.instance.ui.rolling:getLastPercent())
    end
end

function Document:GetLastProgress()
    if self.instance.ui.document.info.has_pages then
        return self.instance.ui.paging:getLastProgress()
    else
        return self.instance.ui.rolling:getLastProgress()
    end
end

function Document:CreateHighlightFromXPointer(start_xp, end_xp, text, note_text)
    self.instance.ui.highlight.selected_text = {
        text = text,
        pos0 = start_xp,
        pos1 = end_xp,
        note = note_text or nil,
    }
    local index = self.instance.ui.highlight:saveHighlight(true)
    self.instance.ui.highlight:clear()
    return index
end



function Document:LoadNativeHighlights()
    if not self:IsDocReady() then return end
    self.instance.ui.annotation:updatePageNumbers(true)
    local clippings = self.instance.parser:parseCurrentDoc()
    self.instance.parser:serializeClippings(clippings)
end

return Document
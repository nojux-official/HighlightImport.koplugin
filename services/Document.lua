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
    local ui = self.instance.ui
    
    local annotation_item = {
        text = text,
        note = note_text and note_text ~= "" and note_text ~= text and note_text or nil,
        pos0 = start_xp,
        pos1 = end_xp,
        page = start_xp,  -- xPointer for EPUB rolling view
        drawer = "highlight",
        color = "yellow",      -- Default highlight color
    }
    
    -- Add to the annotation store directly
    -- addItem automatically:
    -- - Sets datetime if not provided
    -- - Computes pageno and pageref from xPointer
    -- - Triggers AnnotationsModified event
    local index = ui.annotation:addItem(annotation_item)
    
    ui.annotation:onSaveSettings()
    
    return index
end



function Document:LoadNativeHighlights()
    if not self:IsDocReady() then return end
    self.instance.ui.annotation:updatePageNumbers(true)
    local clippings = self.instance.parser:parseCurrentDoc()
    self.instance.parser:serializeClippings(clippings)
end

return Document
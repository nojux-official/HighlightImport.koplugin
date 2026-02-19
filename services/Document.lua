local MyClipping = require("clip")
local Math = require("optmath")

local _ = require("gettext")
local logger = require("logger")


function HighlightImport:isDocReady()
    return self.document and true or false
end

function HighlightImport:getLastPercent()
    if self.ui.document.info.has_pages then
        return Math.roundPercent(self.ui.paging:getLastPercent())
    else
        return Math.roundPercent(self.ui.rolling:getLastPercent())
    end
end

function HighlightImport:getLastProgress()
    if self.ui.document.info.has_pages then
        return self.ui.paging:getLastProgress()
    else
        return self.ui.rolling:getLastProgress()
    end
end

function HighlightImport:createHighlightFromXPointer(start_xp, end_xp, text)
    self.ui.highlight.selected_text = {
        text = text,
        pos0 = start_xp,
        pos1 = end_xp,
        -- For rolling (EPUB/etc)
        -- sboxes = self.document:getScreenBoxesFromPositions(start_xp, end_xp)
    }
    
    local index = self.ui.highlight:saveHighlight(true)
    
    self.ui.highlight:clear()
    
    return index
end



function HighlightImport:loadNativeHighlights()
    if not self:isDocReady() then return end
    self.ui.annotation:updatePageNumbers(true)
    local clippings = self.parser:parseCurrentDoc()
    self:serializeClippings(clippings)
end

function HighlightImport:serializeClippings(clippings)
    if type(clippings) ~= "table" then return end
    local exportables = {}
    for _title, booknotes in pairs(clippings) do
        table.insert(exportables, booknotes)
    end
    if #exportables == 0 then
        UIManager:show(InfoMessage:new{ text = _("No highlights to export") })
        return
    end
    local timestamp = os.time()
    for i, clipping in ipairs(exportables) do
        logger.dbg("Clipping " .. i .. ": " .. tostring(clipping))
    end

    return RapidJSON.encode(exportables, { indent = true })
end


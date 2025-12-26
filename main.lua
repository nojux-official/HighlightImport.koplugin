local Widget = require("ui/widget/widget")
local PathChooser = require("ui/widget/pathchooser")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local RapidJSON = require("rapidjson")
local MyClipping = require("clip")
local Math = require("optmath")

local _ = require("gettext")
local logger = require("logger")
-- require("import")


--[=====[
  #####  ####### ####### #     # ######  
 #     # #          #    #     # #     # 
 #       #          #    #     # #     # 
  #####  #####      #    #     # ######  
       # #          #    #     # #       
 #     # #          #    #     # #       
  #####  #######    #     #####  #       
                                         
]=====]

local HighlightImport = Widget:extend{
    name = "Highlight Import",
    last_path = "/home/nojus/Desktop/JP_test/",
    file_path = "/home/nojus/Desktop/JP_test/My Clippings.txt"
}

function HighlightImport:init()
    self.parser = MyClipping:new{ ui = self.ui }
end

function HighlightImport:onReaderReady()

    local lastPercent = self:getLastPercent()
    local lastProgress = self:getLastProgress()
    local xpointer = "/body/DocFragment[14]/body/div[1]/p[56]/span[1]/text().0"
    local xpointerText = self.document:getTextFromXPointer(xpointer)
    logger.dbg("HighlightImport: Last percent: " .. lastPercent)
    logger.dbg("HighlightImport: Last progress: " .. lastProgress)
    logger.dbg("HighlightImport: Xpointer text: " .. xpointerText)
    
    self.ui.menu:registerToMainMenu(self)
    
end


function HighlightImport:isDocReady()
    return self.document and true or false
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

--[=====[
 #     # ### 
 #     #  #  
 #     #  #  
 #     #  #  
 #     #  #  
 #     #  #  
  #####  ### 
             
]=====]

function HighlightImport:alert(msg)

    local sample
    sample = InfoMessage:new{
        text = _(msg),
        show_icon = false,
        timeout = 5,
    }
    UIManager:show(sample)
end



function HighlightImport:chooseFile()
    local path_chooser = PathChooser:new{
        select_directory = false,
        path = self.last_path,
        onConfirm = function(file_path)
            self.file_path = file_path
            self.last_path = file_path:match("(.*)/")
            if self.last_path == "" then self.last_path = "/" end
        end
    }
    UIManager:show(path_chooser)
end



function HighlightImport:addToMainMenu(menu_items)
    menu_items.higligh_import_plugin = {
        text = _("Highlight Import"),
        sorting_hint = "typeset", -- or tools
        sub_item_table ={
            {
                text = _("1. Select file"),
                -- keep_menu_open = true,
                callback = function()
                    self:chooseFile()
                end,
            },
            {
                text_func = function()
                    return self.file_path ~= "" and ">Import<" or "Import"
                end,
                callback = function()
                    if(self.file_path == "") then
                        self:chooseFile()
                    end
                    self:alert("Importing from: "..self.file_path)

                    local importables = self:import(self.file_path)
                    self:alert(importables)
                    return true
                end,
            },
            {
                text =  _("2. List doc highlights"),
                callback = function()
                    self:loadNativeHighlights()
                    return true
                end,
            },
            {
                text =  _("3. Parse highlights (file)"),
                callback = function()
                    if(self.file_path == "") then
                        self:chooseFile()
                    end
                    local clippings = self.parser:parseFile(self.file_path)
                    local serialized = self:serializeClippings(clippings)
                    self:alert(serialized)

                    return true
                end,
            },
            {
                text =  _("4. Create Highlight"),
                callback = function()
                    -- user selected text
                    -- using builtin search and retrieving indexes
                    -- retrieving text on screen and selecting it
                    -- using random indexes

                    local xpointer = "/body/DocFragment[14]/body/div[1]/p[56]/span[1]/text().0"
                    local xpointer2 = "/body/DocFragment[14]/body/div[1]/p[56]/span[1]/text().12"
                    local xpointerText = self.document:getTextFromXPointers(xpointer, xpointer2)

                    self:createHighlightFromXPointer(xpointer, xpointer2, xpointerText)
                    return true
                end,
            },
            {
                text =  _("5. Comparison"),
                callback = function()
                    -- highlights on document (no need to show)
                    -- highlights on clippings but not on document (to be imported)
                    -- highlights on clippings (but cannot be mapped to document)
                    -- imported highlights (they intersect between documents and the clippings)
                    -- scanning progress
                    -- stats, diagram, etc.

                    return true
                end,
            },
            {
                text = _("Settings"),
                callback = function()
                    return true
                end,
            },
            {
                text = _("About"),
                keep_menu_open = true,
                callback = function()
                    UIManager:show(InfoMessage:new{
                        text = _("A plugin to import your highlights from various formats. Check the plugin Github repo for more info."),
                    })
                end,
            },
        },
    }
end

--[=====[
 #     # ####### ### #       
 #     #    #     #  #       
 #     #    #     #  #       
 #     #    #     #  #       
 #     #    #     #  #       
 #     #    #     #  #       
  #####     #    ### ####### 
                                                                         
]=====]

function HighlightImport:reload()
    logger.dbg("Trying to reload.")
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

function HighlightImport:import(file_path)

    --[=====[
    load my_clippings

    loop foreach through my_clippings {
        search for entry
        obtain xpath start-end indexes
        highlight 
    }
    --]=====]


    if not self:isDocReady() then return end
    
    local clippings = self.parser:parseFile(file_path)

    -- return self:serializeClippings(clippings)
    if type(clippings) ~= "table" then return end
    
    local failures = 0
    local successes = 0
    for _title, booknotes in pairs(clippings) do
        if type(booknotes) ~= "table" or #booknotes == 0 then
            goto continueOuter
        end

        for _, entry in ipairs(booknotes) do
            local serialized = RapidJSON.encode(entry, { indent = true })
            logger.dbg("Entry: " .. tostring(serialized))
            if entry[1].sort ~= "highlight" then 
                failures = failures + 1
                goto continueInner
            end

            local query = entry[1].text
            logger.dbg("HighlightImport: Processing " .. query)
            -- pattern, origin, direction, case_insensitive, page, regex, max_hits
            local res = self.document:findText(query, -1, 0, true, 1, false, 1)
            if not res or #res == 0 then
                logger.dbg("HighlightImport: Failed to find text: " .. query)
                failures = failures + 1
                goto continueInner
            end
            local xpointer_start = res[1].start
            local xpointer_end = res[1]["end"]
            logger.dbg("HighlightImport: Found text at: " .. xpointer_start .. " to " .. xpointer_end)
            
            self:createHighlightFromXPointer(xpointer_start, xpointer_end, query)
  
            successes = successes + 1
            ::continueInner::
        end
        
        ::continueOuter::
    end

    logger.dbg("HighlightImport: successes: " .. successes .. ", failures: " .. failures)



end


return HighlightImport

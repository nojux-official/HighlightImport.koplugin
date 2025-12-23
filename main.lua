local Widget = require("ui/widget/widget")
local PathChooser = require("ui/widget/pathchooser")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local RapidJSON = require("rapidjson")
local MyClipping = require("clip")
local Math = require("optmath")

local _ = require("gettext")
local logger = require("logger")


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
    last_path = "",
    file_path = ""
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
    return self.document and self.ui.annotation:hasAnnotations() and true or false
end

function HighlightImport:onExportCurrentNotes()
    if not self:isDocReady() then return end
    self.ui.annotation:updatePageNumbers(true)
    local clippings = self.parser:parseCurrentDoc()
    self:exportClippings(clippings)
end

function HighlightImport:exportClippings(clippings)
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

    local serialized = RapidJSON.encode(exportables, { indent = true })

    self:alert(serialized)

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
                    return true
                end,
            },
            {
                text =  _("2. List doc highlights"),
                callback = function()
                    self:onExportCurrentNotes()
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
                    self:exportClippings(clippings)
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

return HighlightImport

local Widget = require("ui/widget/widget")
local PathChooser = require("ui/widget/pathchooser")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local RapidJSON = require("rapidjson")
local MyClipping = require("clip")

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

local HiglightImport = Widget:extend{
    name = "Highlight Import",
    last_path = "",
    file_path = ""
}

function HiglightImport:init()
    self.parser = MyClipping:new{ ui = self.ui }
end

function HiglightImport:onReaderReady()
    self.ui.menu:registerToMainMenu(self)
end


function HiglightImport:isDocReady()
    return self.document and self.ui.annotation:hasAnnotations() and true or false
end

function HiglightImport:onExportCurrentNotes()
    if not self:isDocReady() then return end
    self.ui.annotation:updatePageNumbers(true)
    local clippings = self.parser:parseCurrentDoc()
    self:exportClippings(clippings)
end

function HiglightImport:exportClippings(clippings)
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

function HiglightImport:alert(msg)

    local sample
    sample = InfoMessage:new{
        text = _(msg),
        show_icon = false,
        timeout = 5,
    }
    UIManager:show(sample)
end



function HiglightImport:chooseFile()
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



function HiglightImport:addToMainMenu(menu_items)
    menu_items.higligh_import_plugin = {
        text = _("Higlight Import"),
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

function HiglightImport:reload()
    logger.dbg("Trying to reload.")
end

return HiglightImport

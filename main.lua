local Widget = require("ui/widget/widget")
local PathChooser = require("ui/widget/pathchooser")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")

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
    -- self.ui.menu:registerToMainMenu(self)
    -- self:printUI("Hello!")
end

function HiglightImport:onReaderReady()
    self.ui.menu:registerToMainMenu(self)
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


function HiglightImport:ShowFileDialog()

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
                text = _("Select file"),
                -- keep_menu_open = true,
                callback = function()
                    self:chooseFile()
                end,
            },
            {
                text_func = function()
                    return self.last_path ~= "" and ">Import<" or "Import"
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

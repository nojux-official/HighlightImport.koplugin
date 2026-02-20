local Widget = require("ui/widget/widget")
local _ = require("gettext")
local logger = require("logger")
local MyClipping = require("services.MyClipping")

local getMenu = require("views/Menu")
local UIManager = require("ui/uimanager")  
local AnnotationsView = require("views.annotations.Annotations")
local AnnotationView = require("views.annotations.Annotation")


local HighlightImport = Widget:extend{
    name = "Highlight Import",
    file_path = "/home/nojus/Desktop/JP_test/My Clippings.txt",
    
}

function HighlightImport:init()
    self.parser = MyClipping:new{ ui = self.ui }
end

function HighlightImport:onReaderReady()

    self.ui.menu:registerToMainMenu(self)

    UIManager:nextTick(function()
        AnnotationsView(self)
        -- AnnotationView(self)    
    end)
end

function HighlightImport:addToMainMenu(menu_items)
    menu_items.highlight_import_plugin = 
    {
        text = _("Highlight Import"),
        sorting_hint = "typeset", -- or tools
        sub_item_table = getMenu(self)
    }
end









return HighlightImport

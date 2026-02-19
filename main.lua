local Widget = require("ui/widget/widget")
local _ = require("gettext")
local logger = require("logger")
local MyClipping = require("services.MyClipping")

local getMenu = require("views/Menu")


local HighlightImport = Widget:extend{
    name = "Highlight Import",
    file_path = "",
    
}

function HighlightImport:init()
    self.parser = MyClipping:new{ ui = self.ui }
end

function HighlightImport:onReaderReady()

    self.ui.menu:registerToMainMenu(self)
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

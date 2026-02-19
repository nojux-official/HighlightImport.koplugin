local Widget = require("ui/widget/widget")
local _ = require("gettext")
local logger = require("logger")

local getMenu = require("views/Menu")


local HighlightImport = Widget:extend{
    name = "Highlight Import",
    file_path = ""
    
}

function HighlightImport:init()

end

function HighlightImport:onReaderReady()

    self.ui.menu:registerToMainMenu(self)
end

function HighlightImport:addToMainMenu(menu_items)
    menu_items.highlight_import_plugin = getMenu(self)
end









return HighlightImport

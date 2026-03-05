local Widget = require("ui/widget/widget")
local _ = require("gettext")
local logger = require("logger")
local MyClipping = require("services.MyClipping")
local Import = require("services.LocalMatching")
local DB = require("services.Db")
local TargetStore = require("stores.TargetStore")

local getMenu = require("views/Menu")
local UIManager = require("ui/uimanager")
local ReaderUI = require("apps/reader/readerui")

local AnnotationsView = require("views.annotations.Annotations")
local AnnotationView = require("views.annotations.Annotation")
local ImportsView = require("views.Imports")
local StatusPopup = require("components.StatusPopup")


local HighlightImport = Widget:extend{
    name = "Highlight Import",
    file_path = "/home/studentas/projects/HighlightImport.koplugin/stuff/clippingsAll.txt",
    targets = {},
    db = nil
}

function HighlightImport:init()
    self.parser = MyClipping:new{ ui = self.ui }
    self.db = DB:new{}
    self.targets = TargetStore:new{ db = self.db, parser = self.parser }
end

function HighlightImport:onReaderReady()

    self.ui.menu:registerToMainMenu(self)

    self.targets:loadFromClippings(self.file_path)
    self.targets:commit()

    UIManager:nextTick(function()
        -- AnnotationsView(self)
        -- AnnotationView(self)    
        -- ImportsView(self)
        -- StatusPopup()

    end)

    -- Import(self)
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

local Widget = require("ui/widget/widget")
local _ = require("gettext")
local logger = require("logger")
local MyClipping = require("services.MyClipping")

local getMenu = require("views/Menu")
local UIManager = require("ui/uimanager")
local ReaderUI = require("apps/reader/readerui")  

local AnnotationsView = require("views.annotations.Annotations")
local AnnotationView = require("views.annotations.Annotation")
local ImportsView = require("views.Imports")
local StatusPopup = require("components.StatusPopup")
local FileSelector = require("components.fileSelector")

local PLUGIN_SETTINGS_KEYS = {
    "highlight_import_file_path",
    "highlight_import_last_path",
    "highlight_import_matching_algorithm",
    "highlight_import_save_unmatched_file",
    "highlight_import_note_in_book",
}


local HighlightImport = Widget:extend{
    name = "Highlight Import",
    file_path = "",
    targets = {},
    
}

function HighlightImport:init()
    self.parser = MyClipping:new{ ui = self.ui }
    self.file_path = G_reader_settings:readSetting("highlight_import_file_path") or ""
    self.last_path = G_reader_settings:readSetting("highlight_import_last_path") or ""
    self.algorithm = G_reader_settings:readSetting("highlight_import_matching_algorithm") or "adaptive"
end

function HighlightImport:onReaderReady()

    self.ui.menu:registerToMainMenu(self)

    UIManager:nextTick(function()
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

function HighlightImport:deletePluginSettings()
    for _, setting_key in ipairs(PLUGIN_SETTINGS_KEYS) do
        G_reader_settings:delSetting(setting_key)
    end
    if G_reader_settings.flush then
        G_reader_settings:flush()
    end

    self.file_path = ""
    self.last_path = ""
    self.algorithm = "adaptive"
end

return HighlightImport

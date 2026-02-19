local Widget = require("ui/widget/widget")
local PathChooser = require("ui/widget/pathchooser")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local RapidJSON = require("rapidjson")
local MyClipping = require("clip")
local Math = require("optmath")

local _ = require("gettext")
local logger = require("logger")


local HighlightImport = Widget:extend{
    name = "Highlight Import",
    last_path = "",
    file_path = ""
}

function HighlightImport:init()
    self.parser = MyClipping:new{ ui = self.ui }
end

function HighlightImport:onReaderReady()
    self.ui.menu:registerToMainMenu(self)
end











return HighlightImport

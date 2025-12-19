local Event = require("ui/event")
local PluginShare = require("pluginshare")
local UIManager = require("ui/uimanager")
local Widget = require("ui/widget/widget")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local _ = require("gettext")
local Screen = require("device").screen
local logger = require("logger")

local HiglightImport = Widget:extend{
    name = "Highlight Import"
}

function HiglightImport:reload()
    logger.dbg("Trying to reload.")
end

function HiglightImport:printUI(msg)

    local sample
    sample = InfoMessage:new{
        text = _(msg),
        -- height = Screen:scaleBySize(400),
        -- Set to false to hide the icon, and also the span between the icon and text.
        show_icon = false,
        timeout = 5,
    }
    UIManager:show(sample)
end

function HiglightImport:reloadDialog()
    -- local button_dialog = ButtonDialog:new{
    --     buttons = {
            
    --             text = "reload?",
    --             callback = reload() end,
    --             hold_callback = reload() end
    --     }
    -- }
    -- UIManager:show(button_dialog)

    -- local Button = require("ui/widget/button")
    -- local button = Button:new{
    --     text = _("Reload!"),
    --     enabled = true, -- defaults to true
    --     callback = reload,
    --     width = Screen:scaleBySize(50),
    --     bordersize = Screen:scaleBySize(3),
    --     margin = 0,
    --     padding = Screen:scaleBySize(2),
    -- }
end


function HiglightImport:ShowFileDialog()

end


-- function HiglightImport:onReaderReady()
    -- self.ui.menu:registerToMainMenu(self)
--     self.view:registerViewModule("higligh_import", self)
-- end

function HiglightImport:addToMainMenu(menu_items)
    menu_items.higligh_import_plugin = {
        text = _("Higlight Import"),
        sub_item_table ={
            {
                text = _(">Import<"),
                callback = function()
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

function HiglightImport:init()
    self.ui.menu:registerToMainMenu(self)
    self:printUI("Hello!")
end

-- reloadDialog()
return HiglightImport

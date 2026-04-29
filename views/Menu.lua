local _ = require("gettext")

local ImportsView = require("views.Imports")
local AnnotationsView = require("views.annotations.Annotations")
local FailedTargetsView = require("views.FailedTargets")
local getSettings = require("views.settings.Settings")
local fileSelector = require("components.fileSelector")
local Alert = require("components.Alert")
local Popup = require("components.Popup")
local useRecreateStatusPopup = require("composables/useRecreateStatusPopup")


function GetMenu(instance)
    return
    {
        {
            text_func = function()
                if instance.file_path == "" then
                    return ">Select file<"
                end
                local filename = instance.file_path:match("([^/]+)$") or instance.file_path
                return _("Select file") .. ": " .. filename
            end,
            -- keep_menu_open = true,
            callback = function()
                fileSelector(instance)
            end,
        },
        {
            text_func = function()
                return instance.file_path ~= "" and ">Import<" or "Import"
            end,
            callback = function()
                ImportsView(instance)
            end
        },
        {
            text =  _("Status"),
            callback = function()
                local ctx = {}
                ctx.file_path = instance.file_path
                ctx.targets = instance.targets
                ctx.finished = true
                ctx.popup = useRecreateStatusPopup(ctx)
            end
        },
        {
            text = _("Browse file highlights"),
            callback = function()
                AnnotationsView(instance)
            end
        },
        {
            text = _("Settings"),
            sub_item_table = getSettings(instance),
        },
        {
            text = _("About"),
            keep_menu_open = true,
            callback = function()
                Alert("A plugin to import your highlights from various formats. Check the plugin Github repo for more info.")
            end,
        },
    }
end

return GetMenu
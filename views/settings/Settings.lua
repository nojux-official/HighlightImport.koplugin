local _ = require("gettext")
local logger = require("logger")
local UIManager = require("ui/uimanager")
local RadioDialog = require("components.RadioDialog")

function GetSettings(instance)
    return {
        {
            text = _("Matching algorithm"),
            keep_open = true,
            callback = function()
                local items =
                {
                    {name = "Legacy (exact)", provider = "exact_legacy", checked = false}, 
                    {name = "Adaptive search", provider = "adaptive", checked = false},
                }
                local strategyName = G_reader_settings:readSetting(("highlight_import_matching_algorithm"), "fuzzy")

                for _, item in pairs(items) do
                    if item.provider == strategyName then
                        item.checked = true
                    end
                end


                local radio_buttons = {}  
                for _, item in pairs(items) do  
                    table.insert(radio_buttons, {{  
                        text = item.name,  
                        provider = item.provider,  
                        checked = item.checked,
                    }})  
                end

                local callback = function(ctx)
                    logger.info("Selected matching algorithm: " .. ctx.provider)
                    G_reader_settings:saveSetting("highlight_import_matching_algorithm", ctx.provider)
                    
                end

                local radioDialog = RadioDialog("Select matching algorithm"
                    , "Choose the algorithm to use for matching highlights"
                    , radio_buttons
                    , callback
                    , instance)

                UIManager:show(radioDialog)
                return true
            end,
        },
        {
            text = _("On fail: save unmatched to file"),
            checked_func = function()
                return G_reader_settings:isTrue("highlight_import_save_unmatched_file")
            end,
            callback = function()
                G_reader_settings:saveSetting("highlight_import_save_unmatched_file",
                    not G_reader_settings:isTrue("highlight_import_save_unmatched_file"))
            end,
            keep_menu_open = true,
        },
        {
            text = _("On fail: add note in book"),
            checked_func = function()
                return G_reader_settings:isTrue("highlight_import_note_in_book")
            end,
            callback = function()
                G_reader_settings:saveSetting("highlight_import_note_in_book",
                    not G_reader_settings:isTrue("highlight_import_note_in_book"))
            end,
            keep_menu_open = true,
        },
    }
end

return GetSettings
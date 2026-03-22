local _ = require("gettext")
local RadioButtonWidget = require("ui/widget/radiobuttonwidget")

return function(title, message, items, callback, instance)

    local radioDialog = RadioButtonWidget:new{
        title_text = title,
        info_text = message,
        cancel_text = _("Close"),
        ok_text = _("Apply"),
        width_factor = 0.9,
        radio_buttons = items,
        callback = function(radio)
            local ctx = {
                provider = radio.provider,
                db = instance.db,
            }
            if callback then
                callback(ctx)
            end
        end,
    }

    return radioDialog
end
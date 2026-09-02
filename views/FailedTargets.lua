local _ = require("gettext")
local UIManager = require("ui/uimanager")
local Modal = require("components.Modal")
local Popup = require("components.Popup")
local useCloseButton = require("composables.useCloseButton")

--- Shows a scrollable list of highlights that failed to import.
--- @param failed table  List of target objects with .annotation, .page, .note fields.
return function(failed)
    if not failed or #failed == 0 then return end

    local ctx = {}

    local entries = {}
    for i, t in ipairs(failed) do
        local page_str = tostring(t.page or "?")
        local note_flag = t.note and " [note]" or ""
        local label = string.format("[p.%s]%s %s", page_str, note_flag, t.annotation)
        entries[#entries + 1] = {
            text = label,
            -- Tapping an entry shows its full text in a small popup.
            callback = function()
                local lines = {
                    string.format(_("Page: %s"), page_str),
                    "",
                    t.annotation,
                }
                if t.note then
                    lines[#lines + 1] = ""
                    lines[#lines + 1] = _("Note:") .. " " .. t.note
                end
                local detail_ctx = {}
                local detail = Popup(
                    string.format(_("Failed highlight %d/%d"), i, #failed),
                    table.concat(lines, "\n"),
                    {{ text = _("Close"), callback = function() useCloseButton(detail_ctx) end }}
                )
                detail_ctx["parent"] = detail
                UIManager:show(detail)
            end,
        }
    end

    local title = string.format(_("Failed highlights (%d)"), #failed)
    local modal = Modal(title, entries)
    ctx["parent"] = modal
    UIManager:show(modal)
end

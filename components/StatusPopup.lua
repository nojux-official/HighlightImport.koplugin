local UIManager = require("ui/uimanager")
local Popup = require("components.Popup")
local useCloseButton = require("composables/useCloseButton")


return function ()
    -- highlights on document (no need to show)
    -- highlights on clippings but not on document (to be imported)
    -- highlights on clippings (but cannot be mapped to document)
    -- imported highlights (they intersect between documents and the clippings)
    -- scanning progress
    -- stats, diagram, etc.

    local ctx = {parent = self}

    local buttons = {
        { text = "Cancel", callback = function() useCloseButton(ctx) end }, 
        { text = "Browse", callback = function() useCloseButton(ctx) end },
        { text = "Background", callback = function() useCloseButton(ctx) end },
    }


    local popup = Popup("Import status", [[
Importing from /ff/dsd/.../book.txt
Status: in progress
Suceeded: 100
Skipped: 15
Failed: 2
Remaining: 50
Elapsed time: 20 s

]], buttons)

    ctx["parent"] = popup

    UIManager:show(popup)

    -- alert("Not implemented yet.")
    return true
end
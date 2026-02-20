local _ = require("gettext")
local MyClipping = require("services.MyClipping")
local logger = require("logger")

local ITargetStatus = require("interfaces.ITargetStatus")


local UIManager = require("ui/uimanager")
local AnnotationView = require("views.annotations.Annotation")
local Alert = require("components.Alert")
local Modal = require("components.Modal")


function buildItemList(targets, ctx)
    local modalEntries = {}

    for _, target in ipairs(targets) do
        local annotation = target.annotation
        local status = target.status
        local toggle = "[   ]"
        if status == ITargetStatus.SELECTED then
            toggle = "[ * ]"
        end

        local currentTargetIdx = #modalEntries + 1 -- will be accessible in callback
        local targetsRef = targets
        
        modalEntries[currentTargetIdx] = {
            text = string.format("%s %s", toggle, annotation),
            callback = function()
                if(targetsRef[currentTargetIdx] == ITargetStatus.ADDED) then
                    targetsRef[currentTargetIdx] = ITargetStatus.SELECTED
                end
                if(targetsRef[currentTargetIdx] == ITargetStatus.SELECTED) then
                    targetsRef[currentTargetIdx] = ITargetStatus.ADDED
                end
                UIManager:close(ctx["modalRef"])

                ctx["recreateFunc"]()
            end,
        }
    end

    return modalEntries
end

function ImportsView(instance)

    local targets = {}

    local clippings = instance.parser:parseFile(instance.file_path)

    if type(clippings) ~= "table" then return end
    
    for _title, booknotes in pairs(clippings) do
        if type(booknotes) ~= "table" or #booknotes == 0 then
        else
            for _, entry in ipairs(booknotes) do
                if entry[1].sort == "highlight" then 
                    local query = entry[1].text
                    targets[#targets + 1] = {
                        annotation = query,
                        status = ITargetStatus.SELECTED
                    }
                end
            end
        end
    end

    local function recreate()
        local ctx = {}
        local modalEntries = buildItemList(targets, ctx)  
        local modal = Modal(_("Annotations (file)"), modalEntries)  
        ctx["modalRef"] = modal
        ctx["recreateFunc"] = recreate
        UIManager:show(modal)

        logger.dbg("HighlightImport: recreate ImportsViewModal")
    end 

    recreate()
end

return ImportsView
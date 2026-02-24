local _ = require("gettext")
local MyClipping = require("services.MyClipping")
local logger = require("logger")

local ITargetStatus = require("interfaces.ITargetStatus")
local Import = require("services.LocalMatching")

local UIManager = require("ui/uimanager")
local ButtonTable = require("ui/widget/buttontable")
local AnnotationView = require("views.annotations.Annotation")
local Alert = require("components.Alert")
local Modal = require("components.Modal")
local useCloseButton = require("composables.useCloseButton")



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
                if(targetsRef[currentTargetIdx].status == ITargetStatus.ADDED) then
                    targetsRef[currentTargetIdx].status = ITargetStatus.SELECTED
                else
                    if(targetsRef[currentTargetIdx].status == ITargetStatus.SELECTED) then
                        targetsRef[currentTargetIdx].status = ITargetStatus.ADDED
                    end
                end

                local page = ctx["modalRef"].page
                UIManager:close(ctx["modalRef"])
                ctx["recreateFunc"](page)
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
                        status = ITargetStatus.ADDED
                    }
                end
            end
        end
    end

    local function recreate(page)
        if not page then page = 1 end
        local ctx = {}
        
        local modalEntries = buildItemList(targets, ctx)  
        local buttonTable = ButtonTable:new{
            buttons = {{
                {text="Import all", callback=function() Import(instance); useCloseButton(ctx) end},
                {text="Import selected", callback=function() Import(instance); useCloseButton(ctx) end},
                {text="Toggle browsing", callback=function() useCloseButton(ctx) end},
            }}
        }


        local modal = Modal(_("Annotations (file)"), modalEntries, buttonTable)  
        --for displaying checkbox updates
        ctx["modalRef"] = modal
        ctx["recreateFunc"] = recreate
        -- for modal closing
        ctx["parent"] = modal


        UIManager:show(modal)
        modal:onGotoPage(page)  

        logger.dbg("HighlightImport: recreate ImportsViewModal")
    end 

    recreate()
end

return ImportsView
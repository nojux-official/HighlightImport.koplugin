local _ = require("gettext")
local logger = require("logger")

local ITargetStatus = require("interfaces.ITargetStatus")
local ParseClippings = require("utils.ParseClippings")
local Import = require("services.LocalMatching")

local UIManager = require("ui/uimanager")
local ButtonTable = require("ui/widget/buttontable")
local AnnotationsView = require("views.annotations.Annotations")
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

    instance.targets = ParseClippings(instance)


    local function recreate(page)
        if not page then page = 1 end
        local ctx = {}
        
        local modalEntries = buildItemList(instance.targets, ctx)  
        local buttonTable = ButtonTable:new{
            buttons = {{
                {text="Import all", callback=function()
                    for idx, _ in ipairs(instance.targets) do
                        instance.targets[idx].status = ITargetStatus.SELECTED
                    end
                    useCloseButton(ctx)
                    UIManager:nextTick(function()
                        Import(instance)
            
                    end)
                end},
                {text="Import selected", callback=function() useCloseButton(ctx); Import(instance);  end},
                {text="Toggle browsing", callback=function() useCloseButton(ctx); AnnotationsView(instance) end},
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
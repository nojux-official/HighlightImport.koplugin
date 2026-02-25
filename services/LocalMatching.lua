local _ = require("gettext")

local logger = require("logger")
local RapidJSON = require("rapidjson")
local ITargetStatus = require("interfaces.ITargetStatus")
local StatusPopup = require("components.StatusPopup")
local UIManager = require("ui/uimanager")

local Document = require("services.Document")

return function (instance)

    --[=====[
    load my_clippings

    loop foreach through my_clippings {
        search for entry
        obtain xpath start-end indexes
        highlight 
    }
    --]=====]
    local doc = Document:new(instance)

    logger.dbg(string.format("HighlighitImport: Local matching algorithm starting. Clippings: %d", #instance.targets))

    if not doc:IsDocReady() then return end


    -- ReaderUI instance
    if not instance.ui then error("No ReaderUI instance running") end  
    
    -- ReaderSearch 
    local search = instance.ui.search
  

local function calculateStats(ctx)
        ctx.total = 0
        ctx.succeeded=0
        ctx.skipped=0
        ctx.failed=0
        ctx.remaining=0
        for idx, target in ipairs(ctx.targets) do

            if target.status == ITargetStatus.SELECTED then 
                ctx.remaining = ctx.remaining + 1 
                ctx.total = ctx.total + 1
            end
            if target.status == ITargetStatus.ALGORITHM_RESOLVED then
                ctx.succeeded = ctx.succeeded + 1
                ctx.total = ctx.total + 1
            end
            if target.status == ITargetStatus.FAILED then
                ctx.failed = ctx.failed + 1
                ctx.total = ctx.total + 1
            end
        end
    end


    local function recreate(ctx)

        UIManager:close(popup)

        
        -- local modalEntries = calculateStats(ctx)  
        -- local buttonTable = ButtonTable:new{
        --     buttons = {{
        --         {text="Import all", callback=function()
        --             for idx, _ in ipairs(instance.targets) do
        --                 instance.targets[idx].status = ITargetStatus.SELECTED
        --             end
        --             Import(instance)
        --             useCloseButton(ctx)
        --         end},
        --         {text="Import selected", callback=function() Import(instance); useCloseButton(ctx) end},
        --         {text="Toggle browsing", callback=function() useCloseButton(ctx); AnnotationsView(instance) end},
        --     }}
        -- }


        local content = string.format([[
Importing from %s
Status: %s
Succeeded: %d
Skipped: %d
Failed: %d
Remaining: %d]],
instance.file_path, 'in progress',
ctx.succeeded, ctx.skipped, ctx.failed, ctx.remaining
)

        local popup = StatusPopup(content)
        UIManager:show(popup)  
        --for displaying checkbox updates

        
        -- ctx["modalRef"] = popup
        -- ctx["recreateFunc"] = recreate
        -- for modal closing
        -- ctx["parent"] = popup

    end



    local ctx = {}
    ctx.targets = instance.targets


    -- instance.targets = ParseClippings(instance)


    for idx, target in ipairs(instance.targets) do
        if target.status ~= ITargetStatus.SELECTED then goto continueInner end

        local serialized = RapidJSON.encode(target.annotation, { indent = true })
        logger.dbg("Entry: " .. tostring(serialized))

        logger.dbg("HighlightImport: Processing " .. target.annotation)
        -- direction=0, no regex, case_insensitive  
        local res = search:searchFromCurrent(target.annotation, 0, false, true)

        if not res or #res == 0 then
            logger.dbg("HighlightImport: Failed to find match: " .. target.annotation)
            instance.targets[idx].status = ITargetStatus.FAILED
            goto continueInner
        end
        local xpointer_start = res[1].start
        local xpointer_end = res[1]["end"]
        logger.dbg("HighlightImport: Found text at: " .. xpointer_start .. " to " .. xpointer_end)
        
        doc:CreateHighlightFromXPointer(xpointer_start, xpointer_end, target.annotation)

        instance.targets[idx].status = ITargetStatus.ALGORITHM_RESOLVED

        calculateStats(ctx)
        recreate(ctx)

        ::continueInner::
    end
        
    logger.dbg("HighlightImport: algorithm finished.")

end


    
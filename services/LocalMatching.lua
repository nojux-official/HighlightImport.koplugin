local logger = require("logger")
local RapidJSON = require("rapidjson")

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

    logger.dbg(string.format("HighlighitImport: Local matching algorithm starting. Clippings: %s", instance.file_paths))

    if not doc:IsDocReady() then return end


    -- ReaderUI instance
    if not instance.ui then error("No ReaderUI instance running") end  
    
    -- ReaderSearch 
    local search = instance.ui.search
  
    
    local clippings = instance.parser:parseFile(instance.file_path)

    -- return self:serializeClippings(clippings)
    if type(clippings) ~= "table" then return end
    
    local failures = 0
    local successes = 0
    for _title, booknotes in pairs(clippings) do
        if type(booknotes) ~= "table" or #booknotes == 0 then
            goto continueOuter
        end

        for _, entry in ipairs(booknotes) do
            local serialized = RapidJSON.encode(entry, { indent = true })
            logger.dbg("Entry: " .. tostring(serialized))
            if entry[1].sort ~= "highlight" then 
                failures = failures + 1
                goto continueInner
            end

            local query = entry[1].text
            logger.dbg("HighlightImport: Processing " .. query)
            -- direction=0, no regex, case_insensitive  
            local res = search:searchFromCurrent(query, 0, false, true)

            if not res or #res == 0 then
                logger.dbg("HighlightImport: Failed to find text: " .. query)
                failures = failures + 1
                goto continueInner
            end
            local xpointer_start = res[1].start
            local xpointer_end = res[1]["end"]
            logger.dbg("HighlightImport: Found text at: " .. xpointer_start .. " to " .. xpointer_end)
            
            doc:CreateHighlightFromXPointer(xpointer_start, xpointer_end, query)
  
            successes = successes + 1
            ::continueInner::
        end
        
        ::continueOuter::
    end

    logger.dbg("HighlightImport: successes: " .. successes .. ", failures: " .. failures)

end

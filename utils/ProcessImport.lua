local RapidJSON = require("rapidjson")
local MyClipping = require("clip")

local _ = require("gettext")
local logger = require("logger")


function HighlightImport:import(file_path)

    --[=====[
    load my_clippings

    loop foreach through my_clippings {
        search for entry
        obtain xpath start-end indexes
        highlight 
    }
    --]=====]


    if not self:isDocReady() then return end
    
    local clippings = self.parser:parseFile(file_path)

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
            -- pattern, origin, direction, case_insensitive, page, regex, max_hits
            local res = self.document:findText(query, -1, 0, true, 1, false, 1)
            if not res or #res == 0 then
                logger.dbg("HighlightImport: Failed to find text: " .. query)
                failures = failures + 1
                goto continueInner
            end
            local xpointer_start = res[1].start
            local xpointer_end = res[1]["end"]
            logger.dbg("HighlightImport: Found text at: " .. xpointer_start .. " to " .. xpointer_end)
            
            self:createHighlightFromXPointer(xpointer_start, xpointer_end, query)
  
            successes = successes + 1
            ::continueInner::
        end
        
        ::continueOuter::
    end

    logger.dbg("HighlightImport: successes: " .. successes .. ", failures: " .. failures)



end
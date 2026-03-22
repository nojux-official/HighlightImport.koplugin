local logger = require("logger")
local exactLegacy = require("services.MatchingStrategies.exact_legacy")
local adaptiveSearch = require("services.MatchingStrategies.adaptive")

MatchingStrategies= {
    strategies = {
        exact_legacy = exactLegacy,
        adaptive = fuzzy,
    },
    strategy = exactLegacy,
    instance = adaptiveSearch,
}

function MatchingStrategies:new(o)
    if o == nil then o = {} end
    setmetatable(o, self)
    self.__index = self
    return o
end
function MatchingStrategies:selectByName(name)
    local strategy = self.strategies[name]
    if not strategy then
        logger.err("MatchingStrategies: Strategy not found: " .. name)
        return
    end
    self.strategy = strategy
end

function MatchingStrategies:select(strategy)
    self.strategy = strategy
end

function MatchingStrategies:execute()
    if(not self.strategy) then
        logger.err("MatchingStrategies: No strategy selected")
        return
    end

    self.strategy(self.instance)
end

return MatchingStrategies
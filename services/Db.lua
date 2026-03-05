local DataStorage = require("datastorage")
local SQ3 = require("lua-ljsqlite3/init")
local logger = require("logger")

local db_path = DataStorage:getSettingsDir() .. "/highlight_import.sqlite3"

local DB_SCHEMA_VERSION = 20260305
local DB_SCHEMA = [[
    CREATE TABLE IF NOT EXISTS "annotation" (
        "id"            INTEGER NOT NULL UNIQUE,
        "book_id"       INTERGER,
        "status"        INTEGER NOT NULL,
        "highlight"     TEXT NOT NULL,
        "note"          TEXT,
        "pos1"          TEXT,
        "pos2"          TEXT,
        "updated_at"    DATETIME DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY("id")
    );
    CREATE TABLE IF NOT EXISTS "annotation_status" (
        "id"            INTEGER NOT NULL UNIQUE,
        "status"        TEXT NOT NULL,
        PRIMARY KEY("id")
    );
    INSERT OR IGNORE INTO "annotation_status" (id, status) VALUES 
        (1, 'added'),
        (2, 'selected'),
        (3, 'resolved'),
        (4, 'failed'),
        (5, 'skipped'),
        (6, 'deleted')
    ;
    CREATE TABLE IF NOT EXISTS "book" (
        "id"              TEXT NOT NULL UNIQUE,
        "path"            TEXT,
        "clippings_path"  TEXT,
        "updated_at"      DATETIME DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY("id")
    );
]]



local DB = {}

function DB:extend(subclass_prototype)
    local o = subclass_prototype or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function DB:new(o)
    o = self:extend(o)
    if o.init then o:init() end
    return o
end

function DB:init()
    self.db = SQ3.open(db_path)
    self.db:exec(DB_SCHEMA)
end

function DB:keys(t)
    local result = {}
    for k, _ in pairs(t) do
        table.insert(result, k)
    end
    return result
end

function DB:values(t)
    local result = {}
    for _, v in pairs(t) do
        table.insert(result, v)
    end
    return result
end

function DB:map(t, func)
    local result = {}
    for _, v in ipairs(t) do
        table.insert(result, func(v))
    end
    return result
end

function DB:getCollection(collection_name)
    return self.db:exec("SELECT * FROM " .. collection_name)
end

function DB:postCollection(collection_name, data)
    local keys = self:keys(data)
    local columns = table.concat(keys, ", ")
    local placeholders = table.concat(self:map(keys, function() return "?" end), ", ")
    local sql = "INSERT INTO " .. collection_name .. " (" .. columns .. ") VALUES (" .. placeholders .. ")"
    
    local stmt = self.db:prepare(sql)
    
    local values = {}
    for _, key in ipairs(keys) do
        table.insert(values, data[key])
    end
    
    stmt:bind(unpack(values))
    stmt:step()
end

function DB:isExists(collection_name, conditions)
    local keys = self:keys(conditions)
    local where_clause = table.concat(self:map(keys, function(k) return k .. " = ?" end), " AND ")
    local sql = "SELECT COUNT(*) as count FROM " .. collection_name .. " WHERE " .. where_clause
    
    local stmt = self.db:prepare(sql)
    
    local values = {}
    for _, key in ipairs(keys) do
        table.insert(values, conditions[key])
    end
    
    stmt:bind(unpack(values))
    
    if stmt:step() == SQ3.ROW then
        return stmt:get_value(0) > 0
    end
    
    return false
end

return DB
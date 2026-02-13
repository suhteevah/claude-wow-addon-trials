-- CallbackHandler-1.0
-- CallbackHandler is a back-end utility library that makes it easy for a library to fire callbacks to its users.
-- License: Public Domain
-- Source: https://repos.wowace.com/wow/callbackhandler/

local MAJOR, MINOR = "CallbackHandler-1.0", 7
local CallbackHandler = LibStub:NewLibrary(MAJOR, MINOR)
if not CallbackHandler then return end

local meta = {__index = function(tbl, key) tbl[key] = {} return tbl[key] end}

local type = type
local pcall = pcall
local pairs = pairs
local assert = assert
local concat = table.concat
local loadstring = loadstring or load
local next = next
local select = select
local type = type
local xpcall = xpcall

local function errorhandler(err)
    return geterrorhandler()(err)
end

local function Dispatch(handlers, ...)
    local index, method = next(handlers)
    if not method then return end
    repeat
        xpcall(method, errorhandler, ...)
        index, method = next(handlers, index)
    until not method
end

function CallbackHandler:New(target, RegisterName, UnregisterName, UnregisterAllName)
    RegisterName = RegisterName or "RegisterCallback"
    UnregisterName = UnregisterName or "UnregisterCallback"
    UnregisterAllName = UnregisterAllName or "UnregisterAllCallbacks"

    local events = setmetatable({}, meta)
    local registry = {recurse = 0, events = events}

    function registry:Fire(eventname, ...)
        local handlers = rawget(events, eventname)
        if not handlers or not next(handlers) then return end
        Dispatch(handlers, eventname, ...)
    end

    target[RegisterName] = function(self, eventname, method, ...)
        if type(eventname) ~= "string" then
            error("Usage: " .. RegisterName .. "(eventname, method[, arg]): 'eventname' - string expected.", 2)
        end

        method = method or eventname

        if type(method) ~= "string" and type(method) ~= "function" then
            error("Usage: " .. RegisterName .. "(\"eventname\", \"methodname\"): 'methodname' - string or function expected.", 2)
        end

        local firstselfarg
        if type(method) == "string" then
            if type(self) ~= "table" then
                error("Usage: " .. RegisterName .. "(\"eventname\", \"methodname\"): self was not a table?", 2)
            elseif self == target then
                error("Usage: " .. RegisterName .. "(\"eventname\", \"methodname\"): do not use Library:" .. RegisterName .. "(), use your own object.", 2)
            elseif type(self[method]) ~= "function" then
                error("Usage: " .. RegisterName .. "(\"eventname\", \"methodname\"): self[methodname] was not a function?", 2)
            end
            local extra = {...}
            if #extra > 0 then
                events[eventname][self] = function(...) self[method](self, unpack(extra), ...) end
            else
                events[eventname][self] = function(...) self[method](self, ...) end
            end
        else
            local extra = {...}
            if #extra > 0 then
                events[eventname][self] = function(...) method(unpack(extra), ...) end
            else
                events[eventname][self] = method
            end
        end
    end

    target[UnregisterName] = function(self, eventname)
        if not self or self == target then
            error("Usage: " .. UnregisterName .. "(eventname): bad self", 2)
        end
        if type(eventname) ~= "string" then
            error("Usage: " .. UnregisterName .. "(eventname): 'eventname' - string expected.", 2)
        end
        if rawget(events, eventname) and events[eventname][self] then
            events[eventname][self] = nil
        end
    end

    target[UnregisterAllName] = function(self)
        if self == target then
            error("Usage: " .. UnregisterAllName .. "(): bad self", 2)
        end
        for eventname, handlers in pairs(events) do
            if handlers[self] then
                handlers[self] = nil
            end
        end
    end

    return registry
end

local function inherit(subclass, superclass)
    local meta = getmetatable(subclass)
    if not meta then
        meta = {}
        setmetatable(subclass, meta)
    end
    meta.__index = superclass
    return subclass
end

local function class(superclass)
    local Type = {}
    
    if superclass then
        inherit(Type, superclass)
    end
    
    Type.__index = Type
    
    local meta = {}
    meta.__call = function(self, ...)
        local instance = setmetatable({}, Type)
        if instance.new then
            instance:new(...)
        end
        return instance
    end
    
    setmetatable(Type, meta)
    
    return Type
end

return class

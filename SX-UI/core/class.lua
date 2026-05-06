local function class(superclass)
    local Type = {}

    Type.__index = Type

    local meta = {}
    if superclass then
        meta.__index = superclass
    end

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

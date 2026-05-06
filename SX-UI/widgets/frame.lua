local class = require("core.class")
local Element = require("core.element")

local Frame = class(Element)

function Frame:new()
    Element.new(self)
    self.backgroundColor = colors.lightGray
end

return Frame

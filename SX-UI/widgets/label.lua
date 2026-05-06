local class = require("core.class")
local Element = require("core.element")

local Label = class(Element)

function Label:new(text)
    Element.new(self)
    self.text = text or ""
    self.align = "left"
    self.backgroundColor = false -- false means transparent
    self.foregroundColor = colors.white
end

function Label:draw(renderTarget)
    if not self.visible then return end
    
    if self.backgroundColor and self.width > 0 and self.height > 0 then
        renderTarget.setBackgroundColor(self.backgroundColor)
        for dy = 0, self.height - 1 do
            renderTarget.setCursorPos(self.x, self.y + dy)
            renderTarget.write(string.rep(" ", self.width))
        end
    end
    
    local txt = tostring(self.text)
    if #txt > self.width then txt = string.sub(txt, 1, self.width) end
    local drawX = self.x
    if self.align == "center" then
        drawX = self.x + math.floor((self.width - #txt) / 2)
    elseif self.align == "right" then
        drawX = self.x + self.width - #txt
    end
    
    renderTarget.setCursorPos(drawX, self.y)
    if self.backgroundColor then renderTarget.setBackgroundColor(self.backgroundColor) end
    renderTarget.setTextColor(self.foregroundColor)
    renderTarget.write(txt)
    
    local sortedChildren = {}
    for _, c in ipairs(self.children) do table.insert(sortedChildren, c) end
    table.sort(sortedChildren, function(a, b) return a.zIndex < b.zIndex end)
    
    for _, c in ipairs(sortedChildren) do
        c:draw(renderTarget)
    end
end

return Label

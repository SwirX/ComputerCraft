local class = require("lib.sxui.core.class")
local Element = require("lib.sxui.core.element")

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

    local x, y = self:getAbsolutePosition()
    local w, h = self:getAbsoluteSize()

    if self.backgroundColor and w > 0 and h > 0 then
        renderTarget.setBackgroundColor(self.backgroundColor)
        for dy = 0, h - 1 do
            renderTarget.setCursorPos(x, y + dy)
            renderTarget.write(string.rep(" ", w))
        end
    end

    local txt = tostring(self.text)
    if #txt > w then txt = string.sub(txt, 1, w) end
    local drawX = x
    if self.align == "center" then
        drawX = x + math.floor((w - #txt) / 2)
    elseif self.align == "right" then
        drawX = x + w - #txt
    end

    renderTarget.setCursorPos(drawX, y)
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

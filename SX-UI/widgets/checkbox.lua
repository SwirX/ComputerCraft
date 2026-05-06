local class = require("core.class")
local Element = require("core.element")

local Checkbox = class(Element)

function Checkbox:new(text)
    Element.new(self)
    self.text = text or ""
    self.checked = false
    self.width = #self.text + 4
    self.height = 1
    self.backgroundColor = false
    self.foregroundColor = colors.white
    self.checkedColor = colors.lime
end

function Checkbox:handleEvent(event, p1, p2, p3)
    if not self.visible then return false end
    
    -- Consume the built in event propagation
    local wasHandled = Element.handleEvent(self, event, p1, p2, p3)
    
    -- Checkbox specific toggle on fully valid click
    if event == "mouse_click" or event == "monitor_touch" then
        local btn, x, y = p1, p2, p3
        if event == "monitor_touch" then btn = 1; x = p1; y = p2; end
        
        if self:hitTest(x, y) and btn == 1 then
            self.checked = not self.checked
            return true
        end
    end
    
    return wasHandled
end

function Checkbox:draw(renderTarget)
    if not self.visible then return end
    
    if self.backgroundColor then
        renderTarget.setBackgroundColor(self.backgroundColor)
        for dy = 0, self.height - 1 do
            renderTarget.setCursorPos(self.x, self.y + dy)
            renderTarget.write(string.rep(" ", self.width))
        end
    end
    
    renderTarget.setCursorPos(self.x, self.y)
    if self.backgroundColor then renderTarget.setBackgroundColor(self.backgroundColor) end
    
    renderTarget.setTextColor(self.foregroundColor)
    renderTarget.write("[")
    
    if self.checked then
        renderTarget.setTextColor(self.checkedColor)
        renderTarget.write("X")
    else
        renderTarget.write(" ")
    end
    
    renderTarget.setTextColor(self.foregroundColor)
    renderTarget.write("] ")
    
    local txt = tostring(self.text)
    local avail = self.width - 4
    if avail > 0 then
        if #txt > avail then txt = string.sub(txt, 1, avail) end
        renderTarget.write(txt)
    end
    
    local sortedChildren = {}
    for _, c in ipairs(self.children) do table.insert(sortedChildren, c) end
    table.sort(sortedChildren, function(a, b) return a.zIndex < b.zIndex end)
    
    for _, c in ipairs(sortedChildren) do
        c:draw(renderTarget)
    end
end

return Checkbox

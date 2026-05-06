local class = require("core.class")
local Element = require("core.element")

local Button = class(Element)

function Button:new(text)
    Element.new(self)
    self.text = text or "Button"
    self.align = "center"
    self.backgroundColor = colors.gray
    self.foregroundColor = colors.white
    self.pressedColor = colors.lightGray
    self._isPressed = false
end

function Button:handleEvent(event, p1, p2, p3)
    if not self.visible then return false end
    
    if event == "mouse_click" or event == "monitor_touch" then
        local btn, x, y = p1, p2, p3
        if event == "monitor_touch" then btn = 1; x = p1; y = p2; end
        
        if self:hitTest(x, y) and btn == 1 then
            self._isPressed = true
        end
    elseif event == "mouse_up" then
        if self._isPressed then
            self._isPressed = false
            -- Base class will handle the generic onClick dispatch, 
            -- but visually we pop back up.
        end
    elseif event == "mouse_move" then
        if self._isPressed and not self:hitTest(p1, p2) then
            self._isPressed = false
        end
    end
    
    return Element.handleEvent(self, event, p1, p2, p3)
end

function Button:draw(renderTarget)
    if not self.visible then return end
    
    local bg = self._isPressed and self.pressedColor or self.backgroundColor
    
    if self.width > 0 and self.height > 0 then
        renderTarget.setBackgroundColor(bg)
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
    
    local textY = self.y + math.floor((self.height - 1) / 2)
    renderTarget.setCursorPos(drawX, textY)
    renderTarget.setTextColor(self.foregroundColor)
    renderTarget.write(txt)
    
    local sortedChildren = {}
    for _, c in ipairs(self.children) do table.insert(sortedChildren, c) end
    table.sort(sortedChildren, function(a, b) return a.zIndex < b.zIndex end)
    
    for _, c in ipairs(sortedChildren) do
        c:draw(renderTarget)
    end
end

return Button

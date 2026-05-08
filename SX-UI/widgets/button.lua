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
        local btn, cx, cy = p1, p2, p3
        if event == "monitor_touch" then
            btn = 1; cx = p1; cy = p2;
        end

        if self:hitTest(cx, cy) and btn == 1 then
            self._isPressed = true
        end
    elseif event == "mouse_up" then
        if self._isPressed then
            self._isPressed = false
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
    local x, y = self:getAbsolutePosition()
    local w, h = self:getAbsoluteSize()

    if w > 0 and h > 0 then
        renderTarget.setBackgroundColor(bg)
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

    local textY = y + math.floor((h - 1) / 2)
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

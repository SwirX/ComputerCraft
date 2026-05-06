local class = require("lib.sxui.core.class")
local Element = require("lib.sxui.core.element")

local Checkbox = class(Element)

function Checkbox:new(text)
    Element.new(self)
    self.text = text or ""
    self.checked = false
    self.size.offsetX = #(self.text) + 4
    self.size.offsetY = 1
    self.backgroundColor = false
    self.foregroundColor = colors.white
    self.checkedColor = colors.lime
end

function Checkbox:handleEvent(event, p1, p2, p3)
    if not self.visible then return false end

    -- Consume the built in event propagation
    local wasHandled = Element.handleEvent(self, event, p1, p2, p3)

    if event == "mouse_click" or event == "monitor_touch" then
        local btn, cx, cy = p1, p2, p3
        if event == "monitor_touch" then
            btn = 1; cx = p1; cy = p2;
        end

        if self:hitTest(cx, cy) and btn == 1 then
            self.checked = not self.checked
            return true
        end
    end

    return wasHandled
end

function Checkbox:draw(renderTarget)
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

    renderTarget.setCursorPos(x, y)
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
    local avail = w - 4
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

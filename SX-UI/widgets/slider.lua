local class = require("lib.sxui.core.class")
local Element = require("lib.sxui.core.element")

local Slider = class(Element)

function Slider:new()
    Element.new(self)
    self.size.offsetX = 10
    self.size.offsetY = 1
    self.min = 0
    self.max = 100
    self.value = 50
    self.backgroundColor = colors.gray
    self.foregroundColor = colors.white
    self.sliderColor = colors.lightBlue
    self._isDraggingSlider = false
end

function Slider:setValue(val)
    self.value = val
    if self.value < self.min then self.value = self.min end
    if self.value > self.max then self.value = self.max end
end

function Slider:updateFromMouse(cx)
    local x, _ = self:getAbsolutePosition()
    local w, _ = self:getAbsoluteSize()

    local relX = cx - x
    local ratio = relX / (w - 1)
    if ratio < 0 then ratio = 0 end
    if ratio > 1 then ratio = 1 end

    local oldVal = self.value
    self.value = self.min + ratio * (self.max - self.min)
    if oldVal ~= self.value and type(self.onChange) == "function" then
        self.onChange(self, self.value)
    end
end

function Slider:handleEvent(event, p1, p2, p3)
    if not self.visible then return false end

    if event == "mouse_click" or event == "monitor_touch" then
        local btn, cx, cy = p1, p2, p3
        if event == "monitor_touch" then
            btn = 1; cx = p1; cy = p2;
        end

        if self:hitTest(cx, cy) and btn == 1 then
            self._isDraggingSlider = true
            self:updateFromMouse(cx)
        end
    elseif event == "mouse_drag" then
        local btn, cx, cy = p1, p2, p3
        if self._isDraggingSlider then
            self:updateFromMouse(cx)
            return true
        end
    elseif event == "mouse_up" then
        if self._isDraggingSlider then
            self._isDraggingSlider = false
            return true
        end
    end

    return Element.handleEvent(self, event, p1, p2, p3)
end

function Slider:draw(renderTarget)
    if not self.visible then return end

    local x, y = self:getAbsolutePosition()
    local w, h = self:getAbsoluteSize()

    renderTarget.setBackgroundColor(self.backgroundColor)
    for dy = 0, h - 1 do
        renderTarget.setCursorPos(x, y + dy)
        renderTarget.write(string.rep(" ", w))
    end

    local ratio = (self.value - self.min) / (self.max - self.min)
    if ratio ~= ratio then ratio = 0 end
    local handleX = math.floor(ratio * (w - 1))

    renderTarget.setCursorPos(x + handleX, y + math.floor((h - 1) / 2))
    renderTarget.setBackgroundColor(self.sliderColor)
    renderTarget.setTextColor(self.foregroundColor)
    renderTarget.write(" ")

    local sortedChildren = {}
    for _, c in ipairs(self.children) do table.insert(sortedChildren, c) end
    table.sort(sortedChildren, function(a, b) return a.zIndex < b.zIndex end)
    for _, c in ipairs(sortedChildren) do c:draw(renderTarget) end
end

return Slider

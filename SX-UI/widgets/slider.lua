local class = require("core.class")
local Element = require("core.element")

local Slider = class(Element)

function Slider:new()
    Element.new(self)
    self.width = 10
    self.height = 1
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

function Slider:updateFromMouse(x)
    local relX = x - self.x
    local ratio = relX / (self.width - 1)
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
        local btn, x, y = p1, p2, p3
        if event == "monitor_touch" then btn = 1; x = p1; y = p2; end
        
        if self:hitTest(x, y) and btn == 1 then
            self._isDraggingSlider = true
            self:updateFromMouse(x)
        end
    elseif event == "mouse_drag" then
        local btn, x, y = p1, p2, p3
        if self._isDraggingSlider then
            self:updateFromMouse(x)
            return true -- Consume so we don't accidentally trigger draggable parent logic
        end
    elseif event == "mouse_up" then
        if self._isDraggingSlider then
            self._isDraggingSlider = false
            return true
        end
    end
    
    -- We pass the event strictly to Element now, but if we are dragging the slider, we consumed it above to prevent normal window drag
    return Element.handleEvent(self, event, p1, p2, p3)
end

function Slider:draw(renderTarget)
    if not self.visible then return end
    
    renderTarget.setBackgroundColor(self.backgroundColor)
    for dy = 0, self.height - 1 do
        renderTarget.setCursorPos(self.x, self.y + dy)
        renderTarget.write(string.rep(" ", self.width))
    end
    
    local ratio = (self.value - self.min) / (self.max - self.min)
    if ratio ~= ratio then ratio = 0 end -- NaN guard
    local handleX = math.floor(ratio * (self.width - 1))
    
    renderTarget.setCursorPos(self.x + handleX, self.y + math.floor((self.height - 1) / 2))
    renderTarget.setBackgroundColor(self.sliderColor)
    renderTarget.setTextColor(self.foregroundColor)
    renderTarget.write(" ")
    
    local sortedChildren = {}
    for _, c in ipairs(self.children) do table.insert(sortedChildren, c) end
    table.sort(sortedChildren, function(a, b) return a.zIndex < b.zIndex end)
    for _, c in ipairs(sortedChildren) do c:draw(renderTarget) end
end

return Slider

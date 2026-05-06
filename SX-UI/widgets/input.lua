local class = require("core.class")
local Element = require("core.element")

local Input = class(Element)

function Input:new()
    Element.new(self)
    self.text = ""
    self.placeholder = "Type here..."
    self.isFocused = false
    self.width = 15
    self.height = 1
    self.backgroundColor = colors.black
    self.foregroundColor = colors.white
    self.placeholderColor = colors.gray
end

function Input:handleEvent(event, p1, p2, p3)
    if not self.visible then return false end
    
    if event == "mouse_click" or event == "monitor_touch" then
        local btn, x, y = p1, p2, p3
        if event == "monitor_touch" then btn = 1; x = p1; y = p2; end
        
        if self:hitTest(x, y) then
            self.isFocused = true
        else
            self.isFocused = false
        end
    end
    
    if self.isFocused then
        if event == "char" then
            self.text = self.text .. p1
            return true
        elseif event == "key" then
            local key = p1
            if key == keys.backspace then
                if #self.text > 0 then
                    self.text = string.sub(self.text, 1, #self.text - 1)
                end
                return true
            end
        end
    end
    
    return Element.handleEvent(self, event, p1, p2, p3)
end

function Input:draw(renderTarget)
    if not self.visible then return end
    
    renderTarget.setBackgroundColor(self.backgroundColor)
    for dy = 0, self.height - 1 do
        renderTarget.setCursorPos(self.x, self.y + dy)
        renderTarget.write(string.rep(" ", self.width))
    end
    
    renderTarget.setCursorPos(self.x, self.y)
    
    local txt = self.text
    if #txt == 0 and not self.isFocused then
        renderTarget.setTextColor(self.placeholderColor)
        local p = self.placeholder
        if #p > self.width then p = string.sub(p, 1, self.width) end
        renderTarget.write(p)
    else
        renderTarget.setTextColor(self.foregroundColor)
        local displayTxt = txt
        if #displayTxt > self.width then
            displayTxt = string.sub(displayTxt, #displayTxt - self.width + 1)
        end
        renderTarget.write(displayTxt)
    end
    
    if self.isFocused and renderTarget.setCursorBlink then
        local px = self.x + math.min(#self.text, self.width - 1)
        renderTarget.setCursorPos(px, self.y)
        renderTarget.setCursorBlink(true)
    elseif not self.isFocused and renderTarget.setCursorBlink then
        -- Technically we can't unset it globally safely without tracking who owns focus,
        -- but Screen could do an event pass to disable blinking if no input is focused.
    end
    
    local sortedChildren = {}
    for _, c in ipairs(self.children) do table.insert(sortedChildren, c) end
    table.sort(sortedChildren, function(a, b) return a.zIndex < b.zIndex end)
    for _, c in ipairs(sortedChildren) do c:draw(renderTarget) end
end

return Input

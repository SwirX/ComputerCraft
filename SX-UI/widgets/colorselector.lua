local class = require("lib.sxui.core.class")
local Element = require("lib.sxui.core.element")

local ColorSelector = class(Element)

local CC_COLORS = {
    colors.white, colors.orange, colors.magenta, colors.lightBlue,
    colors.yellow, colors.lime, colors.pink, colors.gray,
    colors.lightGray, colors.cyan, colors.purple, colors.blue,
    colors.brown, colors.green, colors.red, colors.black,
}

function ColorSelector:new()
    Element.new(self)
    self.selectedColor = colors.white
    self.tileWidth = 2
    self.tileHeight = 1
    self.columns = 8
    local rows = math.ceil(16 / self.columns)
    self.size.offsetX = self.columns * self.tileWidth
    self.size.offsetY = rows
    self.onChange = nil
end

function ColorSelector:handleEvent(event, p1, p2, p3)
    if not self.visible then return false end

    if event == "mouse_click" or event == "monitor_touch" then
        local btn, cx, cy = p1, p2, p3
        if event == "monitor_touch" then
            btn = 1; cx = p1; cy = p2;
        end

        if self:hitTest(cx, cy) and btn == 1 then
            local bx, by = self:getAbsolutePosition()
            local col = math.floor((cx - bx) / self.tileWidth)
            local row = cy - by
            local idx = row * self.columns + col + 1

            if idx >= 1 and idx <= 16 then
                self.selectedColor = CC_COLORS[idx]
                if self.onChange then self.onChange(self, self.selectedColor) end
            end
            return true
        end
    end

    return Element.handleEvent(self, event, p1, p2, p3)
end

function ColorSelector:draw(renderTarget)
    if not self.visible then return end

    local x, y = self:getAbsolutePosition()

    for i, color in ipairs(CC_COLORS) do
        local idx = i - 1
        local col = idx % self.columns
        local row = math.floor(idx / self.columns)
        local tx = x + col * self.tileWidth
        local ty = y + row * self.tileHeight

        renderTarget.setBackgroundColor(color)
        renderTarget.setCursorPos(tx, ty)

        if color == self.selectedColor then
            renderTarget.setTextColor(color == colors.black and colors.white or colors.black)
            renderTarget.write(string.rep("*", self.tileWidth))
        else
            renderTarget.write(string.rep(" ", self.tileWidth))
        end
    end

    local sortedChildren = {}
    for _, c in ipairs(self.children) do table.insert(sortedChildren, c) end
    table.sort(sortedChildren, function(a, b) return a.zIndex < b.zIndex end)
    for _, c in ipairs(sortedChildren) do c:draw(renderTarget) end
end

return ColorSelector

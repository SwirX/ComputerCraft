local class = require("core.class")
local Element = require("core.element")

local Multiline = class(Element)

function Multiline:new(text)
    Element.new(self)
    self.text = text or ""
    self.size.offsetX = 20
    self.size.offsetY = 5
    self.backgroundColor = colors.black
    self.foregroundColor = colors.white
    self.scrollY = 0
end

local function wrapText(str, limit)
    local lines = {}
    for line in string.gmatch(str .. '\n', "(.-)\n") do
        if #line == 0 then
            table.insert(lines, "")
        else
            while #line > 0 do
                table.insert(lines, string.sub(line, 1, limit))
                line = string.sub(line, limit + 1)
            end
        end
    end
    return lines
end

function Multiline:handleEvent(event, p1, p2, p3)
    if not self.visible then return false end

    if event == "mouse_scroll" then
        local dir, cx, cy = p1, p2, p3
        if self:hitTest(cx, cy) then
            self.scrollY = self.scrollY + dir
            if self.scrollY < 0 then self.scrollY = 0 end
            return true
        end
    end

    return Element.handleEvent(self, event, p1, p2, p3)
end

function Multiline:draw(renderTarget)
    if not self.visible then return end

    local x, y = self:getAbsolutePosition()
    local w, h = self:getAbsoluteSize()

    if w > 0 and h > 0 then
        renderTarget.setBackgroundColor(self.backgroundColor)
        for dy = 0, h - 1 do
            renderTarget.setCursorPos(x, y + dy)
            renderTarget.write(string.rep(" ", w))
        end
    end

    renderTarget.setTextColor(self.foregroundColor)

    local lines = wrapText(self.text, w)

    local maxScroll = math.max(0, #lines - h)
    if self.scrollY > maxScroll then self.scrollY = maxScroll end

    for i = 1, h do
        local lineIdx = self.scrollY + i
        if lineIdx <= #lines then
            renderTarget.setCursorPos(x, y + i - 1)
            renderTarget.write(lines[lineIdx])
        end
    end

    local sortedChildren = {}
    for _, c in ipairs(self.children) do table.insert(sortedChildren, c) end
    table.sort(sortedChildren, function(a, b) return a.zIndex < b.zIndex end)
    for _, c in ipairs(sortedChildren) do c:draw(renderTarget) end
end

return Multiline

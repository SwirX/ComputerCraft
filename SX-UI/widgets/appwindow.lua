local class = require("lib.sxui.core.class")
local Element = require("lib.sxui.core.element")

-- We handle drag exclusively from the titlebar rather than the whole frame body,
-- so draggable is intentionally left false on the base Element.
local AppWindow = class(Element)

function AppWindow:new(title)
    Element.new(self)
    self.title = title or "Window"
    self.titlebarHeight = 1
    self.backgroundColor = colors.lightGray
    self.titlebarColor = colors.blue
    self.titlebarTextColor = colors.white
    self.size.offsetX = 30
    self.size.offsetY = 15

    self._titleDragging = false
    self._titleDragOffsetX = 0
    self._titleDragOffsetY = 0
end

function AppWindow:handleEvent(event, p1, p2, p3)
    if not self.visible then return false end

    local myX, myY = self:getAbsolutePosition()
    local myW, _ = self:getAbsoluteSize()

    if event == "mouse_click" or event == "monitor_touch" then
        local btn, cx, cy = p1, p2, p3
        if event == "monitor_touch" then
            btn = 1; cx = p1; cy = p2;
        end

        if btn == 1 and cx >= myX and cx < myX + myW and cy == myY then
            self._titleDragging = true
            self._titleDragOffsetX = cx - myX
            self._titleDragOffsetY = cy - myY
            if self.parent then
                local maxZ = 0
                for _, sibling in ipairs(self.parent.children) do
                    if sibling ~= self and sibling.zIndex > maxZ then
                        maxZ = sibling.zIndex
                    end
                end
                self.zIndex = maxZ + 1
            end
        end
    elseif event == "mouse_drag" then
        local _, cx, cy = p1, p2, p3
        if self._titleDragging then
            local newAbsX = cx - self._titleDragOffsetX
            local newAbsY = cy - self._titleDragOffsetY
            if self.positionType == "relative" and self.parent then
                local pX, pY = self.parent:getAbsolutePosition()
                local pW, pH = self.parent:getAbsoluteSize()
                self.position.offsetX = newAbsX - pX - math.floor(pW * self.position.scaleX)
                self.position.offsetY = newAbsY - pY - math.floor(pH * self.position.scaleY)
            else
                self.position.offsetX = newAbsX
                self.position.offsetY = newAbsY
            end
            return true
        end
    elseif event == "mouse_up" then
        if self._titleDragging then
            self._titleDragging = false
        end
    end

    return Element.handleEvent(self, event, p1, p2, p3)
end

function AppWindow:draw(renderTarget)
    if not self.visible then return end

    local x, y = self:getAbsolutePosition()
    local w, h = self:getAbsoluteSize()

    renderTarget.setBackgroundColor(self.backgroundColor)
    for dy = 1, h - 1 do
        renderTarget.setCursorPos(x, y + dy)
        renderTarget.write(string.rep(" ", w))
    end

    renderTarget.setBackgroundColor(self.titlebarColor)
    renderTarget.setCursorPos(x, y)
    renderTarget.write(string.rep(" ", w))

    local txt = tostring(self.title)
    if #txt > w - 2 then txt = string.sub(txt, 1, w - 2) end
    local drawX = x + math.floor((w - #txt) / 2)
    renderTarget.setCursorPos(drawX, y)
    renderTarget.setTextColor(self.titlebarTextColor)
    renderTarget.write(txt)

    local sortedChildren = {}
    for _, c in ipairs(self.children) do table.insert(sortedChildren, c) end
    table.sort(sortedChildren, function(a, b) return a.zIndex < b.zIndex end)
    for _, c in ipairs(sortedChildren) do c:draw(renderTarget) end
end

return AppWindow

local class = require("core.class")
local Element = require("core.element")

-- We use window.create() for real terminal-level clipping instead of manually
-- checking bounds on every child draw call. This is the only correct way to clip in CC.
local ScrollPanel = class(Element)

function ScrollPanel:new()
    Element.new(self)
    self.backgroundColor = colors.black
    self.size.offsetX = 20
    self.size.offsetY = 8
    self.scrollY = 0
    self._window = nil
end

function ScrollPanel:handleEvent(event, p1, p2, p3)
    if not self.visible then return false end

    if event == "mouse_scroll" then
        local dir, cx, cy = p1, p2, p3
        if self:hitTest(cx, cy) then
            self.scrollY = self.scrollY + dir
            if self.scrollY < 0 then self.scrollY = 0 end
            return true
        end
    end

    if event == "mouse_click" or event == "mouse_drag" or event == "monitor_touch" then
        local btn, cx, cy = p1, p2, p3
        if event == "monitor_touch" then
            btn = 1; cx = p1; cy = p2;
        end

        local ax, ay = self:getAbsolutePosition()
        local aw, ah = self:getAbsoluteSize()
        if cx >= ax and cx < ax + aw and cy >= ay and cy < ay + ah then
            return Element.handleEvent(self, event, p1, p2, p3)
        end
        return false
    end

    return Element.handleEvent(self, event, p1, p2, p3)
end

function ScrollPanel:draw(renderTarget)
    if not self.visible then return end

    local x, y = self:getAbsolutePosition()
    local w, h = self:getAbsoluteSize()

    if not self._window then
        self._window = window.create(renderTarget, x, y, w, h)
    end

    self._window.reposition(x, y, w, h)
    self._window.setBackgroundColor(self.backgroundColor)
    self._window.clear()

    local sortedChildren = {}
    for _, c in ipairs(self.children) do table.insert(sortedChildren, c) end
    table.sort(sortedChildren, function(a, b) return a.zIndex < b.zIndex end)

    -- Shift children up by scrollY purely for the draw pass, then restore
    for _, c in ipairs(sortedChildren) do
        local origOffsetY = c.position.offsetY
        c.position.offsetY = origOffsetY - self.scrollY
        c:draw(self._window)
        c.position.offsetY = origOffsetY
    end
end

return ScrollPanel

local class = require("core.class")

local Element = class()

function Element:new()
    self.position = { scaleX = 0, offsetX = 1, scaleY = 0, offsetY = 1 }
    self.size = { scaleX = 0, offsetX = 10, scaleY = 0, offsetY = 1 }
    self.positionType = "relative" -- relative or absolute

    self.backgroundColor = colors.black
    self.foregroundColor = colors.white
    self.zIndex = 1
    self.visible = true

    self.draggable = false
    self.resizable = false

    self.parent = nil
    self.children = {}

    -- Callbacks
    self.onClick = nil
    self.onRightClick = nil
    self.onMiddleClick = nil
    self.onHover = nil
    self.onLeave = nil
    self.onDrag = nil
    self.onScroll = nil
    self.onKey = nil
    self.onChar = nil

    -- Internal state
    self._isHovered = false
    self._isDragging = false
    self._dragOffsetX = 0
    self._dragOffsetY = 0
end

function Element:getAbsoluteSize()
    if not self.parent then
        return self.size.offsetX, self.size.offsetY
    end
    local pW, pH = self.parent:getAbsoluteSize()
    local w = math.floor(pW * self.size.scaleX + self.size.offsetX)
    local h = math.floor(pH * self.size.scaleY + self.size.offsetY)
    return w, h
end

function Element:getAbsolutePosition()
    if self.positionType == "absolute" or not self.parent then
        return math.floor(self.position.offsetX), math.floor(self.position.offsetY)
    end
    local pX, pY = self.parent:getAbsolutePosition()
    local pW, pH = self.parent:getAbsoluteSize()
    local x = pX + math.floor(pW * self.position.scaleX + self.position.offsetX)
    local y = pY + math.floor(pH * self.position.scaleY + self.position.offsetY)
    return x, y
end

function Element:addChild(child)
    table.insert(self.children, child)
    child.parent = self
end

function Element:removeChild(child)
    for i, c in ipairs(self.children) do
        if c == child then
            table.remove(self.children, i)
            child.parent = nil
            break
        end
    end
end

function Element:draw(renderTarget)
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

    local sortedChildren = {}
    for _, c in ipairs(self.children) do table.insert(sortedChildren, c) end
    table.sort(sortedChildren, function(a, b) return a.zIndex < b.zIndex end)

    for _, c in ipairs(sortedChildren) do
        c:draw(renderTarget)
    end
end

function Element:hitTest(cx, cy)
    local x, y = self:getAbsolutePosition()
    local w, h = self:getAbsoluteSize()
    return cx >= x and cx < x + w and cy >= y and cy < y + h
end

function Element:handleEvent(event, p1, p2, p3)
    if not self.visible then return false end

    -- Sort children backwards to pass events to highest zIndex first
    local sortedChildren = {}
    for _, c in ipairs(self.children) do table.insert(sortedChildren, c) end
    table.sort(sortedChildren, function(a, b) return a.zIndex > b.zIndex end)

    for _, c in ipairs(sortedChildren) do
        if c:handleEvent(event, p1, p2, p3) then
            return true -- Event consumed by child
        end
    end

    -- Handle generic built-in events for self
    if event == "mouse_click" or event == "monitor_touch" then
        local button, cx, cy = p1, p2, p3
        if event == "monitor_touch" then button, cx, cy = 1, p1, p2 end

        if self:hitTest(cx, cy) then
            if self.draggable and button == 1 then
                self._isDragging = true
                local myX, myY = self:getAbsolutePosition()
                self._dragOffsetX = cx - myX
                self._dragOffsetY = cy - myY
            end

            if button == 1 and self.onClick then self.onClick(self, cx, cy) end
            if button == 2 and self.onRightClick then self.onRightClick(self, cx, cy) end
            if button == 3 and self.onMiddleClick then self.onMiddleClick(self, cx, cy) end

            return true -- Consumed
        end
        -- if clicked outside, maybe we were hovered, drop it
        if self._isHovered then
            self._isHovered = false
            if self.onLeave then self.onLeave(self, cx, cy) end
        end
    elseif event == "mouse_drag" then
        local button, cx, cy = p1, p2, p3
        if self._isDragging then
            local newAbsX = cx - self._dragOffsetX
            local newAbsY = cy - self._dragOffsetY

            if self.positionType == "relative" and self.parent then
                local pX, pY = self.parent:getAbsolutePosition()
                local pW, pH = self.parent:getAbsoluteSize()
                self.position.offsetX = newAbsX - pX - math.floor(pW * self.position.scaleX)
                self.position.offsetY = newAbsY - pY - math.floor(pH * self.position.scaleY)
            else
                self.position.offsetX = newAbsX - math.floor(self.position.scaleX)
                self.position.offsetY = newAbsY - math.floor(self.position.scaleY)
            end

            if self.onDrag then self.onDrag(self, cx, cy) end
            return true
        end
    elseif event == "mouse_up" then
        if self._isDragging then
            self._isDragging = false
            return true
        end
    elseif event == "mouse_scroll" then
        local dir, cx, cy = p1, p2, p3
        if self:hitTest(cx, cy) then
            if self.onScroll then self.onScroll(self, dir, cx, cy) end
            return true
        end
    elseif event == "mouse_move" then -- Synthetic event generated by Screen
        local cx, cy = p1, p2
        local hit = self:hitTest(cx, cy)
        if hit and not self._isHovered then
            self._isHovered = true
            if self.onHover then self.onHover(self, cx, cy) end
        elseif not hit and self._isHovered then
            self._isHovered = false
            if self.onLeave then self.onLeave(self, cx, cy) end
        end
    end

    if event == "key" and self.onKey then
        return self.onKey(self, p1, p2)
    end
    if event == "char" and self.onChar then
        return self.onChar(self, p1)
    end

    return false
end

return Element

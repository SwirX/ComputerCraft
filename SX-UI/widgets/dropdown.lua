local class = require("core.class")
local Element = require("core.element")

local Dropdown = class(Element)

function Dropdown:new(options)
    Element.new(self)
    self.options = options or {}
    self.selectedIndex = 1
    self.isOpen = false
    self.size.offsetX = 15
    self.size.offsetY = 1
    self.backgroundColor = colors.gray
    self.foregroundColor = colors.white
    self.listBackgroundColor = colors.lightGray
    self.listForegroundColor = colors.black
    self.listHighlightColor = colors.blue
    self.onChange = nil
end

function Dropdown:getSelectedText()
    if self.options[self.selectedIndex] then
        return tostring(self.options[self.selectedIndex])
    end
    return ""
end

function Dropdown:handleEvent(event, p1, p2, p3)
    if not self.visible then return false end

    if event == "mouse_click" or event == "monitor_touch" then
        local btn, cx, cy = p1, p2, p3
        if event == "monitor_touch" then
            btn = 1; cx = p1; cy = p2;
        end

        if btn == 1 then
            if self.isOpen then
                local lx, ly = self:getAbsolutePosition()
                local lw, _ = self:getAbsoluteSize()
                ly = ly + 1

                for i, opt in ipairs(self.options) do
                    if cx >= lx and cx < lx + lw and cy == ly + i - 1 then
                        self.selectedIndex = i
                        self.isOpen = false
                        if self.onChange then self.onChange(self, i, opt) end
                        return true
                    end
                end
                self.isOpen = false
                return true
            else
                if self:hitTest(cx, cy) then
                    self.isOpen = true
                    return true
                end
            end
        end
    end

    return Element.handleEvent(self, event, p1, p2, p3)
end

function Dropdown:draw(renderTarget)
    if not self.visible then return end

    local x, y = self:getAbsolutePosition()
    local w, _ = self:getAbsoluteSize()

    renderTarget.setBackgroundColor(self.backgroundColor)
    renderTarget.setCursorPos(x, y)
    renderTarget.write(string.rep(" ", w))

    local arrow = self.isOpen and " v " or " > "
    local headerText = self:getSelectedText()
    local maxTxt = w - #arrow
    if #headerText > maxTxt then headerText = string.sub(headerText, 1, maxTxt) end

    renderTarget.setCursorPos(x, y)
    renderTarget.setTextColor(self.foregroundColor)
    renderTarget.write(headerText .. arrow)

    if self.isOpen then
        for i, opt in ipairs(self.options) do
            local itemY = y + i
            renderTarget.setCursorPos(x, itemY)

            if i == self.selectedIndex then
                renderTarget.setBackgroundColor(self.listHighlightColor)
            else
                renderTarget.setBackgroundColor(self.listBackgroundColor)
            end

            renderTarget.write(string.rep(" ", w))
            renderTarget.setCursorPos(x, itemY)
            renderTarget.setTextColor(self.listForegroundColor)
            local optTxt = tostring(opt)
            if #optTxt > w then optTxt = string.sub(optTxt, 1, w) end
            renderTarget.write(optTxt)
        end
    end

    local sortedChildren = {}
    for _, c in ipairs(self.children) do table.insert(sortedChildren, c) end
    table.sort(sortedChildren, function(a, b) return a.zIndex < b.zIndex end)
    for _, c in ipairs(sortedChildren) do c:draw(renderTarget) end
end

return Dropdown

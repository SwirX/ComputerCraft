local class = require("lib.sxui.core.class")
local Element = require("lib.sxui.core.element")

local TextEdit = class(Element)

function TextEdit:new()
    Element.new(self)
    self.lines = { "" }
    self.cursorLine = 1
    self.cursorCol = 1
    self.scrollY = 0
    self.isFocused = false
    self.size.offsetX = 30
    self.size.offsetY = 8
    self.backgroundColor = colors.black
    self.foregroundColor = colors.white
    self.placeholderColor = colors.gray
    self.placeholder = "Type here..."
end

function TextEdit:getText()
    return table.concat(self.lines, "\n")
end

function TextEdit:setText(str)
    self.lines = {}
    for line in string.gmatch(str .. "\n", "(.-)\n") do
        table.insert(self.lines, line)
    end
    if #self.lines == 0 then self.lines = { "" } end
    self.cursorLine = #self.lines
    self.cursorCol = #self.lines[self.cursorLine] + 1
end

function TextEdit:handleEvent(event, p1, p2, p3)
    if not self.visible then return false end

    if event == "mouse_click" or event == "monitor_touch" then
        local btn, cx, cy = p1, p2, p3
        if event == "monitor_touch" then
            btn = 1; cx = p1; cy = p2;
        end

        if self:hitTest(cx, cy) then
            self.isFocused = true
            local ex, ey = self:getAbsolutePosition()
            local clickedLine = self.scrollY + (cy - ey) + 1
            if clickedLine >= 1 and clickedLine <= #self.lines then
                self.cursorLine = clickedLine
                local lineLen = #self.lines[self.cursorLine]
                self.cursorCol = math.min(cx - ex + 1, lineLen + 1)
            end
            return true
        else
            self.isFocused = false
        end
    elseif event == "mouse_scroll" then
        local dir, cx, cy = p1, p2, p3
        if self:hitTest(cx, cy) then
            self.scrollY = self.scrollY + dir
            if self.scrollY < 0 then self.scrollY = 0 end
            local _, h = self:getAbsoluteSize()
            local maxScroll = math.max(0, #self.lines - h)
            if self.scrollY > maxScroll then self.scrollY = maxScroll end
            return true
        end
    end

    if self.isFocused then
        if event == "char" then
            local line = self.lines[self.cursorLine]
            local before = string.sub(line, 1, self.cursorCol - 1)
            local after = string.sub(line, self.cursorCol)
            self.lines[self.cursorLine] = before .. p1 .. after
            self.cursorCol = self.cursorCol + 1
            return true
        elseif event == "key" then
            local key = p1
            if key == keys.backspace then
                if self.cursorCol > 1 then
                    local line = self.lines[self.cursorLine]
                    self.lines[self.cursorLine] = string.sub(line, 1, self.cursorCol - 2) ..
                    string.sub(line, self.cursorCol)
                    self.cursorCol = self.cursorCol - 1
                elseif self.cursorLine > 1 then
                    local prevLine = self.lines[self.cursorLine - 1]
                    local curLine = self.lines[self.cursorLine]
                    self.cursorCol = #prevLine + 1
                    self.lines[self.cursorLine - 1] = prevLine .. curLine
                    table.remove(self.lines, self.cursorLine)
                    self.cursorLine = self.cursorLine - 1
                end
                return true
            elseif key == keys.enter then
                local line = self.lines[self.cursorLine]
                local before = string.sub(line, 1, self.cursorCol - 1)
                local after = string.sub(line, self.cursorCol)
                self.lines[self.cursorLine] = before
                table.insert(self.lines, self.cursorLine + 1, after)
                self.cursorLine = self.cursorLine + 1
                self.cursorCol = 1
                local _, h = self:getAbsoluteSize()
                if self.cursorLine > self.scrollY + h then self.scrollY = self.cursorLine - h end
                return true
            elseif key == keys.up then
                if self.cursorLine > 1 then
                    self.cursorLine = self.cursorLine - 1
                    self.cursorCol = math.min(self.cursorCol, #self.lines[self.cursorLine] + 1)
                    if self.cursorLine <= self.scrollY then self.scrollY = self.cursorLine - 1 end
                end
                return true
            elseif key == keys.down then
                if self.cursorLine < #self.lines then
                    self.cursorLine = self.cursorLine + 1
                    self.cursorCol = math.min(self.cursorCol, #self.lines[self.cursorLine] + 1)
                    local _, h = self:getAbsoluteSize()
                    if self.cursorLine > self.scrollY + h then self.scrollY = self.cursorLine - h end
                end
                return true
            elseif key == keys.left then
                if self.cursorCol > 1 then
                    self.cursorCol = self.cursorCol - 1
                elseif self.cursorLine > 1 then
                    self.cursorLine = self.cursorLine - 1
                    self.cursorCol = #self.lines[self.cursorLine] + 1
                end
                return true
            elseif key == keys.right then
                if self.cursorCol <= #self.lines[self.cursorLine] then
                    self.cursorCol = self.cursorCol + 1
                elseif self.cursorLine < #self.lines then
                    self.cursorLine = self.cursorLine + 1
                    self.cursorCol = 1
                end
                return true
            end
        end
    end

    return Element.handleEvent(self, event, p1, p2, p3)
end

function TextEdit:draw(renderTarget)
    if not self.visible then return end

    local x, y = self:getAbsolutePosition()
    local w, h = self:getAbsoluteSize()

    renderTarget.setBackgroundColor(self.backgroundColor)
    for dy = 0, h - 1 do
        renderTarget.setCursorPos(x, y + dy)
        renderTarget.write(string.rep(" ", w))
    end

    if #self.lines == 1 and self.lines[1] == "" and not self.isFocused then
        renderTarget.setCursorPos(x, y)
        renderTarget.setTextColor(self.placeholderColor)
        local p = self.placeholder
        if #p > w then p = string.sub(p, 1, w) end
        renderTarget.write(p)
        return
    end

    renderTarget.setTextColor(self.foregroundColor)

    for row = 1, h do
        local lineIdx = self.scrollY + row
        if lineIdx <= #self.lines then
            local lineTxt = self.lines[lineIdx]
            if #lineTxt > w then lineTxt = string.sub(lineTxt, 1, w) end
            renderTarget.setCursorPos(x, y + row - 1)
            renderTarget.write(lineTxt)
        end
    end

    if self.isFocused and renderTarget.setCursorBlink then
        local cursorScreenRow = self.cursorLine - self.scrollY
        if cursorScreenRow >= 1 and cursorScreenRow <= h then
            local cursorX = x + math.min(self.cursorCol - 1, w - 1)
            local cursorY = y + cursorScreenRow - 1
            renderTarget.setCursorPos(cursorX, cursorY)
            renderTarget.setCursorBlink(true)
        end
    end

    local sortedChildren = {}
    for _, c in ipairs(self.children) do table.insert(sortedChildren, c) end
    table.sort(sortedChildren, function(a, b) return a.zIndex < b.zIndex end)
    for _, c in ipairs(sortedChildren) do c:draw(renderTarget) end
end

return TextEdit

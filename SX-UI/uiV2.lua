-- ui.lua

local UI = {}
local elements = {}
local selectedElementIndex = 1
background = colors.black

local Button = {
    -- Properties
    parent = nil,
    backgroundColor = colors.white,
    name = "Button",
    text = "Button",
    textColor = colors.black,
    textAlign = "center",
    visible = true,
    position = {0, 0},
    offset = 1,
    onClick = {},
    _type = "UI_BUTTON",

    -- Methods
    AddOnClick = function(self, callback)
        if type(callback) == "function" then
            table.insert(self.onClick, callback)
        end
    end,

    Render = function(self, isSelected)
        term.setCursorPos(self.position[1], self.position[2])
        term.setBackgroundColor(self.backgroundColor or colors.black)
        term.setTextColor(self.textColor or colors.white)
        
        local text = ""
        if self.textAlign == "center" then
            text = string.rep(" ", self.offset) .. self.text .. string.rep(" ", self.offset)
        elseif self.textAlign == "left" then
            text = self.text .. string.rep(" ", self.offset * 2)
        elseif self.textAlign == "right" then
            text = string.rep(" ", self.offset * 2) .. self.text
        end
        
        if isSelected then
            term.setCursorPos(self.position[1]-4, self.position[2]-4)
            text = "--> " .. text
        end

        term.write(text)
    end,
    Click = function(self)
        for _, func in ipairs(self.onClick) do
            func()
        end
    end
}

local TextLabel = {
    -- Properties
    parent = nil,
    backgroundColor = colors.white,
    name = "",
    text = "TextLabel",
    textColor = colors.black,
    textAlign = "center",
    visible = true,
    position = {0, 0},
    offset = 1,
    _type = "UI_TEXT_LABEL",

    -- Methods
    Render = function(self, isSelected)
        term.setCursorPos(self.position[1], self.position[2])
        local text = ""

        if self.textAlign == "center" then
            text = string.rep(" ", self.offset) .. self.text .. string.rep(" ", self.offset)
        elseif self.textAlign == "left" then
            text = self.text .. string.rep(" ", self.offset * 2)
        elseif self.textAlign == "right" then
            text = string.rep(" ", self.offset * 2) .. self.text
        end

        if isSelected then
            term.setCursorPos(self.position[1]-4, self.position[2]-4)
            text = "--> " .. text
        end

        term.setBackgroundColor(self.backgroundColor or colors.black)
        term.setTextColor(self.textColor or colors.white)
        term.write(text)
    end
}

local CheckBox = {
    -- Properties
    parent = nil,
    backgroundColor = colors.white,
    name = "",
    text = "CheckBox",
    textColor = colors.black,
    visible = true,
    position = {0, 0},
    checked = false,
    _type = "UI_CHECKBOX",

    -- Methods
    Toggle = function(self)
        self.checked = not self.checked
    end,

    Render = function(self, isSelected)
        term.setBackgroundColor(self.backgroundColor or colors.black)
        term.setTextColor(self.textColor or colors.white)
        if isSelected then
            term.setCursorPos(self.position[1]-4, self.position[2]-4)
            if self.checked then
                term.write("--> [X] " .. self.text)
            else
                term.write("--> [ ] " .. self.text)
            end
        else
            term.setCursorPos(self.position[1], self.position[2])
            if self.checked then
                term.write("--> [X] " .. self.text)
            else
                term.write("--> [ ] " .. self.text)
            end
        end
    end
}

local TextBox = {
    -- Properties
    parent = nil,
    backgroundColor = colors.white,
    name = "",
    text = "",
    textColor = colors.black,
    visible = true,
    position = {0, 0},
    width = 10,
    _type = "UI_TEXTBOX",

    -- Methods
    Render = function(self, isSelected)
        term.setBackgroundColor(self.backgroundColor or colors.black)
        term.setTextColor(self.textColor or colors.white)
        term.write(string.rep(" ", self.width))
        term.setCursorPos(self.position[1], self.position[2])
        if isSelected then
            term.setCursorPos(self.position[1]-4, self.position[2]-4)
            term.write("--> " .. self.text)
        else
            term.setCursorPos(self.position[1], self.position[2])
            term.write(self.text)
        end
    end
}

local Slider = {
    -- Properties
    parent = nil,
    backgroundColor = colors.white,
    name = "",
    textColor = colors.black,
    visible = true,
    position = {0, 0},
    width = 10,
    value = 0,
    minValue = 0,
    maxValue = 100,
    onChange = {},
    _type = "UI_SLIDER",

    -- Methods
    SetValue = function(self, value)
        if value >= self.minValue and value <= self.maxValue then
            self.value = value
            self:TriggerChange()
        end
    end,

    IncrementValue = function(self, amount)
        self:SetValue(self.value + amount)
    end,

    DecrementValue = function(self, amount)
        self:SetValue(self.value - amount)
    end,

    TriggerChange = function(self)
        for _, callback in ipairs(self.onChange) do
            callback(self.value)
        end
    end,

    Render = function(self, isSelected)
        term.setBackgroundColor(self.backgroundColor or colors.black)
        term.setTextColor(self.textColor or colors.white)

        local barWidth = math.floor((self.width - 2) * (self.value - self.minValue) / (self.maxValue - self.minValue))
        if isSelected then
            term.setCursorPos(self.position[1]-4, self.position[2]-4)
            term.write("--> ")
            term.write("[")
            term.setBackgroundColor(colors.gray)
            term.write(string.rep(" ", barWidth))
            term.setBackgroundColor(colors.lightGray)
            term.write(string.rep(" ", self.width - 2 - barWidth))
            term.setBackgroundColor(self.backgroundColor or colors.black)
            term.write("]")
        else
            term.setCursorPos(self.position[1], self.position[2])
            term.write("[")
            term.setBackgroundColor(colors.gray)
            term.write(string.rep(" ", barWidth))
            term.setBackgroundColor(colors.lightGray)
            term.write(string.rep(" ", self.width - 2 - barWidth))
            term.setBackgroundColor(self.backgroundColor or colors.black)
            term.write("]")
        end
    end
}

local Frame = {
    -- Properties
    parent = nil,
    backgroundColor = colors.white,
    name = "",
    visible = true,
    position = {0, 0},
    size = {10, 5},
    _type = "UI_FRAME",

    -- Methods
    Render = function(self)
        term.setBackgroundColor(self.backgroundColor or colors.black)

        for y = self.position[2], self.position[2] + self.size[2] - 1 do
            term.setCursorPos(self.position[1], y)

            for x = self.position[1], self.position[1] + self.size[1] - 1 do
                term.write(" ")
            end
        end
    end
}

local ScrollingFrame = {
    -- Properties
    parent = nil,
    backgroundColor = colors.white,
    name = "",
    visible = true,
    position = {0, 0},
    size = {10, 5},
    contentSize = {10, 5},
    scrollPosition = {0, 0},
    _type = "UI_SCROLLING_FRAME",

    -- Methods
    SetScrollPosition = function(self, x, y)
        local maxScrollX = math.max(0, self.contentSize[1] - self.size[1])
        local maxScrollY = math.max(0, self.contentSize[2] - self.size[2])

        self.scrollPosition[1] = math.max(0, math.min(x, maxScrollX))
        self.scrollPosition[2] = math.max(0, math.min(y, maxScrollY))
    end,

    ScrollUp = function(self, amount)
        self:SetScrollPosition(self.scrollPosition[1], self.scrollPosition[2] - (amount or 1))
    end,

    ScrollDown = function(self, amount)
        self:SetScrollPosition(self.scrollPosition[1], self.scrollPosition[2] + (amount or 1))
    end,

    ScrollLeft = function(self, amount)
        self:SetScrollPosition(self.scrollPosition[1] - (amount or 1), self.scrollPosition[2])
    end,

    ScrollRight = function(self, amount)
        self:SetScrollPosition(self.scrollPosition[1] + (amount or 1), self.scrollPosition[2])
    end,

    Render = function(self)
        term.setBackgroundColor(self.backgroundColor or colors.black)

        for y = self.position[2], self.position[2] + self.size[2] - 1 do
            term.setCursorPos(self.position[1], y)

            for x = self.position[1], self.position[1] + self.size[1] - 1 do
                local contentX = x + self.scrollPosition[1]
                local contentY = y + self.scrollPosition[2]

                if contentX >= self.position[1] and contentX < self.position[1] + self.size[1]
                    and contentY >= self.position[2] and contentY < self.position[2] + self.size[2] then
                    term.write(" ")
                else
                    term.write(" ")
                end
            end
        end
    end
}

-- Public Functions

function UI.CreateButton()
    local instance = {}
    setmetatable(instance, { __index = Button })
    table.insert(elements, instance)
    return instance
end

function UI.CreateTextLabel()
    local instance = {}
    setmetatable(instance, { __index = TextLabel })
    table.insert(elements, instance)
    return instance
end

function UI.CreateCheckBox()
    local instance = {}
    setmetatable(instance, { __index = CheckBox })
    table.insert(elements, instance)
    return instance
end

function UI.CreateTextBox()
    local instance = {}
    setmetatable(instance, { __index = TextBox })
    table.insert(elements, instance)
    return instance
end

function UI.CreateSlider()
    local instance = {}
    setmetatable(instance, { __index = Slider })
    table.insert(elements, instance)
    return instance
end

function UI.CreateFrame()
    local instance = {}
    setmetatable(instance, { __index = Frame })
    table.insert(elements, instance)
    return instance
end

function UI.CreateScrollingFrame()
    local instance = {}
    setmetatable(instance, { __index = ScrollingFrame })
    table.insert(elements, instance)
    return instance
end

function UI.ClearScreen()
    term.clear()
    term.setCursorPos(1, 1)
end

function UI.RenderAll()
    term.clear()
    term.setCursorPos(1, 1)

    for i, element in ipairs(elements) do
        element:Render(i == selectedElementIndex)
        term.setBackgroundColor(colors.black)
    end
end

function UI.ChangeBackground(color)
    if type(color) == "number" and color >= 0 and color <= 15 then
        background = color
    end
end

function UI.CreateUI()
    while true do
        UI.RenderAll()
        local event, key = os.pullEvent("key")
        if key == keys.up then
            selectedElementIndex = selectedElementIndex - 1
            if selectedElementIndex < 1 then
                selectedElementIndex = #elements
            end
        elseif key == keys.down then
            selectedElementIndex = selectedElementIndex + 1
            if selectedElementIndex > #elements then
                selectedElementIndex = 1
            end
        elseif key == keys.enter then
            local selectedElement = elements[selectedElementIndex]
            if selectedElement then
                selectedElement:Click()
            end
        end
        UI.ClearScreen()
    end
end

return UI

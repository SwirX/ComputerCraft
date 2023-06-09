Button = {
    -- Properties
    parent = nil,
    backgroundColor = colors.black,
    name = "Button",
    text = "Button",
    textColor = colors.white,
    textAlign = "center",
    visible = true,
    position = {0, 0},
    offset = 1,
    onClick = {},
    _type = "SX_UI_BUTTON",

    -- Methods
    AddOnClick = function(self, func)
        if type(func) == "function" then
            table.insert(self.onClick, func)
        end
    end,
    Click = function(self)
        for _, func in ipairs(self.onClick) do
            func()
        end
    end
}

TextLabel = {
    -- Properties
    parent = nil,
    backgroundColor = colors.black,
    name = "",
    text = "TextLabel",
    textColor = colors.white,
    textAlign = "center",
    visible = true,
    position = {0, 0},
    _type = "SX_UI_TEXT_LABEL",

    -- Methods
    Render = function(self)
        term.setBackgroundColor(self.backgroundColor)
        term.setTextColor(self.textColor)
        term.setCursorPos(self.position[1], self.position[2])
        term.write(self.text)
    end
}

CheckBox = {
    -- Properties
    parent = nil,
    backgroundColor = colors.black,
    name = "CheckBox",
    text = "CheckBox",
    textColor = colors.white,
    position = {0, 0},
    checked = false,
    _type = "SX_UI_CHECKBOX",

    -- Methods
    Toggle = function(self)
        self.checked = not self.checked
    end,

    Render = function(self)
        term.setBackgroundColor(self.backgroundColor)
        term.setTextColor(self.textColor)
        term.setCursorPos(self.position[1], self.position[2])

        local text = "[" .. (self.checked and "X" or " ") .. "] " .. self.text
        term.write(text)
    end
}

TextBox = {
    -- Properties
    parent = nil,
    backgroundColor = colors.black,
    name = "TextBox",
    text = "",
    textColor = colors.white,
    position = {0, 0},
    width = 10,
    _type = "SX_UI_TEXTBOX",

    -- Methods
    SetText = function(self, text)
        self.text = text
    end,

    Render = function(self)
        term.setBackgroundColor(self.backgroundColor)
        term.setTextColor(self.textColor)
        term.setCursorPos(self.position[1], self.position[2])
        term.write(string.rep(" ", self.width))

        local displayText = self.text:sub(1, self.width)
        term.setCursorPos(self.position[1], self.position[2])
        term.write(displayText)
    end
}

UI = {
    RefreshRate = 30,
    items = {},

    -- Methods
    ClearScreen = function()
        term.clear()
        term.setCursorPos(1, 1)
    end,

    AddInstance = function(type, name, parent)
        if type == nil then
            error("Error: Unreferenced type when adding an instance", 0)
        end

        local newInstance = {}
        setmetatable(newInstance, { __index = type })
        if name ~= nil then
            newInstance.name = name
        end
        if parent ~= nil then
            newInstance.parent = parent
        end
        table.insert(UI.items, newInstance)
        return newInstance
    end,

    Render = function()
        for _, element in ipairs(UI.items) do
            if element.visible and element.Render then
                element:Render()
            end
        end
    end
}

EventHandler = function()
    while true do
        local event, param1, param2, param3 = os.pullEvent()
        if event == "key" then
            if param1 == keys.enter then
                for _, element in ipairs(UI.items) do
                    if element._type == "SX_UI_BUTTON" and element.visible then
                        local cursorX, cursorY = term.getCursorPos()
                        local startX = element.position[1]
                        local endX = startX + #element.text + (element.offset * 2) - 1
                        local startY = element.position[2]
                        local endY = startY

                        if cursorX >= startX and cursorX <= endX and cursorY == startY then
                            for _, onClick in ipairs(element.onClick) do
                                onClick(element)
                            end
                        end
                    end
                end
            end
        elseif event == "mouse_click" or event == "monitor_touch" then
            local x = param2
            local y = param3

            for _, element in ipairs(UI.items) do
                if element._type == "SX_UI_CHECKBOX" and element.visible then
                    local startX = element.position[1]
                    local endX = startX + #element.text + 3
                    local startY = element.position[2]
                    local endY = startY

                    if x >= startX and x <= endX and y == startY then
                        element:Toggle()
                    end
                end
            end
        end
    end
end
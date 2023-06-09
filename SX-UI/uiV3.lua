-- ui.lua

local UI = {}

-- Default colors
local defaultBackgroundColor = colors.black
local defaultTextColor = colors.white
local defaultFrameBackgroundColor = colors.gray
local defaultScrollingFrameBackgroundColor = colors.crimson
local defaultSelectedArrow = "--> "

-- UI elements
local elements = {}
local selectedElement = nil

-- Private functions

local function setElementVisibility(element, isVisible)
    element.isVisible = isVisible
    if element.elements ~= nil then
        for _, childElement in ipairs(element.elements) do
            setElementVisibility(childElement, isVisible)
        end
    end
end

local function renderElement(element)
    term.setCursorPos(element.position[1], element.position[2])
    term.setBackgroundColor(element.backgroundColor)
    term.setTextColor(element.textColor)
    term.write(element.text)
end

local function renderSelectedArrow(element)
    term.setCursorPos(element.position[1] - #defaultSelectedArrow, element.position[2])
    term.setTextColor(colors.red)
    term.write(defaultSelectedArrow)
end

local function renderUI()
    term.setBackgroundColor(defaultBackgroundColor)
    term.clear()
    for _, element in ipairs(elements) do
        if element.isVisible then
            renderElement(element)
            if element == selectedElement then
                renderSelectedArrow(element)
            end
        end
    end
end

local function handleKey(key)
    if selectedElement ~= nil then
        if selectedElement.handleKey ~= nil then
            selectedElement:handleKey(key)
        end
    end
    renderUI()
end

-- UI element metatable
local elementMetatable = {
    __index = function(tbl, key)
        if key == "parent" then
            return tbl._parent
        elseif key == "text" then
            return tbl._text
        elseif key == "backgroundColor" then
            return tbl._backgroundColor
        elseif key == "textColor" then
            return tbl._textColor
        elseif key == "isVisible" then
            return tbl._isVisible
        end
    end,
    __newindex = function(tbl, key, value)
        if key == "parent" then
            if value ~= nil and value.elements == nil then
                error("Error: Invalid parent element", 2)
            end
            if tbl._parent ~= nil and tbl._parent.elements ~= nil then
                for i, childElement in ipairs(tbl._parent.elements) do
                    if childElement == tbl then
                        table.remove(tbl._parent.elements, i)
                        break
                    end
                end
            end
            tbl._parent = value
            if tbl._parent ~= nil and tbl._parent.elements ~= nil then
                table.insert(tbl._parent.elements, tbl)
            end
        elseif key == "text" then
            tbl._text = value
        elseif key == "backgroundColor" then
            tbl._backgroundColor = value
        elseif key == "textColor" then
            tbl._textColor = value
        elseif key == "isVisible" then
            tbl._isVisible = value
            setElementVisibility(tbl, value)
        end
    end,
    __tostring = function(tbl)
        return tbl._type
    end,
    __metatable = false
}

-- Button element
local Button = {
    _type = "Button",
    _parent = nil,
    _text = "",
    _backgroundColor = defaultBackgroundColor,
    _textColor = defaultTextColor,
    _isVisible = true,
    handleKey = nil,
    onClick = nil
}
Button = setmetatable(Button, elementMetatable)

function Button:render()
    renderElement(self)
end

-- Checkbox element
local Checkbox = {
    _type = "Checkbox",
    _parent = nil,
    _text = "",
    _backgroundColor = defaultBackgroundColor,
    _textColor = defaultTextColor,
    _isVisible = true,
    handleKey = nil,
    onCheckedChanged = nil,
    isChecked = false
}
Checkbox = setmetatable(Checkbox, elementMetatable)

function Checkbox:render()
    renderElement(self)
end

-- TextBox element
local TextBox = {
    _type = "TextBox",
    _parent = nil,
    _text = "",
    _backgroundColor = defaultBackgroundColor,
    _textColor = defaultTextColor,
    _isVisible = true,
    handleKey = nil,
    onTextChanged = nil
}
TextBox = setmetatable(TextBox, elementMetatable)

function TextBox:render()
    renderElement(self)
end

-- Slider element
local Slider = {
    _type = "Slider",
    _parent = nil,
    _text = "",
    _backgroundColor = defaultBackgroundColor,
    _textColor = defaultTextColor,
    _isVisible = true,
    handleKey = nil,
    onValueChanged = nil,
    minValue = 0,
    maxValue = 100,
    value = 0
}
Slider = setmetatable(Slider, elementMetatable)

function Slider:render()
    renderElement(self)
end

-- Frame element
local Frame = {
    _type = "Frame",
    _parent = nil,
    _backgroundColor = defaultFrameBackgroundColor,
    _isVisible = true,
    elements = {}
}
Frame = setmetatable(Frame, elementMetatable)

function Frame:render()
    renderElement(self)
end

-- ScrollingFrame element
local ScrollingFrame = {
    _type = "ScrollingFrame",
    _parent = nil,
    _backgroundColor = defaultScrollingFrameBackgroundColor,
    _isVisible = true,
    elements = {}
}
ScrollingFrame = setmetatable(ScrollingFrame, elementMetatable)

function ScrollingFrame:render()
    renderElement(self)
end

-- Public functions

function UI.Create(elementType, parent)
    local element
    if elementType == "Button" then
        element = setmetatable({}, { __index = Button })
    elseif elementType == "Checkbox" then
        element = setmetatable({}, { __index = Checkbox })
    elseif elementType == "TextBox" then
        element = setmetatable({}, { __index = TextBox })
    elseif elementType == "Slider" then
        element = setmetatable({}, { __index = Slider })
    elseif elementType == "Frame" then
        element = setmetatable({}, { __index = Frame })
    elseif elementType == "ScrollingFrame" then
        element = setmetatable({}, { __index = ScrollingFrame })
    else
        error("Error: Invalid element type", 2)
    end

    if parent ~= nil and parent.elements == nil then
        error("Error: Invalid parent element", 2)
    end

    element.parent = parent or UI
    element.parent.elements = element.parent.elements or {}
    table.insert(element.parent.elements, element)

    return element
end

function UI.Render()
    renderUI()
end

function UI.HandleKey(key)
    handleKey(key)
end

function UI.Destroy(element)
    if element ~= nil and element.parent ~= nil and element.parent.elements ~= nil then
        for i, childElement in ipairs(element.parent.elements) do
            if childElement == element then
                table.remove(element.parent.elements, i)
                break
            end
        end
    end
end

return UI

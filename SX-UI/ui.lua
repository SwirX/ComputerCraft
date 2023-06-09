-- ui.lua

local UI = {}

-- UI Element metatable
local Element = {}
Element.__index = Element

function Element:Destroy()
  -- Remove element from parent's childNodes
  if self.parent and self.parent.childNodes then
    for i, child in ipairs(self.parent.childNodes) do
      if child == self then
        table.remove(self.parent.childNodes, i)
        break
      end
    end
  end
  
  -- Clear events
  self.events = nil
  
  -- Clear parent reference
  self.parent = nil
end

function Element:onEvent(eventType, handler)
  if not self.events then
    self.events = {}
  end
  if not self.events[eventType] then
    self.events[eventType] = {}
  end
  table.insert(self.events[eventType], handler)
end

function Element:Render()
  -- Render element to screen
  -- You can modify this function to fit your desired rendering logic using the term API
  -- Example: render a button as "[Button]"
  term.setCursorPos(self.position.x, self.position.y)
  term.setBackgroundColor(self.backgroundColor)
  term.write("[" .. self.text .. "]")
end

-- Button constructor
function UI.Button(parent, name, position)
  local button = setmetatable({}, Element)
  button.name = name or "Button"
  button.parent = parent or UI
  button.visibility = true
  button.backgroundColor = colors.gray
  button.position = position or { x = 1, y = 1 }
  button.textColor = colors.white
  button.text = "Button"
  button.textAlign = "left"
  button.offset = 0
  button.onClick = {}
  button.events = {}
  button.childNodes = {}
  -- Event handler for click
  button:onEvent("click", function()
    for _, handler in ipairs(button.onClick) do
      handler()
    end
  end)
  
  return button
end

-- TextLabel constructor
function UI.TextLabel(parent, name, position)
  local textLabel = setmetatable({}, Element)
  textLabel.name = name or "TextLabel"
  textLabel.parent = parent or UI
  textLabel.visibility = true
  textLabel.backgroundColor = colors.black
  textLabel.position = position or { x = 1, y = 1 }
  textLabel.textColor = colors.white
  textLabel.text = "TextLabel"
  textLabel.textAlign = "left"
  textLabel.offset = 0
  textLabel.events = {}
  textLabel.childNodes = {}
  
  return textLabel
end

-- Checkbox constructor
function UI.Checkbox(parent, name, position)
  local checkbox = setmetatable({}, Element)
  checkbox.name = name or "CheckBox"
  checkbox.parent = parent or UI
  checkbox.visibility = true
  checkbox.backgroundColor = colors.lightGray
  checkbox.position = position or { x = 1, y = 1 }
  checkbox.checked = false
  checkbox.events = {}
  checkbox.childNodes = {}
  
  return checkbox
end

-- TextBox constructor
function UI.TextBox(parent, name, position)
  local textBox = setmetatable({}, Element)
  textBox.name = name or "TextBox"
  textBox.parent = parent or UI
  textBox.visibility = true
  textBox.backgroundColor = colors.white
  textBox.position = position or { x = 1, y = 1 }
  textBox.textColor = colors.black
  textBox.text = "TextBox"
  textBox.textAlign = "left"
  textBox.offset = 0
  textBox.events = {}
  textBox.childNodes = {}
  
  return textBox
end

-- Slider constructor
function UI.Slider(parent, name, position)
  local slider = setmetatable({}, Element)
  slider.name = name or "Slider"
  slider.parent = parent or UI
  slider.visibility = true
  slider.backgroundColor = colors.gray
  slider.position = position or { x = 1, y = 1 }
  slider.maxValue = 100
  slider.currentValue = 0
  slider.events = {}
  slider.childNodes = {}
  
  return slider
end

-- Frame constructor
function UI.Frame(parent, name, position)
  local frame = setmetatable({}, Element)
  frame.name = name or "Frame"
  frame.parent = parent or UI
  frame.visibility = true
  frame.backgroundColor = colors.black
  frame.position = position or { x = 1, y = 1 }
  frame.events = {}
  frame.childNodes = {}
  
  return frame
end

-- UI create function
function UI.Create(elementType, parent, name, position)
  if elementType == "button" then
    return UI.Button(parent, name, position)
  elseif elementType == "textlabel" then
    return UI.TextLabel(parent, name, position)
  elseif elementType == "checkbox" then
    return UI.Checkbox(parent, name, position)
  elseif elementType == "textbox" then
    return UI.TextBox(parent, name, position)
  elseif elementType == "slider" then
    return UI.Slider(parent, name, position)
  elseif elementType == "frame" then
    return UI.Frame(parent, name, position)
  else
    error("Invalid element type: " .. tostring(elementType))
  end
end

-- UI destroy function
function UI.Destroy(element)
  if element and type(element) == "table" and element.Destroy then
    element:Destroy()
  else
    error("Invalid element provided")
  end
end

-- Render the UI elements
function UI.Render()
  term.clear()
  term.setCursorPos(1, 1)
  
  local function renderElement(element)
    if element.visibility then
      element:Render()
      
      if element.childNodes then
        for _, child in ipairs(element.childNodes) do
          renderElement(child)
        end
      end
    end
  end
  
  renderElement(UI)
end

return UI

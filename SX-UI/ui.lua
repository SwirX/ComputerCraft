local UI = {}

local function generateUniqueID()
  return tostring(os.clock()) -- Generate a unique ID based on the current time
end

--UI elements


--[[BUTTON]]
local Button = {
  --[[Public Properties]]
  --The position of the element. Defaults to x=1, y=1
  position = { x = 1, y = 1 },
  --The name of the element. Defaults to the element's name
  _name = "Button",
  --Background color of the element. Defaults to white
  backgroundColor = colors.white,
  --Text of the element. Defaults to the name of the element
  text = "Button",
  --Text color of the element. Defaults to black
  textColor = colors.black,
  --Text align of the element's text. Default to 'center'
  textAlign = "center",
  --The offset of the text. Defaults to 0
  offset = 0,
  --[[Private Values]]
  _type = "button",
  _onclickevents = {},
  _id = generateUniqueID(),
  --[[Functions]]
  --Runs the passed function when the button is clicked
  onClick = function(self, fun)
    if type(fun) == 'function' then
      table.insert(self._onclickevents, fun)
    else
      error("The provided argument is not a function", 2)
    end
  end,
  --Removes the element from the UI
  Remove = function(self)
    for i, v in pairs(UI.elements.Screen.elements) do
      if v._id == self._id then
        table.remove(UI.elements.Screen.elements, i)
      end
    end
  end,
  --Stimulate a user click
  Click = function(self)
    for _, func in ipairs(self._onclickevents) do
      func()
    end
  end
}
--Removes the element from the UI
function Button:Remove()
  for i, v in pairs(UI.elements.Screen.elements) do
    if v._id == self._id then
      table.remove(UI.elements.Screen.elements, i)
    end
  end
end

--Clones the current element
function Button:Clone()
  local clone = setmetatable({}, { __index = Button })
  -- Copy properties from self to clone
  -- (position, backgroundColor, text, textColor, etc.)
  return clone
end

--[[TEXTLABEL]]
local TextLabel = {
  --[[Public Properties]]
  --The position of the element. Defaults to x=1, y=1
  position = { x = 1, y = 1 },
  --The name of the element. Defaults to the element's name
  _name = "TextLabel",
  --Background color of the element. Defaults to white
  backgroundColor = colors.white,
  --Text of the element. Defaults to the name of the element
  text = "TextLabel",
  --Text color of the element. Defaults to black
  textColor = colors.black,
  --Text align of the element's text. Default to 'center'
  textAlign = "center",
  --The offset of the text. Defaults to 0
  offset = 0,
  --[[Private Properties]]
  _type = "textlabel",
  _id = generateUniqueID(),
}
--Removes the element from the UI
function TextLabel:Remove()
  for i, v in pairs(UI.elements.Screen.elements) do
    if v._id == self._id then
      table.remove(UI.elements.Screen.elements, i)
    end
  end
end

--Clones the current element
function TextLabel:Clone()
  local clone = setmetatable({}, { __index = TextLabel })
  -- Copy properties from self to clone
  -- (position, backgroundColor, text, textColor, etc.)
  return clone
end

--[[CHECKBOX]]
local CheckBox = {
  --[[Public Properties]]
  --The position of the element. Defaults to x=1, y=1
  position = { x = 1, y = 1 },
  --The name of the element. Defaults to the element's name
  _name = "CheckBox",
  --Background color of the element. Defaults to white
  backgroundColor = colors.white,
  --Text color of the element. Defaults to black
  textColor = colors.black,
  --The value of the checkbox, Defaults to false
  value = false,
  --[[Private Values]]
  _type = "checkbox",
  _id = generateUniqueID(),
  _ontoggleevents = {},
  --[[Functions]]
  --Toggles the value
  Toggle = function(self)
    self.value = not self.value
    for _, func in ipairs(self._ontoggleevents) do
      func()
    end
  end,
  onToggle = function(self, fun)
    if type(fun) == 'function' then
      table.insert(self._ontoggleevents, fun)
    else
      error("The provided argument is not a function", 2)
    end
  end,
  --Stimulate a click
  Click = function(self)
    self:Toggle()
  end
}
--Removes the element from the UI
function CheckBox:Remove()
  for i, v in pairs(UI.elements.Screen.elements) do
    if v._id == self._id then
      table.remove(UI.elements.Screen.elements, i)
    end
  end
end

--Clones the current element
function CheckBox:Clone()
  local clone = setmetatable({}, { __index = CheckBox })
  -- Copy properties from self to clone
  -- (position, backgroundColor, value, etc.)
  return clone
end

--[[TEXTCHECKBOX]]
local TextCheckBox = {
  --[[Public Properties]]
  --The name of the element. Defaults to the element's name
  _name = "TextCheckBox",
  --The position of the element. Defaults to x=1, y=1
  position = { x = 1, y = 1 },
  --Background color of the element. Defaults to white
  backgroundColor = colors.white,
  --Text of the element. Defaults to the name of the element
  text = "",
  --Text color of the element. Defaults to black
  textColor = colors.black,
  --Text align of the element's text. Default to 'center'
  textAlign = "center",
  --Type of the text. Defaults to text
  textType = "text",
  --The offset of the text. Defaults to 0
  offset = 0,
  --The value of the checkbox, Defaults to false
  value = false,
  --[[Private Values]]
  _type = "textcheckbox",
  _id = generateUniqueID(),
  _ontoggleevents = {},
  --[[Functions]]
  --Toggles the value
  Toggle = function(self)
    self.value = not self.value
    for _, func in ipairs(self._ontoggleevents) do
        local s, e = pcall(function ()
          func()
        end)
        if not s then
          error("Error "..e)
        end
    end
  end,
  onToggle = function(self, fun)
    if type(fun) == 'function' then
      table.insert(self._ontoggleevents, fun)
    else
      error("The provided argument is not a function", 2)
    end
  end,
  --Stimulate a click
  Click = function(self)
    self:Toggle()
  end
}
--Removes the element from the UI
function TextCheckBox:Remove()
  for i, v in pairs(UI.elements.Screen.elements) do
    if v._id == self._id then
      table.remove(UI.elements.Screen.elements, i)
    end
  end
end

--Clones the current element
function TextCheckBox:Clone()
  local clone = setmetatable({}, { __index = TextCheckBox })
  -- Copy properties from self to clone
  -- (position, backgroundColor, value, etc.)
  return clone
end


--[[TEXTBOX]]
local TextBox = {
  --[[Public Properties]]
  --The position of the element. Defaults to x=1, y=1
  position = { x = 1, y = 1 },
  --The name of the element. Defaults to the element's name
  _name = "TextBox",
  --Background color of the element. Defaults to white
  backgroundColor = colors.white,
  --Text of the element. Defaults to the name of the element
  text = "",
  --Text color of the element. Defaults to black
  textColor = colors.black,
  --Text of the element. Defaults to the name of the element
  placeholderText = "Type here...",
  --Text color of the element. Defaults to black
  placeholderTextColor = colors.lightGray,
  --Text align of the element's text. Default to 'center'
  textAlign = "center",
  --The offset of the text. Defaults to 0
  offset = 0,
  --Is the element focused. Defaults to false
  focused = false,
  --Clear the text on focus. Defaults to true
  clearOnFocus = true,
  --Type of the text. Defaults to text
  textType = "text",
  --[[Private Properties]]
  _type = "textbox",
  _id = generateUniqueID(),
}
function TextBox:Click()
  self:Focus()
end

function TextBox:Focus(state)
  if type(state) == "nil" then state = true end
  if type(state) ~= "boolean" then error("Wrong type passed. Expected a boolean, got " .. type(state), 2) end
  self.focused = state
  term.setCursorPos(self.position.x, self.position.y)
  term.setCursorBlink(true)

  -- Clear the input text initially
  if self.clearOnFocus then
    self.text = ""
    UI.Clear()
  end
  repeat
    local _, key = os.pullEvent("key")

    -- Handle different key presses
    if key == 28 then -- Enter
      print()
      self.text = self.text:gsub("%s+", " ")
      self.focused = false
    elseif key == 14 then --Backspace
      if #self.text > 0 then
        self.text = self.text:sub(1, #self.text - 1)
      end
    elseif contains(key, {
          --[[2, 3, 4, 5, 6, 7, 8, 9, 10, 11,]]
          16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
          30, 31, 32, 33, 34, 35, 36, 37, 38,
          44, 45, 46, 47, 48, 49, 50,
        }) then
      local char = keys.getName(key)
      self.text = self.text .. char
    elseif key == 57 then
      self.text = self.text .. " "
    elseif key == 5 then
      self.text = self.text .. "'"
    elseif key == 4 then
      self.text = self.text .. '"'
    elseif key == 6 then
      self.text = self.text .. "("
    elseif key == 7 then
      self.text = self.text .. "-"
    elseif key == 9 then
      self.text = self.text .. "_"
    elseif key == 12 then
      self.text = self.text .. ")"
    end
    Render()
  until not self.focused
  term.setCursorBlink(false)
end

--[[SLIDER]]

Slider = {
  --[[Public Properties]]
  --The position of the element. Defaults to x=1, y=1
  position = { x = 1, y = 1 },
  --The name of the element. Defaults to the element's name
  _name = "Slider",
  --Background color of the element. Defaults to white
  backgroundColor = colors.white,
  --Color of the slider. defaults to gray
  sliderColor = colors.gray,
  --The Current value of the slider. Defaults to 50
  value = 50,
  --Width of the slider. Defaults to 10
  width = 10,
  --Is the slider is focused on. Defaults to false
  focused = false,
  --[[Private Properties]]
  _type = "slider",
  _id = generateUniqueID(),
  _onchangeevents = {},
  onChange = function(self, fun)
    if type(fun) == 'function' then
      table.insert(self._onchangeevents, fun)
    else
      error("The provided argument is not a function", 2)
    end
  end,
  --Removes the element from the UI
  Remove = function(self)
    for i, v in pairs(UI.elements.Screen.elements) do
      if v._id == self._id then
        table.remove(UI.elements.Screen.elements, i)
      end
    end
  end,
  --Stimulate a user click
  Change = function(self, value)
    if value == nil then value = 0 end
    self.value = self.value + value
    for _, func in ipairs(self._onchangeevents) do
      func(self.value)
    end
  end
}
function Slider:Focus(state)
  if type(state) == "nil" then state = true end
  if type(state) ~= "boolean" then error("Wrong type passed. Expected a boolean, got " .. type(state), 2) end
  self.focused = state
end

function Slider:Click()
  self:Focus()
end

--[[FRAME]]
Frame = {
  --[[Public Properties]]
  --The position of the element. Defaults to x=1, y=1
  position = { x = 1, y = 1 },
  --The name of the element. Defaults to the element's name
  _name = "Frame",
  --Background color of the element. Defaults to white
  backgroundColor = colors.white,
  --Width
  width = 10,
  --Height
  height = 10,
  --Child elements
  childNodes = {},
  --[[Private Properties]]
  _type = "frame",
  _id = generateUniqueID(),
  _onchange = {},
}
function Frame:getChilds( limit, name, eleType )
  if type(name) == "nil" then name = "" end
  if type(eleType) == "nil" then eleType = "" end
  local elementsTable = {}
  for i, v in pairs(self.childNodes) do
    if limit == 0 then break end
    if limit == nil then table.insert(elementsTable, v)
    else limit = limit - 1 table.insert(elementsTable, v) end
  end
  return elementsTable
end

--[[UI Functions]]

function UI.init()
  UI.Clear()
  UI.hasScreen = false
  UI.elements = {}
  UI.SelectPos = 1
end

function UI.Screen(name)
  local Screen = {
    name = name or "Screen",
    elements = {},
    visible = {},
    backgroundColor = colors.black,
    textColor = colors.white,
  }
  UI.hasScreen = true
  UI.elements.Screen = Screen
  return UI.elements.Screen
end

function UI.Create(type, parent)
  if parent == nil then parent = UI.elements end
  -- if not UI.hasScreen then error("The screen element is not present. Use UI.Screen()", 2) end
  if type == "button" then
    local element = setmetatable({}, { __index = Button })
    element._id = generateUniqueID()
    table.insert(parent, element)
    return element
  elseif type == "textlabel" then
    local element = setmetatable({}, { __index = TextLabel })
    element._id = generateUniqueID()
    table.insert(parent, element)
    return element
  elseif type == "checkbox" then
    local element = setmetatable({}, { __index = CheckBox })
    element._id = generateUniqueID()
    table.insert(parent, element)
    return element
  elseif type == "textcheckbox" then
    local element = setmetatable({}, { __index = TextCheckBox })
    element._id = generateUniqueID()
    table.insert(parent, element)
    return element
  elseif type == "textbox" then
    local element = setmetatable({}, { __index = TextBox })
    element._id = generateUniqueID()
    table.insert(parent, element)
    return element
  elseif type == "slider" then
    local element = setmetatable({}, { __index = Slider })
    element._id = generateUniqueID()
    table.insert(parent, element)
    return element
  elseif type == "frame" then
    local element = setmetatable({}, { __index = Frame })
    element._id = generateUniqueID()
    table.insert(parent, element)
    return element
  else
    error("Invalid element type: " .. tostring(type), 2)
  end
end

function UI.Clear()
  term.clear()
  term.setCursorPos(1, 1)
end

--[[RENDERING]]

local function Render(source)
  if source == nil then source = UI.elements end
  UI.Clear()
  -- if not UI.hasScreen then error("At least one screen should exist", 2) end
    for index, properties in pairs(source) do
      local type = properties._type
      if type == "textlabel" or type == "button" or type == "textcheckbox" then
        local isTxtCB = type == "textcheckbox"
        local x, y = properties.position.x, properties.position.y
        term.setCursorPos(x, y)
        term.setBackgroundColor(properties.backgroundColor)
        term.setTextColor(properties.textColor)
        term.write(string.rep(" ", properties.offset) .. properties.text .. string.rep(" ", properties.offset))
        if isTxtCB then
          local checked = properties.value
          if checked then
            term.write(" [X]")
          else
            term.write(" [ ]")
          end
        end
      elseif type == "textbox" then
        local x, y = properties.position.x, properties.position.y
        local txt
        local clr
        local ogtext = #properties.text or 0
        if properties.text == "" then
          txt = properties.placeholderText
          clr = properties.placeholderTextColor
        elseif properties.textType == "password" then
          if ogtext == nil then ogtext = 0 end
          txt = string.rep("*", ogtext)
        else
          txt = properties.text
          clr = properties.textColor
        end
        term.setCursorPos(x, y)
        term.setBackgroundColor(properties.backgroundColor)
        term.setTextColor(clr)
        term.write(string.rep(" ", properties.offset) .. txt .. string.rep(" ", properties.offset))
      elseif type == "checkbox" then
        local x, y = properties.position.x, properties.position.y
        local checked = properties.value
        term.setCursorPos(x, y)
        term.setBackgroundColor(properties.backgroundColor)
        term.setTextColor(properties.textColor)
        if checked then
          term.write("[X]")
        else
          term.write("[ ]")
        end
      elseif type == "slider" then
        local x, y = properties.position.x, properties.position.y
        local value = properties.value
        local width = properties.width
        local sliderPosition = math.floor((value / 100) * width)
        term.setCursorPos(x, y)
        term.setBackgroundColor(properties.backgroundColor)
        term.setTextColor(properties.sliderColor)
        -- if sliderPosition == 0 then sliderPosition = 1 end
          local text = string.rep(" ", sliderPosition) .. "#" .. string.rep(" ", width - sliderPosition)
          term.write(text)
      elseif type == "frame" then
        local x, y = properties.position.x, properties.position.y
        local width = properties.width+1
        local height = properties.height+1
        local children = properties.childNodes
        term.setBackgroundColor(properties.backgroundColor)
        term.setTextColor(colors.black)
      
        -- Render top border
        term.setCursorPos(x, y)
        term.write(string.rep("-", width))
      
        -- Render sides
        for i = 1, height do
          term.setCursorPos(x, y + i)
          term.write("|")
          term.write(string.rep(" ", width - 2))
          term.setCursorPos(x + width - 1, y + i)
          term.write("|")
        end
      
        -- Render bottom border
        term.setCursorPos(x, y + height)
        term.write(string.rep("-", width))

        for findex, fprops in ipairs(children) do
          local type = properties._type
      if type == "textlabel" or type == "button" then
        local x, y = properties.position.x, properties.position.y
        term.setCursorPos(x, y)
        term.setBackgroundColor(properties.backgroundColor)
        term.setTextColor(properties.textColor)
        term.write(string.rep(" ", properties.offset) .. properties.text .. string.rep(" ", properties.offset))
      elseif type == "textbox" then
        local x, y = properties.position.x, properties.position.y
        local txt
        local clr
        local ogtext = #properties.text or 0
        if properties.text == "" then
          txt = properties.placeholderText
          clr = properties.placeholderTextColor
        elseif properties.textType == "password" then
          if ogtext == nil then ogtext = 0 end
          txt = string.rep("*", ogtext)
        else
          txt = properties.text
          clr = properties.textColor
        end
        term.setCursorPos(x, y)
        term.setBackgroundColor(properties.backgroundColor)
        term.setTextColor(clr)
        term.write(string.rep(" ", properties.offset) .. txt .. string.rep(" ", properties.offset))
      elseif type == "checkbox" then
        local x, y = properties.position.x, properties.position.y
        local checked = properties.value
        term.setCursorPos(x, y)
        term.setBackgroundColor(properties.backgroundColor)
        term.setTextColor(properties.textColor)
        if checked then
          term.write("[X]")
        else
          term.write("[ ]")
        end
      elseif type == "slider" then
        local x, y = properties.position.x, properties.position.y
        local value = properties.value
        local width = properties.width
        local sliderPosition = math.floor((value / 100) * width)
        term.setCursorPos(x, y)
        term.setBackgroundColor(properties.backgroundColor)
        term.setTextColor(properties.sliderColor)
        -- if sliderPosition == 0 then sliderPosition = 1 end
          local text = string.rep(" ", sliderPosition) .. "#" .. string.rep(" ", width - sliderPosition)
          term.write(text)
      end
        end
      end
      
      UI.elements[index] = properties
    end
    term.setBackgroundColor(UI.elements.Screen.backgroundColor)
    term.setTextColor(UI.elements.Screen.textColor)
  end

function ClearScreen()
  term.clear()
  term.setCursorPos(1,1)
end

--[[INPUT HANDELING]]
function UI.HandleInput()
  Render()
  while true do
    local event, button, x, y = os.pullEvent("mouse_click")
    for element, properties in pairs(UI.elements) do
      local type = properties._type
      if type == "button" then
        local ex, ey = properties.position.x, properties.position.y
        local text = properties.text
        local offset = properties.offset
        if y == ey and x >= ex and x <= ex + #text + offset - 1 then
          UI.elements[element]:Click()
        end
      elseif type == "checkbox" then
        local ex, ey = properties.position.x, properties.position.y
        local text = "[X]"
        if y == ey and x >= ex and x <= ex + #text - 1 then
          UI.elements[element]:Click()
        end
      elseif type == "textcheckbox" then
        local ex, ey = properties.position.x, properties.position.y
        local text = properties.text .. " [ ]"
        local offset = properties.offset
        if y == ey and x >= ex and x <= ex + #text + offset - 1 then
          UI.elements[element]:Toggle()
        end
      elseif type == "textbox" then
        local ex, ey = properties.position.x, properties.position.y
        local text
        if properties.text == "" then
          text = properties.placeholderText
        else
          text = properties.text
        end
        local offset = properties.offset
        if y == ey then
          if y == ey and x >= ex and x <= ex + #text + offset - 1 then
            UI.elements[element]:Click()
          else
            UI.elements[element]:Focus(false)
          end
        end
      elseif type == "slider" then
        local ex, ey = properties.position.x, properties.position.y
        local width = properties.width
        local value = properties.value
        local initialScrollBarPosition = math.floor((value / 100) * width) + ex
        -- if properties.focused then
        --   local _, key = os.pullEvent('key')
        --   if key == keys.left then
        --     UI.elements[element]:Change(-1)
        --   elseif key == keys.right then
        --     UI.elements[element]:Change(1)
        --   end
        -- end
        if y == ey and x == initialScrollBarPosition then
          UI.elements[element]:Focus()
          local _, _, x2, _ = os.pullEvent("mouse_up")
          -- Calculate the new value based on the change in position
          local newValue = (x2 - ex) * 10
          if newValue == 0 then
            newValue = value
          elseif newValue < 0 then
            newValue = 0
          elseif newValue > 100 then
            newValue = 100
          end
          -- Calculate the change in value
          local delta = newValue - value
          
          -- Trigger the Change event and pass the delta value
          UI.elements[element]:Change(delta)
        elseif y == ey and x >= ex and x <= ex + width and x ~= initialScrollBarPosition then
          UI.elements[element]:Focus()
          local newValue = (x - ex) * 10
          if newValue < 0 then
            newValue = 0
          elseif newValue > 100 then
            newValue = 100
          end
          local delta = newValue - value
          UI.elements[element]:Change(delta)
        end
      end
    end
    Render()
  end
end

function UI.Refresh()
  Render()
end

function contains(element, table)
  for _, value in ipairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

return UI
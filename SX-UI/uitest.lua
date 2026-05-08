require("sx")
local ui = require("ui")

-- Mega-test showing every widget in a multi-window layout.
-- Two draggable AppWindows are placed on screen. Each demonstrates different widgets.
-- Drag them from their titlebars to reposition.

local screen = ui.Screen()

-- -------------------------
-- Window 1 -- Core Widgets
-- -------------------------
local win1 = ui.AppWindow("Core Widgets")
win1.position.offsetX = 1
win1.position.offsetY = 1
win1.size.offsetX = 36
win1.size.offsetY = 16
win1.zIndex = 1
screen:addChild(win1)

local clickCount = 0
local clickLabel = ui.Label("Clicks: 0")
clickLabel.position.offsetX = 2
clickLabel.position.offsetY = 2
clickLabel.size.offsetX = 15
win1:addChild(clickLabel)

local btn = ui.Button("Click Me!")
btn.position.offsetX = 2
btn.position.offsetY = 3
btn.size.offsetX = 12
btn.backgroundColor = colors.blue
btn.onClick = function(self)
    clickCount = clickCount + 1
    clickLabel.text = "Clicks: " .. clickCount
    self.backgroundColor = colors.purple
    ui.Animator.animate(1, 0, 0.3, ui.Animator.Easing.SineOut, nil, function()
        self.backgroundColor = colors.blue
    end)
end
win1:addChild(btn)

local chk = ui.Checkbox("Toggle me")
chk.position.offsetX = 2
chk.position.offsetY = 5
win1:addChild(chk)

local inputLabel = ui.Label("Text input:")
inputLabel.position.offsetX = 2
inputLabel.position.offsetY = 7
inputLabel.size.offsetX = 12
win1:addChild(inputLabel)

local inp = ui.Input()
inp.position.offsetX = 2
inp.position.offsetY = 8
inp.size.offsetX = 30
inp.placeholder = "Type something..."
win1:addChild(inp)

local sliderLabel = ui.Label("Slider: 50")
sliderLabel.position.offsetX = 2
sliderLabel.position.offsetY = 10
sliderLabel.size.offsetX = 16
win1:addChild(sliderLabel)

local slider = ui.Slider()
slider.position.offsetX = 2
slider.position.offsetY = 11
slider.size.offsetX = 30
slider.min = 0
slider.max = 100
slider.value = 50
slider.onChange = function(self, val)
    sliderLabel.text = "Slider: " .. math.floor(val)
end
win1:addChild(slider)

local ddLabel = ui.Label("Pick a shape:")
ddLabel.position.offsetX = 2
ddLabel.position.offsetY = 13
ddLabel.size.offsetX = 14
win1:addChild(ddLabel)

local dd = ui.Dropdown({ "Circle", "Square", "Triangle", "Hexagon" })
dd.position.offsetX = 2
dd.position.offsetY = 14
dd.size.offsetX = 15
dd.zIndex = 20 -- float above siblings when open
win1:addChild(dd)

-- -------------------------
-- Window 2 -- Text and Colors
-- -------------------------
local win2 = ui.AppWindow("Text & Colors")
win2.position.offsetX = 39
win2.position.offsetY = 1
win2.size.offsetX = 30
win2.size.offsetY = 18
win2.zIndex = 1
screen:addChild(win2)

local teLabel = ui.Label("Multiline Editor:")
teLabel.position.offsetX = 2
teLabel.position.offsetY = 2
teLabel.size.offsetX = 20
win2:addChild(teLabel)

local te = ui.TextEdit()
te.position.offsetX = 2
te.position.offsetY = 3
te.size.offsetX = 26
te.size.offsetY = 5
win2:addChild(te)

local colorLabel = ui.Label("Pick a color:")
colorLabel.position.offsetX = 2
colorLabel.position.offsetY = 9
colorLabel.size.offsetX = 20
win2:addChild(colorLabel)

local selectedColorLabel = ui.Label("Selected: white")
selectedColorLabel.position.offsetX = 2
selectedColorLabel.position.offsetY = 10
selectedColorLabel.size.offsetX = 20
win2:addChild(selectedColorLabel)

local colorPicker = ui.ColorSelector()
colorPicker.position.offsetX = 2
colorPicker.position.offsetY = 11
colorPicker.columns = 8
colorPicker.tileWidth = 2
colorPicker.onChange = function(self, color)
    -- Find name by looking up the colors table
    for name, val in pairs(colors) do
        if type(val) == "number" and val == color then
            selectedColorLabel.text = "Selected: " .. name
            break
        end
    end
end
win2:addChild(colorPicker)

-- -------------------------
-- Window 3 -- Scroll Panel
-- -------------------------
local win3 = ui.AppWindow("Scroll Panel")
win3.position.offsetX = 1
win3.position.offsetY = 19
win3.size.offsetX = 35
win3.size.offsetY = 8
win3.zIndex = 1
screen:addChild(win3)

local sp = ui.ScrollPanel()
sp.position.offsetX = 2
sp.position.offsetY = 2
sp.size.offsetX = 30
sp.size.offsetY = 5
sp.backgroundColor = colors.black
win3:addChild(sp)

-- Fill the scroll panel with multiple labels to scroll through
for i = 1, 15 do
    local row = ui.Label("Item " .. i .. " -- scroll me down!")
    row.position.offsetX = 1
    row.position.offsetY = i
    row.size.offsetX = 28
    row.foregroundColor = (i % 2 == 0) and colors.lime or colors.white
    sp:addChild(row)
end

-- -------------------------
-- Quit Button on Screen Root
-- -------------------------
local quit = ui.Button("[ QUIT ]")
quit.position.offsetX = 1
quit.position.scaleY = 1
quit.position.offsetY = -1
quit.size.offsetX = 10
quit.backgroundColor = colors.red
quit.foregroundColor = colors.white
quit.onClick = function()
    screen:stop()
end
screen:addChild(quit)

screen:run()

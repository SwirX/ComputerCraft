local ui = require("lib.sxui.ui")

local screen = ui.Screen()

local frame = ui.Frame()
frame.position.offsetX = 2
frame.position.offsetY = 2
-- Scaled Frame! It binds to 80% of screen width and 17 characters tall.
frame.size.scaleX = 0.8
frame.size.offsetY = 17
frame.draggable = true
screen:addChild(frame)

local title = ui.Label("SX-UI v" .. ui._VERSION)
title.position.offsetX = 0
title.position.offsetY = 0
title.size.scaleX = 1 -- Takes up 100% of parent width dynamically
title.align = "center"
title.backgroundColor = colors.blue
title.foregroundColor = colors.white
frame:addChild(title)

local clicks = 0
local clickLabel = ui.Label("Clicks: 0")
clickLabel.position.offsetX = 3
clickLabel.position.offsetY = 4
clickLabel.size.offsetX = 15
frame:addChild(clickLabel)

local btn = ui.Button("Click Me")
btn.position.offsetX = 3
btn.position.offsetY = 5
btn.size.offsetX = 15
btn.onClick = function(self)
    clicks = clicks + 1
    clickLabel.text = "Clicks: " .. clicks

    self.backgroundColor = colors.red

    ui.Animator.animate(1, 0, 0.2, nil, nil, function()
        self.backgroundColor = colors.gray
    end)
end
frame:addChild(btn)

local input = ui.Input()
input.position.offsetX = 20
input.position.offsetY = 5
input.size.offsetX = 20
input.placeholder = "Type here..."
frame:addChild(input)

local chk = ui.Checkbox("Enable features")
chk.position.offsetX = 3
chk.position.offsetY = 8
frame:addChild(chk)

local slider = ui.Slider()
slider.position.offsetX = 3
slider.position.offsetY = 10
slider.size.offsetX = 15
slider.min = 0
slider.max = 100
slider.value = 50

local sliderVal = ui.Label("50%")
sliderVal.position.offsetX = 20
sliderVal.position.offsetY = 10
sliderVal.size.offsetX = 10
slider.onChange = function(self, val)
    sliderVal.text = math.floor(val) .. "%"
end
frame:addChild(slider)
frame:addChild(sliderVal)

local multi = ui.Multiline(
"This is a multiline text block.\nIt natively wraps text correctly according to Scale width constraints!")
multi.position.offsetX = 3
multi.position.offsetY = 12
-- Bound multiline size tracking 90% of frame width
multi.size.scaleX = 0.90
multi.size.offsetY = 3
multi.backgroundColor = colors.black
frame:addChild(multi)

local quitBtn = ui.Button("Quit")
-- Pins perfectly to the bottom-right of the frame recursively
quitBtn.position.scaleX = 1
quitBtn.position.offsetX = -6
quitBtn.position.scaleY = 1
quitBtn.position.offsetY = -1
quitBtn.size.offsetX = 6
quitBtn.backgroundColor = colors.red
quitBtn.onClick = function()
    screen:stop()
end
frame:addChild(quitBtn)

-- Start the framework loop
screen:run()

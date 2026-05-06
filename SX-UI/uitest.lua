local ui = require("lib.sxui.ui")

local screen = ui.Screen()

local frame = ui.Frame()
frame.x = 2
frame.y = 2
frame.width = 48
frame.height = 17
frame.draggable = true -- Enable drag!
screen:addChild(frame)

local title = ui.Label("SX-UI v" .. ui._VERSION)
title.x = 1
title.y = 1
title.width = frame.width
title.align = "center"
title.backgroundColor = colors.blue
title.foregroundColor = colors.white
frame:addChild(title)

local clicks = 0
local clickLabel = ui.Label("Clicks: 0")
clickLabel.x = 3
clickLabel.y = 4
clickLabel.width = 15
frame:addChild(clickLabel)

local btn = ui.Button("Click Me")
btn.x = 3
btn.y = 5
btn.width = 15
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
input.x = 20
input.y = 5
input.width = 20
input.placeholder = "Type here..."
frame:addChild(input)

local chk = ui.Checkbox("Enable features")
chk.x = 3
chk.y = 8
frame:addChild(chk)

local slider = ui.Slider()
slider.x = 3
slider.y = 10
slider.width = 15
slider.min = 0
slider.max = 100
slider.value = 50

local sliderVal = ui.Label("50%")
sliderVal.x = 20
sliderVal.y = 10
sliderVal.width = 10
slider.onChange = function(self, val)
    sliderVal.text = math.floor(val) .. "%"
end
frame:addChild(slider)
frame:addChild(sliderVal)

local multi = ui.Multiline("This is a multiline text block.\nIt automatically wraps text if it's too long, and is totally supported in v2.0.0.")
multi.x = 3
multi.y = 12
multi.width = 40
multi.height = 3
multi.backgroundColor = colors.black
frame:addChild(multi)

local quitBtn = ui.Button("Quit")
quitBtn.x = frame.width - 6
quitBtn.y = frame.height - 1
quitBtn.width = 6
quitBtn.backgroundColor = colors.red
quitBtn.onClick = function()
    screen:stop()
end
frame:addChild(quitBtn)

-- Start the framework loop
screen:run()

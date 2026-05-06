local ui = require("lib.sxui.ui")

local mon = peripheral.find("monitor")
if not mon then
    print("No monitor found!")
    return
end

mon.setTextScale(1)
local screen = ui.Screen(mon)

local label = ui.Label("Monitor UI Test v" .. ui._VERSION)
label.size.scaleX = 1
label.size.offsetY = 1
label.align = "center"
label.backgroundColor = colors.blue
screen:addChild(label)

local btn = ui.Button("Touch Me")
btn.position.offsetY = 3
btn.size.offsetX = 10
btn.backgroundColor = colors.gray
btn.onClick = function(self)
    label.text = "Touched!"
    label.backgroundColor = colors.lime
end
screen:addChild(btn)

local quit = ui.Button("Quit")
quit.position.offsetY = 5
quit.size.offsetX = 10
quit.backgroundColor = colors.red
quit.onClick = function()
    screen:stop()
end
screen:addChild(quit)

screen:run()

local ui = require("ui")

local mon = peripheral.find("monitor")
if not mon then
    print("No monitor found!")
    return
end

mon.setTextScale(1)
-- Creating a screen natively linked to a monitor
local screen = ui.Screen(mon)

local label = ui.Label("Monitor UI Test v" .. ui._VERSION)
label.width = 25
label.height = 1
label.align = "center"
label.backgroundColor = colors.blue
screen:addChild(label)

local btn = ui.Button("Touch Me")
btn.y = 3
btn.width = 10
btn.backgroundColor = colors.gray
btn.onClick = function(self)
    label.text = "Touched!"
    label.backgroundColor = colors.lime
end
screen:addChild(btn)

local quit = ui.Button("Quit")
quit.y = 5
quit.width = 10
quit.backgroundColor = colors.red
quit.onClick = function()
    screen:stop()
end
screen:addChild(quit)

screen:run()

-- main.lua

local UI = require("uiV2")

local button1 = UI.CreateButton()
button1.text = "Button 1"
button1.position = {2, 2}
button1.backgroundColor = colors.blue
button1.textColor = colors.white

local button2 = UI.CreateButton()
button2.text = "Button 2"
button2.position = {2, 4}
button2.backgroundColor = colors.red
button2.textColor = colors.white

local tl = UI.CreateTextLabel()
tl.text = ""
tl.position = {2, 6}

button1.AddOnClick(function()
    tl.text = "button 1 clicked!"
end)
button2.AddOnClick(function()
    tl.text = "button 2 clicked!"
end)

while true do
    UI.CreateUI()
end

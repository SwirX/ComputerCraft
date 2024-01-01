--require the library
local ui = require("ui")

--initialise the ui
ui.init()

--set a screen
local screen = ui.Screen()  -- you can pass the screen name if you like or leave it empty

clicks = 0

--create a textlabel
label = ui.Create("textlabel")
label.text = term.getSize()

--create a button
button = ui.Create("button") -- thhe parent can be passed as the second argument
button.text = "This is a button"
button.backgroundColor = colors.red
button.textColor = colors.white
button.position = {x=1, y=3}
button:onClick(function ()
    button.backgroundColor = colors.blue
    clicks = clicks + 1
    text = string.format("the button has been clicked %d time", clicks)
    if clicks ~= 1 then text = text .. "s" end
    label.text = text
end)


--create a textbox
textbox = ui.Create("textbox")
textbox.clearOnFocus = false -- wether or not the text would be cleared when focusing the textbox
textbox.placeholderText = "click here to write"
textbox.offset = 2 -- the offset of the text in relation with the width of the textbox
textbox.position = {x=1, y=4}

--create a frame
frame = ui.Create("frame")
frame.position = {x=1, y=5}
frame.width = 51
frame.height = 15
frame.backgroundColor = colors.green


--create a slider
slider = ui.Create("slider")
slider.position = {x=5, y=7}
sliderValue = ui.Create("textlabel")
sliderValue.position = {x=5, y=8}
slider:onChange(function (value)
    sliderValue.text = string.format("%d", value)
end)

--[[        uncomment the commented lines bellow if
            you have some problem with your program
            and send me the error
]]

-- local success, err = pcall(function()
    -- your existing code here
    ui.HandleInput()
-- end)

-- if not success then
    -- print("Error occurred: " .. err)
-- end
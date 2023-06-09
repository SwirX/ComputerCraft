local UI = require("ui")

local root = UI.Create("frame", nil, "RootFrame", { x = 1, y = 1 })
local button = UI.Create("button", root, "MyButton", { x = 2, y = 2 })
button.text = "Click Me!"
local label = UI.Create("textlabel", root, "MyLabel", {1,1})
label.text = "This is a textlabel"
button.onClick = {
  function()
    label.text = "Button clicked"
end
}
button:onEvent("click", function()
    label.text = "Button clicked!"
    label.backgroundColor = colors.green
end)

UI.Render()

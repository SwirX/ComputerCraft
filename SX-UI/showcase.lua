local UI = require("uiV3")

local button = UI.Create("Button")
button.text = "Click me!"
button.position = {1,1}
button._backgroundColor = colors.blue
button._textColor = colors.red

-- Render the UI
while true do
    UI.Render()
    local event, key = os.pullEvent("key")
    if event == "key" then
        UI.HandleKey(key)
    end
end

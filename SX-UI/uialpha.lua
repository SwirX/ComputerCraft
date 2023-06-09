UI = {}
elements = UI.elements


--UI elements
Button = {
    position = {x=1, y=1},
    name = "Button"
    
}


function UI.Screen(name)
    local Screen = {
        name = name or "Screen",
        elements = {},
        visible = {},
        background = colors.black,
}
end

function UI.Create(type, parent)
    if type == "button" then
        table.insert(elements, type)
        return UI.Button(parent)
      elseif type == "textlabel" then
        return UI.TextLabel(parent)
      elseif type == "checkbox" then
        return UI.Checkbox(parent)
      elseif type == "textbox" then
        return UI.TextBox(parent)
      elseif type == "slider" then
        return UI.Slider(parent)
      elseif type == "frame" then
        return UI.Frame(parent)
      else
        error("Invalid element type: " .. tostring(type))
      end
end
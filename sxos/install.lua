-- SXOS Installation Selector
term.clear()
term.setCursorPos(1, 1)
print("Welcome to the SXOS Live Environment")
print("Please select an installation mode:\n")

local w, h = term.getSize()
local options = {
    "1. Easy Install (Guided setup for beginners)",
    "2. Advanced Install (Minimal TTY for manual setup)"
}
local selected = 1

local function drawMenu()
    for i, opt in ipairs(options) do
        term.setCursorPos(2, math.floor(h / 2) + i)
        if i == selected then
            term.setTextColor(colors.black)
            term.setBackgroundColor(colors.white)
            term.write(opt)
        else
            term.setTextColor(colors.white)
            term.setBackgroundColor(colors.black)
            term.write(opt)
        end
    end
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
end

drawMenu()
while true do
    local event, key = os.pullEvent("key")
    if key == keys.up then
        selected = selected - 1
        if selected < 1 then selected = #options end
        drawMenu()
    elseif key == keys.down then
        selected = selected + 1
        if selected > #options then selected = 1 end
        drawMenu()
    elseif key == keys.enter then
        break
    end
end

term.clear()
term.setCursorPos(1, 1)

if selected == 1 then
    shell.run("/installers/easy.lua")
elseif selected == 2 then
    shell.run("/installers/advanced.lua")
end

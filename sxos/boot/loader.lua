-- SXOS Bootloader
local configPath = "/.config/sxboot/config.lua"

local config = {
    default_entry = 2,
    timeout = 5,
    hidden = false,
    colors = {
        background = colors.black,
        text = colors.lightGray,
        selected_bg = colors.gray,
        selected_text = colors.white,
        title = colors.blue
    }
}

if fs.exists(configPath) then
    local loadedConfig = dofile(configPath)
    if type(loadedConfig) == "table" then
        for k, v in pairs(loadedConfig) do
            if type(v) == "table" and type(config[k]) == "table" then
                for ik, iv in pairs(v) do config[k][ik] = iv end
            else
                config[k] = v
            end
        end
    end
end

local entries = {
    "CraftOS",
    "SXOS"
}

if config.hidden then
    if config.default_entry == 2 then
        shell.run("/sys/kernel.lua")
    end
    return
end

local selected = config.default_entry
local w, h = term.getSize()
local timer = os.startTimer(config.timeout)
local timeoutRemaining = config.timeout

local function drawMenu()
    term.setBackgroundColor(config.colors.background)
    term.clear()

    -- Draw Title
    local title = "GNU GRUB version SXOS-1.0"
    term.setCursorPos(math.floor((w - #title) / 2) + 1, 2)
    term.setTextColor(config.colors.title)
    term.write(title)

    local menuY = math.floor(h / 2) - 1

    for i, entry in ipairs(entries) do
        term.setCursorPos(math.floor((w - #entry - 4) / 2) + 1, menuY + i - 1)
        if i == selected then
            term.setBackgroundColor(config.colors.selected_bg)
            term.setTextColor(config.colors.selected_text)
            term.write(" * " .. entry .. " ")
        else
            term.setBackgroundColor(config.colors.background)
            term.setTextColor(config.colors.text)
            term.write("   " .. entry .. " ")
        end
    end

    term.setBackgroundColor(config.colors.background)
    term.setTextColor(config.colors.text)
    term.setCursorPos(1, h - 2)
    term.clearLine()
    if timeoutRemaining > 0 then
        term.write("Booting default in " .. math.ceil(timeoutRemaining) .. " seconds.")
    else
        term.write("Use arrow keys to select, enter to boot.")
    end
end

drawMenu()

while true do
    local event, p1, p2, p3 = os.pullEvent()

    if event == "key" then
        if p1 == keys.up then
            selected = selected - 1
            if selected < 1 then selected = #entries end
            timeoutRemaining = 0 -- Cancel timeout on input
            drawMenu()
        elseif p1 == keys.down then
            selected = selected + 1
            if selected > #entries then selected = 1 end
            timeoutRemaining = 0
            drawMenu()
        elseif p1 == keys.enter then
            break
        end
    elseif event == "timer" and p1 == timer and timeoutRemaining > 0 then
        timeoutRemaining = timeoutRemaining - 1
        if timeoutRemaining <= 0 then
            break
        else
            timer = os.startTimer(1)
            drawMenu()
        end
    end
end

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)

if selected == 1 then
    print("Booting CraftOS...")
    return -- Returns to the default shell
elseif selected == 2 then
    print("Booting SXOS...")
    -- Run the kernel, which will override and loop
    shell.run("/sys/kernel.lua")
end

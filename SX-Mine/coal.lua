print("starting")

function printtable(t)
    for i, v in pairs(t) do
        print(i, v)
    end
end

local specials = {"coal_ore", "iron_ore", "gold_ore", "diamond_ore", "emerald_ore"}

tablefind = function (t, s)
    for _, v in pairs(t) do
        if string.find(v, s) then
            return true
        else
            return false
        end
    end
end

function checkleft(getback, turns)
    if getback == nil then getback = 0 end
    turtle.turnLeft()
    local block, info = turtle.inspect()
    if block then
        local name = string.gsub(info['name'],string.sub(info["name"], 0, string.find(info["name"], ":")),"", 1)
        if tablefind(specials, name) then
            turtle.dig()
            fwd(getback)
            for i=0, turns do
                turtle.turnRight()
            end
        end
    end
end
function checkright(getback, turns)
    if getback == nil then getback = 0 end
    turtle.turnRight()
    local block, info = turtle.inspect()
    if block then
        local name = string.gsub(info['name'],string.sub(info["name"], 0, string.find(info["name"], ":")),"", 1)
        if tablefind(specials, name) then
            turtle.dig()
            fwd(getback)
            for i=0, turns do
                turtle.turnLeft()
            end
        end
    end
end
function checkup(getback)
    if getback == nil then getback = 0 end
    local block, info = turtle.inspectUp()
    if block then
        local name = string.gsub(info['name'],string.sub(info["name"], 0, string.find(info["name"], ":")),"", 1)
        if tablefind(specials, name) then
            turtle.dig()
            turtle.up()
            checkup(getback+1)
        else
            for i=0, getback do
                turtle.down()
            end
        end
    end
end
function checkdown(getback)
    if getback == nil then getback = 0 end
    local block, info = turtle.inspectDown()
    if block then
        local name = string.gsub(info['name'],string.sub(info["name"], 0, string.find(info["name"], ":")),"", 1)
        if tablefind(specials, name) then
            turtle.dig()
            turtle.down()
            checkdown(getback+1)
        else
            for i=0, getback do
                turtle.up()
            end
        end
    end
end

function fwd(getback)
    if getback == nil then getback = 0 end
    local block, info = turtle.inspect()
    if block then
        local name = string.gsub(info['name'],string.sub(info["name"], 0, string.find(info["name"], ":")),"", 1)
        if tablefind(specials, name) then
            turtle.dig()
            turtle.forward()
            checkup(0)
            checkdown(0)
            checkleft(0)
            checkright(0)
            fwd(getback+1)
        else
            if getback > 0 then
                for i=0, getback do
                    turtle.back()
                end
            else
                turtle.dig()
                turtle.forward()
            end
        end
    else
        error("Terminated", 0)
    end
end


while true do
    fwd()
end
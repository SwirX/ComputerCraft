local Tracker = {}

Tracker.x = 0
Tracker.y = 0
Tracker.z = 0
Tracker.facing = 0 -- 0: +x, 1: +z, 2: -x, 3: -z
Tracker.path = {}

-- Directions mapping
-- 0 = Forward (+X initially)
-- 1 = Right (+Z initially)
-- 2 = Back (-X initially)
-- 3 = Left (-Z initially)

function Tracker.reset()
    Tracker.x = 0
    Tracker.y = 0
    Tracker.z = 0
    Tracker.facing = 0
    Tracker.path = {}
end

function Tracker.getDistance()
    -- Manhattan distance from origin
    return math.abs(Tracker.x) + math.abs(Tracker.y) + math.abs(Tracker.z)
end

function Tracker.logMove(action)
    table.insert(Tracker.path, action)
end

function Tracker.forward()
    if turtle.forward() then
        if Tracker.facing == 0 then
            Tracker.x = Tracker.x + 1
        elseif Tracker.facing == 1 then
            Tracker.z = Tracker.z + 1
        elseif Tracker.facing == 2 then
            Tracker.x = Tracker.x - 1
        elseif Tracker.facing == 3 then
            Tracker.z = Tracker.z - 1
        end
        Tracker.logMove("forward")
        return true
    end
    return false
end

function Tracker.back()
    if turtle.back() then
        if Tracker.facing == 0 then
            Tracker.x = Tracker.x - 1
        elseif Tracker.facing == 1 then
            Tracker.z = Tracker.z - 1
        elseif Tracker.facing == 2 then
            Tracker.x = Tracker.x + 1
        elseif Tracker.facing == 3 then
            Tracker.z = Tracker.z + 1
        end
        Tracker.logMove("back")
        return true
    end
    return false
end

function Tracker.up()
    if turtle.up() then
        Tracker.y = Tracker.y + 1
        Tracker.logMove("up")
        return true
    end
    return false
end

function Tracker.down()
    if turtle.down() then
        Tracker.y = Tracker.y - 1
        Tracker.logMove("down")
        return true
    end
    return false
end

function Tracker.turnLeft()
    turtle.turnLeft()
    Tracker.facing = (Tracker.facing - 1) % 4
    Tracker.logMove("turnLeft")
end

function Tracker.turnRight()
    turtle.turnRight()
    Tracker.facing = (Tracker.facing + 1) % 4
    Tracker.logMove("turnRight")
end

-- Reverse all recorded movements
function Tracker.goHome()
    for i = #Tracker.path, 1, -1 do
        local move = Tracker.path[i]
        if move == "forward" then
            turtle.back() -- Simple reverse
        elseif move == "back" then
            turtle.forward()
        elseif move == "up" then
            turtle.down()
        elseif move == "down" then
            turtle.up()
        elseif move == "turnLeft" then
            turtle.turnRight()
        elseif move == "turnRight" then
            turtle.turnLeft()
        end
    end
    Tracker.reset()
end

return Tracker

package.path = "/sxmine/?.lua;/?.lua;/?/init.lua;" .. package.path

require("sx")
local Net = require("net")
local Tracker = require("tracker")
local Inventory = require("inventory")

local Miner = {}
Miner.state = "IDLE" -- IDLE, EXPLORING, RETURNING
Miner.targetOres = {
    "coal_ore",
    "iron_ore",
    "gold_ore",
    "diamond_ore",
    "emerald_ore",
    "redstone_ore",
    "lapis_ore",
    "copper_ore",
    "deepslate_coal_ore",
    "deepslate_iron_ore",
    "deepslate_gold_ore",
    "deepslate_diamond_ore",
    "deepslate_emerald_ore",
    "deepslate_redstone_ore",
    "deepslate_lapis_ore",
    "deepslate_copper_ore"
}

local function isOre(name)
    if not name then return false end
    for _, ore in ipairs(Miner.targetOres) do
        if string.find(name, ore) then return true end
    end
    return false
end

local function safeForward()
    while not Tracker.forward() do
        if turtle.detect() then
            turtle.dig()
        elseif turtle.getFuelLevel() == 0 then
            return false
        else
            turtle.attack()
        end
    end
    return true
end

local function safeUp()
    while not Tracker.up() do
        if turtle.detectUp() then
            turtle.digUp()
        else
            turtle.attackUp()
        end
    end
end

local function safeDown()
    while not Tracker.down() do
        if turtle.detectDown() then
            turtle.digDown()
        else
            turtle.attackDown()
        end
    end
end

local checkUp, checkDown, checkLeft, checkRight

function checkLeft()
    Tracker.turnLeft()
    local hasBlock, data = turtle.inspect()
    if hasBlock and isOre(data.name) then
        turtle.dig()
        safeForward()
        -- Explore recursively
        checkUp()
        checkDown()
        checkLeft()
        checkRight()
        Tracker.back()  -- Return exactly where we were
    end
    Tracker.turnRight() -- Restore orientation
end

function checkRight()
    Tracker.turnRight()
    local hasBlock, data = turtle.inspect()
    if hasBlock and isOre(data.name) then
        turtle.dig()
        safeForward()
        -- Explore recursively
        checkUp()
        checkDown()
        checkLeft()
        checkRight()
        Tracker.back()
    end
    Tracker.turnLeft()
end

function checkUp()
    local hasBlock, data = turtle.inspectUp()
    if hasBlock and isOre(data.name) then
        turtle.digUp()
        safeUp()
        checkUp()
        checkLeft()
        checkRight()
        Tracker.down()
    end
end

function checkDown()
    local hasBlock, data = turtle.inspectDown()
    if hasBlock and isOre(data.name) then
        turtle.digDown()
        safeDown()
        checkDown()
        checkLeft()
        checkRight()
        Tracker.up()
    end
end

function Miner.heartbeatLoop(computerId)
    while true do
        Net.broadcastHeartbeat(Miner.state, Tracker.x, Tracker.y, Tracker.z, Tracker.getDistance(), "Cave Mining")
        -- Read any incoming commands
        local sender, msg = Net.receive(1)
        if sender == computerId and msg then
            if msg.type == Net.MESSAGE_TYPES.COMMAND then
                if msg.command == Net.COMMANDS.RETURN then
                    Miner.state = "RETURNING"
                end
            elseif msg.type == Net.MESSAGE_TYPES.INVENTORY then
                Net.sendInventory(computerId, Inventory.getInventoryData())
            end
        end
        -- Fallback: Check tools every few seconds
        Inventory.equipPickaxe()
    end
end

function Miner.exploreLoop()
    while Miner.state == "EXPLORING" do
        local hasBlock, data = turtle.inspect()
        if hasBlock and isOre(data.name) then
            -- We hit an ore directly in front
            turtle.dig()
            safeForward()
            checkUp()
            checkDown()
            checkLeft()
            checkRight()
        else
            safeForward()
            checkUp()
            checkDown()
            checkLeft()
            checkRight()
        end

        -- Check fuel and inventory
        if turtle.getFuelLevel() < Tracker.getDistance() + 50 then
            Miner.state = "RETURNING"
        elseif Inventory.getFullness() > 0.9 then
            Inventory.dropJunk()
            if Inventory.getFullness() > 0.9 then
                Miner.state = "RETURNING"
            end
        end
    end
    if Miner.state == "RETURNING" then
        Tracker.goHome()
        Miner.state = "IDLE"
    end
end

return Miner

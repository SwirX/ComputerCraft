package.path = "/sxmine/?.lua;/?.lua;/?/init.lua;" .. package.path

local Net = require("net")
local Tracker = require("tracker")
local Miner = require("miner")

print("Initializing SX-Mine v3.0.0 Turtle System...")

if not Net.init() then
    print("Error: No wireless modem found.")
    print("Please attach a modem on the right or left side.")
    return
end

print("Modem initialized.")
print("Waiting for dashboard ping to calibrate...")

-- Find dashboard first
local dashboardId = nil
Net.broadcastHeartbeat("IDLE", 0, 0, 0, 0, "Waiting")

while not dashboardId do
    local sender, msg = Net.receive(5)
    if msg and msg.type == Net.MESSAGE_TYPES.COMMAND and msg.command == Net.COMMANDS.RUN then
        dashboardId = sender
        print("Dashboard found! ID: " .. dashboardId)
    else
        Net.broadcastHeartbeat("IDLE", 0, 0, 0, 0, "Waiting")
    end
end

Miner.state = "EXPLORING"
Tracker.reset()

print("Starting autonomous operations.")
parallel.waitForAny(
    function() Miner.heartbeatLoop(dashboardId) end,
    Miner.exploreLoop
)

print("Operation terminated.")

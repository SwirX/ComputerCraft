-- CC sets CWD to the script folder, so absolute-style requires break unless
-- we explicitly add root-based search paths here.
package.path = "/?.lua;/?/init.lua;" .. package.path

local Net = require("net")
local ui = require("lib.sxui.ui")

if not Net.init() then
    print("Error: No rednet modem found on this dashboard.")
    return
end

local turtles = {}
local selectedTurtle = nil

local screen = ui.Screen()

local app = ui.AppWindow("SX-Mine v3.0 - Fleet Manager")
app.size.scaleX = 0.9
app.size.scaleY = 0.9
app.position.scaleX = 0.05
app.position.scaleY = 0.05
screen:addChild(app)

local listPanel = ui.ScrollPanel()
listPanel.size.scaleX = 0.35
listPanel.size.scaleY = 0.8
listPanel.position.offsetX = 2
listPanel.position.offsetY = 2
app:addChild(listPanel)

local detailsPanel = ui.Frame()
detailsPanel.size.scaleX = 0.55
detailsPanel.size.scaleY = 0.8
detailsPanel.position.scaleX = 0.4
detailsPanel.position.offsetY = 2
app:addChild(detailsPanel)

local lblDetails = ui.Label("Waiting for turtle data...")
lblDetails.position.offsetX = 1
lblDetails.position.offsetY = 1
detailsPanel:addChild(lblDetails)

local btnRun = ui.Button("Run / Dispatch")
btnRun.size.scaleX = 0.8
btnRun.size.offsetY = 3
btnRun.position.scaleX = 0.1
btnRun.position.offsetY = 10
detailsPanel:addChild(btnRun)

local btnReturn = ui.Button("Recall / Return")
btnReturn.size.scaleX = 0.8
btnReturn.size.offsetY = 3
btnReturn.position.scaleX = 0.1
btnReturn.position.offsetY = 14
detailsPanel:addChild(btnReturn)

btnRun.onClick = function()
    if selectedTurtle then
        Net.sendCommand(selectedTurtle, Net.COMMANDS.RUN)
    end
end

btnReturn.onClick = function()
    if selectedTurtle then
        Net.sendCommand(selectedTurtle, Net.COMMANDS.RETURN)
    end
end

local function updateDetails()
    if not selectedTurtle or not turtles[selectedTurtle] then
        return
    end
    local t = turtles[selectedTurtle]
    local dt = (os.epoch("utc") - t.lastSeen) / 1000
    local stateStr = t.state
    if dt > 5 then
        stateStr = "LOST CONNECTION"
    end

    local text = string.format(
        "Selected ID: %d\n\nState: %s\nTask: %s\nDistance: %d blocks\nPosition: X:%d Y:%d Z:%d\n\nLast Ping: %.1fs ago",
        selectedTurtle, stateStr, t.task, t.distance, t.pos.x, t.pos.y, t.pos.z, dt)
    lblDetails:setText(text)
end

local function rebuildList()
    -- Simple recreation by clearing children
    listPanel.children = {}
    local y = 0
    for id, _ in pairs(turtles) do
        local btn = ui.Button("Turtle #" .. id)
        btn.size.scaleX = 0.9
        btn.size.offsetY = 3
        btn.position.offsetY = y
        btn.onClick = function()
            selectedTurtle = id
            updateDetails()
        end
        listPanel:addChild(btn)
        y = y + 4
    end
end

local function networkLoop()
    while true do
        local sender, msg = Net.receive(1)
        if sender and msg.type == Net.MESSAGE_TYPES.HEARTBEAT then
            local isNew = (turtles[sender] == nil)
            turtles[sender] = {
                state = msg.state,
                pos = msg.pos,
                distance = msg.distance,
                task = msg.task,
                lastSeen = os.epoch("utc")
            }
            if isNew then rebuildList() end
            if sender == selectedTurtle then updateDetails() end
        end
    end
end

-- Screen run manages os.pullEvents for the UI seamlessly
parallel.waitForAny(
    function() screen:run() end,
    networkLoop,
    function()
        while true do
            sleep(1)
            -- Periodic refresh to check for 'LOST CONNECTION'
            if selectedTurtle then updateDetails() end
        end
    end
)

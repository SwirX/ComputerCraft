local Net = {}

Net.PROTOCOL = "SX-MINE-V3"

Net.MESSAGE_TYPES = {
    HEARTBEAT = "heartbeat",
    STATUS = "status",
    INVENTORY = "inventory",
    COMMAND = "command"
}

Net.COMMANDS = {
    RETURN = "return",
    RUN = "run"
}

function Net.init()
    local modem = peripheral.find("modem")
    if modem then
        rednet.open(peripheral.getName(modem))
        return true
    end
    return false
end

function Net.broadcastHeartbeat(state, x, y, z, distance, task)
    rednet.broadcast({
        type = Net.MESSAGE_TYPES.HEARTBEAT,
        state = state,
        pos = { x = x, y = y, z = z },
        distance = distance,
        task = task
    }, Net.PROTOCOL)
end

function Net.sendInventory(id, inventoryData)
    rednet.send(id, {
        type = Net.MESSAGE_TYPES.INVENTORY,
        data = inventoryData
    }, Net.PROTOCOL)
end

function Net.sendCommand(id, commandType)
    rednet.send(id, {
        type = Net.MESSAGE_TYPES.COMMAND,
        command = commandType
    }, Net.PROTOCOL)
end

function Net.receive(timeout)
    local senderId, message, protocol = rednet.receive(Net.PROTOCOL, timeout)
    if senderId and type(message) == "table" then
        return senderId, message
    end
    return nil, nil
end

return Net

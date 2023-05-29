term.clear()
term.setCursorPos(1,1)
print("starting...")
local modem = peripheral.getName(peripheral.find("modem"))
if not modem then error("No modem is found on this computer", 0) end
if not rednet.isOpen(modem) then rednet.open(modem) end
repeat
id, req, proto = rednet.receive("sx-dt-doors")
until id ~= nil

if req == "CONNECTION_REQUEST" then
    rednet.send(id, "CONNECTION_SUCCESSFUL", "sx-dt-doors")
end
print("Connected")
connected = true
while connected do
    repeat
    id, cmd, proto = rednet.receive("sx-dt-doors")
    until id ~= nil
    if cmd == "OPEN_DOORS" then
        rs.setOutput("back", true)
        sleep(2.5)
        rs.setOutput("back", false)
    elseif cmd == ("ABORT_CONNECTION" or "KILL_CONNECTION") then
        os.reboot()
    end
end

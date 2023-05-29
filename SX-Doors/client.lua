-- right 16, 19
-- left 13, 14

-- C:\Users\Hamza\AppData\Roaming\.minecraft\versions\1.16.5 modpack01\saves\Nouveau monde (3)\computercraft\computer\

function clearscreen()
    term.clear()
    term.setCursorPos(1,1)
end

print("Starting Up...")
sleep(1.5)
clearscreen()
print("Opening the rednet")
if rednet.isOpen() then
    print("The rednet is already open")
    print("skipping...")
else
    local modem = peripheral.getName(peripheral.find("modem"))
    if not modem then error("No modem is found on this computer", 0) end
    rednet.open(modem)
end 
sleep(.2)
print("Making a connection")

rednet.broadcast("CONNECTION_REQUEST", "sx-dt-doors")
for i=1, 4 do
    repeat
        id, resp, proto = rednet.receive("sx-dt-doors", 10 )
    until id ~= nil
    if resp == "CONNECTION_SUCCESSFUL" then
        print("Connection #"..i.." successful ("..4-i.." left)")
    else
        print("Connection #"..i.." failed aborting...")
        print("Connection phase aborted restarting...")
        rednet.broadcast("ABORT_CONNECTION")
        shell.execute("doors")
    end
end

print("All pistons are connected")
sleep(1)
print("Main thread starting")
sleep(2)
clearscreen()

print("Welcome to the wireless door opener")
print("There are two commands open and close")
connected = true
while connected do
    local cmd = string.lower(read())
    if cmd == "exit" then
        print("Are you sure to exit")
        local confirmation = read()
        if confirmation == "y" then
            print("Killing the connection")
            rednet.broadcast("KILL_CONNECTION", "sx-dt-doors")
            sleep(1)
            print("Connection killed")
            sleep(.5)
            print("Closing the rednet")
            rednet.close()
            sleep(.5)
            print("Rednet closed")
            error("Exited", 0)
        else
            return
        end
    elseif cmd == "open" then
        rednet.broadcast("OPEN_DOORS", "sx-dt-doors")
        print("Opening doors")
    end
end 

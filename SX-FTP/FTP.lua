local modem = peripheral.getName(peripheral.find("modem"))
if not modem then error("No modem is found on this computer", 0) end
if not rednet.isOpen(modem) then rednet.open(modem) end

--Values
Connected = false
ConnectedDevice = nil
IsHost = false

--Headers
ConnRequestHeader = "CONNECTION_REQUEST"
ConnAcceptedHeader = "CONNECTION_ACCEPTED"
ConnDeclinedHeader = "CONNECTION_DECLINED"
SendRequestHeader = "SEND_REQUEST"
SendAcceptHeader = "SEND_ACCEPT"
SendDeclineHeader = "SEND_DECLINE"
SendFileHeader = "RECEIVE_DATA_TYPE_FILE"
KillExitConnHeader = "KILL_CONNECTION_AND_EXIT"
KickDeviceHeader = "KICK_DEVICE"

function FlushScreen()
    term.clear()
    term.setCursorPos(1, 1)
end

function Connect(hType)
    if hType == 0 then
        FlushScreen()
        print("Waiting for a connection...")
        local id, msg, p
        repeat
           id, msg, p = rednet.receive()
        until msg == ConnRequestHeader
        print("Got a connection from computer #"..id..". Accept the connection? (Y/n)")
        local choice = string.lower(read())
        if choice == "y" then
            Connected = true
            ConnectedDevice = id
            rednet.send(id, ConnAcceptedHeader)
            print("The connection request from computer #"..id.." has been accepted")
        else
            rednet.send(id, ConnDeclinedHeader)
            print("The connection request from computer #"..id.." has been declined")
        end
    elseif hType == 1 then
        term.clear()
        term.setCursorPos(1,1)
        print("Enter the id of the computer that you want to connect to and make sure that the rednet on that computer is open and it's a host")
        local id = tonumber(read())
        if not id then
            term.setTextColor(colors.red)
            term.write("You should enter a valid id")
            term.setTextColor(colors.white)
            sleep(2.5)
            Connect(hType)
        else
            rednet.send(id, ConnRequestHeader)
            print("Waiting for the computer that you are connecting to to accept")
            local id_, conn, p_ = rednet.receive()
            if conn == ConnAcceptedHeader then
                print('Successfuly connected to the computer#'..id)
                Connected = true
                ConnectedDevice = id
            elseif conn == ConnDeclinedHeader then
                print("The connection request have been declined by the user")
                print("Exit?")
            else
                print("Failed to connect")
                print("Trouble shooting Tips:")
                print("Check if the computer ID that you entered is a valid one")
                print("--Go to the other computer and type id in the terminal the number that you get is the id")
                print("Check if the other computer has a modem connected and the rednet is open")
                print("--Go to the other computer and type lua then enter rednet.open()")
            end
        end
    end
end

function ReceiveData()
    while Connected do
        local id, type, protocol
        repeat
            id, type, protocol = rednet.receive()
        until id == ConnectedDevice
        if type == SendRequestHeader then
            print("A request to receive a file from computer #"..id.."has been received")
            print("Do you wanna accept the request (Y/n)")
            local choice = string.lower(read())
            if choice == "y" then
                rednet.send(id, SendAcceptHeader)
                id, protocol = nil, nil
                local filename
                repeat
                    id, filename, protocol = rednet.receive()
                until id == ConnectedDevice
                print("Downloading File")
                local file = fs.open("/Programs/SX-FTP/Received/"..filename, "w")
                id, protocol = nil, nil
                local data
                repeat
                    id, data, protocol = rednet.receive()
                until id == ConnectedDevice
                file.writeLine(data)
                print("The file "..filename.." has been downloaded successfuly")
                print("The file can be found in :")
                print('/Programs/SX-FTP/Received/')
                file.close()
                FlushScreen()
            elseif choice == "n" then
                print("You have declined the request")
                rednet.send(id, SendDeclineHeader)
                print("The other end has been informed")
            end
        elseif type == KillExitConnHeader then
            print("Computer #"..id.." has exited the connection")
            rednet.close()
        elseif type == KickDeviceHeader then
            print("The host device has kicked you from the connection")
        end
    end
end

function SendData(filedir)
    if type(filedir) == "string" then
        if fs.exists(filedir) then
            print("Sending the file")
            local file = fs.open(filedir, "r")
            local filedata = file.readLine(true)
            print("Sending the user a request to send him a file")
            rednet.send(ConnectedDevice, SendRequestHeader)
            local id, response, p_
            repeat
                id, response, p_ = rednet.receive()
            until id == ConnectedDevice
            if response == SendAcceptHeader then
                print("Computer #"..id.." has accepted your request to send a file")
                rednet.send(ConnectedDevice, fs.getName(filedir))
                rednet.send(ConnectedDevice, filedata)
                print(filedir.."Has been sent successfuly")
            elseif response == SendDeclineHeader then
                print("Computer #"..id.." has declined your request to send a file")
                return
            end
    end
end
end

function UInput()
    while Connected do
        print("if you need help try typing 'help'")
        local cmd = string.lower(read())
        if cmd == "help" then
            term.setTextColor(colors.cyan)
            print("send ")
            term.setTextColor(colors.magenta)
            print("<file directory>")
            term.setTextColor(colors.white)
            local cx, cy = term.getCursorPos()
            term.setCursorPos(1, cy+1)
        elseif string.find(cmd, "send") then
            local filedir = string.gsub(cmd, "send ", "")
            SendData(filedir)
        elseif cmd == "exit" then
            print("Killing the connection and exiting...")
            rednet.send(ConnectedDevice, KillExitConnHeader)
            rednet.close()
            error("Terminated", 0)
        elseif cmd == "kick" then
            if IsHost then
                rednet.send(ConnectedDevice, KickDeviceHeader)
            else
                print("You can't use this command whilst not the host")
            end
        end
    end
end

function App()
    FlushScreen()
    print("FTP Started")
    print("are you the host (this app refers to the first computer to connect as the host)")
    print("(Y/n)")
    local response = string.lower(read())
    if response == "y" then
        IsHost = true
        Connect(0)
    else
        IsHost = false
        Connect(1)
    end
    parallel.waitForAny(UInput, ReceiveData)
end
App()
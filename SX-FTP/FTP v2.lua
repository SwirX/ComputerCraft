--[[
            This Program has been programmed and developped by SwirX
            This is an FTP (File Transfer Protocol) App that is mainly used to share and send files between two computers using a modem
            
            It is acheved by using Rednet API allows systems to communicate between each other without using redstone. It serves as a wrapper for the modem API.
            
            I made this program because i was bored and i wanted a way to send files from computer to computer without that pain of copying
            it to a disk and then putting that disk into the other computer and copy it to it.
            With Just a command you can send any files that you want on any computer that you want just make sure that it is connected to a modem
            doesn't matter if it is a wireless or wired modem.

            USAGE:

            go to your computers that you want to add this feature to then you type:
                pastebin get Rx0NPdYx ftp.lua 
            The last argument can be whatever you want to name the file
            then open a new shell tab by typing bg just to be able to find files without exiting the app every now and then
            then when the script get downloaded you start it then you will be prompted with a question asking if you want this current
            computer to be a host or not (The difference between them is just that the host computer can kick the other connected device)
            you type y or n and depending on what you choose you will be prompted with a text that explain what to do
            then on the client computer you should write the id of the host computer once entered the host computer will be prompted with
            a question that asks him if he wants to accept this connection
            After accepting the two computers will be connected and you can start transfering your files
            you have four commands that you can use:
                help                  -- get help
                kick                  -- kick the client if you computer is the host
                exit                  -- exit and tell the other end that the connection will be terminated
                send <file directory>


            UPDATE LOG:
            
            Release2.0:
            - Added message encryption for more secure connection
            Release1.5:
            - Added Protocols for somewhat secure connection
            - Added ability to send to all connected users
            Release1.0:
            - Added the functionality to listen and be still able to write commands at the same time
            alpha0.9:
            - Added soft shutdown
            - Added exiting posible
            - Added kicking the computer you're connected to
            alpha0.8:
            - Added request to connect
            alpha0.7.5:
            - Added sending file request
            alpha0.7:
            - Made that both computers can send files:
            alpha0.6:
            - Added host and client computer
            - Lowered the number of computers that you can connect to to 2
            alpha0.5:
            - Added connecting to a specific computer
            alpha0.4:
            - Added sending file to a any computer with his ID
            alpha0.3:
            - The sent file keeps the same name as it was
            alpha0.2:
            - Added checking if the modem exists
            alpha0.1:
            - Ability to send files to any computer running the app with the rednet open

]]

-- Required Libraries

local md5 = require'SX-Crypt.md5'
local sha3 = require'SX-Crypt.sha3'
local bin = require'SX-Crypt.bin'
local morus = require'SX-Crypt.morus'
local xhs = bin.hextos

-- Script

local modem = peripheral.getName(peripheral.find("modem"))
if not modem then error("No modem is found on this computer", 0) end
if not rednet.isOpen(modem) then rednet.open(modem) end

--Values
Connected = false
ConnectedDevices = nil
Protocol = ""
IsHost = false
HostID = 0
--Encryption
EncryptionKey = ""
InitValue = "00000000000000000000000000000000"

--Headers
ConnRequestHeader = "CONNECTION_REQUEST"
ConnAcceptedHeader = "CONNECTION_ACCEPTED"
ConnDeclinedHeader = "CONNECTION_DECLINED"
ProtocolHeader = "CONNECTION_PROTOCOL"
EncryptionKeyHeader = "ENCRYPTION_KEY"
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
    if hType == 1 then
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
            print('Enter the password of this FTP Session')
            local pw = md5.hash(sha3.sha256(read()))
            rednet.send(id, ConnRequestHeader, pw)
            print("Waiting for the computer that you are connecting to to accept")
            local id_, conn, p_ = rednet.receive(pw, 10)
            if conn == ConnAcceptedHeader then
                print('Successfuly connected to the computer#'..id)
                Connected = true
                HostID = id
                -- Get the Header to receive the protocol
                local pro, msg, _
                repeat
                    id, msg, _ = rednet.receive()
                until id == HostID and msg == ProtocolHeader
                -- Get the protocol and save it
                repeat
                    id, msg, _ = rednet.receive()
                until id == HostID
                Protocol = msg
                -- Get the encriptionkey header
                repeat
                    id, msg, _ = rednet.receive(Protocol)
                until id == HostID
                -- Get the encryption key
                repeat
                    id, msg, _ = rednet.receive(Protocol)
                until id == HostID
                EncryptionKey = msg

            elseif conn == ConnDeclinedHeader then
                print("The connection request have been declined by the user")
                print("Exit?")
                local resp = string.lower(read())
                if resp == 'y' then
                    os.reboot()
                else
                    Connect(hType)
                end
            elseif id == nil then
                print("Timeout: Response time exhausted")
                print("Check if the password that you entered is correct and try again")
                Connect(hType)
            else
                print("Failed to connect")
                print("Trouble shooting Tips:")
                print("Check if the computer ID that you entered is a valid one")
                print("--Go to the other computer and type id in the terminal the number that you get is the id")
                print("Check if the other computer has a modem connected and the rednet is open")
                print("--Go to the other computer and type lua then enter rednet.open()")
                Connect(hType)
            end
        end
    end
end

function ReceiveData()
    while Connected do
        if ConnectedDevices == nil then
            FlushScreen()
            print("Waiting for a connection...")
            local id, msg, p
            repeat
            id, msg, p = rednet.receive(Protocol)
            until msg == ConnRequestHeader
            print("Got a connection request from computer #"..id..". Accept the connection? (Y/n)")
            local choice = string.lower(read())
            if choice == "y" then
                Connected = true
                ConnectedDevices = {}
                table.insert(ConnectedDevices, id)
                rednet.send(id, ConnAcceptedHeader)
                rednet.send(id, ProtocolHeader)
                rednet.send(id, Protocol)
                print("The connection request from computer #"..id.." has been accepted")
            else
                rednet.send(id, ConnDeclinedHeader)
                print("The connection request from computer #"..id.." has been declined")
            end
        else
            local id, msg, prot
            repeat
                id, msg, prot = rednet.receive()
            until id ~= nil
            if prot == Protocol then
                if msg == ConnRequestHeader then
                    print("Got a connection request from computer #"..id..". Accept the connection? (Y/n)")
                    local choice = string.lower(read())
                    if choice == "y" then
                        Connected = true
                        ConnectedDevices = {}
                        table.insert(ConnectedDevices, id)
                        rednet.send(id, ConnAcceptedHeader)
                        rednet.send(id, ProtocolHeader)
                        rednet.send(id, Protocol)
                        print("The connection request from computer #"..id.." has been accepted")
                    else
                        rednet.send(id, ConnDeclinedHeader)
                        print("The connection request from computer #"..id.." has been declined")
                    end
                end
            else
                if type == SendRequestHeader then
                    print("A request to receive a file from computer #"..id.."has been received")
                    print("Do you wanna accept the request (Y/n)")
                    local choice = string.lower(read())
                    if choice == "y" then
                        rednet.send(id, SendAcceptHeader)
                        local filename
                        repeat
                            id, filename, _ = rednet.receive(Protocol)
                        until id ~= nil
                        print("Downloading File")
                        filename = morus.decrypt(EncryptionKey, InitValue)
                        local file = fs.open("/Programs/SX-FTP/Received/"..filename, "w")
                        local data
                        repeat
                            id, data, _ = rednet.receive(Protocol)
                        until id ~= nil
                        data = morus.decrypt(EncryptionKey, InitValue, data)
                        file.writeLine(data)
                        print("The file "..filename.." has been downloaded successfuly")
                        print("The file can be found in :")
                        print('/Programs/SX-FTP/Received/')
                        file.close()
                        FlushScreen()
                    elseif choice == "n" then
                        print("You have declined the request")
                        rednet.send(id, SendDeclineHeader, Protocol)
                        print("The other end has been informed")
                    end
                
                elseif type == KillExitConnHeader then
                    print("Computer #"..id.." has exited the connection")
                    rednet.close()
                    
                elseif type == KickDeviceHeader then
                    print("The host device has kicked you from the connection")
                else
                    Protocol = type
                end
            end
        end
    end
end

function SendData(filedir, id)
    if type(filedir) == "string" then
        if fs.exists(filedir) then
            print("Sending the file")
            local file = fs.open(filedir, "r")
            local filedata = file.readLine(true)
            print("Sending the user a request to send him a file")
            rednet.send(id, SendRequestHeader, Protocol)
            local id_, response, protocol
            repeat
                id_, response, protocol = rednet.receive(Protocol)
            until id_ == id
            if response == SendAcceptHeader then
                print("Computer #"..id.." has accepted your request to send a file")
                rednet.send(id, fs.getName(filedir), Protocol)
                rednet.send(id, filedata, Protocol)
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
            print("<file directory> <receiver id>")
            term.setTextColor(colors.white)
            local cx, cy = term.getCursorPos()
            term.setCursorPos(1, cy+1)
        elseif string.find(cmd, "send") then
            local filedir = string.gsub(cmd, "send ", "")
            SendData(filedir)
        elseif cmd == "exit" then
            print("Killing the connection and exiting...")
            if ConnectedDevices ~= nil then
                for _, v in pairs(ConnectedDevices) do
                    rednet.send(v, KillExitConnHeader)
                    rednet.close()
                    error("Terminated", 0)
                end
            end
        elseif cmd == "kick" then
            if IsHost then
                if ConnectedDevices ~= nil and type(ConnectedDevices) == "table" then
                    for _, v in pairs(ConnectedDevices) do
                        rednet.send(v, KickDeviceHeader)
                        rednet.close()
                        error("Terminated", 0)
                    end
                end
            else
                print("You can't use this command whilst not the host")
            end
        end
    end
end

function UpdateProtocol()
    while Connected do
        sleep(60)
        local oldProto = Protocol
        Protocol = PSC()
        rednet.broadcast(Protocol, oldProto)
    end
end

--Generate 16bytes Hex
function genHex()
    return tostring(math.random(1000000000000000, 9999999999999999))..tostring(math.random(1000000000000000, 9999999999999999))
end

--Generate Protocol
function PSC(m)
    local p = md5.hash(sha3.sha256(m))
    return p
end

function App()
    FlushScreen()
    print("FTP Started")
    print("are you the host?")
    print("(Y/n)")
    local response = string.lower(read())
    if response == "y" then
        print("Enter a password for other to connect to you (It's a one session password)")
        local pw = read()
        FlushScreen()
        Protocol = PSC(pw)
        EncryptionKey = genHex()
        -- InitValue = genHex()
        IsHost = true
        Connect(0)
    else
        IsHost = false
        Connect(1)
    end
    parallel.waitForAny(UInput, ReceiveData, UpdateProtocol)
end
App()
<h1>SX-FTP</h1>
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
    <p style="color:cyan">send</p> <p style="color:magenta">\<file directory\></p>

<h2>Update Logs<h2>
* Release2.0:
- Added message encryption for more secure connection
* Release1.5:
- Added Protocols for somewhat secure connection
- Added ability to send to all connected users
* Release1.0:
- Added the functionality to listen and be still able to write commands at the same time
* alpha0.9:
- Added soft shutdown
- Added exiting posible
- Added kicking the computer you're connected to
* alpha0.8:
- Added request to connect
* alpha0.7.5:
- Added sending file request
* alpha0.7:
- Made that both computers can send files:
* alpha0.6:
- Added host and client computer
- Lowered the number of computers that you can connect to to 2
* alpha0.5:
- Added connecting to a specific computer
* alpha0.4:
- Added sending file to a any computer with his ID
* alpha0.3:
- The sent file keeps the same name as it was
* alpha0.2:
- Added checking if the modem exists
* alpha0.1:
- Ability to send files to any computer running the app with the rednet open

<h3 style="color: red">NOTE: FTP v2.lua is still work in progress and it's not working nor ready for use</h3>
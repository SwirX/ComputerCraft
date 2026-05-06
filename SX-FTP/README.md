# SX-FTP

An FTP (File Transfer Protocol) application for sharing files between two computers using the Rednet modem API.

### Implementation details
I made this because copying files via floppies from computer to computer was super annoying. With this, as long as two computers have a modem, you can spin up the script and transfer files remotely. The application works on a "host" and "client" system. The host can set up a listener and kick clients if needed. The client just needs the host's ID to initiate a connection, which the host can accept or decline. Once connected, anyone can use the `send <file directory>` command to push a file over.

### Development status
The base script `FTP.lua` works great and transfers files reliably. The user can continue issuing terminal commands without disrupting the Rednet thread since I'm using `parallel.waitForAny`. 

I also started working on `FTP v2.lua` which introduces message encryption to stop people from intercepting the transfers, but that version is still a work in progress and isn't fully operational yet.
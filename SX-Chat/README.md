# SX-Chat

A simple client and server chat application over Rednet.

### Implementation details
The idea here was to create a basic chatting hub. The `server.lua` script handles incoming connections, user creation, and password masking (printing asterisks instead of the actual characters using `os.pullEvent`). The client script connects to the server and handles the UI and message sending.

### Development status
It's currently in a working state for basic text messaging. The server can hide passwords during sign-in and grab basic keystrokes securely. I didn't get around to implementing complex database storage for accounts, so it's more of a proof of concept for secure input fields and rednet communication.

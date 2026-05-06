# SX-Installer

An OS installer wizard with a GUI for ComputerCraft.

### Implementation details
This script acts as the bootstrapper for downloading and installing my custom OS ("SX-OS") and UI library. It pulls the `ui.lua` library from my personal host (`swirx.ddns.net`), loads it up into the `system/` directory, and then boots up a visual wizard letting the user pick between a default or custom installation.

### Development status
The core structure and the web fetching logic work perfectly. It successfully pulls down `ui.lua`, renders the checkboxes and buttons, and logs the process cleanly into a logs file with timestamps. However, the actual logic for finishing the OS installation is paused at the moment—hitting continue on the default installation just triggers a "still working on it lol :P" error message.

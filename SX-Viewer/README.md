# SX-Viewer

A graphical file viewer for reading files within ComputerCraft.

### Implementation details
The default `edit` command in CC is decent, but sometimes you just want a clean read-only interface to look at code or logs without accidentally typing into them. `fileviewer.lua` uses my custom UI library to render a nice application window. It allows you to pass in a directory path, and it will load up the contents into an organized, scrollable view using click events to navigate.

### Development status
It's fully operational. It leverages the file system APIs and UI system cohesively, rendering files cleanly on the terminal without visual glitches.

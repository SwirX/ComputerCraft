# SX-UI

A comprehensive graphical user interface (GUI) library for ComputerCraft.

### Implementation details
ComputerCraft generally relies on text-heavy terminals, so I wrote this library to make building modern, clickable, and structured interfaces way easier. The `ui.lua` library handles an object-oriented approach to creating screens, containing elements like:
- Buttons (`button`)
- Text Labels (`textlabel`)
- Checkboxes (`textcheckbox`)
- Input boxes/TextBoxes (`textbox`)

It wraps the native `term` and `paintutils` APIs, abstracting away position math, background colors, and event listening. It also comes with an event loop via `ui.HandleInput` to globally listen for mouse clicks or keydown events and trigger callbacks dynamically.

### Development status
The library is in a stable state and fully functioning. It's heavily utilized by some of my other projects like `SX-Installer` and `SX-Viewer` to render their visuals. The file `uitest.lua` acts as a playground showcasing all widgets.

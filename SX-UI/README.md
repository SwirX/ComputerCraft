# SX-UI Framework (v2.2.0)

SX-UI is a professional, high-performance, object-oriented GUI framework built exclusively for CC:Tweaked. Gone are the days of manually querying `term.getSize()` and manually mathing `setCursorPos` across infinite `os.pullEvent` loops. 

SX-UI completely abstracts the CC terminal rendering API behind an intelligent, recursive UDim2 layout engine and standard DOM event propagation, all running on a modern 18yo prodigy-grade OOP foundation.

## Features

* **UDim2 Layout Engine**: Size and Position respect both fractional scales (e.g., `0.5` is 50% of parent boundaries) and absolute character offsets recursively.
* **Mega Event Loop Propagation**: Input streams natively capture `mouse_click`, `mouse_drag`, `mouse_scroll`, `monitor_touch`, `key`, and `char` and safely route them through the zIndex stack to intercepting objects.
* **Multi-Monitor Plug & Play**: Render interfaces natively across massive monitors without needing separate implementations.
* **Easing Animation Engine**: Smooth transitions across properties utilizing Linear, Sine, Cubic, Expo, and Bezier curves.
* **Extensive Widget Library**: From draggable App Windows floating desktop-style frames to interactive Multiline Editors, sliders, dropdowns, and color pickers.

## Installation

Run the native web installer to fetch the framework instantly:
```bash
wget run https://raw.githubusercontent.com/SwirX/ComputerCraft/main/SX-UI/install.lua
```

This deposits the `ui.lua` entrypoint and core components into `/lib/sxui/`.

## Architecture Guide

SX-UI embraces composition. You declare an invisible `Screen` on top of your target device (Terminal or Monitor), append `Elements` onto its `addChild` tree, and execute `Screen:run()`. 

The DOM is composed of layers:
1. `Screen` (Root orchestrator)
2. `AppWindow` / `Frame` (Layout containers & clippers)
3. Standard Widgets (`Button`, `Label`, `Input`, etc.)

All elements derive from the base `Element` class natively.

### Positioning & Scaling: UDim2 Layouts

Elements use `.position` and `.size` vectors mirroring the robust "Scale vs Offset" paradigm utilized by larger game engines.

* `scaleX`, `scaleY`: A decimal map of the Parent coordinate bounds ranging from `0` to `1`.
* `offsetX`, `offsetY`: The literal column/row count override added back to the mapped coordinate.

```lua
local btn = ui.Button("Click!")
-- 50% of parent width, shifted explicitly down by 2 columns
btn.size.scaleX = 0.5 
btn.size.offsetX = 0
btn.position.scaleY = 0
btn.position.offsetY = 2 
```

### Event Callbacks

All elements map common handlers seamlessly if defined by your logic controllers. Available hooks include:
* `onClick(self, x, y)`
* `onRightClick(self, x, y)`
* `onMiddleClick(self, x, y)`
* `onHover(self, x, y)`
* `onLeave(self, x, y)`
* `onDrag(self, x, y)`
* `onScroll(self, direction, x, y)`

## Core Widget API 

#### `Frame()`
An opaque clipping region. Essential for nesting structures safely. Can be toggled perfectly draggable out of the box dynamically via `frame.draggable = true`. 

#### `AppWindow(title)`
A composite window framing structure. Encapsulates an opaque body locked securely to a colored titlebar. The titlebar serves as an exclusive drag handle, behaving identically to MacOS and Windows application layouts. Calling focus raises it immediately to the active Z-Index overhead priority structure.

#### `TextEdit()`
A dedicated multiline script editor handling comprehensive line breaks, cursor positional maths, typing boundaries, wrapping limits, backspace line merging, scrolling, and cursor blinking natively out of the box via active event capturing logic sequences. Extract active text loops via `getText()`.

#### `Button(text)`
A clickable action interface carrying innate logical press state overrides rendering a defined `pressedColor`. 

#### `Checkbox(text)`
Interchanges a boolean `checked` tag safely outputting toggles. 

#### `Slider()`
An adjustable progress handler ranging strictly along defined `min` and `max` numeric caps firing back dynamic coordinates seamlessly into `onChange(self, value)`. 

#### `Dropdown(optionsTable)`
Renders a secure bounding box dynamically raising a list projection at ultra-high priority Z-Index rendering strictly above active siblings, trapping further events mathematically until resolved accurately. Output fires `onChange(self, index, option)`.

#### `ColorSelector()`
Visualizes every 16 primary CC identifiers mapped visually as exact colored layout tiles mathematically mapped inside an offset tracking grid, outputting instantly tracked color hex tags dynamically to an interface upon selection.

#### `ScrollPanel()`
Orchestrates genuine internal interface clipping exclusively via `window.create()` tracking, safely swallowing layout over-boundaries while mapping exact Y coordinate scrolling structures back inside the engine limits sequentially.

## Test Examples

The project repository includes two primary execution scripts testing boundaries safely:
* `uitest.lua`: Deploys massive structural stress testing via three distinct application windows tracking TextEdit instances, color grid selectors, dropping arrays, and structural tracking logic mathematically accurately. 
* `monitor_test.lua`: Simple remote bounding track confirming generic monitor wrapping dynamically intercepts accurately.

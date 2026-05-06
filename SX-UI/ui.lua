-- Auto-inject package path so the framework loads internal modules without touching startup.lua
local libPath = "/lib/sxui/?.lua"
if not package.path:find(libPath, 1, true) then
    package.path = package.path .. ";" .. libPath
end

local _VERSION = "2.2.0"

local UI = {
    _VERSION = _VERSION,
    Screen = require("core.screen"),
    Element = require("core.element"),
    Animator = require("core.animator"),
    Frame = require("widgets.frame"),
    AppWindow = require("widgets.appwindow"),
    Button = require("widgets.button"),
    Label = require("widgets.label"),
    Input = require("widgets.input"),
    Checkbox = require("widgets.checkbox"),
    Slider = require("widgets.slider"),
    Multiline = require("widgets.multiline"),
    TextEdit = require("widgets.textedit"),
    ScrollPanel = require("widgets.scrollpanel"),
    Dropdown = require("widgets.dropdown"),
    ColorSelector = require("widgets.colorselector"),
}

return UI

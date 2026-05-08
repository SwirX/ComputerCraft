local REPO_USER = "SwirX"
local REPO_NAME = "ComputerCraft"
local REPO_BRANCH = "main"
local REPO_BASE = "SX-UI/"

local FILES = {
    "ui.lua",
    "core/class.lua",
    "core/animator.lua",
    "core/element.lua",
    "core/screen.lua",
    "widgets/frame.lua",
    "widgets/appwindow.lua",
    "widgets/button.lua",
    "widgets/label.lua",
    "widgets/input.lua",
    "widgets/checkbox.lua",
    "widgets/slider.lua",
    "widgets/multiline.lua",
    "widgets/textedit.lua",
    "widgets/scrollpanel.lua",
    "widgets/dropdown.lua",
    "widgets/colorselector.lua",
}

local INSTALL_DIR = "/lib/sxui/"

print("SX-UI v2.2.0 installer")

if not fs.exists(INSTALL_DIR) then fs.makeDir(INSTALL_DIR) end
if not fs.exists(INSTALL_DIR .. "core") then fs.makeDir(INSTALL_DIR .. "core") end
if not fs.exists(INSTALL_DIR .. "widgets") then fs.makeDir(INSTALL_DIR .. "widgets") end

local function downloadFile(path)
    local url = string.format("https://raw.githubusercontent.com/%s/%s/%s/%s%s", REPO_USER, REPO_NAME, REPO_BRANCH,
        REPO_BASE, path)
    write("  " .. path .. "... ")
    local req = http.get(url)
    if req then
        local content = req.readAll()
        req.close()
        local file = fs.open(INSTALL_DIR .. path, "w")
        file.write(content)
        file.close()
        print("ok")
    else
        print("FAILED")
    end
end

for _, path in ipairs(FILES) do
    downloadFile(path)
end

local function setupPackage()
    local pkgPath = "/.sx_packages.json"
    local apps = {}
    if fs.exists(pkgPath) then
        local f = fs.open(pkgPath, "r")
        local content = f.readAll()
        f.close()
        if content and content ~= "" then
            apps = textutils.unserialiseJSON(content) or {}
        end
    end
    apps["sxui"] = { version = "2.2.0", type = "library", name = "SX-UI" }
    local pf = fs.open(pkgPath, "w")
    pf.write(textutils.serialiseJSON(apps))
    pf.close()

    local bootstrapper = [[
local sxuiPath = "/lib/sxui/?.lua"
if not package.path:find(sxuiPath, 1, true) then
    package.path = package.path .. ";" .. sxuiPath
end
]]
    local hasInjection = false
    if fs.exists("/startup.lua") then
        local sf = fs.open("/startup.lua", "r")
        local s_content = sf.readAll() or ""
        sf.close()
        if s_content:find("/lib/sxui/?.lua", 1, true) then hasInjection = true end
    end
    if not hasInjection then
        local sf = fs.open("/startup.lua", "a")
        sf.write("\n" .. bootstrapper)
        sf.close()
        print(">> Added SX-UI library path to /startup.lua")
        print(">> WARNING: You must reboot this computer for changes to take effect.")
    end
end
setupPackage()

print("Installed to " .. INSTALL_DIR)
print('Usage: local ui = require("ui")')

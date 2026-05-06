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
    "widgets/button.lua",
    "widgets/label.lua",
    "widgets/input.lua",
    "widgets/checkbox.lua",
    "widgets/slider.lua",
    "widgets/multiline.lua",
}

local INSTALL_DIR = "/lib/sxui/"

print("Starting installation of SX-UI v2.0.0...")

if not fs.exists(INSTALL_DIR) then fs.makeDir(INSTALL_DIR) end
if not fs.exists(INSTALL_DIR .. "core") then fs.makeDir(INSTALL_DIR .. "core") end
if not fs.exists(INSTALL_DIR .. "widgets") then fs.makeDir(INSTALL_DIR .. "widgets") end

local function downloadFile(path)
    local url = string.format("https://raw.githubusercontent.com/%s/%s/%s/%s%s", REPO_USER, REPO_NAME, REPO_BRANCH, REPO_BASE, path)
    write("Downloading " .. path .. "... ")
    local req = http.get(url)
    if req then
        local content = req.readAll()
        req.close()
        local file = fs.open(INSTALL_DIR .. path, "w")
        file.write(content)
        file.close()
        print("Done.")
    else
        print("Failed!")
    end
end

for _, path in ipairs(FILES) do
    downloadFile(path)
end

print("\nSuccessfully installed SX-UI into: " .. INSTALL_DIR)
print("No startup modifications were required. You can load it instantly with:")
print([[local ui = require("lib.sxui.ui")]])


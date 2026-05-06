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

local INSTALL_DIR = "/.sxui/"

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

-- Safely inject into package.path so require("ui") resolves flawlessly
local startupFile = "/startup.lua"
local hookLine = "package.path = package.path .. ';/.sxui/?.lua'"
local content = ""

if fs.exists(startupFile) then
    if not fs.isDir(startupFile) then
        local f = fs.open(startupFile, "r")
        content = f.readAll() or ""
        f.close()
    end
end

if not content:find(hookLine, 1, true) then
    if fs.isDir(startupFile) then
        -- User is using a /startup/ directory structure
        local hookFile = fs.open("/startup/00_sxui.lua", "w")
        hookFile.write "-- SX-UI Global Path Hook\n"
        hookFile.write(hookLine .. "\n")
        hookFile.close()
    else
        local f = fs.open(startupFile, "a")
        if content ~= "" and not content:match("\n$") then
            f.write("\n")
        end
        f.write("-- SX-UI Global Path Hook\n")
        f.write(hookLine .. "\n")
        f.close()
    end
end

-- Update path dynamically for the current session without requiring reboot
package.path = package.path .. ";/.sxui/?.lua"

print("\nSuccessfully installed SX-UI to hidden directory: " .. INSTALL_DIR)
print("Startup file hooked. You can seamlessly `require(\"ui\")` in your projects.")

local REPO_USER   = "SwirX"
local REPO_NAME   = "ComputerCraft"
local REPO_BRANCH = "main"
local RAW_BASE    = "https://raw.githubusercontent.com/" .. REPO_USER .. "/" .. REPO_NAME .. "/" .. REPO_BRANCH

local SXUI_FILES  = {
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

local function makeDir(path)
    if not fs.exists(path) then fs.makeDir(path) end
end

local function downloadTo(url, destPath)
    write("  " .. destPath .. "... ")
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        local file = fs.open(destPath, "w")
        file.write(content)
        file.close()
        print("ok")
        return true
    else
        print("FAILED")
        return false
    end
end

print("SX-Music installer")
print("Installing SX-UI framework into /lib/sxui/...")

makeDir("/lib/sxui")
makeDir("/lib/sxui/core")
makeDir("/lib/sxui/widgets")

local failed = 0
for _, relPath in ipairs(SXUI_FILES) do
    local url  = RAW_BASE .. "/SX-UI/" .. relPath
    local dest = "/lib/sxui/" .. relPath
    if not downloadTo(url, dest) then
        failed = failed + 1
    end
end

print("")
print("Installing SX-Music player to /music...")
local musicUrl  = RAW_BASE .. "/SX-Music/music.lua"
local musicDest = "/music"
if not downloadTo(musicUrl, musicDest) then
    failed = failed + 1
end

print("")
if failed == 0 then
    print("Done. Run 'music' to launch SX-Music.")
else
    print(failed .. " file(s) failed to download. Check your internet access and retry.")
end

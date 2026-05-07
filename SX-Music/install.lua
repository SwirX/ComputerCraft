local REPO_USER   = "SwirX"
local REPO_NAME   = "ComputerCraft"
local REPO_BRANCH = "main"
local RAW_BASE    = "https://raw.githubusercontent.com/" .. REPO_USER .. "/" .. REPO_NAME .. "/" .. REPO_BRANCH

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
print("")
print("What do you want to install?")
print("1. Main App (GUI/CLI Player)")
print("2. Speaker Node (Wireless relay/speaker extension)")
write("Enter choice (1/2): ")
local mainChoice = read()

local failed = 0

if mainChoice == "2" then
    print("")
    print("Installing Speaker Node to /startup.lua...")
    if not downloadTo(RAW_BASE .. "/SX-Music/speaker_node.lua", "/startup.lua") then
        failed = failed + 1
    end
    print("")
    if failed == 0 then
        print("Done. Please attach a modem and a speaker, then reboot.")
    else
        print("Failed to download. Check connection.")
    end
    return
end

print("")
print("Installing SX-UI framework dependency...")
local sxuiUrl = RAW_BASE .. "/SX-UI/install.lua"
if shell then
    shell.run("wget", "run", sxuiUrl)
else
    local response = http.get(sxuiUrl)
    if response then
        local content = response.readAll()
        response.close()
        local func, err = load(content, "sxui_install", "t", _ENV)
        if func then
            func()
        else
            print("Failed to run SX-UI installer: " .. tostring(err))
            failed = failed + 1
        end
    else
        print("FAILED to download SX-UI installer")
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

makeDir("/lib/sxmusic")
print("Installing SX-Music GUI to /lib/sxmusic/gui.lua...")
if not downloadTo(RAW_BASE .. "/SX-Music/gui.lua", "/lib/sxmusic/gui.lua") then
    failed = failed + 1
end

print("Installing SX-Music CLI to /lib/sxmusic/cli.lua...")
if not downloadTo(RAW_BASE .. "/SX-Music/cli.lua", "/lib/sxmusic/cli.lua") then
    failed = failed + 1
end

print("")
print("Which version do you want to run by default?")
print("1. GUI (Requires Advanced Computer/Turtle)")
print("2. CLI (Works on any Computer/Turtle)")
print("3. Auto-detect (Defaults to GUI on Color, CLI on B/W)")
write("Enter choice (1/2/3): ")
local choice = read()
local prefStr = ""
if choice == "1" then
    prefStr = "gui"
elseif choice == "2" then
    prefStr = "cli"
else
    prefStr = "auto"
end

local pf = fs.open(".sxmusic_pref", "w")
if pf then
    pf.write(prefStr)
    pf.close()
end

print("")
if failed == 0 then
    print("Done. Run 'music' to launch SX-Music.")
else
    print(failed .. " file(s) failed to download. Check your internet access and retry.")
end

local site = "https://swirx.github.io/ComputerCraft/"
local pythonDownloadLink = "https://www.python.org/ftp/python/3.11.3/python-3.11.3-amd64.exe"

local function splitString(input, delimiter)
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter)
    input:gsub(pattern, function(substring)
        table.insert(result, substring)
    end)
    return result
end

local function download(url, destination)
    print("Downloading " .. url)
    local response = http.get(url)
    local content = response.readAll()
    response.close()

    local file = io.open(destination, "w")
    file:write(content)
    file:close()

    print("Download complete: " .. destination)
end

local function showProgressBar(progress)
    local progressBarWidth = 30
    local numFilled = math.floor(progress * progressBarWidth)
    local numEmpty = progressBarWidth - numFilled
    local progressBar = string.rep("=", numFilled) .. string.rep(" ", numEmpty)
    local progressPercentage = string.format(" %.2f%%", progress * 100)

    term.clear()
    term.setCursorPos(1, 1)
    print("Downloading Python installer...")
    print(progressBar)
    print(progressPercentage)
end

local function downloadPythonInstaller()
    download(pythonDownloadLink, "SX-Music/python-installer.exe")
end

local function installPython()
    print("Installing Python...")
    -- Code to execute the Python installer goes here
    -- You can use the 'shell.execute' function to run the installer
    -- Example: shell.execute("SX-Music/python-installer.exe", "-silent -install")
    print("Python installation complete")
end

local function pipInstallLibs()
    print("Installing the required libraries...")
    shell.execute("pip install -r SX-Music/requirements.txt")
    shell.execute("del SX-Music/requirements.txt")
    print("Library installation complete")
end

local function downloadFiles()
    local app = site .. "SX-Music/"
    local player = app .. "player.lua"
    local requirements = app .. "requirements.txt"

    download(player, "SX-Music/player.lua")
    download(requirements, "SX-Music/requirements.txt")
end

local function flushScreen()
    term.clear()
    term.setCursorPos(1, 1)
end

local function getUserInput(prompt)
    print(prompt)
    return string.lower(read())
end

local function showMenu(message, options)
    local validInput = false
    local choice = nil

    while not validInput do
        flushScreen()
        print(message)
        for i, option in ipairs(options) do
            print(i .. ". " .. option)
        end

        local input = getUserInput("Enter your choice: ")

        if tonumber(input) ~= nil then
            local index = tonumber(input)
            if index >= 1 and index <= #options then
                validInput = true
                choice = index
            end
        end
    end

    return choice
end

local function runInstaller()
    flushScreen()
    print("SX-Music Installer Wizard")
    shell.execute("mkdir SX-Music")

    local installed = showMenu("Do you have Python installed on your machine?", {"Yes", "No"})
    if installed == 1 then
        flushScreen()
        pipInstallLibs()
        flushScreen()
        print("Download SX-Music")
        downloadFiles()
        print("Download finished")
        flushScreen()
    else
        flushScreen()
        local installMethod = showMenu("Do you want to install Python or use the SX-Music web-converter?", {"Install Python", "Use Web Converter"})
        if installMethod == 1 then
            downloadPythonInstaller()
            installPython()
            pipInstallLibs()
            flushScreen()
            print("Download SX-Music")
            downloadFiles()
            print("Download finished")
            flushScreen()
        else
            local ufile = io.open("SX-Music/Usage.sx", "w")
            ufile:write("WebConvert: true")
            ufile:close()
        end
    end

    print("App downloaded successfully")

    local createShortcut = showMenu("Create a shortcut?", {"Yes", "No"})
    if createShortcut == 1 then
        local shortcut = io.open("sxmusic", "w")
        local player = io.open("SX-Music/player.lua", "r")
        local content = player:read("*a")
        shortcut:write(content)
        shortcut:close()
        player:close()
    end

    flushScreen()
end

runInstaller()

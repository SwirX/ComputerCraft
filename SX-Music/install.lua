local site = "https://swirx.github.io/ComputerCraft/"
local pythonDownloadLink = "https://www.python.org/ftp/python/3.11.3/python-3.11.3-amd64.exe"

function splitString(input, delimiter)
    local result = {}
    local patern = string.format("([^%s]+)", delimiter)
    input:gsub(patern, function(substring)
        table.insert(result, substring)
    end)
    return result
end

function pipTheLibs()
    print("Donwloading the required libraries")
    shell.execute("pip install -r rq.txt")
    shell.execute("del rq.txt")
end

function download(url)
    print("Downloading "..url)
    local response = http.get(url)
    local content = response.readAll()
    local length = response.getResponseHeader("Content-Length")
    response.close()

    local split = splitString(url, "/")
    local filename = split[#split]

    -- Save the Python installer to a file
    local file = fs.open("SX-Music\\"..filename, "w")
    file.write(content)
    file.close()
  
    -- Display a progress bar
    local progressBarWidth = 30
    local downloadedSize = string.len(content)
    local progress = downloadedSize / tonumber(length)
  
    term.clear()
    term.setCursorPos(1, 1)
    term.write("Downloading Python installer...")
    term.setCursorPos(1, 2)
    term.write(("="):rep(progress * progressBarWidth))
    term.setCursorPos(1, 3)
    term.write((" "):rep(progressBarWidth - (progress * progressBarWidth)) .. string.format(" %.2f%%", progress * 100))
end

function downloadFiles()
    local app = site.."SX-Music/"
    local player = app.."player.lua"
    local req = app.."rq.txt"


    download(player)
    download(req)
end

function choice(trueV, falseV)
    print('('..trueV..','..falseV')')
    local c = string.lower(read())
    if c == string.lower(trueV) then
        return true
    elseif c == string.lower(falseV) then
        return false
    end
end

function flushScr()
    term.clear()
    term.setCursorPos(1,1)
end


function App()
    print("SX-Music Installer Wizard")
    print("A new directory will be created on your machine")
    shell.execute("mkdir", "SX-Music")
    print(nil, "Do you have python installed on your machine?")
    local installed = choice("Y", "n")
    if installed then
        flushScr()
        pipTheLibs()
        print("Download complete")
        flushScr()
        print("Downloading SX-Music")
        downloadFiles()
        print(nil, "Download finished")
        flushScr()
    else
        flushScr()
        print("You want to install it or use the SX-Music web-converter")
        local web = choice("Y", "n")
        if web then
            local ufile = fs.open("SX-Music\\Usage.sx", "w")
            ufile.write("WebConvert: true")
            ufile.close()
        else
            local app = site.."SX-Music/"
            local downloader = app.."downloader.py"
            local converter = app.."converter.py"
            
            download(downloader)
            download(converter)
        end
    end
    flushScr()
    print("App downloaded successfully")
    print("Create a shortcut?")
    local c = choice("Y", "n")
    if c then
        local shortcut = fs.open("sxmusic", "w")
        local player = fs.open("SX-Music\\install.lua", "r")
        local content = player.readAll()
        shortcut.write(content)
        shortcut.close()
        player.close()
    end
    flushScr()
end
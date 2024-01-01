local uiLink = "http://swirx.ddns.net/cc/SX-UI/ui.lua"

local logsFile = fs.open("system/logs/installer", "w")

local function log(...)
    local d = os.date("!*t")
    local timestamp = string.format("%d-%d-%d-%d:%d:%d", d.year, d.month, d.day, d.hour, d.min, d.sec)
    print("[" .. timestamp .. "]" .. ...)
    logsFile.write("[" .. timestamp .. "]" .. ...)
end

function installUI()
    log("checking if the SX-UI library is present")
    sleep(1)
    if fs.exists("system/ui.lua") then
        log("SX-UI was found on the system")
        log("Skipping the installation of the ui")
        sleep(1)
        return true
    else
        log("SX-UI was not found on the system")
        log("installing the SX-UI library")
        local request = http.get(uiLink)
        if request == nil then error("No response from the requested server") end
        local response = request.readAll()
        local downloadedFile = fs.open("/system/ui.lua", "w")
        downloadedFile.write(response)
        downloadedFile.close()
        log("SX-UI library was downloaded successfully")
        sleep(1)
        return true
    end
end

installed = installUI()

if installed ~= true then log('re-run the installer')return end

ui = require("system/ui")

ui.init()

local screen = ui.Screen()

local sw, sh = term.getSize()

local title = ui.Create("textlabel")
title.text = "SX-Installer"
title.position = {x=(sw/2)-title.text:len(), y=1}
title.backgroundColor = colors.blue

local message = ui.Create("textlabel")
message.text = "The Best OS For ComputerCraft:Tweaked"
message.position = {x=5, y=5}
message.backgroundColor = colors.cyan

local errormsg = ui.Create("textlabel")
errormsg.text = ""
errormsg.position = {x=5, y=3}
errormsg.backgroundColor = colors.red

local function defaultInstalation()
    message.text = "the installation of SX-OS will begin shortly"
    sleep(1)
    error("still working on it lol :P")
end

local function start()
    sleep(1)
    message.text = "Choose the installation mode you want"
    local default = ui.Create("textcheckbox")
    local custom = ui.Create("textcheckbox")
    default.text = "Default instalation"
    default.position = {x=1, y=7}
    default:onToggle(function ()
        custom.value = not default.value
    end)
    custom:onToggle(function ()
        default.value = not custom.value
    end)
    custom.text = "Custom installation"
    custom.position = {x=1, y=9}
    local continueBtn = ui.Create("button")
    continueBtn.text = "Continue"
    continueBtn.backgroundColor = colors.blue
    continueBtn.position = {x=sw-(continueBtn.text:len()+5), y=12}
    continueBtn:onClick(function()
        continueBtn.backgroundColor = colors.cyan
        if default.value and custom.value then
            errormsg.text = "You can't choose both custom and default"
            sleep(1)
        elseif default.value and not custom.value then
            default:Remove()
            default:Remove()
            custom:Remove()
            custom:Remove()
            message.text = "The default instalation has been choosen"
            ui.Refresh()
            sleep(1)
            defaultInstalation()
        elseif not default.value and custom.value then
            errormsg.text = "still working on it :P"
            sleep(1)
            errormsg.text = ""
            start()
        end
        continueBtn.backgroundColor = color.blue
    end)
end

start()

ui.HandleInput()
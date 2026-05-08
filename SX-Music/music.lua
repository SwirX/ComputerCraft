require("sx")

local isColor = term.isColor()
local settingsFile = ".sxmusic_pref"

local sxuiPath = "/lib/sxui/?.lua"
if not package.path:find(sxuiPath, 1, true) then
    package.path = package.path .. ";" .. sxuiPath
end

local pref = nil
if fs.exists(settingsFile) then
    local f = fs.open(settingsFile, "r")
    if f then
        pref = f.readAll()
        f.close()
    end
end

-- Trim whitespace just in case
if type(pref) == "string" then
    pref = pref:gsub("^%s*(.-)%s*$", "%1")
end

if pref == "cli" then
    shell.run("/lib/sxmusic/cli.lua")
elseif pref == "gui" then
    shell.run("/lib/sxmusic/gui.lua")
else
    if isColor then
        shell.run("/lib/sxmusic/gui.lua")
    else
        shell.run("/lib/sxmusic/cli.lua")
    end
end

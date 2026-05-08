local args = { ... }
local tDir = args[1] or _ENV.ENV.HOME or "/"
tDir = shell.resolve(tDir)
if fs.isDir(tDir) then
    shell.setDir(tDir)
else
    printError("cd: " .. tostring(args[1]) .. ": No such directory")
end

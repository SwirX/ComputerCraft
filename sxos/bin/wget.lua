local args = { ... }
if #args < 1 then
    print("Usage: wget <url> <filename>")
    print("       wget run <url>")
    return
end

local isRun = false
local url = ""
local path = ""

if args[1] == "run" then
    if #args < 2 then
        print("Usage: wget run <url>")
        return
    end
    isRun = true
    url = args[2]
else
    if #args < 2 then
        print("Usage: wget <url> <filename>")
        return
    end
    url = args[1]
    path = shell.resolve(args[2])
end

if not string.find(url, "^https?://") then
    url = "http://" .. url
end

print("Connecting to " .. url)
local res = http.get(url)
if not res then
    printError("Failed to download.")
    return
end

local data = res.readAll()
res.close()

if isRun then
    local func, err = load(data, url, "t", _ENV)
    if not func then
        printError("Failed to compile downloaded code: " .. tostring(err))
        return
    end
    local runArgs = {}
    for i = 3, #args do table.insert(runArgs, args[i]) end
    local ok, runErr = pcall(func, table.unpack(runArgs))
    if not ok then
        printError("Runtime error: " .. tostring(runErr))
    end
else
    local f = fs.open(path, "w")
    if f then
        f.write(data)
        f.close()
        print("Downloaded " .. #data .. " bytes to " .. args[2])
    else
        printError("Failed to open file for writing.")
    end
end

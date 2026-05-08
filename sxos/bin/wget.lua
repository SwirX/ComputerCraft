local args = { ... }
if #args < 2 then
    print("Usage: wget <url> <filename>")
    return
end

local url = args[1]
local path = shell.resolve(args[2])

print("Connecting to " .. url)
local res = http.get(url)
if res then
    local data = res.readAll()
    res.close()
    local f = fs.open(path, "w")
    if f then
        f.write(data)
        f.close()
        print("Downloaded " .. #data .. " bytes.")
    else
        printError("Failed to open file for writing.")
    end
else
    printError("Failed to download.")
end

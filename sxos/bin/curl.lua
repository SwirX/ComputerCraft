local args = { ... }
if #args < 1 then
    print("Usage: curl <url>")
    return
end

local url = args[1]
local res = http.get(url)
if res then
    print(res.readAll())
    res.close()
else
    printError("curl: (7) Failed to connect to host")
end

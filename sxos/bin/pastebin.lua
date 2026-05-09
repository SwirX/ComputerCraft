local args = { ... }
if #args < 2 then
    print("Usage:")
    print("  pastebin put <file>")
    print("  pastebin get <code> <file>")
    print("  pastebin run <code>")
    return
end

local command = args[1]

if command == "put" then
    local path = shell.resolve(args[2])
    if not fs.exists(path) then
        printError("File not found.")
        return
    end
    local f = fs.open(path, "r")
    if not f then
        printError("Failed to open file."); return
    end
    local data = f.readAll()
    f.close()

    print("Connecting to pastebin.com...")
    local key = "0rZ94E2z" -- Standard CC pastebin key
    local requestBody = "api_option=paste&api_dev_key=" ..
    textutils.urlEncode(key) ..
    "&api_paste_format=lua&api_paste_name=" ..
    textutils.urlEncode(fs.getName(path)) .. "&api_paste_code=" .. textutils.urlEncode(data)

    local res = http.post("https://pastebin.com/api/api_post.php", requestBody)
    if res then
        local responseBody = res.readAll()
        res.close()
        local pasteCode = string.match(responseBody, "^https?://pastebin.com/(.+)$")
        if pasteCode then
            print("Success! Uploaded to:")
            print(responseBody)
        else
            printError("Upload failed: " .. responseBody)
        end
    else
        printError("Failed to connect to pastebin.com")
    end
elseif command == "get" or command == "run" then
    local code = args[2]

    local paste = string.match(code, "[a-zA-Z0-9]+$")
    if not paste then
        printError("Invalid paste code")
        return
    end

    print("Connecting to pastebin.com...")
    local res = http.get("https://pastebin.com/raw/" .. textutils.urlEncode(paste))
    if not res then
        printError("Failed to download.")
        return
    end
    local data = res.readAll()
    res.close()

    if command == "get" then
        if #args < 3 then
            print("Usage: pastebin get <code> <file>")
            return
        end
        local path = shell.resolve(args[3])
        local f = fs.open(path, "w")
        if not f then
            printError("Failed to open file for writing."); return
        end
        f.write(data)
        f.close()
        print("Downloaded as " .. args[3])
    else
        local func, err = load(data, "pastebin", "t", _ENV)
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
    end
else
    print("Usage:")
    print("  pastebin put <file>")
    print("  pastebin get <code> <file>")
    print("  pastebin run <code>")
end

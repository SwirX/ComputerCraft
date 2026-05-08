-- /bin/bsh.lua
-- Better SHell for SXOS

local history = {}
local aliases = {
    ll = "ls -l",
    la = "ls -a"
}
local dir = _ENV.ENV.HOME or "/"
_ENV.ENV.PWD = dir
local path = _ENV.ENV.PATH or "/bin;/usr/bin"
local runningProgram = "/bin/bsh.lua"
local isInstaller = _ENV.INSTALLER_MODE

local user = _ENV.ENV.USER or "user"
local hostname = "sxos"

local shellAPI = {
    dir = function() return dir end,
    setDir = function(d)
        dir = d; _ENV.ENV.PWD = dir
    end,
    path = function() return path end,
    setPath = function(p)
        path = p; _ENV.ENV.PATH = path
    end,
    resolve = function(p)
        if string.sub(p, 1, 1) == "/" then return fs.combine("", p) end
        return fs.combine(dir, p)
    end,
    aliases = function() return aliases end,
    setAlias = function(c, p) aliases[c] = p end,
    clearAlias = function(c) aliases[c] = nil end,
    getRunningProgram = function() return runningProgram end
}
_ENV.shell = shellAPI

local function resolveExecutable(name)
    if aliases[name] then
        local first = string.match(aliases[name], "[^ \t]+")
        if first then return resolveExecutable(first), aliases[name] end
    end

    local p = shellAPI.resolve(name)
    if fs.exists(p) and not fs.isDir(p) then return p, nil end
    if fs.exists(p .. ".lua") and not fs.isDir(p .. ".lua") then return p .. ".lua", nil end

    for pathStr in string.gmatch(path, "[^;:]+") do
        local testP = fs.combine(pathStr, name)
        if fs.exists(testP) and not fs.isDir(testP) then return testP, nil end
        if fs.exists(testP .. ".lua") and not fs.isDir(testP .. ".lua") then return testP .. ".lua", nil end
    end
    return nil, nil
end
shellAPI.resolveProgram = resolveExecutable

function shellAPI.run(...)
    local args = { ... }
    if type(args[1]) == "string" then
        args = {}
        for s in string.gmatch(..., "[^ \t]+") do table.insert(args, s) end
    end

    local cmd = args[1]
    if not cmd then return true end

    local execPath, aliasCommand = resolveExecutable(cmd)

    if aliasCommand then
        -- Reparse based on alias
        local newArgs = {}
        for s in string.gmatch(aliasCommand, "[^ \t]+") do table.insert(newArgs, s) end
        for i = 2, #args do table.insert(newArgs, args[i]) end
        args = newArgs
    end

    if not execPath then
        printError("bsh: " .. cmd .. ": command not found")
        return false
    end

    table.remove(args, 1)

    local fn, err = loadfile(execPath, "t", _ENV)
    if not fn then
        printError("bsh: " .. execPath .. ": load error: " .. err)
        return false
    end

    local prevProgram = runningProgram
    runningProgram = execPath
    local ok, res = pcall(fn, table.unpack(args))
    runningProgram = prevProgram

    if not ok then
        printError("bsh: " .. execPath .. ": " .. tostring(res))
        return false
    end
    return true
end

shellAPI.execute = shellAPI.run

local function getCompletion(text)
    if isInstaller then return nil end
    local words = {}
    for s in string.gmatch(text, "[^ \t]+") do table.insert(words, s) end
    if string.sub(text, -1) == " " then table.insert(words, "") end

    if #words <= 1 then
        local cmd = words[1] or ""
        for k, _ in pairs(aliases) do
            if string.sub(k, 1, #cmd) == cmd then return string.sub(k, #cmd + 1) end
        end
        for pathStr in string.gmatch(path, "[^;:]+") do
            if fs.exists(pathStr) then
                for _, file in ipairs(fs.list(pathStr)) do
                    local noExt = string.gsub(file, "%.lua$", "")
                    if string.sub(noExt, 1, #cmd) == cmd then return string.sub(noExt, #cmd + 1) end
                    if string.sub(file, 1, #cmd) == cmd then return string.sub(file, #cmd + 1) end
                end
            end
        end
    end
    return nil
end

local function drawPrompt()
    local promptDir = dir
    if promptDir == _ENV.ENV.HOME then
        promptDir = "~"
    end
    term.setTextColor(user == "root" and colors.red or colors.green)
    write(user .. "@" .. hostname)
    term.setTextColor(colors.white)
    write(" ")
    term.setTextColor(colors.blue)
    write(promptDir)
    term.setTextColor(colors.lightGray)
    write(user == "root" and " # " or " $ ")
    term.setTextColor(colors.white)
end

local function read_line()
    drawPrompt()
    local startX, startY = term.getCursorPos()
    local w, h = term.getSize()
    local line = ""
    local pos = 0
    local suggestion = ""
    local historyPos = #history + 1
    local scroll = 0

    local function redraw()
        local maxLen = w - startX
        if pos - scroll > maxLen then
            scroll = pos - maxLen
        elseif pos < scroll then
            scroll = pos
        end

        term.setCursorPos(startX, startY)
        local visible = string.sub(line, scroll + 1, scroll + maxLen)

        local cmdEnd = string.find(visible, " ")
        if not cmdEnd then cmdEnd = #visible + 1 end
        local cmdStr = string.sub(visible, 1, cmdEnd - 1)
        local restStr = string.sub(visible, cmdEnd)

        if #cmdStr > 0 then
            local isCmd = resolveExecutable(string.sub(line, 1, (string.find(line, " ") or (#line + 1)) - 1))
            term.setTextColor(isCmd and colors.cyan or colors.red)
            write(cmdStr)
        end
        term.setTextColor(colors.white)
        write(restStr)

        if not isInstaller and #line > 0 and pos == #line then
            suggestion = getCompletion(line) or ""
            local sugVisible = string.sub(suggestion, 1, maxLen - #visible)
            term.setTextColor(colors.gray)
            write(sugVisible)
        else
            suggestion = ""
        end

        local cx, cy = term.getCursorPos()
        if cx <= w then
            term.write(string.rep(" ", w - cx + 1))
        end

        term.setCursorPos(startX + (pos - scroll), startY)
        term.setTextColor(colors.white)
    end

    redraw()

    while true do
        local event, p1, p2, p3 = os.pullEvent()
        if event == "char" then
            line = string.sub(line, 1, pos) .. p1 .. string.sub(line, pos + 1)
            pos = pos + 1
            redraw()
        elseif event == "key" then
            if p1 == keys.enter then
                print()
                break
            elseif p1 == keys.backspace and pos > 0 then
                line = string.sub(line, 1, pos - 1) .. string.sub(line, pos + 1)
                pos = pos - 1
                redraw()
            elseif p1 == keys.left and pos > 0 then
                pos = pos - 1
                redraw()
            elseif p1 == keys.right then
                if pos < #line then
                    pos = pos + 1
                    redraw()
                elseif #suggestion > 0 then
                    line = line .. suggestion
                    pos = #line
                    redraw()
                end
            elseif p1 == keys.tab and #suggestion > 0 then
                line = line .. suggestion
                pos = #line
                redraw()
            elseif p1 == keys.up then
                if historyPos > 1 then
                    historyPos = historyPos - 1
                    line = history[historyPos]
                    pos = #line
                    redraw()
                end
            elseif p1 == keys.down then
                if historyPos < #history then
                    historyPos = historyPos + 1
                    line = history[historyPos]
                    pos = #line
                    redraw()
                elseif historyPos == #history then
                    historyPos = historyPos + 1
                    line = ""
                    pos = 0
                    redraw()
                end
            end
        end
    end

    if #line > 0 and line ~= history[#history] then
        table.insert(history, line)
    end
    return line
end

-- Core loop
term.setTextColor(colors.lightGray)
print("Welcome to bsh (Better SHell).")
if isInstaller then
    print("Warning: Installer TTY active. Autocompletion disabled.")
end

while true do
    local success, line = pcall(read_line)
    if not success then
        print()
        break
    end

    if line == "exit" then
        break
    elseif string.match(line, "^%s*$") then
        -- do nothing
    else
        shellAPI.run(line)
    end
end

local pos = 1
local path = "./"
local selectedpath = "./"
local FCount = 0
local oldPosition = 0

local c = {
    up = function()
        if pos == 0 then pos = 1 end
        if pos == 1 then
            pos = FCount
        elseif pos > 1 and pos <= FCount+1 then
            pos = pos - 1
        end
    end,
    down = function()
        if pos == 0 then pos = 1 end
        if pos == FCount then
            pos = 1
        elseif pos>=1 and pos<FCount+1 then
            pos = pos + 1
        end
    end,
    uipos = {
        "../", "./"
    },
    azM = {
        fwd = keys.z,
        bwd = keys.s,
        rgt = keys.d,
        lft = keys.q,
    },
    qwM = {
        fwd = keys.w,
        bwd = keys.s,
        rgt = keys.d,
        lft = keys.a,
    },
    kbMode = "az",
    filesInView = {},
}



function GetDir(path_)
    if path_ == nil then path_ = "./" end
    return fs.list(path_)
end

function GetTypes(files)
    if type(files) ~= "table" or files == nil then error("GetTypes(files) <-- files should be a table", 0) end

    local d = {}
    local f = {}

    for _, v in pairs(files) do
        if fs.isDir(shell.resolve(v)) then
            table.insert(d, v)
        else
            table.insert(f, v)
        end
    end
    return d, f
end

function CheckType(file)
    if type(file) ~= "string" or file == nil then error("CheckType(file) <-- file should be a string", 0) end
    if file == "../" or file == "./" then
        return file, "u"
    elseif fs.isDir(shell.resolve(file)) then
        return file, "d"
    else
        return file, "f"
    end
end

function fsout(fs_, type_, selected)
    if type(fs_) ~= "string" and type(type_) ~= "string" or fs_ == nil or type_ == nil then error("Missing or arguments with wrong type", 0) end
    if selected == nil then selected = false end
    if type_ == "d" then
        if selected then
            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.lightBlue)
            term.write("./"..fs_)
            local x, y = term.getCursorPos()
            term.setCursorPos(1, y+1)
            term.setBackgroundColor(colors.black)
        else
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.lightBlue)
            term.write("./"..fs_)
            local x, y = term.getCursorPos()
            term.setCursorPos(1, y+1)
        end
    elseif type_ == "f" then
        if selected then
            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.orange)
            term.write("./"..fs_)
            local x, y = term.getCursorPos()
            term.setCursorPos(1, y+1)
            term.setBackgroundColor(colors.black)
        else
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.orange)
            term.write("./"..fs_)
            local x, y = term.getCursorPos()
            term.setCursorPos(1, y+1)
            term.setBackgroundColor(colors.black)
        end
    elseif type_ == "u" then
        if selected then
            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.magenta)
            term.write(fs)
            local x, y = term.getCursorPos()
            term.setCursorPos(1, y+1)
            term.setTextColor(colors.white)
            term.setBackgroundColor(colors.black)
        else
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.magenta)
            term.write(fs)
            local x, y = term.getCursorPos()
            term.setCursorPos(1, y+1)
            term.setTextColor(colors.white)
            term.setBackgroundColor(colors.black)
        end
    end
end

function splitString(input, delimiter)
    local result = {}
    local patern = string.format("([^%s]+)", delimiter)
    input:gsub(patern, function(substring)
        table.insert(result, substring)
    end)
    return result
end

function fsOpen(fs_)
    if type(fs_) ~= "string" or fs_ == nil then error("Missing or argument with wrong type", 0) end
    local path_ = shell.resolve(fs_)
    if fs.isDir(path_) then
        path = path_
    elseif fs_ == "./" then
        local patharr = splitString(path, "/")
        patharr = table.remove(patharr)
        path = table.concat(patharr, "/")
    elseif fs_ == "../" then
        path = "/"
    else
        shell.execute("edit", path_)
    end
    oldPosition = 0
end

function Input()
    local f, d, r, l
    if c.kbMode == "az" then
        f, d, r, l = c.azM.fwd, c.azM.bwd, c.azM.rgt, c.azM.lft
    else
        f, d, r, l = c.qwM.fwd, c.qwM.bwd, c.qwM.rgt, c.qwM.lft
    end
    while true do
        local _, key = os.pullEvent('key')
        
        if key == keys.up or key == f then
            c.up()
        elseif key == keys.down or key == d then
            c.down()
        elseif key == keys.left or key == l then
            c.down()
        elseif key == keys.right or key == r then
            c.up()
        elseif key == keys.enter or key == keys.numPadEnter then
            fsOpen(selectedpath)
        end
    end
end

function isRoot(path_)
    if path_ == "/" then return true else return false end
end

function UI()
    while true do
        if oldPosition == pos then repeat sleep(.1) until oldPosition ~= pos end
        term.clear()
        term.setCursorBlink(false)
        term.setCursorPos(0,0)
        if path == "" or path == nil then path = "./" end
        local files = GetDir(path)
        -- if fs.isDriveRoot(path) then
        --     for i, file in pairs(files) do
        --         table.insert(c.filesInView, file)
        --         local f, t = CheckType(file)
        --         if pos == i then fsout(f, t, true)
        --         else fsout(f, t, false) end
        --     end
        -- else
            local oldFiles = files
            files = {}
            table.insert(files, "../")
            table.insert(files, "./")
            for i, v in pairs(oldFiles)do table.insert(files, v)end
            table.insert(c.filesInView, "../")
            table.insert(c.filesInView, "./")
            FCount = #files
            for i, file in ipairs(files) do
                table.insert(c.filesInView, file)
                local f, t = CheckType(file)
                if pos == i then fsout(f, t, true)selectedpath = path.."/"..file
                else fsout(f, t) end
            -- end
        end
        oldPosition = pos
    end
end

function App()
    parallel.waitForAny(UI, Input)--https://pastebin.com/JcRw98j6
end

App()

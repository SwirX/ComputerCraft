local args = { ... }
local tDir = args[1] or shell.dir()
local p = shell.resolve(tDir)

if not fs.exists(p) then
    printError("ls: cannot access '" .. tDir .. "': No such file or directory")
    return
end

if not fs.isDir(p) then
    print(tDir)
    return
end

local files = fs.list(p)
table.sort(files)

-- Simple coloring: blue for directories, white for files.
for _, file in ipairs(files) do
    local fp = fs.combine(p, file)
    if fs.isDir(fp) then
        term.setTextColor(colors.blue)
    else
        term.setTextColor(colors.white)
    end
    write(file .. "  ")
end
print()
term.setTextColor(colors.white)

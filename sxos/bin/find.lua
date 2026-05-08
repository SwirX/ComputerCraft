local args = { ... }
local rootPath = shell.resolve(args[1] or ".")
local namePattern = nil

for i = 1, #args do
    if args[i] == "-name" and args[i + 1] then
        namePattern = args[i + 1]
        namePattern = string.gsub(namePattern, "%.", "%%.")
        namePattern = string.gsub(namePattern, "%*", ".*")
        namePattern = "^" .. namePattern .. "$"
    end
end

local function crawl(dir)
    if not fs.isDir(dir) then return end
    for _, f in ipairs(fs.list(dir)) do
        local p = fs.combine(dir, f)
        if not namePattern or string.find(f, namePattern) then
            print("/" .. p)
        end
        if fs.isDir(p) then crawl(p) end
    end
end

if fs.exists(rootPath) then
    if not namePattern then print("/" .. rootPath) end
    crawl(rootPath)
else
    printError("find: '" .. rootPath .. "': No such file or directory")
end

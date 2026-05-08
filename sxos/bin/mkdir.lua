local args = { ... }
if #args == 0 then
    printError("mkdir: missing operand")
    return
end
for _, dir in ipairs(args) do
    local p = shell.resolve(dir)
    fs.makeDir(p)
end

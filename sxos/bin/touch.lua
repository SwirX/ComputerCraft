local args = { ... }
if #args == 0 then
    printError("touch: missing file operand")
    return
end
for _, file in ipairs(args) do
    local p = shell.resolve(file)
    if not fs.exists(p) then
        local f = fs.open(p, "w")
        if f then f.close() end
    end
end

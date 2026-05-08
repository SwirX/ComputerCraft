local args = { ... }
local ok, vfs = pcall(require, "lib.sx.vfs")
if not ok then
    printError("mount: vfs disabled"); return
end
vfs.init()

if #args == 0 then
    -- list mounts
    print("Logical System Mounts:")
    for mnt, target in pairs(vfs.getMounts()) do
        print(target .. " on " .. mnt)
    end
    return
end

if #args < 2 then
    printError("mount: missing operand")
    return
end
local target = args[1]
local mnt = shell.resolve(args[2])

vfs.setMount(mnt, target)
print("Mounted " .. target .. " into " .. mnt)

local args = { ... }
if #args == 0 then
    printError("umount: missing operand")
    return
end

local ok, vfs = pcall(require, "lib.sx.vfs")
if not ok then return end
vfs.init()

local mnt = shell.resolve(args[1])
vfs.clearMount(mnt)
print("Unmounted " .. mnt)

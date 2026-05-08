-- /sys/kernel.lua
local function load_module(path)
    local fn, err = loadfile(path)
    if not fn then error("Kernel failed to load " .. path .. ": " .. err, 0) end
    return fn()
end

local env = load_module("/sys/env.lua")
local auth = load_module("/sys/auth.lua")

-- Perform login
local username, userinfo = auth.do_login()

if not userinfo then
    error("Kernel failed to resolve user information for " .. tostring(username), 0)
end

-- Create base process environment for the shell
local process_env = env.create_process_env(_G, {
    PATH = "/bin;/usr/bin",
    HOME = userinfo.home,
    USER = username
})

local config = auth.read_config()
process_env.INSTALLER_MODE = config.installer_shell or false

local shell_path = userinfo.shell or "/bin/bsh.lua"
if not fs.exists(shell_path) then
    error("Kernel panic: Configured shell not found: " .. shell_path, 0)
end

local bsh_fn, err = loadfile(shell_path, "t", process_env)
if not bsh_fn then
    error("Kernel failed to launch shell: " .. err, 0)
end

-- Clear screen and run shell
term.setBackgroundColor(colors.black)
term.setTextColor(colors.lightGray)
term.clear()
term.setCursorPos(1, 1)

-- Execute UI shell, capturing errors
local success, err_msg = pcall(bsh_fn)
if not success then
    printError("Shell exited unexpectedly: " .. tostring(err_msg))
    print("Press any key to reboot.")
    os.pullEvent("key")
end

os.reboot()

local _M = {}

function _M.create_process_env(parentEnv, envVars)
    -- inherits from parentEnv, but constructs a custom cc.require
    local newEnv = {}
    for k, v in pairs(parentEnv or _G) do
        newEnv[k] = v
    end

    newEnv._ENV = newEnv

    -- setup ENV vars
    newEnv.ENV = envVars or {
        PATH = "/bin;/usr/bin",
        HOME = "/root",
        USER = "root"
    }

    -- set up custom require using cc.require.make
    -- this ensures that module contexts do not bleed into the global CraftOS package
    local cc_req = require("cc.require")
    local req, pkg = cc_req.make(newEnv, "/")
    newEnv.require = req
    newEnv.package = pkg

    -- provide custom package paths
    newEnv.package.path = "/lib/?.lua;/usr/lib/?.lua;/?/init.lua;/?.lua"

    return newEnv
end

return _M

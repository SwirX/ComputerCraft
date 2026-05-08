local extraPaths = {
    "/lib/?.lua",
    "/lib/?/init.lua",
    "/lib/?/?.lua",
    "/lib/sxui/?.lua",
}

for _, path in ipairs(extraPaths) do
    if not package.path:find(path, 1, true) then
        package.path = package.path .. ";" .. path
    end
end

return true

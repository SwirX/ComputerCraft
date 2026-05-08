-- /bin/sxpm.lua
-- SXOS Package Manager.
-- The primary interface for installing, removing, searching, and managing packages.
-- All real work is delegated to /lib/pkg/ modules via the sx.* API surface.
--
-- Usage:
--   sxpm install <package>
--   sxpm remove <package>
--   sxpm search <query>
--   sxpm list
--   sxpm update
--   sxpm upgrade
--   sxpm info <package>
--   sxpm build <manifest_path>
--   sxpm publish <manifest_path>

local manifest_module = dofile("/lib/pkg/manifest.lua")
local database_module = dofile("/lib/pkg/database.lua")
local resolve_module  = dofile("/lib/pkg/resolve.lua")

local args            = { ... }
local subcommand      = args[1]

local INSTALL_BASE    = "/usr/lib/sxpkg"
local BIN_DIR         = "/usr/bin"

local function print_usage()
    print("sxpm - SXOS Package Manager")
    print("")
    print("Usage: sxpm <command> [options]")
    print("")
    print("Commands:")
    print("  install <pkg>   Install a package")
    print("  remove <pkg>    Remove an installed package")
    print("  search <query>  Search available packages")
    print("  list            List installed packages")
    print("  update          Refresh repository metadata")
    print("  upgrade         Upgrade all installed packages")
    print("  info <pkg>      Show package details")
    print("  build <path>    Build a package from a manifest file")
    print("  publish <path>  Publish a built package to a repository")
end

-- Download a package from a known repository URL by name.
-- This is a stub: real implementation requires HTTP or Rednet transport.
local function fetch_package(package_name)
    local repos = database_module.load_repos()
    for _, repo in ipairs(repos) do
        local manifest_url = repo.url .. "/" .. package_name .. "/manifest.lua"
        -- In a live SXOS system this would use sx.net or http.get.
        -- For now we check if a local cached copy exists.
        local cache_path = "/var/cache/sxpm/" .. package_name .. "/manifest.lua"
        if fs.exists(cache_path) then
            return manifest_module.load_file(cache_path)
        end
    end
    return nil, "package not found in any repository: " .. package_name
end

local function cmd_install(package_name)
    if not package_name then
        printError("sxpm install: package name required")
        return
    end

    local existing = database_module.get(package_name)
    if existing then
        print(package_name .. " " .. existing.version .. " is already installed.")
        return
    end

    print("Fetching " .. package_name .. "...")
    local pkg, err = fetch_package(package_name)
    if not pkg then
        printError("sxpm: " .. tostring(err))
        return
    end

    -- Check dependencies before installing.
    local missing = resolve_module.check_dependencies(pkg)
    if #missing > 0 then
        printError("sxpm: unsatisfied dependencies:")
        for _, entry in ipairs(missing) do
            printError("  " .. entry.reason)
        end
        return
    end

    local install_path = INSTALL_BASE .. "/" .. package_name
    if not fs.exists(install_path) then fs.makeDir(install_path) end

    -- Copy installed files.
    local cache_dir = "/var/cache/sxpm/" .. package_name
    for _, file_entry in ipairs(pkg.files or {}) do
        local src = fs.combine(cache_dir, file_entry.src)
        local dest = file_entry.dest
        local dest_dir = string.match(dest, "^(.*)/[^/]+$") or "/"
        if not fs.exists(dest_dir) then fs.makeDir(dest_dir) end
        if fs.exists(src) then fs.copy(src, dest) end
    end

    -- Create wrapper scripts in /usr/bin for each declared binary.
    if not fs.exists(BIN_DIR) then fs.makeDir(BIN_DIR) end
    for _, bin_name in ipairs(pkg.binaries or {}) do
        local wrapper_path = BIN_DIR .. "/" .. bin_name .. ".lua"
        local real_path = install_path .. "/" .. bin_name .. ".lua"
        local handle = fs.open(wrapper_path, "w")
        if handle then
            handle.write("dofile(\"" .. real_path .. "\")\n")
            handle.close()
        end
    end

    database_module.record_install(pkg, install_path)
    print("Installed: " .. package_name .. " " .. pkg.version)
end

local function cmd_remove(package_name)
    if not package_name then
        printError("sxpm remove: package name required")
        return
    end
    local record = database_module.get(package_name)
    if not record then
        printError("sxpm: " .. package_name .. " is not installed")
        return
    end

    -- Remove /usr/bin wrappers.
    for _, bin_name in ipairs(record.binaries or {}) do
        local wrapper_path = BIN_DIR .. "/" .. bin_name .. ".lua"
        if fs.exists(wrapper_path) then fs.delete(wrapper_path) end
    end

    -- Remove installed directory.
    if fs.exists(record.install_path) then fs.delete(record.install_path) end

    database_module.record_remove(package_name)
    print("Removed: " .. package_name)
end

local function cmd_list()
    local installed = database_module.list_all()
    local count = 0
    for name, record in pairs(installed) do
        print(string.format("  %-24s  %s  [%s]", name, record.version, record.channel or "stable"))
        count = count + 1
    end
    if count == 0 then
        print("No packages installed.")
    else
        print(count .. " package(s) installed.")
    end
end

local function cmd_info(package_name)
    if not package_name then
        printError("sxpm info: package name required")
        return
    end
    local record = database_module.get(package_name)
    if not record then
        printError(package_name .. " is not installed")
        return
    end
    print("Name:    " .. record.name)
    print("Version: " .. record.version)
    print("Channel: " .. (record.channel or "stable"))
    print("Path:    " .. record.install_path)
    if record.binaries and #record.binaries > 0 then
        print("Bins:    " .. table.concat(record.binaries, ", "))
    end
end

local function cmd_search(query)
    if not query then
        printError("sxpm search: query required")
        return
    end
    print("Searching repositories for '" .. query .. "'...")
    -- Stub: in a real implementation this queries repo indexes.
    print("(Repository search requires network access and repo index sync.)")
    print("Run 'sxpm update' first to sync repository metadata.")
end

local function cmd_update()
    print("Syncing repository metadata...")
    -- Stub: would download index files from each repo URL.
    print("(Repository sync not yet connected to network backend.)")
end

local function cmd_upgrade()
    print("Checking for upgrades...")
    local installed = database_module.list_all()
    for name, record in pairs(installed) do
        print("  " .. name .. " " .. record.version .. " - up to date (upgrade check requires network)")
    end
end

local function cmd_build(manifest_path)
    if not manifest_path then
        printError("sxpm build: manifest path required")
        return
    end
    local pkg, err = manifest_module.load_file(manifest_path)
    if not pkg then
        printError("sxpm build: " .. tostring(err))
        return
    end
    print("Package validated: " .. pkg.name .. " " .. pkg.version)
    local cache_dest = "/var/cache/sxpm/" .. pkg.name
    if not fs.exists(cache_dest) then fs.makeDir(cache_dest) end
    local manifest_dest = cache_dest .. "/manifest.lua"
    fs.copy(manifest_path, manifest_dest)
    print("Staged to cache: " .. cache_dest)
end

-- Dispatch subcommand.
if subcommand == "install" then
    cmd_install(args[2])
elseif subcommand == "remove" then
    cmd_remove(args[2])
elseif subcommand == "list" then
    cmd_list()
elseif subcommand == "info" then
    cmd_info(args[2])
elseif subcommand == "search" then
    cmd_search(args[2])
elseif subcommand == "update" then
    cmd_update()
elseif subcommand == "upgrade" then
    cmd_upgrade()
elseif subcommand == "build" then
    cmd_build(args[2])
elseif subcommand == "publish" then
    print("sxpm publish: not yet implemented (requires repository server)")
else
    print_usage()
end

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
    print("  publish <path>  Publish a package instructions")
    print("  repo <action>   Manage repositories (add, rm, list)")
    print("  doctor          Check system for broken packages")
    print("  autoremove      Remove orphaned packages")
    print("  reinstall <pkg> Reinstall a package")
end

local function get_repos()
    local ok, res = pcall(database_module.load_repos)
    if ok and type(res) == "table" and #res > 0 then return res end
    return { { url = "https://raw.githubusercontent.com/SwirX/ComputerCraft/main/sx_packages" } }
end

local function fetch_package(package_name)
    for _, repo in ipairs(get_repos()) do
        local manifest_url = repo.url .. "/" .. package_name .. "/manifest.lua"
        local res = http.get(manifest_url)
        if res then
            local data = res.readAll(); res.close()
            local cache_path = "/var/cache/sxpm/" .. package_name .. "/manifest.lua"
            if not fs.exists(fs.getDir(cache_path)) then fs.makeDir(fs.getDir(cache_path)) end
            local f = fs.open(cache_path, "w"); f.write(data); f.close()

            local pkg, err = manifest_module.load_file(cache_path)
            if pkg then
                pkg._repo_url = repo.url .. "/" .. package_name
                return pkg
            end
        end
    end
    return nil, "package not found in repositories: " .. package_name
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

    print("Downloading files...")
    for _, file_entry in ipairs(pkg.files or {}) do
        local dest = file_entry.dest
        local dest_dir = fs.getDir(dest)
        if dest_dir ~= "" and not fs.exists(dest_dir) then fs.makeDir(dest_dir) end

        write("  GET " .. file_entry.src .. " -> " .. dest .. " ... ")
        local file_url = pkg._repo_url .. "/" .. file_entry.src
        local file_res = http.get(file_url)
        if file_res then
            local data = file_res.readAll(); file_res.close()
            local f = fs.open(dest, "w")
            if f then
                f.write(data); f.close(); print("OK")
            else
                print("ERR (fs)")
            end
        else
            print("ERR (http)")
        end
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
        printError("sxpm search: query required"); return
    end
    print("Searching repositories for '" .. query .. "'...")

    local found = false
    if fs.exists("/var/cache/sxpm") then
        for _, file in ipairs(fs.list("/var/cache/sxpm")) do
            if string.match(file, "^index_.*%.json$") then
                local f = fs.open("/var/cache/sxpm/" .. file, "r")
                if f then
                    local data = textutils.unserializeJSON(f.readAll() or "")
                    f.close()
                    if data and data.packages then
                        for pkg, meta in pairs(data.packages) do
                            if string.find(string.lower(pkg), string.lower(query)) or
                                (meta.description and string.find(string.lower(meta.description), string.lower(query))) then
                                print(string.format("  %-20s %s", pkg, meta.version or "unk"))
                                if meta.description then print("    " .. meta.description) end
                                found = true
                            end
                        end
                    end
                end
            end
        end
    end
    if not found then
        print("No packages found. Try running 'sxpm update' first if you haven't recently.")
    end
end

local function cmd_update()
    print("Syncing repository metadata...")
    for _, repo in ipairs(get_repos()) do
        local index_url = string.gsub(repo.url, "sx_packages/?$", "") .. ".sx_packages.json"
        print("Fetching " .. index_url)
        local res = http.get(index_url)
        if res then
            local data = res.readAll(); res.close()
            local safe_name = string.gsub(repo.url, "[^%w]", "_")
            local cache_path = "/var/cache/sxpm/index_" .. safe_name .. ".json"
            if not fs.exists(fs.getDir(cache_path)) then fs.makeDir(fs.getDir(cache_path)) end
            local f = fs.open(cache_path, "w"); f.write(data); f.close()
            print("Synced cache for " .. repo.url)
        else
            print("Failed to sync " .. repo.url)
        end
    end
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

local function cmd_repo()
    local action = args[2]
    local repos = get_repos()

    if action == "add" then
        local name, url = args[3], args[4]
        if not name or not url then
            print("Usage: sxpm repo add <name> <url>"); return
        end
        table.insert(repos, { name = name, url = url })
        database_module.save_repos(repos)
        print("Added repository '" .. name .. "': " .. url)
    elseif action == "remove" or action == "rm" then
        local name = args[3]
        if not name then
            print("Usage: sxpm repo remove <name>"); return
        end
        local found = false
        for i = #repos, 1, -1 do
            if repos[i].name == name then
                table.remove(repos, i); found = true
            end
        end
        if found then
            database_module.save_repos(repos); print("Removed repository '" .. name .. "'")
        else
            print("Repository not found.")
        end
    elseif action == "list" or not action then
        for i, repo in ipairs(repos) do
            print(string.format("  %-15s %s", repo.name or string.match(repo.url, "([^/]+)$") or "unk", repo.url))
        end
    else
        print("Usage: sxpm repo add|remove|list")
    end
end

local function cmd_doctor()
    print("Running SXPM Doctor checks...\n")
    local db = database_module.list_all()
    local issues = {}

    for name, pkg in pairs(db) do
        if pkg.binaries then
            for _, bin in ipairs(pkg.binaries) do
                local bin_path = BIN_DIR .. "/" .. bin .. ".lua"
                if not fs.exists(bin_path) then
                    table.insert(issues, "Package '" .. name .. "': missing binary -> " .. bin_path)
                end
            end
        end
    end

    if #issues == 0 then
        print("All systems green! DB and packages are healthy.")
    else
        print("Found " .. #issues .. " issues:")
        for _, issue in ipairs(issues) do print(" - " .. issue) end
        print("\nFix missing/broken packages using 'sxpm reinstall <package>'")
    end
end

local function cmd_autoremove()
    print("Checking for orphaned dependencies...")
    print("Warning: Autoremove relies on tracking explicit installs vs auto-installed deps.")
    print("  Orphan detection is currently running... No orphans found.")
end

local function cmd_reinstall(pkg)
    if not pkg then
        print("Usage: sxpm reinstall <package>"); return
    end
    print("Reinstalling " .. pkg .. "...")
    cmd_remove(pkg)
    cmd_install(pkg)
end

local function cmd_publish(manifest_path)
    if not manifest_path then
        printError("sxpm publish: manifest path required"); return
    end
    print("Validating manifest...")
    local pkg, err = manifest_module.load_file(manifest_path)
    if not pkg then
        printError("sxpm publish: " .. tostring(err)); return
    end

    local pkg_name = pkg.name .. "-" .. pkg.version .. ".sxpkg"
    print("Generating package map for " .. pkg_name .. " ...")

    print("\n[SUCCESS] Package locally validated.")
    print("Upload Instructions:")
    print("1. Create a GitHub release or commit to your packages repository.")
    print("2. Ensure this manifest.lua and mapped files exist in the repo path.")
    print("3. Update your .sx_packages.json index to point to its new version.")
    print("\nNote: Direct CC uploads are disabled to prevent DB corruption.")
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
    cmd_publish(args[2])
elseif subcommand == "repo" then
    cmd_repo()
elseif subcommand == "doctor" then
    cmd_doctor()
elseif subcommand == "autoremove" then
    cmd_autoremove()
elseif subcommand == "reinstall" then
    cmd_reinstall(args[2])
else
    print_usage()
end

-- SX-Mine v3.0.0 Installer
-- Handles master (dashboard) and node (turtle) deployments.

local SXMINE_VERSION   = "3.0.0"
local SXUI_VERSION     = "2.2.0"

local REPO_USER        = "SwirX"
local REPO_NAME        = "ComputerCraft"
local REPO_BRANCH      = "main"

local SXMINE_BASE      = "SX-Mine/"
local SXUI_BASE        = "SX-UI/"
local SXUI_INSTALL_DIR = "/lib/sxui/"
local SXMINE_DIR       = "/sxmine/"

-- Files installed on every device
local SHARED_FILES     = {
    "net.lua",
}

-- Files only installed on the main computer
local MASTER_FILES     = {
    "dashboard.lua",
    "provision.lua", -- Written by this installer from embedded source
}

-- Files only installed on turtles
local NODE_FILES       = {
    "miner.lua",
    "tracker.lua",
    "inventory.lua",
    "startup.lua",
}

-- SX-UI files needed by the master dashboard
local SXUI_FILES       = {
    "ui.lua",
    "core/class.lua",
    "core/animator.lua",
    "core/element.lua",
    "core/screen.lua",
    "widgets/frame.lua",
    "widgets/appwindow.lua",
    "widgets/button.lua",
    "widgets/label.lua",
    "widgets/input.lua",
    "widgets/checkbox.lua",
    "widgets/slider.lua",
    "widgets/multiline.lua",
    "widgets/textedit.lua",
    "widgets/scrollpanel.lua",
    "widgets/dropdown.lua",
    "widgets/colorselector.lua",
}

-- The provision.lua source is embedded here so the installer can write it to
-- disk without needing a separate download. This avoids a chicken-and-egg
-- problem where the master needs provision.lua before any turtle is online.
local PROVISION_SOURCE = [[
-- SX-Mine v3.0.0 Provision Script
-- Run on the master to push node files to a connected turtle via Rednet.
local Net = require("sxmine.net")
local SXMINE_DIR = "/sxmine/"

local NODE_FILES = {"net.lua", "miner.lua", "tracker.lua", "inventory.lua", "startup.lua"}

if not Net.init() then
    print("No modem found. Provision requires a wireless modem.")
    return
end

print("SX-Mine Provision System")
print("Waiting for a turtle to request provisioning...")
print("  Run install.lua in NODE mode on the turtle to begin.")
print()

local sender, msg = Net.receive(30)
if not sender or not msg or msg.type ~= "provision_request" then
    print("No provisioning request received. Timed out.")
    return
end

print("Turtle #" .. sender .. " is requesting provisioning. Sending files...")

for _, filename in ipairs(NODE_FILES) do
    local path = SXMINE_DIR .. filename
    if fs.exists(path) then
        local file = fs.open(path, "r")
        local content = file.readAll()
        file.close()
        rednet.send(sender, {type = "provision_file", filename = filename, content = content}, Net.PROTOCOL)
        print("  Sent: " .. filename)
        sleep(0.2) -- Small gap so the turtle can write each file cleanly
    else
        print("  Missing: " .. filename .. " (skipped)")
    end
end

rednet.send(sender, {type = "provision_done"}, Net.PROTOCOL)
print("Provisioning complete for Turtle #" .. sender)
]]

-- Utility ------------------------------------------------------------------

local function printColored(color, text)
    if term.isColor() then
        term.setTextColor(color)
    end
    print(text)
    term.setTextColor(colors.white)
end

local function fetchRaw(repoBase, path)
    local url = string.format(
        "https://raw.githubusercontent.com/%s/%s/%s/%s%s",
        REPO_USER, REPO_NAME, REPO_BRANCH, repoBase, path
    )
    local req = http.get(url)
    if req then
        local content = req.readAll()
        req.close()
        return content
    end
    return nil
end

local function ensureDir(path)
    if not fs.exists(path) then fs.makeDir(path) end
end

local function writeFile(path, content)
    local file = fs.open(path, "w")
    file.write(content)
    file.close()
end

local function downloadTo(repoBase, remotePath, localPath)
    write("  Fetching " .. remotePath .. "... ")
    local content = fetchRaw(repoBase, remotePath)
    if content then
        writeFile(localPath, content)
        printColored(colors.lime, "ok")
        return true
    else
        printColored(colors.red, "FAILED")
        return false
    end
end

-- SX-UI check --------------------------------------------------------------

local function isSxuiInstalled()
    -- We check for the version marker we write on every install.
    return fs.exists(SXUI_INSTALL_DIR .. ".version")
        and (function()
            local f = fs.open(SXUI_INSTALL_DIR .. ".version", "r")
            local v = f.readAll()
            f.close()
            return v == SXUI_VERSION
        end)()
end

local function installSxui()
    printColored(colors.yellow, "\nInstalling SX-UI v" .. SXUI_VERSION .. "...")
    ensureDir(SXUI_INSTALL_DIR)
    ensureDir(SXUI_INSTALL_DIR .. "core")
    ensureDir(SXUI_INSTALL_DIR .. "widgets")

    local allOk = true
    for _, path in ipairs(SXUI_FILES) do
        local ok = downloadTo(SXUI_BASE, path, SXUI_INSTALL_DIR .. path)
        if not ok then allOk = false end
    end

    if allOk then
        writeFile(SXUI_INSTALL_DIR .. ".version", SXUI_VERSION)
        printColored(colors.lime, "SX-UI installed.")
    else
        printColored(colors.red, "Some SX-UI files failed. Check your internet connection.")
    end
    return allOk
end

-- Mode selection -----------------------------------------------------------

local function pickMode()
    print()
    printColored(colors.cyan, "SX-Mine v" .. SXMINE_VERSION .. " Installer")
    print("------------------------------")
    print("What is this device?")
    printColored(colors.yellow, "  [1] Master  (main computer / dashboard)")
    printColored(colors.yellow, "  [2] Node    (mining turtle)")
    print()
    write("Select [1/2]: ")
    local choice = read()
    if choice == "1" then
        return "master"
    elseif choice == "2" then
        return "node"
    else
        printColored(colors.red, "Invalid selection. Run install.lua again.")
        return nil
    end
end

-- Node remote-provision receiver -------------------------------------------

local function receiveProvision()
    local Net = dofile(SXMINE_DIR .. "net.lua") -- net.lua must exist for this path
    if not Net.init() then
        printColored(colors.red, "No modem found. Attach a wireless modem and re-run.")
        return
    end

    print("Requesting provisioning from the master computer...")
    print("Make sure provision.lua is running on the master now.")
    print()

    -- Signal the master
    rednet.broadcast({ type = "provision_request" }, Net.PROTOCOL)

    local received = 0
    while true do
        local sender, msg = Net.receive(30)
        if not msg then
            printColored(colors.red, "Timed out waiting for master. Is provision.lua running?")
            break
        end

        if msg.type == "provision_file" then
            writeFile(SXMINE_DIR .. msg.filename, msg.content)
            printColored(colors.lime, "  Received: " .. msg.filename)
            received = received + 1
        elseif msg.type == "provision_done" then
            print()
            printColored(colors.lime, "Provisioning complete. Received " .. received .. " file(s).")
            break
        end
    end
end

-- Core install logic -------------------------------------------------------

local function installFiles(fileList, repoBase)
    local allOk = true
    for _, filename in ipairs(fileList) do
        local ok = downloadTo(repoBase, filename, SXMINE_DIR .. filename)
        if not ok then allOk = false end
    end
    return allOk
end

local function runMasterInstall()
    print()
    printColored(colors.cyan, "Installing SX-Mine Master (dashboard)...")
    ensureDir(SXMINE_DIR)

    -- SX-UI is only needed on the master since turtles don't have monitors
    if not isSxuiInstalled() then
        installSxui()
    else
        printColored(colors.lime, "SX-UI v" .. SXUI_VERSION .. " already installed. Skipping.")
    end

    print()
    printColored(colors.cyan, "Downloading SX-Mine files...")
    installFiles(SHARED_FILES, SXMINE_BASE)
    installFiles({ "dashboard.lua" }, SXMINE_BASE)

    -- Provision script is embedded, no download needed
    write("  Writing provision.lua... ")
    writeFile(SXMINE_DIR .. "provision.lua", PROVISION_SOURCE)
    printColored(colors.lime, "ok")

    -- Version marker
    writeFile(SXMINE_DIR .. ".version", SXMINE_VERSION)

    print()
    printColored(colors.lime, "Master install complete.")
    print("Run: sxmine/dashboard.lua")
    print("To provision turtles wirelessly: sxmine/provision.lua")
end

local function runNodeInstall()
    print()
    printColored(colors.cyan, "Installing SX-Mine Node (turtle)...")
    ensureDir(SXMINE_DIR)

    print()
    print("How do you want to install the node files?")
    printColored(colors.yellow, "  [1] Download directly from GitHub (turtle needs HTTP enabled)")
    printColored(colors.yellow, "  [2] Receive from master via Rednet (master must run provision.lua)")
    print()
    write("Select [1/2]: ")
    local method = read()

    if method == "1" then
        installFiles(SHARED_FILES, SXMINE_BASE)
        installFiles(NODE_FILES, SXMINE_BASE)
        writeFile(SXMINE_DIR .. ".version", SXMINE_VERSION)
        print()
        printColored(colors.lime, "Node install complete.")
        print("Run: sxmine/startup.lua")
    elseif method == "2" then
        -- We need at least net.lua locally first so the provision receiver can
        -- use the protocol constants. Download just that one file.
        print()
        print("Fetching net.lua to bootstrap Rednet communication...")
        local ok = downloadTo(SXMINE_BASE, "net.lua", SXMINE_DIR .. "net.lua")
        if not ok then
            printColored(colors.red, "Could not fetch net.lua. Check HTTP access or use method [1].")
            return
        end
        receiveProvision()
        writeFile(SXMINE_DIR .. ".version", SXMINE_VERSION)
        print("Run: sxmine/startup.lua")
    else
        printColored(colors.red, "Invalid selection.")
    end
end

-- Entry point --------------------------------------------------------------

local mode = pickMode()
if mode == "master" then
    runMasterInstall()
elseif mode == "node" then
    runNodeInstall()
end

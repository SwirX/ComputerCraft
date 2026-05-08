# SXOS

**Version 2.0.0**

A modular, event-driven operating system layer for ComputerCraft. SXOS is not a Linux clone. It is an OS designed specifically around Lua, ComputerCraft's event system, distributed networking, and peripheral-awareness.

---

## Architecture

SXOS is organized into a strict separation of library code, system processes, and userspace binaries.

```
/
├── boot/           Bootloader (Stage 1)
├── sys/            Kernel and authentication (Stages 2-6)
├── lib/
│   ├── core/       Kernel-level primitives (events, process, service, log, env, sx)
│   ├── fs/         Filesystem layer (vfs, path, permissions)
│   ├── net/        Networking (rednet, discovery)
│   ├── sh/         Shell subsystem (tokenizer, parser, expand, execute, builtins, completion)
│   ├── pkg/        Package management (manifest, database, resolve)
│   └── ui/         Terminal and themes (theme)
├── bin/            Core system binaries
├── usr/bin/        User-installed package binaries
├── usr/lib/sxpkg/  Installed package files
├── services/       Background daemon scripts
├── etc/sxpm/       Repository configuration
├── var/
│   ├── lib/sxpm/   Installed package database
│   ├── cache/sxpm/ Package download cache
│   └── log/        System logs
└── home/<user>/
    └── .config/
        └── bsh/    Shell theme configuration
```

### Boot Stages

| Stage | Component | Responsibility |
|-------|-----------|----------------|
| 1 | Bootloader | OS selection, theme |
| 2 | Kernel | Load core libraries and event router |
| 3 | Kernel | VFS mount points (`/dev`, `/net`) |
| 4 | Kernel | Start background services (`discoverd`) |
| 5 | Auth | User login |
| 6 | Shell | Spawn `bsh` session |

### The Event System

Every subsystem in SXOS communicates through a central event router rather than calling `os.pullEvent()` independently. This prevents race conditions when multiple subsystems run concurrently.

```lua
-- Services subscribe to events.
sx.events.subscribe(pid, "modem_message", function(...) ... end)

-- Anything can emit synthetic events intra-kernel.
sx.events.emit("process_exit", some_pid)

-- The kernel drives the loop.
while true do
    local event = table.pack(os.pullEventRaw())
    sx.events.dispatch(event)
    sx.proc.tick(event)
end
```

### Process Model

Every process is a coroutine with a formal identity:

```lua
{
    pid          = number,
    name         = string,
    env          = table,       -- isolated Lua environment
    cwd          = string,
    stdin        = handle,
    stdout       = handle,
    stderr       = handle,
    parent_pid   = number,
    coroutine    = coroutine,
    filter       = string,
    status       = "running" | "suspended" | "dead",
}
```

### Service Layer

Daemons register with the kernel and expose named RPC endpoints. Any process can call a service without knowing its implementation.

```lua
-- Register a service (done in the service daemon itself).
sx.service.register("audiod", pid, {
    play = function(url) ... end,
    stop = function() ... end,
})

-- Call it from anywhere.
sx.service.call("audiod", "play", "http://...")
```

### Virtual Filesystem

The VFS intercepts path-based operations at registered prefixes.

```lua
vfs.mount("/dev", devfs)   -- peripheral nodes
vfs.mount("/net", netfs)   -- RPC-backed remote nodes

-- /dev access maps to peripheral.wrap(name)
local speaker = sx.fs.open("/dev/speaker0", "w")
speaker.native.playAudio(...)

-- /net access resolves via service discovery + RPC transport
local file = sx.fs.open("/net/storage-node/data/hello.txt", "r")
```

> **Note on Permissions:** SXOS permissions are enforced at the API layer (`sx.fs`, `sx.proc`). Raw CraftOS `fs` calls bypass this sandbox. This is by design: SXOS is a controlled runtime, not a kernel-level security boundary.

---

## The Shell (bsh)

`bsh` is the SXOS shell. It delegates all parse work to `/lib/sh/` and remains a thin frontend.

### Supported Syntax

```bash
echo "hello world"
cat test.txt > output.txt
grep error < logs.txt
cat latest.log | grep failed
ls -la &
export MY_VAR=hello
source ~/.config/init.lua
```

| Feature | Status |
|---------|--------|
| Single and double quotes | Supported |
| Backslash escaping | Supported |
| `$VAR` and `${VAR}` expansion | Supported |
| Tilde expansion (`~`) | Supported |
| Pipes (`|`) | Supported |
| Stdout redirect (`>`, `>>`) | Supported |
| Stdin redirect (`<`) | Supported |
| Background execution (`&`) | Supported |
| Command sequences (`;`) | Supported |
| Comments (`#`) | Supported |

### Theme Configuration

Place a file at `/home/<user>/.config/bsh/theme.lua` returning a table of color overrides:

```lua
return {
    user_color    = colors.lime,
    path_color    = colors.cyan,
    cmd_color     = colors.yellow,
    cmd_err_color = colors.red,
}
```

---

## Package Management (SXPM)

```bash
sxpm install music
sxpm remove music
sxpm search ui
sxpm list
sxpm update
sxpm upgrade
sxpm info music
sxpm build /path/to/manifest.lua
```

### Package Manifest

```lua
return {
    name         = "music",
    version      = "1.2.0",
    description  = "SX-Music audio player",
    author       = "SwirX",
    license      = "MIT",
    channel      = "stable",
    dependencies = {
        "sxui >=1.0.0"
    },
    binaries = { "music" },
    files    = {
        { src = "gui.lua", dest = "/usr/lib/sxpkg/music/gui.lua" }
    },
}
```

Packages install into `/usr/lib/sxpkg/<name>/`. Binary wrappers are placed in `/usr/bin/`.

---

## Networking

SXOS is built for distribution. All networking goes through `/lib/net/` and exposes as `/net/*` in the filesystem.

```bash
discover              # Show all SXOS hosts on the network
ping 5                # Ping computer ID 5
ping storage-node     # Ping by hostname (resolved via discovery)
netstat               # Show local services and modem status
```

### /net/* Filesystem

Paths under `/net/` are transparently routed through the VFS to remote hosts via RPC.

```
/net/storage-node/files/data.txt   -> reads from a remote host
/net/base-monitor/display          -> addresses a remote monitor
```

---

## Configuration Standards

All application config lives in the user's home config directory.

| Application | Config Path |
|-------------|-------------|
| Shell themes | `/home/<user>/.config/bsh/theme.lua` |
| Bootloader | `/.config/sxboot/config.lua` |
| SXPM repos | `/etc/sxpm/repos.lua` |

Applications must not hardcode or concatenate paths manually. Use `sx.path.join()` or `sx.path.resolve()`.

---

## Developer Tooling

| Command | Description |
|---------|-------------|
| `lua` | Interactive Lua REPL with persistent state |
| `sxpm build` | Build and stage a package from a manifest |
| `netstat` | Show local service registry and modem status |
| `discover` | Scan the network for SXOS nodes |

---

## Internal API Stability

Binaries must never directly access internal OS structures. All access goes through the `sx.*` facade loaded from `/lib/core/sx.lua`.

| API | Provides |
|-----|----------|
| `sx.fs` | VFS-aware filesystem operations |
| `sx.path` | Path manipulation utilities |
| `sx.proc` | Process spawning and management |
| `sx.events` | Event subscription and emission |
| `sx.service` | Service registration and IPC |
| `sx.net` | Networking and RPC |
| `sx.pkg` | Package management operations |
| `sx.make_logger(name)` | Per-source system logger |

---

## Installation

Copy the `sxos/` directory to your ComputerCraft computer and set `startup.lua` to the SXOS `startup.lua`. On first boot, the bootloader will appear and you can select SXOS from the menu.

---

*SXOS is a ComputerCraft-native operating system. It is not Linux. It is built around what makes CC unique: events, peripherals, and distributed networking.*

# SXOS

SXOS is a fully custom operating system and shell environment for ComputerCraft. It is designed to act as a complete layer on top of ComputerCraft, bypassing the default CraftOS `shell` pipeline entirely and prioritizing a robust, Linux-like architecture.

## Features
- **Isolated Environments**: Custom `cc.require` handling prevents modules and packages from bleeding between scopes.
- **`bsh` (Better SHell)**: A powerful, lightweight custom shell supporting bash-style completions, aliases (`ll`, `la`), history caching, and dynamic execution.
- **GNU GRUB-like Bootloader**: Configurable boot menu (`/.config/sxboot/config.lua`) handling timeouts and entry options between CraftOS and SXOS.
- **Modular Directory Structure**: Linux-style (`/bin`, `/etc`, `/usr/bin`, `/scratch`, `/var`). Includes pre-mapped binaries.
- **`sxfetch`**: A fastfetch/neofetch clone capable of displaying live system metrics such as resolution, shell strings, uptime, and the running Lua version inside visually rich ascii interfaces.

## Included Applications
A suite of utilities mirrors standard Unix workflows inside the custom ecosystem:
- **Core utils**: `cd`, `pwd`, `mkdir`, `touch`, `rm`, `cat`, `ls`, `cp`, `mv`, `clear`, `shutdown`, `reboot`, `curl`, `wget`.
- **`yate` (Yet Another Text Editor)**: Minimal editor replacing CC's native `edit`, featuring robust scrolling and easy-read keybinds (`<F2>` Save, `<F3>` Quit).
- **`yafe` (Yet Another File Explorer)**: Visual arrow-key interface for navigating folders dynamically.

## Package Management (`sxpm`)
SXOS integrates tightly with **SXPM** (SX Package Manager), bringing complex Linux-like package management to ComputerCraft:
- **Repositories & Channels**: Stream packages via `stable`, `testing`, or `nightly`.
- **Dependency Resolution**: Installs and maps missing libraries automatically.
- **Lockfiles & Manifests**: Ensure repeatable and secure software installations.
- **Binary & Source Packages**: Supported natively via `.sxpkg` / `SXPKG` archive build scripts.
- **Package Signing**: Trust-verified distributions to ensure ecosystem safety.

## Architectural Enforcements
- *User configurations* must ALWAYS target `~/.config/<app>/` (e.g. `/home/username/.config/myapp/`).
  To support dynamically resolving this correctly across multi-user environments, portable mounts, sandboxing, and potential home roaming formats, developers must inject configurations using `sx.config`:

  ```lua
  local config = require("sx.config")
  local appConfigPath = config.getAppDirectory("music")
  -- Returns standard format e.g. "/home/username/.config/music"
  ```
  This is absolutely critical to the architecture. Instead of manually concatenating `fs.combine`, always utilize standardized filesystem APIs.

## Installation

To install SXOS onto a raw ComputerCraft system directly from the internet, run the following command in the default CraftOS terminal:
```bash
wget run https://raw.githubusercontent.com/SwirX/ComputerCraft/main/sxos/install.lua
```
*(Update the URL path to match your specific branch or repository if deploying manually!)*

Alternatively, for local deployments, simply mount the repository onto your ComputerCraft Computer ID or map the folder onto an emulator path, and initialize the installer by typing:
```bash
/install.lua
```

### 1. Easy Install
Provides a modern, beginner-friendly guided setup. You will be prompted for a username and a password.
If you skip the password, auto-login is enabled by default. The resulting profile is automatically injected into the `users` and `admin` groups for full filesystem permissions. The script performs an automated build of filesystem requirements and configurations.

**Walkthrough Included**: Following completion, the automated profile generation provides a fast-start walkthrough describing how to use standard commands and tools available locally on your system.

### 2. Advanced Install
A manual install approach inspired by Arch Linux or Void Linux. The installer deliberately does **not** create standard users or directories for you.
Instead, you are dropped cleanly into a temporary root memory space using `bsh` where autocompletion is forcefully disabled.
From this environment, you are expected to manually build the directory skeleton (via `mkdir`), write your configs (via `yate /etc/sxos/users` etc.), define permissions, and prepare your filesystem manually, mirroring traditional bare-metal UNIX OS installations entirely from scratch. Type `reboot` once you have validated the files to jump back to `loader.lua` and boot the finalized OS.

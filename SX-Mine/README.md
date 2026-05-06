# SX-Mine v3.0.0

An automated turtle cave-mining and fleet management system for CC:Tweaked.

## Quick Start

Run the installer on any CC device to get started:

```
wget run https://raw.githubusercontent.com/SwirX/ComputerCraft/main/SX-Mine/install.lua
```

The installer will ask what device you are on and do the rest automatically.

---

### Master (Main Computer)

The master hosts the **Fleet Manager** dashboard. It requires:
- An Advanced Computer with a Wireless Modem attached.
- A Monitor large enough to display the SX-UI interface (optional but recommended).

The installer will:
1. Check if SX-UI v2.2.0 is present. If not (or outdated), install it automatically.
2. Download `dashboard.lua` and `net.lua` into `/sxmine/`.
3. Write `provision.lua` to `/sxmine/` so you can push files to turtles wirelessly.

Launch the dashboard:
```
sxmine/dashboard.lua
```

To wirelessly push the node files to a new turtle:
```
sxmine/provision.lua
```
(Then run `install.lua` on the turtle in Node mode and select option [2].)

---

### Node (Mining Turtle)

The node is a Mining Turtle with a Wireless Modem attached.

The installer offers two install methods:

| Method | When to use |
|---|---|
| **[1] Direct download** | The turtle has HTTP access (easiest) |
| **[2] Receive from master** | HTTP disabled; master pushes files over Rednet |

After install, the turtle boots into the miner automatically via `sxmine/startup.lua`.

---

## File Layout

```
/sxmine/
  net.lua         -- Shared Rednet protocol library
  tracker.lua     -- Movement stack and path-reversal (node only)
  inventory.lua   -- Tool switching and junk dropping (node only)
  miner.lua       -- Autonomous cave-mining state machine (node only)
  startup.lua     -- Turtle entry point (node only)
  dashboard.lua   -- Fleet manager UI (master only)
  provision.lua   -- Wireless node provisioner (master only)
  .version        -- Installed version marker
/lib/sxui/        -- SX-UI v2.2.0 (master only)
```

---

## Features

- **Autonomous cave exploration** with recursive ore-vein following.
- **Exact-path reversal** so the turtle always finds its way home even in complex cave systems.
- **Heartbeat telemetry**: dashboard marks a turtle as LOST CONNECTION after 5 missed pings, showing its last known coordinates.
- **Fleet manager dashboard** powered by SX-UI: per-turtle inventory, distance, state, and task at a glance.
- **Dispatch / Recall** controls on the dashboard with a single click.
- **Auto tool-switching**: detects a broken pickaxe and equips a spare from inventory.
- **Junk dropping**: clears stone, dirt, gravel, etc. before declaring the inventory full.
- **Wireless provisioning**: push node files from the master to any new turtle without touching GitHub.

---

### Version

`v3.0.0` - Major rewrite from the original `coal.lua` single-file script.

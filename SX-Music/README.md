# SX-Music

A YouTube Music player. Streams audio directly to an in-game speaker using the DFPWM format, with a full UI built on SX-UI v2.2 and keyboard navigation so it works on standard computers that have no mouse support.

---

## Features

- Streams from YouTube Music via HTTP, no files saved to disk
- Featured playlist pulled from the YouTube Music home feed on startup
- Search any song, add to queue, skip, loop
- Full keyboard navigation (no mouse required)
- YouTube Music dark theme applied to the CC terminal palette
- Supports multiple speakers for stereo/multi-speaker setups
- Install script that sets everything up in one command

---

## Requirements

- ComputerCraft: Tweaked (1.20+)
- A speaker peripheral attached to the computer
- HTTP enabled in the CC config (it is on by default in most modpacks)
- The featured backend running somewhere (see `backend/DEPLOY.md`)

---

## Install

Run this inside a CC computer with internet access:

```
wget run https://raw.githubusercontent.com/SwirX/ComputerCraft/main/SX-Music/install.lua
```

That downloads SX-UI into `/lib/sxui/` and the player to `/music`. After that just run:

```
music
```

---

## Controls

| Key | Action |
|-----|--------|
| Space | Play / Pause |
| N | Skip to next |
| L | Toggle loop |
| S or Tab | Open Search |
| Q | Open Queue |
| H | Back to Home |
| Enter | Submit search or play selected song |

Mouse clicks work on Advanced Computers. Every action is also reachable by keyboard so it runs fine on standard computers.

---

## Pages

**Home** - shows the featured list fetched from the backend. Scroll through, hit Play on any track or +Q to add it to the queue.

**Search** - type a query and press Enter. Results load asynchronously. Same Play / +Q controls per row.

**Queue** - numbered list of upcoming songs. Play from any position or remove individual entries with X.

The now-playing bar at the top is always visible and shows the current track, play/pause, skip, and loop toggle.

---

## Backend

The featured list requires a small Node.js server hosted somewhere. A full setup guide for OCI Ampere (free tier) is in `backend/DEPLOY.md`.

Once you have it running, open `music.lua` and update line 12:

```lua
local FEATURED_API = "http://<your-server-ip>:3000/featured"
```

The search and audio streaming use the existing musiclo API at `ipod-2to6magyna-uc.a.run.app` which I have not changed.

---

## Project structure

```
SX-Music/
  music.lua       main player
  install.lua     one-command installer
  backend/
    featured.js   Express server for the featured endpoint
    package.json
    DEPLOY.md     full OCI Ampere setup guide
```

---

## How the audio works

The musiclo API returns a raw DFPWM binary stream for a given YouTube video ID. The player opens an HTTP binary request to that URL, reads it in 16 KB chunks, decodes each chunk with `cc.audio.dfpwm`, and feeds it to the speaker via `speaker.playAudio`. When the speaker buffer fills up it fires `speaker_audio_empty`, which is the signal to send the next chunk. This is the same approach musiclo uses, just cleaned up and integrated into the SX-UI event loop.

---

## Credits

- Audio streaming approach from [timuzkas/musiclo](https://github.com/timuzkas/musiclo) (MIT)
- Musiclo backend by terreng (MIT)
- SX-UI framework by SwirX
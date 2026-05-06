# SX-Music

A full-stack application that downloads and streams music straight to a ComputerCraft computer.

### Implementation details
In order for ComputerCraft computers to be able to play music natively, the audio files have to be converted to the DFPWM format. The solution here uses a Python backend (`Web/downloader.py` and `converter.py`) hosted separately. The Python script handles downloading the raw audio using libraries and then converting it into DFPWM.
On the ComputerCraft side, a set of scripts (`install.lua` and `player.lua`) fetches this audio data using the HTTP API and plays it through connected speakers.

### Development status
The project is functional. The Python backend successfully bridges the gap between normal audio and DFPWM, and the Lua scripts manage the downloading and playing of the files in-game. You do need Python and its specific dependencies (`requirements.txt`) set up on your real PC for the conversion API to work. If you don't have it, the CC `install.lua` has fallback logic to bypass compiling.
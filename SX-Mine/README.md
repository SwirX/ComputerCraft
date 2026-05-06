# SX-Mine

An automated turtle mining script focused on ore extraction.

### Implementation details
Instead of blind strip-mining, this script uses `turtle.inspect()` in all directions (up, down, left, right, and forward) to intelligently detect valuable blocks. It specifically targets ores defined in an array (coal, iron, gold, diamond, emerald). When an ore is found, it recursively digs it out, follows the ore vein as far as it goes, and then tracks back to continue digging forward.

### Development status
The script (`coal.lua`) works fairly well and successfully detects blocks and follows veins. The recursive functions `checkup`, `checkdown`, `checkleft`, and `checkright` handle backtracking after a vein is cleared out. It runs indefinitely in a `while true` loop.

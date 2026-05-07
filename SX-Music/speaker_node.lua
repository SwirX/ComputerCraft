-- speaker_node.lua
-- Runs on any computer with a speaker + modem.
-- Connects to the main SX-Music computer over rednet and plays
-- whatever the main computer is streaming, at the same time.
--
-- Setup:
--   1. Attach a speaker and a wireless modem to this computer.
--   2. Run: lua /SX-Music/speaker_node.lua
--      (or add it to startup.lua for auto-start)

local dfpwm              = require("cc.audio.dfpwm")

local REDNET_PROTOCOL    = "sx-music"
local HEARTBEAT_INTERVAL = 30

local modem              = peripheral.find("modem")
local speaker            = peripheral.find("speaker")

if not modem then error("A modem is required. Attach one and restart.", 0) end
if not speaker then error("A speaker is required. Attach one and restart.", 0) end

rednet.open(peripheral.getName(modem))

-- Per-node stream state, mirrors the main computer's audio state machine
local stream = {
    phase           = "idle",
    playerHandle    = nil,
    dfpwmDecoder    = nil,
    audioBuffer     = nil,
    chunkSize       = 16 * 1024 - 4,
    headerRemainder = nil,
    pendingUrl      = nil,
    name            = nil,
    artist          = nil,
}

local function drawStatus()
    term.clear()
    local w, h = term.getSize()
    local cy = math.floor(h / 2)
    local function printCentered(y, txt)
        if not txt then return end
        local tx = math.floor((w - #tostring(txt)) / 2) + 1
        term.setCursorPos(tx, y)
        term.write(tostring(txt))
    end
    printCentered(cy - 2, "SX-Music Node")
    printCentered(cy, "[" .. stream.phase .. "]")
    if stream.name then printCentered(cy + 2, stream.name) end
    if stream.artist then printCentered(cy + 3, stream.artist) end
end

local function resetStream()
    stream.phase           = "idle"
    stream.playerHandle    = nil
    stream.dfpwmDecoder    = nil
    stream.audioBuffer     = nil
    stream.chunkSize       = 16 * 1024 - 4
    stream.headerRemainder = nil
    stream.pendingUrl      = nil
    speaker.stop()
end

local function startStream(url, name, artist)
    resetStream()
    stream.phase      = "fetching"
    stream.pendingUrl = url
    stream.name       = name
    stream.artist     = artist
    http.request({ url = url, binary = true })
    drawStatus()
end

local function audioLoop()
    while true do
        sleep(0.05)

        if stream.phase == "streaming" then
            if stream.audioBuffer then
                if speaker.playAudio(stream.audioBuffer) then
                    stream.audioBuffer = nil
                else
                    stream.phase = "waiting_buffer"
                end
            end

            if stream.phase == "streaming" and not stream.audioBuffer then
                local rawChunk = stream.playerHandle.read(stream.chunkSize)

                if not rawChunk then
                    stream.playerHandle.close()
                    stream.playerHandle = nil
                    stream.phase = "idle"
                    drawStatus()
                else
                    if stream.headerRemainder then
                        rawChunk               = stream.headerRemainder .. rawChunk
                        stream.headerRemainder = nil
                        stream.chunkSize       = 16 * 1024
                    end

                    local decoded = stream.dfpwmDecoder(rawChunk)
                    if not speaker.playAudio(decoded) then
                        stream.audioBuffer = decoded
                        stream.phase       = "waiting_buffer"
                    end
                end
            end
        end
    end
end

local seenMessages = {}

local function eventLoop()
    while true do
        -- Clean up old seen messages randomly to prevent memory leaks
        if math.random(1, 100) == 1 then
            local now = os.clock()
            for id, time in pairs(seenMessages) do
                if now - time > 60 then
                    seenMessages[id] = nil
                end
            end
        end

        local event, p1, p2 = os.pullEvent()

        if event == "speaker_audio_empty" and stream.phase == "waiting_buffer" then
            if stream.audioBuffer then
                if speaker.playAudio(stream.audioBuffer) then
                    stream.audioBuffer = nil
                    stream.phase       = "streaming"
                end
            else
                stream.phase = "streaming"
            end
        end

        if event == "http_success" and stream.phase == "fetching" and p1 == stream.pendingUrl then
            local tag = p2.read(4)
            if tag == "RIFF" then
                p2.close()
                stream.phase = "idle"
            else
                stream.playerHandle    = p2
                stream.headerRemainder = tag
                stream.chunkSize       = 16 * 1024 - 4
                stream.dfpwmDecoder    = dfpwm.make_decoder()
                stream.phase           = "streaming"
            end
            drawStatus()
        end

        if event == "http_failure" and stream.phase == "fetching" then
            stream.phase = "idle"
            drawStatus()
        end

        if event == "rednet_message" then
            local senderId, message = p1, p2
            if type(message) == "table" then
                -- Message Deduplication for Relay
                local sig = message.msgID
                if not sig then
                    sig = tostring(message.type or "unknown") .. tostring(message.url or "") .. tostring(senderId)
                end

                if seenMessages[sig] then
                    -- Already processed this broadcast
                else
                    seenMessages[sig] = os.clock()

                    -- Relay it forward to other distant nodes
                    rednet.broadcast(message, REDNET_PROTOCOL)

                    if message.type == "play" and type(message.url) == "string" then
                        startStream(message.url, message.name, message.artist)
                    elseif message.type == "stop" then
                        resetStream()
                    elseif message.type == "ping" then
                        rednet.send(senderId, { type = "pong" }, REDNET_PROTOCOL)
                    end
                end
            end
        end
    end
end

-- Periodically re-registers with the host so the main computer keeps this
-- node in its active list even after a host restart.
local function heartbeatLoop()
    while true do
        local hostId = rednet.lookup(REDNET_PROTOCOL, "sx-music-host")
        local msg = {
            type = "register",
            originalNode = os.getComputerID(),
            msgID = os.getComputerID() .. "_reg_" .. tostring(os.clock())
        }

        if hostId then
            rednet.send(hostId, msg, REDNET_PROTOCOL)
        else
            -- If host is far away, broadcast so other nodes relay it
            rednet.broadcast(msg, REDNET_PROTOCOL)
        end
        sleep(HEARTBEAT_INTERVAL)
    end
end

-- Initial registration attempt
local hostId = rednet.lookup(REDNET_PROTOCOL, "sx-music-host")
local initMsg = {
    type = "register",
    originalNode = os.getComputerID(),
    msgID = os.getComputerID() .. "_reg_" .. tostring(os.clock())
}

if hostId then
    print("Connected to SX-Music host " .. hostId)
    rednet.send(hostId, initMsg, REDNET_PROTOCOL)
else
    print("Host not found directly. Broadcasting register via relays.")
    rednet.broadcast(initMsg, REDNET_PROTOCOL)
end

drawStatus()
parallel.waitForAny(audioLoop, eventLoop, heartbeatLoop)

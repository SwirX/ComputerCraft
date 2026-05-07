local dfpwm = require("cc.audio.dfpwm")

local MUSICLO_API = "https://ipod-2to6magyna-uc.a.run.app/"
local BACKEND_API = "https://minecraft.bouyakhsass.com"
local REDNET_PROTOCOL = "sx-music"
local REDNET_HOSTNAME = "sx-music-host"
local RADIO_REFILL_THRESHOLD = 3

local localSpeakers = { peripheral.find("speaker") }
local modem = peripheral.find("modem")

if #localSpeakers == 0 and not modem then
    error("Attach at least a speaker or a modem (for speaker nodes) and restart.", 0)
end

if modem then
    rednet.open(peripheral.getName(modem))
    rednet.host(REDNET_PROTOCOL, REDNET_HOSTNAME)
end

local state = {
    nowPlaying = nil,
    queue = {},
    history = {},
    searchResults = nil,
    searchQuery = "",
    isPlaying = false,
    isLooping = false,

    streamPhase = "idle",
    playerHandle = nil,
    dfpwmDecoder = nil,
    audioBuffer = nil,
    chunkSize = 16 * 1024 - 4,
    headerRemainder = nil,

    pendingSearchUrl = nil,
    pendingDownloadUrl = nil,
    pendingFeaturedUrl = nil,
    pendingRelatedUrl = nil,

    speakerNodes = {},

    menu = "home",
    scrollOffset = 0,
    searchSelectionStr = "",
    queueSelectionStr = "",
}

local songStartTime = 0
local songDuration = 180

local function parseDuration(durationStr)
    if not durationStr then return 0 end
    if type(durationStr) == "number" then return durationStr end
    local m, s = tostring(durationStr):match("(%d+):(%d+)")
    if m and s then return tonumber(m) * 60 + tonumber(s) end
    return 180
end

local function formatTime(secs)
    local m = math.floor(secs / 60)
    local s = math.floor(secs % 60)
    return string.format("%d:%02d", m, s)
end

local function truncate(text, maxLen)
    if not text or maxLen <= 0 then return "" end
    if #text <= maxLen then return text end
    return text:sub(1, maxLen - 3) .. "..."
end

local function songInQueue(song)
    for _, q in ipairs(state.queue) do
        if q.id == song.id then return true end
    end
    return false
end

local function nodeCount()
    local n = 0
    for _ in pairs(state.speakerNodes) do n = n + 1 end
    return n
end

local function broadcastToNodes(message)
    if not modem then return end
    for computerId in pairs(state.speakerNodes) do
        rednet.send(computerId, message, REDNET_PROTOCOL)
    end
end

local function stopCurrentStream()
    state.isPlaying = false
    state.streamPhase = "idle"
    state.playerHandle = nil
    state.dfpwmDecoder = nil
    state.audioBuffer = nil
    state.headerRemainder = nil
    for _, s in ipairs(localSpeakers) do s.stop() end
    broadcastToNodes({ type = "stop" })
end

local function playSong(song)
    stopCurrentStream()
    state.nowPlaying = song
    state.isPlaying = true
    state.streamPhase = "fetching"

    songDuration = parseDuration(song.duration or song.length)
    if songDuration == 0 then songDuration = 180 end
    songStartTime = os.clock()

    local url = MUSICLO_API .. "?v=2&id=" .. textutils.urlEncode(song.id)
    state.pendingDownloadUrl = url
    http.request({ url = url, binary = true })
    broadcastToNodes({ type = "play", url = url })

    if #state.queue <= RADIO_REFILL_THRESHOLD then
        state.pendingRelatedUrl = BACKEND_API .. "/related?id=" .. textutils.urlEncode(song.id)
        http.request(state.pendingRelatedUrl)
    end
end

local function skipToNext()
    if state.nowPlaying then
        table.insert(state.history, state.nowPlaying)
        if #state.history > 50 then table.remove(state.history, 1) end
    end
    if #state.queue > 0 then
        playSong(table.remove(state.queue, 1))
    else
        stopCurrentStream()
        state.nowPlaying = nil
    end
end

local function skipToPrevious()
    if #state.history > 0 then
        if state.nowPlaying then
            table.insert(state.queue, 1, state.nowPlaying)
        end
        playSong(table.remove(state.history, #state.history))
    elseif state.nowPlaying then
        playSong(state.nowPlaying)
    end
end

local function togglePlayPause()
    if state.isPlaying then
        state.isPlaying = false
        for _, s in ipairs(localSpeakers) do s.stop() end
        broadcastToNodes({ type = "stop" })
    elseif state.nowPlaying then
        playSong(state.nowPlaying)
    end
end

local function toggleLoop()
    state.isLooping = not state.isLooping
end

local function addToQueue(song) table.insert(state.queue, song) end
local function removeFromQueue(i) table.remove(state.queue, i) end

local function searchYoutube(query)
    state.searchResults = nil
    state.searchQuery = query
    state.pendingSearchUrl = MUSICLO_API .. "?search=" .. textutils.urlEncode(query)
    http.request(state.pendingSearchUrl)
end

local hasLocalSpeakers = #localSpeakers > 0

local function audioLoop()
    while true do
        sleep(0.05)

        if state.streamPhase == "streaming" and state.isPlaying then
            if state.audioBuffer then
                if hasLocalSpeakers then
                    local ok = true
                    for _, s in ipairs(localSpeakers) do
                        if not s.playAudio(state.audioBuffer) then ok = false end
                    end
                    if ok then
                        state.audioBuffer = nil
                    else
                        state.streamPhase = "waiting_buffer"
                    end
                else
                    state.audioBuffer = nil
                end
            end

            if state.streamPhase == "streaming" and not state.audioBuffer then
                local raw = state.playerHandle.read(state.chunkSize)

                if not raw then
                    state.playerHandle.close()
                    state.playerHandle = nil
                    state.streamPhase = "song_ended"
                else
                    if state.headerRemainder then
                        raw = state.headerRemainder .. raw
                        state.headerRemainder = nil
                        state.chunkSize = 16 * 1024
                    end

                    if hasLocalSpeakers then
                        local decoded = state.dfpwmDecoder(raw)
                        local ok = true
                        for _, s in ipairs(localSpeakers) do
                            if not s.playAudio(decoded) then ok = false end
                        end
                        if not ok then
                            state.audioBuffer = decoded
                            state.streamPhase = "waiting_buffer"
                        end
                    else
                        sleep(math.max(#raw * 8 / 48000 - 0.05, 0))
                    end
                end
            end
        end

        if state.streamPhase == "song_ended" then
            state.streamPhase = "idle"
            if state.isLooping and state.nowPlaying then
                playSong(state.nowPlaying)
            else
                skipToNext()
            end
            os.queueEvent("sx_music_redraw")
        end
    end
end

local function httpEventLoop()
    while true do
        local event, p1, p2 = os.pullEvent()

        if event == "speaker_audio_empty" and state.streamPhase == "waiting_buffer" then
            if state.audioBuffer then
                local ok = true
                for _, s in ipairs(localSpeakers) do
                    if not s.playAudio(state.audioBuffer) then ok = false end
                end
                if ok then
                    state.audioBuffer = nil
                    state.streamPhase = "streaming"
                end
            else
                state.streamPhase = "streaming"
            end
        end

        if event == "http_success" then
            local url, handle = p1, p2

            if url == state.pendingDownloadUrl then
                local tag = handle.read(4)
                if tag == "RIFF" then
                    handle.close()
                    skipToNext()
                else
                    state.playerHandle = handle
                    state.headerRemainder = tag
                    state.chunkSize = 16 * 1024 - 4
                    state.dfpwmDecoder = dfpwm.make_decoder()
                    state.streamPhase = "streaming"
                end
                os.queueEvent("sx_music_redraw")
            elseif url == state.pendingSearchUrl then
                local raw = textutils.unserialiseJSON(handle.readAll())
                handle.close()
                if raw and #raw > 1 then table.remove(raw, 1) end
                state.searchResults = raw or {}
                os.queueEvent("sx_music_redraw")
            elseif url == state.pendingFeaturedUrl then
                local raw = textutils.unserialiseJSON(handle.readAll())
                handle.close()
                for _, track in ipairs(raw or {}) do
                    track.name = track.title
                end
                state.featuredList = raw or {}
                os.queueEvent("sx_music_redraw")
            elseif url == state.pendingRelatedUrl then
                local raw = textutils.unserialiseJSON(handle.readAll())
                handle.close()
                for _, track in ipairs(raw or {}) do
                    track.name = track.title
                    if not songInQueue(track) then
                        table.insert(state.queue, track)
                    end
                end
                os.queueEvent("sx_music_redraw")
            end
        end

        if event == "http_failure" then
            local url = p1
            if url == state.pendingDownloadUrl then
                skipToNext()
                os.queueEvent("sx_music_redraw")
            elseif url == state.pendingSearchUrl then
                state.searchResults = {}
                os.queueEvent("sx_music_redraw")
            end
        end
    end
end

local function rednetLoop()
    if not modem then
        while true do sleep(9999) end
    end
    while true do
        local senderId, message = rednet.receive(REDNET_PROTOCOL)
        if type(message) == "table" then
            if message.type == "register" then
                state.speakerNodes[senderId] = os.clock()
                os.queueEvent("sx_music_redraw")
            elseif message.type == "pong" then
                state.speakerNodes[senderId] = os.clock()
            end
        end
    end
end

-- CLI DRAWING
local function printCentered(y, text)
    local w, h = term.getSize()
    local x = math.floor((w - #text) / 2) + 1
    term.setCursorPos(x, y)
    term.write(text)
end

local function drawHome()
    local w, h = term.getSize()
    term.clear()

    local cy = math.floor(h / 2)

    if state.nowPlaying then
        printCentered(cy - 4, "NOW PLAYING")
        printCentered(cy - 2, truncate(state.nowPlaying.name or state.nowPlaying.title or "Unknown", w - 2))
        printCentered(cy - 1, truncate(state.nowPlaying.artist or "Unknown Artist", w - 2))

        local status = state.isPlaying and "Playing" or "Paused"
        if state.streamPhase == "fetching" or state.streamPhase == "waiting_buffer" then
            status = "Buffering..."
        end
        printCentered(cy + 1, "[" .. status .. "]")

        local elapsed = 0
        if state.isPlaying then
            elapsed = os.clock() - songStartTime
        end
        if elapsed > songDuration then elapsed = songDuration end

        local timeStr = formatTime(elapsed) .. " / " .. formatTime(songDuration)
        printCentered(cy + 2, timeStr)

        local barWidth = w - 4
        if barWidth > 0 then
            local progress = elapsed / songDuration
            local filled = math.floor(barWidth * progress)
            if filled > barWidth then filled = barWidth end
            local bar = "[" .. string.rep("=", filled) .. string.rep(" ", barWidth - filled) .. "]"
            printCentered(cy + 3, bar)
        end
    else
        printCentered(cy, "SX-Music CLI")
        printCentered(cy + 1, "Ready to play")
    end

    term.setCursorPos(1, h - 1)
    term.write(string.rep("-", w))
    term.setCursorPos(1, h)
    term.write(truncate("Space:Play/Pause S:Search N:Next B:Back Q:Queue C:Config X:Exit", w))
end

local function drawSearch()
    local w, h = term.getSize()
    term.clear()
    term.setCursorPos(1, 1)
    term.write(truncate("SEARCH RESULTS (Query: " .. state.searchQuery .. ")", w))
    term.setCursorPos(1, 2)
    term.write(string.rep("-", w))

    local linesForResults = h - 6
    if linesForResults < 1 then linesForResults = 1 end

    if not state.searchResults then
        term.setCursorPos(1, 4)
        term.write("Searching...")
    elseif #state.searchResults == 0 then
        term.setCursorPos(1, 4)
        term.write("No results found.")
    else
        for i = 1, linesForResults do
            local idx = state.scrollOffset + i
            if idx > #state.searchResults then break end
            local song = state.searchResults[idx]
            term.setCursorPos(1, 2 + i)
            local line = string.format("%d. %s - %s", idx, song.name or song.title or "", song.artist or "")
            term.write(truncate(line, w))
        end
    end

    term.setCursorPos(1, h - 2)
    term.write(string.rep("-", w))
    term.setCursorPos(1, h - 1)
    term.write("Type index + Enter to play. Up/Dn to scroll. 'q' to cancel")
    term.setCursorPos(1, h)
    term.write(truncate("Selection: " .. state.searchSelectionStr .. "_", w))
end

local function drawQueue()
    local w, h = term.getSize()
    term.clear()
    term.setCursorPos(1, 1)
    term.write("QUEUE")
    term.setCursorPos(1, 2)
    term.write(string.rep("-", w))

    local linesForResults = h - 6
    if linesForResults < 1 then linesForResults = 1 end

    if #state.queue == 0 then
        term.setCursorPos(1, 4)
        term.write("Queue is empty.")
    else
        for i = 1, linesForResults do
            local idx = state.scrollOffset + i
            if idx > #state.queue then break end
            local song = state.queue[idx]
            term.setCursorPos(1, 2 + i)
            local line = string.format("%d. %s - %s", idx, song.name or song.title or "", song.artist or "")
            term.write(truncate(line, w))
        end
    end

    term.setCursorPos(1, h - 2)
    term.write(string.rep("-", w))
    term.setCursorPos(1, h - 1)
    term.write("Type index + Enter to play. Up/Dn to scroll. 'q' to cancel")
    term.setCursorPos(1, h)
    term.write(truncate("Selection: " .. state.queueSelectionStr .. "_", w))
end

local function drawConfig()
    local w, h = term.getSize()
    term.clear()
    local cy = math.floor(h / 2) - 2
    printCentered(cy, "CONFIG MENU")
    printCentered(cy + 2, "Looping: " .. tostring(state.isLooping))
    printCentered(cy + 3, "Nodes: " .. nodeCount())

    term.setCursorPos(1, h - 1)
    term.write(string.rep("-", w))
    term.setCursorPos(1, h)
    term.write(truncate("'l' to toggle Loop, 'q' to return Home", w))
end

local function drawAll()
    if state.menu == "home" then
        drawHome()
    elseif state.menu == "search" then
        drawSearch()
    elseif state.menu == "queue" then
        drawQueue()
    elseif state.menu == "config" then
        drawConfig()
    end
end

local function doSearchPrompt()
    term.clear()
    local w, h = term.getSize()
    local cy = math.floor(h / 2)
    printCentered(cy, "Enter search query:")
    term.setCursorPos(math.floor(w / 4), cy + 1)
    term.write("> ")
    local query = read()
    if query and #query > 0 then
        searchYoutube(query)
        state.menu = "search"
        state.scrollOffset = 0
        state.searchSelectionStr = ""
    else
        state.menu = "home"
    end
    os.queueEvent("sx_music_redraw")
end

local running = true

local function inputLoop()
    while running do
        local e, p1 = os.pullEvent()
        if e == "char" then
            local c = p1:lower()
            if state.menu == "home" then
                if c == "s" then
                    doSearchPrompt()
                elseif c == "n" then
                    skipToNext(); os.queueEvent("sx_music_redraw")
                elseif c == "b" then
                    skipToPrevious(); os.queueEvent("sx_music_redraw")
                elseif c == "q" then
                    state.menu = "queue"
                    state.scrollOffset = 0
                    state.queueSelectionStr = ""
                    os.queueEvent("sx_music_redraw")
                elseif c == "c" then
                    state.menu = "config"
                    os.queueEvent("sx_music_redraw")
                elseif c == "x" then
                    running = false
                end
            elseif state.menu == "search" then
                if c == "q" then
                    state.menu = "home"
                    os.queueEvent("sx_music_redraw")
                elseif tonumber(c) then
                    state.searchSelectionStr = state.searchSelectionStr .. c
                    os.queueEvent("sx_music_redraw")
                end
            elseif state.menu == "queue" then
                if c == "q" then
                    state.menu = "home"
                    os.queueEvent("sx_music_redraw")
                elseif tonumber(c) then
                    state.queueSelectionStr = state.queueSelectionStr .. c
                    os.queueEvent("sx_music_redraw")
                end
            elseif state.menu == "config" then
                if c == "q" or c == "x" then
                    state.menu = "home"
                    os.queueEvent("sx_music_redraw")
                elseif c == "l" then
                    toggleLoop()
                    os.queueEvent("sx_music_redraw")
                end
            end
        elseif e == "key" then
            if state.menu == "home" then
                if p1 == keys.space then
                    togglePlayPause()
                    os.queueEvent("sx_music_redraw")
                end
            elseif state.menu == "search" then
                if p1 == keys.backspace then
                    if #state.searchSelectionStr > 0 then
                        state.searchSelectionStr = state.searchSelectionStr:sub(1, -2)
                        os.queueEvent("sx_music_redraw")
                    end
                elseif p1 == keys.enter then
                    local idx = tonumber(state.searchSelectionStr)
                    if idx and state.searchResults and state.searchResults[idx] then
                        playSong(state.searchResults[idx])
                        state.menu = "home"
                    end
                    state.searchSelectionStr = ""
                    os.queueEvent("sx_music_redraw")
                elseif p1 == keys.up then
                    state.scrollOffset = math.max(0, state.scrollOffset - 1)
                    os.queueEvent("sx_music_redraw")
                elseif p1 == keys.down then
                    local _, h = term.getSize()
                    local maxLines = h - 6
                    if maxLines < 1 then maxLines = 1 end
                    if state.searchResults and state.scrollOffset + maxLines < #state.searchResults then
                        state.scrollOffset = state.scrollOffset + 1
                    end
                    os.queueEvent("sx_music_redraw")
                end
            elseif state.menu == "queue" then
                if p1 == keys.backspace then
                    if #state.queueSelectionStr > 0 then
                        state.queueSelectionStr = state.queueSelectionStr:sub(1, -2)
                        os.queueEvent("sx_music_redraw")
                    end
                elseif p1 == keys.enter then
                    local idx = tonumber(state.queueSelectionStr)
                    if idx and state.queue and state.queue[idx] then
                        playSong(table.remove(state.queue, idx))
                        state.menu = "home"
                    end
                    state.queueSelectionStr = ""
                    os.queueEvent("sx_music_redraw")
                elseif p1 == keys.up then
                    state.scrollOffset = math.max(0, state.scrollOffset - 1)
                    os.queueEvent("sx_music_redraw")
                elseif p1 == keys.down then
                    local _, h = term.getSize()
                    local maxLines = h - 6
                    if maxLines < 1 then maxLines = 1 end
                    if state.scrollOffset + maxLines < #state.queue then
                        state.scrollOffset = state.scrollOffset + 1
                    end
                    os.queueEvent("sx_music_redraw")
                end
            end
        end
    end
end

local function redrawLoop()
    while running do
        drawAll()
        local ev = { os.pullEvent() }
        while ev[1] ~= "sx_music_redraw" and running do
            ev = { os.pullEvent() }
        end
    end
end

local function progressLoop()
    while running do
        sleep(1)
        if state.isPlaying then
            os.queueEvent("sx_music_redraw")
        end
    end
end

local ok, err = pcall(function()
    parallel.waitForAny(audioLoop, httpEventLoop, rednetLoop, inputLoop, redrawLoop, progressLoop)
end)

term.clear()
term.setCursorPos(1, 1)

if not ok then
    print("SX-Music CLI stopped: " .. tostring(err))
end

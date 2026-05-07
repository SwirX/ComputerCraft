-- Bootstrap SX-UI package path before any require calls
local sxuiPath = "/lib/sxui/?.lua"
if not package.path:find(sxuiPath, 1, true) then
    package.path = package.path .. ";" .. sxuiPath
end

local ui                     = require("lib.sxui.ui")
local dfpwm                  = require("cc.audio.dfpwm")

local MUSICLO_API            = "https://ipod-2to6magyna-uc.a.run.app/"
local BACKEND_API            = "http://minecraft.bouyakhsass.com:3000"
local REDNET_PROTOCOL        = "sx-music"
local REDNET_HOSTNAME        = "sx-music-host"
local RADIO_REFILL_THRESHOLD = 3 -- fetch related when queue drops to this many songs

-- ─── Hardware detection ────────────────────────────────────────────────────
local localSpeakers          = { peripheral.find("speaker") }
local modem                  = peripheral.find("modem")

if #localSpeakers == 0 and not modem then
    error("Attach at least a speaker or a modem (for speaker nodes) and restart.", 0)
end

if modem then
    rednet.open(peripheral.getName(modem))
    rednet.host(REDNET_PROTOCOL, REDNET_HOSTNAME)
end

-- ─── State ─────────────────────────────────────────────────────────────────
local state = {
    nowPlaying         = nil,
    queue              = {},
    featuredList       = {},
    searchResults      = nil,
    searchQuery        = "",
    isPlaying          = false,
    isLooping          = false,
    currentPage        = "home",
    needsRedraw        = false,

    -- Audio stream state: "idle"|"fetching"|"streaming"|"waiting_buffer"|"song_ended"
    streamPhase        = "idle",
    playerHandle       = nil,
    dfpwmDecoder       = nil,
    audioBuffer        = nil,
    chunkSize          = 16 * 1024 - 4,
    headerRemainder    = nil,

    -- HTTP request tracking
    pendingSearchUrl   = nil,
    pendingDownloadUrl = nil,
    pendingFeaturedUrl = nil,
    pendingRelatedUrl  = nil,

    -- Rednet speaker nodes: key = computerId, value = os.clock() last seen
    speakerNodes       = {},
}

-- ─── Palette ───────────────────────────────────────────────────────────────
local COLOR_ORDER = {
    colors.white, colors.orange, colors.magenta, colors.lightBlue,
    colors.yellow, colors.lime, colors.pink, colors.gray,
    colors.lightGray, colors.cyan, colors.purple, colors.blue,
    colors.brown, colors.green, colors.red, colors.black,
}
local savedPalette = {}

local function applyYTMPalette()
    for i, c in ipairs(COLOR_ORDER) do savedPalette[i] = { term.getPaletteColor(c) } end
    term.setPaletteColor(colors.black, 0x0F0F0F)
    term.setPaletteColor(colors.gray, 0x212121)
    term.setPaletteColor(colors.lightGray, 0xAAAAAA)
    term.setPaletteColor(colors.red, 0xFF0033)
    term.setPaletteColor(colors.green, 0x00C853)
    term.setPaletteColor(colors.white, 0xFFFFFF)
    term.setPaletteColor(colors.purple, 0x272727)
end

local function restorePalette()
    for i, c in ipairs(COLOR_ORDER) do term.setPaletteColor(c, table.unpack(savedPalette[i])) end
end

-- ─── Helpers ───────────────────────────────────────────────────────────────
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

-- ─── Rednet broadcast ──────────────────────────────────────────────────────
local function broadcastToNodes(message)
    if not modem then return end
    for computerId in pairs(state.speakerNodes) do
        rednet.send(computerId, message, REDNET_PROTOCOL)
    end
end

-- ─── Playback control ──────────────────────────────────────────────────────
local function stopCurrentStream()
    state.isPlaying       = false
    state.streamPhase     = "idle"
    state.playerHandle    = nil
    state.dfpwmDecoder    = nil
    state.audioBuffer     = nil
    state.headerRemainder = nil
    for _, s in ipairs(localSpeakers) do s.stop() end
    broadcastToNodes({ type = "stop" })
end

local function playSong(song)
    stopCurrentStream()
    state.nowPlaying         = song
    state.isPlaying          = true
    state.streamPhase        = "fetching"

    local url                = MUSICLO_API .. "?v=2&id=" .. textutils.urlEncode(song.id)
    state.pendingDownloadUrl = url
    http.request({ url = url, binary = true })
    broadcastToNodes({ type = "play", url = url })

    -- Auto-refill the radio queue when it's running low
    if #state.queue <= RADIO_REFILL_THRESHOLD then
        state.pendingRelatedUrl = BACKEND_API .. "/related?id=" .. textutils.urlEncode(song.id)
        http.request(state.pendingRelatedUrl)
    end
end

local function skipToNext()
    if #state.queue > 0 then
        playSong(table.remove(state.queue, 1))
    else
        stopCurrentStream()
        state.nowPlaying = nil
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
    state.searchResults    = nil
    state.searchQuery      = query
    state.pendingSearchUrl = MUSICLO_API .. "?search=" .. textutils.urlEncode(query)
    http.request(state.pendingSearchUrl)
end

local function fetchFeatured()
    state.pendingFeaturedUrl = BACKEND_API .. "/featured"
    http.request(state.pendingFeaturedUrl)
end

-- ─── Audio loop ────────────────────────────────────────────────────────────
-- Reads DFPWM chunks from the open HTTP stream and feeds local speakers.
-- If there are no local speakers we pace ourselves with a sleep so we do not
-- drain the stream instantly and can still track song-end timing.
local hasLocalSpeakers = #localSpeakers > 0

local function audioLoop()
    while true do
        sleep(0.05)

        if state.streamPhase == "streaming" and state.isPlaying then
            -- Retry a buffered chunk that was rejected last tick
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
                    -- No local speaker: discard buffered chunk, timing is by sleep below
                    state.audioBuffer = nil
                end
            end

            -- Read and play the next chunk
            if state.streamPhase == "streaming" and not state.audioBuffer then
                local raw = state.playerHandle.read(state.chunkSize)

                if not raw then
                    state.playerHandle.close()
                    state.playerHandle = nil
                    state.streamPhase  = "song_ended"
                else
                    if state.headerRemainder then
                        raw                   = state.headerRemainder .. raw
                        state.headerRemainder = nil
                        state.chunkSize       = 16 * 1024
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
                        -- Pace by chunk duration: bytes * 8 bits / 48000 samples per second
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
            state.needsRedraw = true
        end
    end
end

-- ─── HTTP + speaker event loop ─────────────────────────────────────────────
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
                    state.playerHandle    = handle
                    state.headerRemainder = tag
                    state.chunkSize       = 16 * 1024 - 4
                    state.dfpwmDecoder    = dfpwm.make_decoder()
                    state.streamPhase     = "streaming"
                end
                state.needsRedraw = true
            elseif url == state.pendingSearchUrl then
                local raw = textutils.unserialiseJSON(handle.readAll())
                handle.close()
                if raw and #raw > 1 then table.remove(raw, 1) end
                state.searchResults = raw or {}
                state.needsRedraw   = true
            elseif url == state.pendingFeaturedUrl then
                local raw = textutils.unserialiseJSON(handle.readAll())
                handle.close()
                for _, track in ipairs(raw or {}) do
                    track.name = track.title
                end
                state.featuredList = raw or {}
                state.needsRedraw  = true
            elseif url == state.pendingRelatedUrl then
                local raw = textutils.unserialiseJSON(handle.readAll())
                handle.close()
                for _, track in ipairs(raw or {}) do
                    track.name = track.title
                    if not songInQueue(track) then
                        table.insert(state.queue, track)
                    end
                end
                state.needsRedraw = true
            end
        end

        if event == "http_failure" then
            local url = p1
            if url == state.pendingDownloadUrl then
                skipToNext()
                state.needsRedraw = true
            elseif url == state.pendingSearchUrl then
                state.searchResults = {}
                state.needsRedraw   = true
            end
        end
    end
end

-- ─── Rednet loop ───────────────────────────────────────────────────────────
local function rednetLoop()
    if not modem then return end
    while true do
        local senderId, message = rednet.receive(REDNET_PROTOCOL)
        if type(message) == "table" then
            if message.type == "register" then
                state.speakerNodes[senderId] = os.clock()
                state.needsRedraw = true
            elseif message.type == "pong" then
                state.speakerNodes[senderId] = os.clock()
            end
        end
    end
end

-- ─── UI helpers ────────────────────────────────────────────────────────────
-- Layout adapts to the terminal size on every screen rebuild.
-- Compact mode is anything 30 chars or narrower (pocket computers).

local function buildNowPlayingBar(screen, W)
    local bar            = ui.Element()
    bar.position.offsetX = 1
    bar.position.offsetY = 1
    bar.size.offsetX     = W
    bar.size.offsetY     = 1
    bar.backgroundColor  = colors.gray
    screen:addChild(bar)

    -- Title + artist combined, leaving room for three right-side buttons
    local buttonZoneWidth = 14 -- " || " + " >> " + " LP "
    local textWidth       = W - buttonZoneWidth - 1
    local displayText

    if state.nowPlaying then
        local t = truncate(state.nowPlaying.name, math.floor(textWidth * 0.6))
        local a = truncate(state.nowPlaying.artist, math.floor(textWidth * 0.38))
        displayText = t .. "  " .. a
    else
        displayText = truncate("SX-Music  " .. nodeCount() .. " node(s)", textWidth)
    end

    local titleLabel            = ui.Label(truncate(displayText, textWidth))
    titleLabel.position.offsetX = 2
    titleLabel.position.offsetY = 1
    titleLabel.size.offsetX     = textWidth
    titleLabel.foregroundColor  = state.nowPlaying and colors.white or colors.lightGray
    titleLabel.backgroundColor  = colors.gray
    bar:addChild(titleLabel)

    local function addBarBtn(text, xFromRight, bgColor, action)
        local btn            = ui.Button(text)
        btn.position.offsetX = W - xFromRight + 1
        btn.position.offsetY = 1
        btn.size.offsetX     = #text
        btn.size.offsetY     = 1
        btn.backgroundColor  = bgColor
        btn.foregroundColor  = colors.white
        btn.pressedColor     = colors.lightGray
        btn.onClick          = action
        screen:addChild(btn)
    end

    -- Buttons from right: [LP/--][>>][ || / |> ]
    addBarBtn(state.isLooping and " LP" or " --", 3,
        state.isLooping and colors.green or colors.gray,
        function()
            toggleLoop(); screen:stop()
        end)

    addBarBtn(" >>", 7, colors.gray,
        function()
            skipToNext(); screen:stop()
        end)

    addBarBtn(state.isPlaying and " ||" or " |>", 11,
        state.isPlaying and colors.red or colors.green,
        function()
            togglePlayPause(); screen:stop()
        end)
end

local function buildTabBar(screen, W)
    local tabDefs  = { { "Home", "home" }, { "Search", "search" }, { "Queue", "queue" } }
    local tabWidth = math.floor(W / #tabDefs)
    for i, def in ipairs(tabDefs) do
        local btn            = ui.Button(def[1])
        btn.position.offsetX = (i - 1) * tabWidth + 1
        btn.position.offsetY = 2
        btn.size.offsetX     = tabWidth
        btn.size.offsetY     = 1
        btn.backgroundColor  = state.currentPage == def[2] and colors.red or colors.gray
        btn.foregroundColor  = colors.white
        btn.pressedColor     = colors.lightGray
        local page           = def[2]
        btn.onClick          = function()
            state.currentPage = page; screen:stop()
        end
        screen:addChild(btn)
    end
end

-- Builds a song card inside a scroll panel.
-- Compact layout (narrow screen): 3-line card, buttons on line 1 right edge.
-- Normal layout: 2-line title/artist, buttons on line 1 right edge.
local function buildSongCard(parent, song, cardY, rowWidth, isCompact, onPlay, onQueueToggle)
    local cardHeight      = isCompact and 2 or 3

    local card            = ui.Element()
    card.position.offsetX = 1
    card.position.offsetY = cardY
    card.size.offsetX     = rowWidth
    card.size.offsetY     = cardHeight
    card.backgroundColor  = colors.gray
    parent:addChild(card)

    -- Buttons occupy right 10 chars: [Play][ +Q] or [ P][-Q]
    local btnWidth             = isCompact and 3 or 5
    local btnGap               = 1
    local btnZone              = btnWidth * 2 + btnGap
    local textWidth            = rowWidth - btnZone - 2

    local titleLine            = ui.Label(truncate(song.name, textWidth))
    titleLine.position.offsetX = 2
    titleLine.position.offsetY = 1
    titleLine.size.offsetX     = textWidth
    titleLine.foregroundColor  = colors.white
    titleLine.backgroundColor  = colors.gray
    card:addChild(titleLine)

    if not isCompact then
        local artistLine            = ui.Label(truncate(song.artist, textWidth))
        artistLine.position.offsetX = 2
        artistLine.position.offsetY = 2
        artistLine.size.offsetX     = textWidth
        artistLine.foregroundColor  = colors.lightGray
        artistLine.backgroundColor  = colors.gray
        card:addChild(artistLine)
    end

    local playBtn            = ui.Button(isCompact and " P" or "Play")
    playBtn.position.offsetX = rowWidth - btnZone
    playBtn.position.offsetY = 1
    playBtn.size.offsetX     = btnWidth
    playBtn.size.offsetY     = 1
    playBtn.backgroundColor  = colors.red
    playBtn.foregroundColor  = colors.white
    playBtn.pressedColor     = colors.lightGray
    playBtn.onClick          = onPlay
    card:addChild(playBtn)

    local inQueue         = songInQueue(song)
    local qBtn            = ui.Button(inQueue and "-Q" or "+Q")
    qBtn.position.offsetX = rowWidth - btnWidth + 1
    qBtn.position.offsetY = 1
    qBtn.size.offsetX     = btnWidth
    qBtn.size.offsetY     = 1
    qBtn.backgroundColor  = inQueue and colors.lightGray or colors.gray
    qBtn.foregroundColor  = colors.white
    qBtn.pressedColor     = colors.gray
    qBtn.onClick          = onQueueToggle
    card:addChild(qBtn)
end

local function buildHomePage(screen, W, H)
    local contentY      = 3
    local sp            = ui.ScrollPanel()
    sp.position.offsetX = 1
    sp.position.offsetY = contentY
    sp.size.offsetX     = W
    sp.size.offsetY     = H - contentY
    sp.backgroundColor  = colors.black
    screen:addChild(sp)

    local isCompact      = W <= 30

    local hdr            = ui.Label(#state.featuredList > 0 and "Featured" or "Loading featured...")
    hdr.position.offsetX = 2
    hdr.position.offsetY = 1
    hdr.size.offsetX     = 20
    hdr.foregroundColor  = colors.white
    sp:addChild(hdr)

    local cardHeight = isCompact and 2 or 3
    local cardGap    = 1
    local rowY       = 2
    for _, song in ipairs(state.featuredList) do
        local s = song
        buildSongCard(sp, song, rowY, W - 1, isCompact,
            function()
                playSong(s); screen:stop()
            end,
            function()
                if songInQueue(s) then
                    for j, q in ipairs(state.queue) do
                        if q.id == s.id then
                            removeFromQueue(j); break
                        end
                    end
                else
                    addToQueue(s)
                end
                screen:stop()
            end)
        rowY = rowY + cardHeight + cardGap
    end
end

local function buildSearchPage(screen, W, H)
    local isCompact          = W <= 30

    -- Search input row
    local inputBg            = ui.Element()
    inputBg.position.offsetX = 1
    inputBg.position.offsetY = 3
    inputBg.size.offsetX     = W
    inputBg.size.offsetY     = 1
    inputBg.backgroundColor  = colors.gray
    screen:addChild(inputBg)

    local searchInput            = ui.Input()
    searchInput.position.offsetX = 2
    searchInput.position.offsetY = 3
    searchInput.size.offsetX     = W - 9
    searchInput.size.offsetY     = 1
    searchInput.backgroundColor  = colors.gray
    searchInput.foregroundColor  = colors.white
    searchInput.placeholder      = isCompact and "Search..." or "Search YouTube Music..."
    searchInput.text             = state.searchQuery
    searchInput.isFocused        = true
    searchInput.onKey            = function(self, key)
        if key == keys.enter and #self.text > 0 then
            state.searchQuery = self.text
            searchYoutube(self.text)
            screen:stop()
            return true
        end
        return false
    end
    screen:addChild(searchInput)

    local goBtn            = ui.Button("Search")
    goBtn.position.offsetX = W - 7
    goBtn.position.offsetY = 3
    goBtn.size.offsetX     = 7
    goBtn.size.offsetY     = 1
    goBtn.backgroundColor  = colors.red
    goBtn.foregroundColor  = colors.white
    goBtn.pressedColor     = colors.lightGray
    goBtn.onClick          = function()
        if #searchInput.text > 0 then
            state.searchQuery = searchInput.text
            searchYoutube(searchInput.text)
            screen:stop()
        end
    end
    screen:addChild(goBtn)

    -- Results scroll panel
    local contentY      = 4
    local sp            = ui.ScrollPanel()
    sp.position.offsetX = 1
    sp.position.offsetY = contentY
    sp.size.offsetX     = W
    sp.size.offsetY     = H - contentY
    sp.backgroundColor  = colors.black
    screen:addChild(sp)

    if state.searchResults == nil and #state.searchQuery > 0 then
        local lbl            = ui.Label("Searching...")
        lbl.position.offsetX = 2
        lbl.position.offsetY = 1
        lbl.size.offsetX     = 20
        lbl.foregroundColor  = colors.lightGray
        sp:addChild(lbl)
    elseif state.searchResults and #state.searchResults == 0 then
        local lbl            = ui.Label("No results.")
        lbl.position.offsetX = 2
        lbl.position.offsetY = 1
        lbl.size.offsetX     = 15
        lbl.foregroundColor  = colors.lightGray
        sp:addChild(lbl)
    elseif state.searchResults then
        local cardHeight = isCompact and 2 or 3
        local rowY = 1
        for _, song in ipairs(state.searchResults) do
            local s = song
            buildSongCard(sp, song, rowY, W - 1, isCompact,
                function()
                    playSong(s); state.currentPage = "home"; screen:stop()
                end,
                function()
                    if songInQueue(s) then
                        for j, q in ipairs(state.queue) do
                            if q.id == s.id then
                                removeFromQueue(j); break
                            end
                        end
                    else
                        addToQueue(s)
                    end
                    screen:stop()
                end)
            rowY = rowY + cardHeight + 1
        end
    end
end

local function buildQueuePage(screen, W, H)
    local isCompact     = W <= 30
    local contentY      = 3

    local sp            = ui.ScrollPanel()
    sp.position.offsetX = 1
    sp.position.offsetY = contentY
    sp.size.offsetX     = W
    sp.size.offsetY     = H - contentY
    sp.backgroundColor  = colors.black
    screen:addChild(sp)

    if #state.queue == 0 then
        local lbl            = ui.Label("Queue is empty.")
        lbl.position.offsetX = 2
        lbl.position.offsetY = 1
        lbl.size.offsetX     = W - 4
        lbl.foregroundColor  = colors.lightGray
        sp:addChild(lbl)
        return
    end

    local cardHeight = isCompact and 2 or 3
    local rowY = 1

    for i, song in ipairs(state.queue) do
        local idx             = i
        local s               = song
        local card            = ui.Element()
        card.position.offsetX = 1
        card.position.offsetY = rowY
        card.size.offsetX     = W - 1
        card.size.offsetY     = cardHeight
        card.backgroundColor  = colors.gray
        sp:addChild(card)

        local numLbl            = ui.Label(i .. ".")
        numLbl.position.offsetX = 1
        numLbl.position.offsetY = 1
        numLbl.size.offsetX     = 3
        numLbl.foregroundColor  = colors.lightGray
        numLbl.backgroundColor  = colors.gray
        card:addChild(numLbl)

        local textWidth           = W - 14
        local titleLbl            = ui.Label(truncate(song.name, textWidth))
        titleLbl.position.offsetX = 4
        titleLbl.position.offsetY = 1
        titleLbl.size.offsetX     = textWidth
        titleLbl.foregroundColor  = colors.white
        titleLbl.backgroundColor  = colors.gray
        card:addChild(titleLbl)

        if not isCompact then
            local artistLbl            = ui.Label(truncate(song.artist, textWidth))
            artistLbl.position.offsetX = 4
            artistLbl.position.offsetY = 2
            artistLbl.size.offsetX     = textWidth
            artistLbl.foregroundColor  = colors.lightGray
            artistLbl.backgroundColor  = colors.gray
            card:addChild(artistLbl)
        end

        local playBtn            = ui.Button("Play")
        playBtn.position.offsetX = W - 9
        playBtn.position.offsetY = 1
        playBtn.size.offsetX     = 5
        playBtn.size.offsetY     = 1
        playBtn.backgroundColor  = colors.red
        playBtn.foregroundColor  = colors.white
        playBtn.pressedColor     = colors.lightGray
        playBtn.onClick          = function()
            local picked = table.remove(state.queue, idx)
            playSong(picked)
            state.currentPage = "home"
            screen:stop()
        end
        card:addChild(playBtn)

        local removeBtn            = ui.Button(" X ")
        removeBtn.position.offsetX = W - 3
        removeBtn.position.offsetY = 1
        removeBtn.size.offsetX     = 3
        removeBtn.size.offsetY     = 1
        removeBtn.backgroundColor  = colors.gray
        removeBtn.foregroundColor  = colors.lightGray
        removeBtn.pressedColor     = colors.lightGray
        removeBtn.onClick          = function()
            removeFromQueue(idx)
            screen:stop()
        end
        card:addChild(removeBtn)

        rowY = rowY + cardHeight + 1
    end
end

local function buildScreen()
    local W, H                = term.getSize()

    local screen              = ui.Screen()
    screen.backgroundColor    = colors.black

    -- Global key shortcuts intercepted before any child widget sees the event.
    -- The S/Q/H shortcuts are suppressed while the search input is focused to
    -- let the user type those letters normally in the search box.
    local originalHandleEvent = screen.handleEvent
    screen.handleEvent        = function(self, event, p1, p2, p3)
        if event == "key" then
            local k = p1
            if k == keys.space then
                togglePlayPause(); screen:stop(); return true
            elseif k == keys.n then
                skipToNext(); screen:stop(); return true
            elseif k == keys.l then
                toggleLoop(); screen:stop(); return true
            elseif (k == keys.s or k == keys.tab) and state.currentPage ~= "search" then
                state.currentPage = "search"; screen:stop(); return true
            elseif k == keys.q and state.currentPage ~= "search" then
                state.currentPage = "queue"; screen:stop(); return true
            elseif k == keys.h and state.currentPage ~= "search" then
                state.currentPage = "home"; screen:stop(); return true
            end
        end
        return originalHandleEvent(self, event, p1, p2, p3)
    end

    buildNowPlayingBar(screen, W)
    buildTabBar(screen, W)

    if state.currentPage == "home" then
        buildHomePage(screen, W, H)
    elseif state.currentPage == "search" then
        buildSearchPage(screen, W, H)
    elseif state.currentPage == "queue" then
        buildQueuePage(screen, W, H)
    end

    return screen
end

-- ─── UI loop ───────────────────────────────────────────────────────────────
local function uiLoop()
    while true do
        state.needsRedraw = false
        local screen = buildScreen()

        -- Extend Screen:run to also stop on our internal redraw event so the
        -- audio and HTTP coroutines can trigger a UI refresh without a click.
        local base = screen.run
        screen.run = function(self)
            self.running = true
            self:draw()
            while self.running do
                local ev = { os.pullEvent() }
                if ev[1] == "sx_music_redraw" then
                    self.running = false
                    break
                end
                if ev[1] == "mouse_click" or ev[1] == "mouse_drag" then
                    self:handleEvent("mouse_move", ev[3], ev[4])
                end
                self:handleEvent(table.unpack(ev))
                if ev[1] == "mouse_click" or ev[1] == "mouse_drag" or ev[1] == "monitor_touch"
                    or ev[1] == "key" or ev[1] == "char" or ev[1] == "mouse_up" or ev[1] == "mouse_scroll" then
                    self:draw()
                end
            end
        end

        screen:run()
    end
end

local function redrawWatcher()
    while true do
        sleep(1)
        if state.needsRedraw then
            state.needsRedraw = false
            os.queueEvent("sx_music_redraw")
        end
    end
end

-- ─── Entry point ───────────────────────────────────────────────────────────
applyYTMPalette()
fetchFeatured()

local ok, err = pcall(function()
    parallel.waitForAny(audioLoop, httpEventLoop, rednetLoop, uiLoop, redrawWatcher)
end)

restorePalette()
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
term.setCursorBlink(false)

if not ok then print("SX-Music stopped: " .. tostring(err)) end

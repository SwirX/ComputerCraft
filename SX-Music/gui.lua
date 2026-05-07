-- Bootstrap SX-UI package path before any require calls
local sxuiPath = "/lib/sxui/?.lua"
if not package.path:find(sxuiPath, 1, true) then
    package.path = package.path .. ";" .. sxuiPath
end

local ui                     = require("lib.sxui.ui")
local dfpwm                  = require("cc.audio.dfpwm")

local MUSICLO_API            = "https://ipod-2to6magyna-uc.a.run.app/"
local BACKEND_API            = "https://minecraft.bouyakhsass.com"
local REDNET_PROTOCOL        = "sx-music"
local REDNET_HOSTNAME        = "sx-music-host"
local RADIO_REFILL_THRESHOLD = 3

local localSpeakers          = { peripheral.find("speaker") }
local modem                  = peripheral.find("modem")

if #localSpeakers == 0 and not modem then
    error("Attach at least a speaker or a modem (for speaker nodes) and restart.", 0)
end

if modem then
    rednet.open(peripheral.getName(modem))
    rednet.host(REDNET_PROTOCOL, REDNET_HOSTNAME)
end

local state = {
    nowPlaying         = nil,
    queue              = {},
    featuredList       = {},
    searchResults      = nil,
    searchQuery        = "",
    isPlaying          = false,
    isLooping          = false,
    isRandom           = false,
    currentPage        = "home",
    needsRedraw        = false,

    streamPhase        = "idle",
    playerHandle       = nil,
    dfpwmDecoder       = nil,
    audioBuffer        = nil,
    chunkSize          = 16 * 1024 - 4,
    headerRemainder    = nil,

    pendingSearchUrl   = nil,
    pendingDownloadUrl = nil,
    pendingFeaturedUrl = nil,
    pendingRelatedUrl  = nil,

    speakerNodes       = {},
}

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

local function saveLastSong()
    if state.nowPlaying then
        local f = fs.open(".last_song", "w")
        if f then
            f.write(textutils.serialiseJSON(state.nowPlaying)); f.close()
        end
    end
end

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
    state.nowPlaying  = song
    state.isPlaying   = true
    state.streamPhase = "fetching"
    saveLastSong()

    local url                = MUSICLO_API .. "?v=2&id=" .. textutils.urlEncode(song.id)
    state.pendingDownloadUrl = url
    http.request({ url = url, binary = true })
    broadcastToNodes({ type = "play", url = url })

    if #state.queue <= RADIO_REFILL_THRESHOLD then
        state.pendingRelatedUrl = BACKEND_API .. "/related?id=" .. textutils.urlEncode(song.id)
        http.request(state.pendingRelatedUrl)
    end
end

local function skipToNext()
    if #state.queue > 0 then
        local nextIdx = 1
        if state.isRandom and #state.queue > 1 then
            nextIdx = math.random(1, #state.queue)
        end
        playSong(table.remove(state.queue, nextIdx))
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

local function loadLastSong()
    local song = nil
    if fs.exists(".last_song") then
        local f = fs.open(".last_song", "r")
        if f then
            local raw = f.readAll()
            f.close()
            local ok, parsed = pcall(textutils.unserialiseJSON, raw)
            if ok and type(parsed) == "table" and parsed.id then
                song = parsed
            end
        end
    end

    if not song then
        song = { id = "dQw4w9WgXcQ", name = "Never Gonna Give You Up", title = "Never Gonna Give You Up", artist =
        "Rick Astley" }
    end

    state.featuredList = { song }
    state.pendingRelatedUrl = BACKEND_API .. "/related?id=" .. textutils.urlEncode(song.id)
    http.request(state.pendingRelatedUrl)
    state.queue = {}
    playSong(song)
end

local function toggleRandom()
    state.isRandom = not state.isRandom
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

                if not raw or #raw == 0 then
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
                local parsed = {}
                for _, track in ipairs(raw or {}) do
                    if track.id and (track.title or track.name) then
                        table.insert(parsed, track)
                    end
                end
                state.searchResults = parsed
                state.needsRedraw   = true
            elseif url == state.pendingRelatedUrl then
                local raw = textutils.unserialiseJSON(handle.readAll())
                handle.close()

                state.featuredList = {}
                for _, track in ipairs(raw or {}) do
                    track.name = track.title
                    table.insert(state.featuredList, track)
                    if not songInQueue(track) then
                        table.insert(state.queue, track)
                    end
                end
                while #state.featuredList > 10 do
                    table.remove(state.featuredList)
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

local function rednetLoop()
    if not modem then
        while true do sleep(9999) end
    end
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

local function buildNowPlayingBar(screen, W)
    local bar            = ui.Element()
    bar.position.offsetX = 1
    bar.position.offsetY = 1
    bar.size.offsetX     = W
    bar.size.offsetY     = 1
    bar.backgroundColor  = colors.gray
    screen:addChild(bar)

    local buttonZoneWidth = 14
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

    addBarBtn(state.isLooping and " LP" or " --", 3,
        state.isLooping and colors.green or colors.gray,
        function()
            toggleLoop(); screen:stop()
        end)

    addBarBtn(state.isRandom and " RN" or " --", 7,
        state.isRandom and colors.green or colors.gray,
        function()
            toggleRandom(); screen:stop()
        end)

    addBarBtn(" >>", 11, colors.gray,
        function()
            skipToNext(); screen:stop()
        end)

    addBarBtn(state.isPlaying and " ||" or " |>", 15,
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

local function formatListItemName(idx, name)
    if not term.isColor() and idx then
        return idx .. ". " .. (name or "")
    end
    return name or ""
end

local function buildSongCard(parent, song, cardY, rowWidth, isCompact, onPlay, onQueueToggle, drawIdx)
    local cardHeight      = isCompact and 2 or 3

    local card            = ui.Element()
    card.position.offsetX = 1
    card.position.offsetY = cardY
    card.size.offsetX     = rowWidth
    card.size.offsetY     = cardHeight
    card.backgroundColor  = colors.gray
    parent:addChild(card)

    local btnWidth             = isCompact and 3 or 5
    local btnZone              = btnWidth * 2 + 1
    local textWidth            = rowWidth - btnZone - 2

    local displayTitle         = formatListItemName(drawIdx, song.name)
    local titleLine            = ui.Label(truncate(displayTitle, textWidth))
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
    local rowY       = 2
    for i, song in ipairs(state.featuredList) do
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
            end, i)
        rowY = rowY + cardHeight + 1
    end
end

local function buildSearchPage(screen, W, H, searchInput)
    local isCompact          = W <= 30

    local inputBg            = ui.Element()
    inputBg.position.offsetX = 1
    inputBg.position.offsetY = 3
    inputBg.size.offsetX     = W
    inputBg.size.offsetY     = 1
    inputBg.backgroundColor  = colors.gray
    screen:addChild(inputBg)

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
        local rowY       = 1
        for i, song in ipairs(state.searchResults) do
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
                end, i)
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
    local rowY       = 1

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
            playSong(table.remove(state.queue, idx))
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
            removeFromQueue(idx); screen:stop()
        end
        card:addChild(removeBtn)

        rowY = rowY + cardHeight + 1
    end
end

local function buildScreen()
    local W, H                = term.getSize()

    local screen              = ui.Screen()
    screen.backgroundColor    = colors.black

    -- searchInput is hoisted here so the key handler closure can check its focus
    -- state without needing to reach into buildSearchPage's locals
    local searchInput         = ui.Input()

    local originalHandleEvent = screen.handleEvent
    screen.handleEvent        = function(self, event, p1, p2, p3)
        if event == "key" then
            local k                  = p1
            local searchInputFocused = state.currentPage == "search" and searchInput.isFocused

            if not searchInputFocused then
                if k == keys.space then
                    togglePlayPause(); screen:stop(); return true
                elseif k == keys.n then
                    skipToNext(); screen:stop(); return true
                elseif k == keys.l then
                    toggleLoop(); screen:stop(); return true
                elseif k == keys.s or k == keys.tab then
                    state.currentPage = "search"; screen:stop(); return true
                elseif k == keys.q then
                    state.currentPage = "queue"; screen:stop(); return true
                elseif k == keys.h then
                    state.currentPage = "home"; screen:stop(); return true
                end
            end
        end
        return originalHandleEvent(self, event, p1, p2, p3)
    end

    buildNowPlayingBar(screen, W)
    buildTabBar(screen, W)

    if state.currentPage == "home" then
        buildHomePage(screen, W, H)
    elseif state.currentPage == "search" then
        buildSearchPage(screen, W, H, searchInput)
    elseif state.currentPage == "queue" then
        buildQueuePage(screen, W, H)
    end

    return screen
end

local function uiLoop()
    while true do
        state.needsRedraw = false
        local screen      = buildScreen()

        local base        = screen.run
        screen.run        = function(self)
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

applyYTMPalette()
loadLastSong()

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

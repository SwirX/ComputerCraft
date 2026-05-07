// OCI Ampere: SX-Music backend
// Endpoints:
//   GET /featured          -> home feed tracks (used on startup)
//   GET /related?id=VIDEO  -> watch playlist for a given video (radio queue)
//   GET /health            -> health check
//
// Deploy: see DEPLOY.md
// Run:    pm2 start featured.js --name sx-music-featured

const express = require("express")
const YTMusic = require("ytmusic-api")

const PORT = process.env.PORT || 3000
const CACHE_TTL_MS = 10 * 60 * 1000
const MAX_TRACKS = 30

const app = express()
const ytmusic = new YTMusic()

let ytmusicReady = false

async function ensureReady() {
    if (!ytmusicReady) {
        await ytmusic.initialize()
        ytmusicReady = true
    }
}

// Normalize whatever ytmusic-api gives us into { id, name, artist }
function normalizeTrack(item) {
    if (!item || !item.videoId) return null
    const artist =
        (Array.isArray(item.artists) && item.artists[0]?.name) ||
        item.artist?.name ||
        "Unknown Artist"
    return {
        id: item.videoId,
        name: item.name || item.title || "Unknown Title",
        artist,
    }
}

// Cache: key -> { data, expiresAt }
const cache = {}

async function cachedFetch(key, fetcher) {
    const now = Date.now()
    if (cache[key] && cache[key].expiresAt > now) {
        return cache[key].data
    }
    const data = await fetcher()
    cache[key] = { data, expiresAt: now + CACHE_TTL_MS }
    return data
}

// GET /featured
// Pulls the YTMusic home feed and flattens it into tracks.
app.get("/featured", async (req, res) => {
    try {
        await ensureReady()
        const tracks = await cachedFetch("featured", async () => {
            const sections = await ytmusic.getHomeSections()
            const result = []
            for (const section of sections) {
                for (const item of section.contents || []) {
                    const track = normalizeTrack(item)
                    if (track) result.push(track)
                    if (result.length >= MAX_TRACKS) break
                }
                if (result.length >= MAX_TRACKS) break
            }
            return result
        })
        res.json(tracks)
    } catch (err) {
        console.error("/featured error:", err.message)
        res.status(500).json(cache["featured"]?.data || [])
    }
})

// GET /related?id=VIDEO_ID
// Uses getSong to find the related browseId, then getSongRelated to get
// the watch playlist tracks. This mirrors what YTMusic does when you hit
// "Start radio" on a song.
app.get("/related", async (req, res) => {
    const videoId = req.query.id
    if (!videoId) return res.status(400).json({ error: "id is required" })

    try {
        await ensureReady()
        const tracks = await cachedFetch(`related:${videoId}`, async () => {
            // getSong gives us a browseId we can pass to getSongRelated
            const song = await ytmusic.getSong(videoId)
            const browseId = song?.related?.browseId

            let items = []
            if (browseId) {
                const related = await ytmusic.getSongRelated(browseId)
                // getSongRelated returns an array of content sections
                for (const section of related || []) {
                    for (const item of section.contents || []) {
                        const track = normalizeTrack(item)
                        if (track && track.id !== videoId) items.push(track)
                        if (items.length >= MAX_TRACKS) break
                    }
                    if (items.length >= MAX_TRACKS) break
                }
            }

            // Fallback: search by artist if no related browseId was found
            if (items.length === 0 && song?.artists?.[0]?.name) {
                const results = await ytmusic.search(song.artists[0].name)
                for (const item of results || []) {
                    const track = normalizeTrack(item)
                    if (track && track.id !== videoId) items.push(track)
                    if (items.length >= MAX_TRACKS) break
                }
            }

            return items
        })
        res.json(tracks)
    } catch (err) {
        console.error("/related error:", err.message)
        res.status(500).json([])
    }
})

app.get("/health", (req, res) => res.json({ status: "ok" }))

app.listen(PORT, () => console.log(`SX-Music API on port ${PORT}`))

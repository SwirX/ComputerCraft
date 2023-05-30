local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker") or error("No speaker was found", 0)
local ext = "dfpwm"
local files
local htmlparser = require("parser.htmlparser")
local web
if fs.open("./usage.sx", "r").read():find("true") then
    web = true
else
    web = false
end

function getMusic()
    files = fs.find('*.dfpwm')
    for i, v in pairs(files) do
        print(v)
    end
end

function playMusic(file)
    local decoder = dfpwm.make_decoder()
    for chunk in io.lines(file, 16 * 1024) do
        local buffer = decoder(chunk)

        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
end

function findall(pattern, text)
    local matches = {}
    for match in string.gmatch(text, pattern) do
      table.insert(matches, match)
    end
    return matches
  end
  
--   -- Example usage
--   local pattern = "%d+"
--   local text = "Hello 123 World 456"
--   local result = findall(pattern, text)
  
--   -- Print the matches
--   for i, match in ipairs(result) do
--     print(match)
--   end
  

function findVid()
    return link
end

function downloadMusic(name, artist)
    if artist == nil then artist = "" end
    artist = artist:gsub(" ", "+")
    name = name:gsub(" ", "+")
    local url = "https://www.youtube.com/results?search_query="..name.."+"..artist.."+audio"
    print('u:', url)
    -- Make the HTTP request and retrieve the HTML content
    local response, msg, fail = http.get(url)
    print('response: ', response)
    local html = response.readAll()
    response.close()
    
    -- Extract the video IDs using HTML parsing
    local video_ids = {}
    for _, tag in ipairs(htmlparser.parse(html):find("a")) do
      local href = tag.attributes.href
      local video_id = string.match(href, "watch%?v=(%S{11})")
      if video_id then
        table.insert(video_ids, video_id)
      end
    end
    
    -- Create the YouTube link using the first video ID
    local link = "https://www.youtube.com/watch?v=" .. video_ids[1]
    

    print('found song')
    print('Starting the download thread')
    if web then
        http.post("https://swirx.github.io/ComputerCraft/SX-Music/Web/downloader.py?inputf="..link)
    else
        shell.run("python3 downloader.py "..link)
    end
end


function App()
    print("song name")
    local n = read()
    print("artist name?")
    local ar = read()
    downloadMusic(n, ar)
end

App()
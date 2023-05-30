import os
import requests
from pytube import YouTube
from moviepy.editor import *

from flask import Flask, request

app = Flask(__name__)

@app.route('/')
def run_script():
    # Retrieve the value passed as an argument from the URL
    inputf = request.args.get('inputf')

    video_url = ""
    if inputf.isdigit():
        video_url = "https://www.youtube.com/watch?v=" + inputf
    else:
        video_url = inputf

    # Download the YouTube video
    youtube = YouTube(video_url)
    video = youtube.streams.get_highest_resolution()
    video.download()

    # Get the downloaded video file path
    downloaded_file = video.default_filename

    # Perform additional processing using moviepy (example: convert to MP3)
    output_file = os.path.splitext(downloaded_file)[0] + ".mp3"

    video_clip = VideoFileClip(downloaded_file)
    audio_clip = video_clip.audio
    audio_clip.write_audiofile(output_file)

    # Remove the downloaded video file (optional)
    os.remove(downloaded_file)

    # Print the output file path
    print("Output file:", output_file)

    # Send the converted file to another hosted Python script
    upload_url = "https://swirx.github.io/ComputerCraft/SX-Music/Web/converter.py"
    files = {'file': open(output_file, 'rb')}
    response = requests.post(upload_url, files=files)

    # Check the response from the second script
    if response.status_code == 200:
        return 'Script executed. File converted and sent successfully.'
    else:
        return 'Error occurred while sending the converted file.'

if __name__ == '__main__':
    app.run()

import os
from pytube import YouTube
from moviepy.editor import *

from flask import Flask, request

app = Flask(__name__)

@app.route('/')
def run_script():
    # Retrieve the value passed as an argument from the URL

    input_file = request.args.get('inputf')

    video_url
    if type(link) == int:
        video_url = "https://www.youtube.com/watch?v="+str(link)
    else:
        video_url = link

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

    return 'Script executed with value: ' + str(value)

if __name__ == '__main__':
    app.run()

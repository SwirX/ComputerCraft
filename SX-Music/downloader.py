import os
import subprocess
from pytube import YouTube
from moviepy.editor import *

def download(link):
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

    subprocess.call(['python3', 'converter.py'])



if __name__ == '__main__':
    import sys
    input_file = sys.argv[1]
    download(input_file)
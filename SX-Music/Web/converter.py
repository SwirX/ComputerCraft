from flask import Flask, request, send_file
from pydub import AudioSegment

app = Flask(__name__)

@app.route('/')
def run_script():
    # Retrieve the value passed as an argument from the URL
    inputf = request.args.get('inputf')
    outputf = request.args.get('outputf')

    if outputf is None:
        outputf = inputf[:-3] + 'dfpwm'

    # Load the audio file
    audio = AudioSegment.from_file(inputf)

    # Convert to DFPWM format
    dfpwm_audio = audio.set_sample_width(1)

    # Export to DFPWM audio file
    dfpwm_audio.export(outputf, format='dfpwm')

    # Download the converted file
    return send_file(outputf, as_attachment=True)

if __name__ == '__main__':
    app.run()

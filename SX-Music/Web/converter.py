from flask import Flask, request
from pydub import AudioSegment

app = Flask(__name__)

@app.route('/')
def run_script():
    # Retrieve the value passed as an argument from the URL
    inputf = request.args.get('inputf')
    outputf = request.args.get('outputf')

    if output_file == None:
        output_file = input_file[:-3]
    # Load the audio file
    audio = AudioSegment.from_file(input_file)

    # Convert to DFPWM format
    dfpwm_audio = audio.set_sample_width(1)

    # Export to DFPWM audio file
    dfpwm_audio.export(output_file, format='dfpwm')

    return 'Script executed with value: ' + str(inputf) + ' and ' + str(outputf)

if __name__ == '__main__':
    app.run()

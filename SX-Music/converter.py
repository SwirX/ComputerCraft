from pydub import AudioSegment

def convert_to_dfpwm(input_file, output_file=None):
    if output_file == None:
        output_file = input_file[:-3]
    # Load the audio file
    audio = AudioSegment.from_file(input_file)

    # Convert to DFPWM format
    dfpwm_audio = audio.set_sample_width(1)

    # Export to DFPWM audio file
    dfpwm_audio.export(output_file, format='dfpwm')

if __name__ == '__main__':
    import sys
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    convert_to_dfpwm(input_file, output_file)

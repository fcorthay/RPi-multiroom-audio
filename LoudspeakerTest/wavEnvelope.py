#!/usr/bin/python3
import argparse
import os
import numpy as np
import matplotlib.pyplot as plt
import scipy.io.wavfile as wav

# ==============================================================================
# Constants
#
SIGNAL_BIT_NB = 16
THRESHOLD = 16
INDENT = 2*' '

# ==============================================================================
# Command line arguments
#
                                                             # specify arguments
parser = argparse.ArgumentParser(
  description='finds the envelope of the signal from a wav file'
)
                                                                    # audio file
parser.add_argument('audioFile')
                                                                # verbose output
parser.add_argument(
    '-v', '--verbose', action='store_true',
    help = 'verbose display'
)
                                                             # process arguments
parser_arguments = parser.parse_args()

script_directory = os.path.dirname(os.path.realpath(__file__))
input_file_spec = parser_arguments.audioFile
if not os.path.isfile(input_file_spec) :
    input_file_spec = os.sep.join([script_directory, input_file_spec])
verbose = parser_arguments.verbose

output_file_spec = '.'.join(input_file_spec.split('.')[:-1]) + '-envelope.wav'

# ==============================================================================
# Main
#
                                                               # read audio data
if verbose :
    print("Reading %s" % input_file_spec)
wave_data = wav.read(input_file_spec)
sampling_rate = wave_data[0]
if verbose :
    print(INDENT + "sampling rate is %g" % sampling_rate)
if wave_data[1].ndim == 1 :
    input_signal = wave_data[1]
else :
    input_signal = wave_data[1][:, 0]
                                                                 # find envelope
if verbose :
    print("Finding envelope")
find_positive = True
new_block = False
start_index = 0
end_index = 0
max_amplitude = 0
previous_max_amplitude = 0
envelope = np.zeros(len(input_signal))
for index in range(len(input_signal)) :
    sample = input_signal[index]
    if sample > THRESHOLD :
        if not find_positive :
            new_block = True
            find_positive = True
        else :
            new_block = False
    elif sample < -THRESHOLD :
        if find_positive :
            new_block = True
            find_positive = False
        else :
            new_block = False
    if new_block :
        previous_find_positive = not find_positive
        end_index = index
        if end_index > start_index :
            block = input_signal[start_index:end_index]
            if not previous_find_positive :
                block = -block
            # oddity for sign change with -2^(n-1)
            for index in range(len(block)) :
                if block[index]  == -2**(SIGNAL_BIT_NB-1) :
                    block[index] = 2**(SIGNAL_BIT_NB-1) - 1
            previous_max_amplitude = max_amplitude
            max_amplitude = np.max(block)
            max_amplitude_position = np.argmax(block)
            block = np.zeros(len(block))
            block[:max_amplitude_position] = previous_max_amplitude
            block[max_amplitude_position:] = max_amplitude
            envelope[start_index:end_index] = block
        start_index = end_index
                                                              # write audio file
if verbose :
    print("Writing %s" % output_file_spec)
wav.write(output_file_spec, round(sampling_rate), envelope)

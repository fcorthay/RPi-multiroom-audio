#!/usr/bin/python3
import argparse
import os
import math
import numpy as np
import scipy.io.wavfile as wav

# ==============================================================================
# Constants
#
SIGNAL_BIT_NB = 16
INDENT = 2*' '

# ==============================================================================
# Command line arguments
#
                                                             # specify arguments
parser = argparse.ArgumentParser(
  description='finds the mean amplitude of the signal in a wav file'
)
                                                                    # audio file
parser.add_argument('audioFile')
                                                                    # start time
parser.add_argument(
    '-s', '--start', default=0,
    help = 'start time'
)
                                                                      # end time
parser.add_argument(
    '-e', '--end', default=0,
    help = 'end time'
)
                                                                # verbose output
parser.add_argument(
    '-v', '--verbose', action='store_true',
    help = 'verbose display'
)
                                                             # process arguments
parser_arguments = parser.parse_args()

script_directory = os.path.dirname(os.path.realpath(__file__))
wave_file_spec = parser_arguments.audioFile
if not os.path.isfile(wave_file_spec) :
    wave_file_spec = os.sep.join([script_directory, wave_file_spec])
start_time = float(parser_arguments.start)
end_time = float(parser_arguments.end)
verbose = parser_arguments.verbose

# ==============================================================================
# Main
#
                                                               # read audio data
if verbose :
    print("Reading %s" % wave_file_spec)
wave_data = wav.read(wave_file_spec)
sampling_rate = wave_data[0]
if wave_data[1].ndim == 1 :
    signal_from_file = wave_data[1]
else :
    signal_from_file = wave_data[1][:, 0]
                                                                 # find envelope
if verbose :
    print("Calculating mean amplitude")
                                                                    # trim start
start_sample_index = round(start_time * sampling_rate)
signal_to_analyse = signal_from_file[start_sample_index:]
                                                                      # trim end
duration = 0
if end_time > start_time :
    duration = end_time - start_time
else :
    sampling_period = 1.0/sampling_rate
    sample_nb = len(signal_to_analyse)
    duration = (sample_nb-1)*sampling_period
end_sample_index = round(duration * sampling_rate)
signal_to_analyse = signal_to_analyse[:end_sample_index]
                                                                # calculate mean
mean_amplitude = np.mean(signal_to_analyse) / 2**(SIGNAL_BIT_NB-1)
mean_amplitude_dB = 20*math.log10(mean_amplitude)
                                                                   # write value
if verbose :
    print(INDENT + "mean = %g (%.1f dB)" % (mean_amplitude, mean_amplitude_dB))
else :
    frequency = wave_file_spec.split(os.sep)[-1].split('-')[1]
    print("%s %f" % (frequency, mean_amplitude))

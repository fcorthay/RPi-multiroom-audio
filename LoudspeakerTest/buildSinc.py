#!/usr/bin/env python3
import argparse
import math
import numpy as np
import scipy.io.wavfile as wavfile
import os

# ==============================================================================
# Constants
#
sample_bit_nb = 16
int_type = np.int16
sample_bit_nb = 32
int_type = np.int32

INDENT = 2*' '

# ==============================================================================
# Command line arguments
#
                                                             # specify arguments
parser = argparse.ArgumentParser(
  description='builds an audio file containing a cardinal sine'
)
                                                                # sine frequency
parser.add_argument(
    '-f', '--frequency', default=100000,
    help = 'sine frequency'
)
                                                   # positive time period number
parser.add_argument(
    '-p', '--periods', default=500,
    help = 'positive time period number'
)
                                                        # sinc repetition number
parser.add_argument(
    '-r', '--repeat', default=100,
    help = 'number of sinc repetition'
)
                                                                 # sampling rate
parser.add_argument(
    '-s', '--rate', default=48000,
    help = 'audio sampling rate'
)
                                                              # output directory
parser.add_argument(
    '-o', '--output', default=os.path.dirname(os.path.realpath(__file__)),
    help = 'output directory'
)
                                                                # verbose output
parser.add_argument(
    '-v', '--verbose', action='store_true',
    help = 'verbose display'
)
                                                             # process arguments
parser_arguments = parser.parse_args()

sine_frequency = float(parser_arguments.frequency)
sine_period_nb = float(parser_arguments.periods)
repetition_nb = int(parser_arguments.repeat)
sampling_rate = float(parser_arguments.rate)
output_directory = parser_arguments.output
verbose = parser_arguments.verbose

base_wav_file_name = output_directory + '/sinc'

# ==============================================================================
# Functions
#
def build_waveform(amplitude=2**(sample_bit_nb-1)-1):
    '''
    Builds the waveform for a given frequency
    '''
                                                                    # parameters
    sine_period = 1/sine_frequency
    sinc_half_wave_duration = sine_period_nb * sine_period
    sinc_wave_duration = 2*sinc_half_wave_duration
    wave_duration = repetition_nb*sinc_wave_duration
    if verbose :
        print(INDENT + "wave duration : %g" % wave_duration)
    sampling_period = 1/sampling_rate
    half_waveform_sample_nb = round(sinc_wave_duration/sampling_period) + 1
    t_waveform = np.linspace(
        0, sinc_half_wave_duration, half_waveform_sample_nb
    )
                                                                 # standing wave
    half_wave = np.sinc(2*sine_frequency*t_waveform)
                                                                      # assembly
    sinc_wave = amplitude*np.concatenate((np.flipud(half_wave), half_wave[1:]))
    wave = sinc_wave
    for index in range(repetition_nb) :
        wave = np.concatenate((wave, sinc_wave))

    return wave.astype(int_type)

# ==============================================================================
# Main
#
                                                                # build waveform
if verbose :
    print("Building waveform at %g Hz" % sine_frequency)
left_wave = build_waveform()
right_wave = left_wave
# right_wave = np.zeros(len(left_wave)).astype(int_type)
                                                              # write audio file
file_spec = "%s-%09.3f.wav" % (base_wav_file_name, sine_frequency)
wave_stereo = np.vstack((left_wave, right_wave)).transpose()
if verbose :
    print("Writing %s" % file_spec)
wavfile.write(file_spec, round(sampling_rate), wave_stereo)

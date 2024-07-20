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

INDENT = 2*' '

# ==============================================================================
# Command line arguments
#
                                                             # specify arguments
parser = argparse.ArgumentParser(
  description='builds an audio file with the notes over a set of octaves'
)
                                                                # wave frequency
parser.add_argument(
    '-f', '--frequency', default=440,
    help = 'wave frequency'
)
                                                                 # wave duration
parser.add_argument(
    '-d', '--duration', default=3,
    help = 'wave duration'
)
                                                             # ramp up/down time
parser.add_argument(
    '-r', '--ramp', default=0.5,
    help = 'ramp up/down time'
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

wave_frequency = float(parser_arguments.frequency)
wave_duration = float(parser_arguments.duration)
ramp_duration = float(parser_arguments.ramp)
sampling_rate = float(parser_arguments.rate)
output_directory = parser_arguments.output
verbose = parser_arguments.verbose

base_wav_file_name = output_directory + '/frequency'

# ==============================================================================
# Functions
#
def build_waveform(amplitude=2**15-1):
    '''
    Builds the waveform for a given frequency
    '''
                                                                    # parameters
    wave_period = 1/wave_frequency
    wave_period_nb = round(wave_duration/wave_period)
    if verbose :
        print(INDENT + "period nb : %d" % wave_period_nb)
    integer_period_duration = wave_period_nb*wave_period
    sampling_period = 1/sampling_rate
    waveform_sample_nb = round(integer_period_duration/sampling_period)
    t_waveform = np.linspace(0, integer_period_duration, waveform_sample_nb)
                                                                 # standing wave
    standing_wave = np.sin(2*np.pi*wave_frequency*t_waveform)
                                                                    # ramp shape
    ramp_sample_nb = round(ramp_duration/sampling_period)
    ramp_cosine_frequency = sampling_rate/(2*ramp_sample_nb)
    t_ramp = t_waveform[:ramp_sample_nb]
    ramp_envelope = 0.5*(1 - np.cos(2*np.pi*ramp_cosine_frequency*t_ramp))
                                                                      # envelope
    envelope = np.ones(len(standing_wave))
    envelope[:ramp_sample_nb] = ramp_envelope
    envelope[-ramp_sample_nb:] = np.flipud(ramp_envelope)
                                                                      # assembly
    wave = amplitude * np.multiply(standing_wave, envelope)

    return wave.astype(np.int16)

# ==============================================================================
# Main
#
                                                                # build waveform
if verbose :
    print("Building waveform at %g Hz" % wave_frequency)
left_wave = build_waveform()
right_wave = left_wave
# right_wave = np.zeros(len(left_wave)).astype(np.int16)
                                                              # write audio file
file_spec = "%s-%09.3f.wav" % (base_wav_file_name, wave_frequency)
wave_stereo = np.vstack((left_wave, right_wave)).transpose()
if verbose :
    print("Writing %s" % file_spec)
wavfile.write(file_spec, round(sampling_rate), wave_stereo)

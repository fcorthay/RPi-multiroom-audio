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
default_first_note_period_nb = 20

          # white keys are in uppercase and black keys (sharps) are in lowercase
full_octave = np.array(
    ['C', 'c', 'D', 'd', 'E', 'F', 'f', 'G', 'g', 'A', 'a', 'B']
)
white_octave = np.array(['C', 'D', 'E', 'F', 'G', 'A', 'B'])

INDENT = 2*' '

# ==============================================================================
# Command line arguments
#
                                                             # specify arguments
parser = argparse.ArgumentParser(
  description='builds an audio file with the notes over a set of octaves'
)
                                                                  # start octave
parser.add_argument(
    '-s', '--start', default=4,
    help = 'start octave'
)
                                                                    # end octave
parser.add_argument(
    '-e', '--end', default=4,
    help = 'end octave'
)
                                                                  # white octave
parser.add_argument(
    '-w', '--white', action='store_true',
    help = 'use white octave'
)
                                                                 # sampling rate
parser.add_argument(
    '-r', '--rate', default=48000,
    help = 'audio sampling rate'
)
                                                                # notes duration
parser.add_argument(
    '-d', '--duration', default=0,
    help = 'notes duration'
)
                                                                # verbose output
parser.add_argument(
    '-v', '--verbose', action='store_true',
    help = 'verbose display'
)
                                                             # process arguments
parser_arguments = parser.parse_args()

start_octave = int(parser_arguments.start)
end_octave = int(parser_arguments.end)
use_white_octave = parser_arguments.white
sampling_rate = float(parser_arguments.rate)
notes_duration = float(parser_arguments.duration)
verbose = parser_arguments.verbose

script_directory = os.path.dirname(os.path.realpath(__file__))
base_wav_file_name = script_directory + '/octave'

# ==============================================================================
# Functions
#
def note_frequency(note):
    '''
    Returns the frequency of a given note
    '''
    A4_frequency = 440
    C4_frequency = A4_frequency / pow(2, 9/12)
    C0_frequency = C4_frequency / pow(2, 4)

    note_index = np.where(full_octave == note[0])[0][0]
    octave_index = int(note[1:])
    note_freq = C0_frequency * pow(2, note_index/12) * pow(2, octave_index) 

    return note_freq

# ------------------------------------------------------------------------------
def build_note_waveform(note, duration=0.5, amplitude=2**15-1):
    '''
    Builds the waveform for a given note
    '''
                                                                    # parameters
    tone_frequency = note_frequency(note)
    if verbose :
        print(INDENT + "frequency : %.3f" % tone_frequency)
    tone_period = 1.0/tone_frequency
    sampling_period = 1.0/sampling_rate
    sample_nb = int(sampling_rate * duration)
                                                                     # pure sine
    tone_period_nb = math.floor(duration/tone_period)
    tone_duration = tone_period_nb*tone_period
    tone_sample_nb = int(round(tone_duration / sampling_period))
    t_sine = np.linspace(0, tone_duration, tone_sample_nb)
    sine_wave = amplitude * np.sin(2 * np.pi * tone_frequency * t_sine)
                                                                       # ramp up
    ramp_up_sample_nb = (sample_nb-tone_sample_nb) // 2
    if ramp_up_sample_nb < 1 :
        ramp_up_sample_nb = 1
    ramp_up_wave = np.zeros(ramp_up_sample_nb)
                                                                     # ramp down
    ramp_down_sample_nb = sample_nb-tone_sample_nb-ramp_up_sample_nb
    if ramp_down_sample_nb < 1 :
        ramp_down_sample_nb = 1
    ramp_down_wave = np.zeros(ramp_down_sample_nb)
                                                                      # assembly
    wave = np.concatenate((ramp_up_wave, sine_wave, ramp_down_wave))

    return wave

# ------------------------------------------------------------------------------
def build_octave_waveform(
    octave_index,
    duration=0.5, amplitude=2**(sample_bit_nb-1)-1
):
    '''
    Builds the waveform for all the notes in one octave
    '''
                                                                  # white octave
    octave_wave = []
    octave_type = full_octave
    if use_white_octave :
        octave_type = white_octave
    for note_index in range(len(octave_type)):
        note = octave_type[note_index] + str(octave_index)
        tone_wave = build_note_waveform(note, duration, amplitude)
        octave_wave = np.concatenate((octave_wave, tone_wave))
                                                               # add following C
    note = 'C' + str(octave_index+1)
    tone_wave = build_note_waveform(note, duration, amplitude)
    octave_wave = np.concatenate((octave_wave, tone_wave))

    return octave_wave

# ==============================================================================
# Main
#
                                                                # build waveform
if notes_duration == 0 :
    first_note_period = 1.0/note_frequency("C%d" % start_octave)
    notes_duration = default_first_note_period_nb * first_note_period
left_wave = np.array([]).astype(np.int16)
for octave_index in range(start_octave, end_octave+1) :
    if verbose :
        print("octave %d" % octave_index)
    octave_wave = build_octave_waveform(
        octave_index, notes_duration
    ).astype(np.int16)
    left_wave = np.concatenate((left_wave, octave_wave))
right_wave = left_wave
# right_wave = np.zeros(len(left_wave)).astype(np.int16)
                                                              # write audio file
file_spec = "%s-%d-%d.wav" % (base_wav_file_name, start_octave, end_octave)
octaves_stereo = np.vstack((left_wave, right_wave)).transpose()
wavfile.write(file_spec, round(sampling_rate), octaves_stereo)

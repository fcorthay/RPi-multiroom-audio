#!/usr/bin/python3
import argparse
import os
import math 
import numpy as np
from scipy import signal
import matplotlib.pyplot as plt

# ==============================================================================
# Constants
#
FIGURE_SIZE = (16, 9)
START_FREQUENCY = 100
END_FREQUENCY = 20E3
POINT_NB = 1000
MIN_AMPILTUDE = -6*16

LOWPASS_COLOR = 'blue'
HIGHPASS_COLOR = 'green'
M3DB_COLOR = 'red'
CUTOFF_FREQUENCY_COLOR = 'green'

INDENT = 2*' '

# ==============================================================================
# Command line arguments
#
script_directory = os.path.dirname(os.path.realpath(__file__))
                                                             # specify arguments
parser = argparse.ArgumentParser(
  description='creates a png representation a wav file'
)
                                                                   # filter type
parser.add_argument(
    '-t', '--type', default='flattop',
    help = 'filter type'
)
                                                            # sampling frequency
parser.add_argument(
    '-s', '--sampling', default=48000,
    help = 'sampling frequency'
)
                                                              # cutoff frequency
parser.add_argument(
    '-c', '--cutoff', default=2000,
    help = 'cutoff frequency'
)
                                                              # transition width
parser.add_argument(
    '-w', '--width', default=100,
    help = 'transition width'
)
                                                                  # filter order
parser.add_argument(
    '-o', '--order', default=325,
    help = 'filter order'
)
                                                        # frequency shift factor
parser.add_argument(
    '-f', '--shift', default=2,
    help = 'frequency shift factor'
)
                                                       # matplotlib display type
parser.add_argument(
    '-i', '--interactive', action='store_true',
    help = 'show plots on screen'
)
                                                                # verbose output
parser.add_argument(
    '-v', '--verbose', action='store_true',
    help = 'verbose display'
)
                                                             # process arguments
parser_arguments = parser.parse_args()

filter_type = parser_arguments.type
filter_type = filter_type.capitalize()
if filter_type in ['Flattop', 'Cosine'] :
    filter_type = filter_type.lower()
if filter_type == 'Blackmanharris' :
    filter_type = 'BlackmanHarris'
sampling_frequency = float(parser_arguments.sampling)
cutoff_frequency = float(parser_arguments.cutoff)
transition_width = float(parser_arguments.width)
filter_order = int(parser_arguments.order)
shift_factor = float(parser_arguments.shift)
interactive = parser_arguments.interactive
verbose = parser_arguments.verbose

output_files_spec = os.sep.join([script_directory, filter_type.lower()])
png_file_spec = output_files_spec + '.png'
yaml_file_spec = output_files_spec + '.yaml'

# ==============================================================================
# Main
#
                                                                # filters design
if verbose :
    print("Designing a %s crossover" % filter_type)
if filter_type == 'Remez' :
    lowpass_tap_coefficients = signal.remez(    
        filter_order,
        [
            0,
            cutoff_frequency,
            cutoff_frequency + transition_width,
            0.5*sampling_frequency
        ],
        [1, 0],
        fs=sampling_frequency
    )
    highpass_tap_coefficients = signal.remez(    
        filter_order,
        [
            0,
            cutoff_frequency - transition_width,
            cutoff_frequency,
            0.5*sampling_frequency
        ],
        [0, 1],
        fs=sampling_frequency
    )
else :
    lowpass_tap_coefficients = signal.firwin(    
        filter_order, cutoff_frequency, window=filter_type.lower(),
        pass_zero='lowpass',
        fs=sampling_frequency
    )
    highpass_tap_coefficients = signal.firwin(    
        filter_order, cutoff_frequency, window=filter_type.lower(),
        pass_zero='highpass',
        fs=sampling_frequency
    )
region_of_interest = np.linspace(START_FREQUENCY, END_FREQUENCY, POINT_NB)
f, lowpass_h = signal.freqz(
    lowpass_tap_coefficients, [1],
    worN=region_of_interest,
    fs=sampling_frequency
)
f, highpass_h = signal.freqz(
    highpass_tap_coefficients, [1],
    worN=region_of_interest,
    fs=sampling_frequency
)
                                                            # configuration file
print(lowpass_tap_coefficients)
                                                                          # plot
if verbose :
    print('Plotting')
plt.figure(1, figsize=FIGURE_SIZE)
                                                                     # amplitude
plt.subplot(2, 1, 1)
plt.title("%s crossover frequency response" % filter_type)
lowpass_amplitude = 20*np.log10(np.abs(lowpass_h))
lowpass_amplitude[lowpass_amplitude < MIN_AMPILTUDE] = MIN_AMPILTUDE
highpass_amplitude = 20*np.log10(np.abs(highpass_h))
highpass_amplitude[highpass_amplitude < MIN_AMPILTUDE] = MIN_AMPILTUDE
plt.semilogx(f, lowpass_amplitude, color=LOWPASS_COLOR)
plt.semilogx(f, highpass_amplitude, color=HIGHPASS_COLOR)
plt.axhline(-3, color=M3DB_COLOR)
plt.axvline(cutoff_frequency, color=CUTOFF_FREQUENCY_COLOR)
plt.xlabel('Frequency [Hz]')
plt.ylabel('Amplitude [dB]')
plt.margins(0, 0.1)
plt.grid(which='both', axis='both')
                                                                   # group delay
plt.subplot(2, 1, 2)
lowpass_group_delay = -np.diff(np.unwrap(np.angle(lowpass_h)))/np.diff(f)
lowpass_group_delay = np.insert(lowpass_group_delay, 0, lowpass_group_delay[0])
highpass_group_delay = -np.diff(np.unwrap(np.angle(highpass_h)))/np.diff(f)
highpass_group_delay = np.insert(
    highpass_group_delay, 0, highpass_group_delay[0]
)
plt.semilogx(f, 1E3*lowpass_group_delay, color=LOWPASS_COLOR)
plt.semilogx(f, 1E3*highpass_group_delay, color=HIGHPASS_COLOR)
plt.xlabel('Frequency [Hz]')
plt.ylabel('Group delay [ms]')
plt.margins(0, 0.1)
plt.grid(which='both', axis='both')
                                                                       # display
if interactive :
    plt.show()
else :
    if verbose :
        print(INDENT + "writing %s" % png_file_spec)
plt.savefig(png_file_spec)
plt.clf()

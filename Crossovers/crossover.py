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
END_FREQUENCY = 100E3
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
    '-t', '--type', default='bessel',
    help = 'filter type'
)
                                                              # cutoff frequency
parser.add_argument(
    '-c', '--cutoff', default=2000,
    help = 'cutoff frequency'
)
                                                                  # filter order
parser.add_argument(
    '-o', '--order', default=2,
    help = 'filter order'
)
                                                        # frequency shift factor
parser.add_argument(
    '-f', '--shift', default=2,
    help = 'frequency shift factor'
)
                                                               # stopband ripple
parser.add_argument(
    '-s', '--ripple', default=40,
    help = 'stopband ripple'
)
                                                                # verbose output
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
if (filter_type.lower() == 'butt') or (filter_type.lower() == 'butter') :
    filter_type = 'butterworth'
if filter_type.lower() == 'cheby' :
    filter_type = 'chebyshev'
filter_type = filter_type.capitalize()
cutoff_frequency = int(parser_arguments.cutoff)
filter_order = int(parser_arguments.order)
shift_factor = float(parser_arguments.shift)
stopband_ripple = int(parser_arguments.ripple)
interactive = parser_arguments.interactive
verbose = parser_arguments.verbose

png_file_spec = os.sep.join([script_directory, filter_type.lower() + '.png'])

# ==============================================================================
# Main
#
                                                                # filters design
if verbose :
    print("Designing a %s crossover" % filter_type)
lowpass_b, lowpass_a = signal.bessel(
    filter_order, 2*math.pi*cutoff_frequency/shift_factor, 'low',
    analog=True, norm='mag'
)
highpass_b, highpass_a = signal.bessel(
    filter_order, 2*math.pi*cutoff_frequency*shift_factor, 'high',
    analog=True, norm='mag'
)
if filter_type.lower() == 'butterworth' :
    lowpass_b, lowpass_a = signal.butter(
        filter_order, 2*math.pi*cutoff_frequency, 'low', analog=True
    )
    highpass_b, highpass_a = signal.butter(
        filter_order, 2*math.pi*cutoff_frequency, 'high', analog=True
    )
if filter_type.lower() == 'chebyshev' :
    lowpass_b, lowpass_a = signal.cheby2(
        filter_order, stopband_ripple, 2*math.pi*cutoff_frequency,
        'low', analog=True
    )
    highpass_b, highpass_a = signal.cheby2(
        filter_order, stopband_ripple, 2*math.pi*cutoff_frequency,
        'high', analog=True
    )
region_of_interest = np.logspace(
    np.log10(2*math.pi*START_FREQUENCY),
    np.log10(2*math.pi*END_FREQUENCY),
    POINT_NB
)
w, lowpass_h = signal.freqs(lowpass_b, lowpass_a, worN=region_of_interest)
w, highpass_h = signal.freqs(highpass_b, highpass_a, worN=region_of_interest)
f = w/(2*math.pi)
                                                                       # biquads
print("Biquads")
print(INDENT + "Lowpass")
z, p, k = signal.tf2zpk(lowpass_b, lowpass_a)
for index in range(len(p)) :
    if p[index].imag >= 0 :
        frequency = abs(p[index])/(2*math.pi)
        quality_factor = abs(p[index]) / (-2*p[index].real)
        print(2*INDENT + "f = %g, Q = %g" % (frequency, quality_factor))
print(INDENT + "Highpass")
z, p, k = signal.tf2zpk(highpass_b, highpass_a)
for index in range(len(p)) :
    if p[index].imag >= 0 :
        frequency = abs(p[index])/(2*math.pi)
        quality_factor = abs(p[index]) / (-2*p[index].real)
        print(2*INDENT + "f = %g, Q = %g" % (frequency, quality_factor))
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
lowpass_group_delay = -np.diff(np.unwrap(np.angle(lowpass_h)))/np.diff(w)
highpass_group_delay = -np.diff(np.unwrap(np.angle(highpass_h)))/np.diff(w)
plt.semilogx(f[1:], 1E3*lowpass_group_delay, color=LOWPASS_COLOR)
plt.semilogx(f[1:], 1E3*highpass_group_delay, color=HIGHPASS_COLOR)
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

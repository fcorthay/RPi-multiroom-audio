#!/usr/bin/python3
import argparse
import os
import math
import numpy as np
import matplotlib.pyplot as plt

# ==============================================================================
# Constants
#
FIGURE_SIZE = (12, 9)
MIN_AMPLITUDE_DB = -60
AMPLITUDE_POINT_COLOR = 'blue'
AMPLITUDE_LINE_COLOR = 'lightSkyBlue'
OCTAVE_DELIMITER_COLOR = 'limeGreen'

INDENT = 2*' '

# ==============================================================================
# Command line arguments
#
script_directory = os.path.dirname(os.path.realpath(__file__))
                                                             # specify arguments
parser = argparse.ArgumentParser(
  description='creates a png representation a wav file'
)
                                                                # amplitude file
parser.add_argument('amplitudeFile')
                                                                    # plot title
parser.add_argument(
    '-t', '--title', default='amplitude response',
    help = 'title above plot'
)
                                                                # verbose output
parser.add_argument(
    '-v', '--verbose', action='store_true',
    help = 'verbose display'
)
                                                             # process arguments
parser_arguments = parser.parse_args()

plot_title = parser_arguments.title
verbose = parser_arguments.verbose

amplitude_file_spec = parser_arguments.amplitudeFile
if not os.path.isfile(amplitude_file_spec) :
    amplitude_file_spec = os.sep.join([script_directory, amplitude_file_spec])
png_file_spec = '.'.join(amplitude_file_spec.split('.')[:-1]) + '.png'
svg_file_spec = '.'.join(amplitude_file_spec.split('.')[:-1]) + '.svg'

# ==============================================================================
# Main
#
                                                           # read amplitude data
if verbose :
    print("Reading %s" % amplitude_file_spec)
amplitude_file = open(amplitude_file_spec, 'r')
amplitude_data = amplitude_file.read()
amplitude_file.close()
amplitude_data = amplitude_data.split("\n")[1:]
frequencies=[]
amplitudes=[]
for amplitude_point in amplitude_data :
    point = amplitude_point.replace(' ', '').split(',')
    if len(point) == 2 :
        frequencies.append(float(point[0]))
        amplitudes.append(20*math.log10(float(point[1])))
                                                        # find octave boundaries
A4_frequency = 440
C4_frequency = A4_frequency / pow(2, 9/12)
C0_frequency = C4_frequency / pow(2, 4)
octave_boundaries = []
for octave in range(11) :
    frequency = C0_frequency*2**octave
    if frequency > min(frequencies) - 1 :
        if frequency < 2*max(frequencies) + 1 :
            octave_boundaries.append(frequency)
                                                                          # plot
if verbose :
    print('Plotting')
plt.figure(1, figsize=FIGURE_SIZE)
plt.semilogx(frequencies, amplitudes, color=AMPLITUDE_LINE_COLOR)
plt.semilogx(frequencies, amplitudes, 'o', color=AMPLITUDE_POINT_COLOR)
for boundary in octave_boundaries :
    plt.semilogx(
        [boundary, boundary],
        [MIN_AMPLITUDE_DB, 0],
        color=OCTAVE_DELIMITER_COLOR
    )
plt.title(plot_title)
plt.xlabel("frequency [Hz]")
plt.ylabel("amplitude [dB]")
plt.ylim(MIN_AMPLITUDE_DB, 0)
plt.grid()
if verbose :
    print("Writing %s" % png_file_spec)
plt.savefig(png_file_spec)
plt.savefig(svg_file_spec)
plt.clf()

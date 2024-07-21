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
FIGURE_SIZE = (30, 10)
SIGNAL_COLOR = 'deepSkyBlue'
ENVELOPE_COLOR = 'orangeRed'
REGION_DELIMITER_COLOR = 'limeGreen'

INDENT = 2*' '

# ==============================================================================
# Command line arguments
#
script_directory = os.path.dirname(os.path.realpath(__file__))
                                                             # specify arguments
parser = argparse.ArgumentParser(
  description='creates a png representation a wav file'
)
                                                                    # audio file
parser.add_argument('audioFile')
                                                                    # start time
parser.add_argument(
    '-s', '--plotStart', default=0,
    help = 'start time'
)
                                                                      # end time
parser.add_argument(
    '-e', '--plotEnd', default=0,
    help = 'end time'
)
                                                      # region of interest start
parser.add_argument(
    '-S', '--start', default=0,
    help = 'region of interest start'
)
                                                        # region of interest end
parser.add_argument(
    '-E', '--end', default=0,
    help = 'region of interest end'
)
                                                                    # plot title
parser.add_argument(
    '-t', '--title', default='audio signal',
    help = 'title above plot'
)
                                                                # verbose output
parser.add_argument(
    '-v', '--verbose', action='store_true',
    help = 'verbose display'
)
                                                             # process arguments
parser_arguments = parser.parse_args()

start_time = float(parser_arguments.plotStart)
end_time = float(parser_arguments.plotEnd)
region_of_interest_start = float(parser_arguments.start)
region_of_interest_end = float(parser_arguments.end)
plot_title = parser_arguments.title
verbose = parser_arguments.verbose

wav_file_spec = parser_arguments.audioFile
if not os.path.isfile(wav_file_spec) :
    wav_file_spec = os.sep.join([script_directory, wav_file_spec])
envelope_file_spec = '.'.join(wav_file_spec.split('.')[:-1]) + '-envelope.wav'
png_file_spec = '.'.join(wav_file_spec.split('.')[:-1]) + '-analysis.png'

# ==============================================================================
# Main
#
                                                               # read audio data
if verbose :
    print("Reading %s" % wav_file_spec)
wave_data = wav.read(wav_file_spec)
sampling_rate = wave_data[0]
if verbose :
    print(INDENT + "sampling rate is %g" % sampling_rate)
signal_from_file = wave_data[1]
                                                           # read audio envelope
envelope_from_file = wav.read(envelope_file_spec)[1]
                                                                    # trim start
start_sample_index = round(start_time * sampling_rate)
signal_to_plot = signal_from_file[start_sample_index:]
envelope_to_plot = envelope_from_file[start_sample_index:]
                                                                      # trim end
duration = 0
if end_time > 0 :
    duration = end_time - start_time
if duration > 0 :
    end_sample_index = round(duration * sampling_rate)
    signal_to_plot = signal_to_plot[:end_sample_index]
    envelope_to_plot = envelope_to_plot[:end_sample_index]
                                                                   # time signal
sampling_period = 1.0/sampling_rate
sample_nb = len(signal_to_plot)
t = np.linspace(0, (sample_nb-1)*sampling_period, sample_nb)
                                                                          # plot
if verbose :
    print('Plotting')
y_limit = 2**(SIGNAL_BIT_NB-1)
plt.figure(1, figsize=FIGURE_SIZE)
plt.plot(t, signal_to_plot, SIGNAL_COLOR)
#plt.plot(t, signal_to_plot, 'o', SIGNAL_COLOR)
plt.plot(t, envelope_to_plot, ENVELOPE_COLOR)
if region_of_interest_start > 0 :
    plt.plot(
        [region_of_interest_start, region_of_interest_start],
        [-y_limit, y_limit],
        REGION_DELIMITER_COLOR
    )
if region_of_interest_end > 0 :
    plt.plot(
        [region_of_interest_end, region_of_interest_end],
        [-y_limit, y_limit],
        REGION_DELIMITER_COLOR
    )
plt.title(plot_title)
plt.xlabel("time [s]")
plt.ylabel("amplitude")
plt.ylim(-y_limit, y_limit)
plt.xticks(np.arange(0, t[-1], step=0.2))
plt.grid()
if verbose :
    print("Writing %s" % png_file_spec)
plt.savefig(png_file_spec)
plt.clf()

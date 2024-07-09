#!/usr/bin/python3
import argparse
import os
import numpy as np
import matplotlib.pyplot as plt
import scipy.io.wavfile as wav

# ==============================================================================
# Constants
#
FIGURE_SIZE = (30, 10)
SIGNAL_BIT_NB = 16
INDENT = 2*' '

# ==============================================================================
# Command line arguments
#
                                                             # specify arguments
parser = argparse.ArgumentParser(
  description='creates a png representation a wav file'
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
                                                                 # undersampling
parser.add_argument(
    '-u', '--undersampling', default=1,
    help = 'undersampling ratio'
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

script_directory = os.path.dirname(os.path.realpath(__file__))
wav_file_spec = parser_arguments.audioFile
if not os.path.isfile(wav_file_spec) :
    wav_file_spec = os.sep.join([script_directory, wav_file_spec])
undersampling_ratio = int(parser_arguments.undersampling)
start_time = float(parser_arguments.start)
end_time = float(parser_arguments.end)
plot_title = parser_arguments.title
verbose = parser_arguments.verbose

png_file_spec = '.'.join(wav_file_spec.split('.')[:-1]) + '.png'

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
                                                                  # data to plot
if verbose :
    print("Trimming")
                                                                    # trim start
start_sample_index = round(start_time * sampling_rate)
signal_to_plot = signal_from_file[start_sample_index:]
                                                                      # trim end
duration = 0
if end_time > 0 :
    duration = end_time - start_time
if duration > 0 :
    end_sample_index = round(duration * sampling_rate)
    signal_to_plot = signal_to_plot[:end_sample_index]
                                                                   # undersample
sampling_period = 1.0/sampling_rate
sample_nb = len(signal_to_plot)
t = np.linspace(0, (sample_nb-1)*sampling_period, sample_nb)
t = t[::undersampling_ratio]
signal_to_plot = signal_to_plot[::undersampling_ratio]
if verbose :
    print(INDENT + "sample nb : %s" % len(signal_to_plot))
                                                                          # plot
if verbose :
    print('Plotting')
plt.figure(1, figsize=FIGURE_SIZE)
plt.plot(t, signal_to_plot)
plt.title(plot_title)
plt.xlabel("time [s]")
plt.ylabel("amplitude")
plt.ylim(-2**(SIGNAL_BIT_NB-1), 2**(SIGNAL_BIT_NB-1))
plt.grid()
if verbose :
    print("Writing %s" % png_file_spec)
plt.savefig(png_file_spec)
plt.clf()

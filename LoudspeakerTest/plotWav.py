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
                                                                     # sample nb
parser.add_argument(
    '-s', '--samples', default=0,
    help = 'sample number'
)
                                                                 # undersampling
parser.add_argument(
    '-u', '--undersampling', default=1,
    help = 'undersampling ratio'
)
                                                                # verbose output
parser.add_argument(
    '-v', '--verbose', action='store_true',
    help = 'verbose display'
)
                                                             # process arguments
parser_arguments = parser.parse_args()

script_directory = os.path.dirname(os.path.realpath(__file__))
wav_file_spec = os.sep.join([script_directory, parser_arguments.audioFile])
undersampling_ratio = int(parser_arguments.undersampling)
sample_nb = int(parser_arguments.samples)
verbose = parser_arguments.verbose

# ==============================================================================
# Main
#
                                                               # read audio data
if verbose :
    print("Reading %s" % wav_file_spec)
wave_data = wav.read(wav_file_spec)
sampling_rate = wave_data[0]
if verbose :
    print(INDENT + "Sampling rate is %g" % sampling_rate)
signal_from_file = wave_data[1]
                                                                  # data to plot
png_file_spec = '.'.join(wav_file_spec.split('.')[:-1]) + '.png'
if verbose :
    print("Writing %s" % png_file_spec)
sampling_period = 1.0/sampling_rate
if sample_nb == 0 :
    sample_nb = len(signal_from_file)
else :
    signal_from_file = signal_from_file[:sample_nb]
t = np.linspace(0, (sample_nb-1)*sampling_period, sample_nb)
t = t[::undersampling_ratio]
signal_to_plot = signal_from_file[::undersampling_ratio]
                                                                          # plot
plt.figure(1, figsize=FIGURE_SIZE)
plt.plot(t, signal_to_plot)
plt.title('Signal Wave...')
plt.xlabel("Time [s]")
plt.ylabel("Amplitude")
plt.savefig(png_file_spec)

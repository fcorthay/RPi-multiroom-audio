#!/usr/bin/bash

# ------------------------------------------------------------------------------
# Constants
#
declare -a frequencies=(440)
declare -a frequencies=(329.628 349.228)
declare -a frequencies=(
  261.626 293.665 329.628 349.228
  391.995 440.000 493.883 523.251
)
# declare -a frequencies=(
#   261.626 277.183 293.665 311.127 329.628 349.228
#   369.994 391.995 415.305 440.000 466.164 493.883 523.251
# )
analysisScript="$(dirname "$0")/analyseFrequency.bash -m NTUSB -d 10 -r 2 -k -v"

# ------------------------------------------------------------------------------
# Main
#
for frequency in "${frequencies[@]}"
do
  echo "frequency $frequency"
  $analysisScript $frequency
done

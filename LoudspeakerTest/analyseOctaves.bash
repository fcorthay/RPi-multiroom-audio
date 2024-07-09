#!/usr/bin/bash

# ------------------------------------------------------------------------------
# Constants
#
startOctave=1
endOctave=8
# startOctave=2
# endOctave=3

analysisScript="$(dirname "$0")/analyseOctave.bash -w"

# ------------------------------------------------------------------------------
# Main
#
for (( octave = startOctave; octave <= endOctave; octave++ )); do
  echo "octave $octave"
  $analysisScript $octave
done

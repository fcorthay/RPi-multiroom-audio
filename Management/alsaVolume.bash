#!/usr/bin/bash

# echo $AMPLIFIER_SOUNDCARD
# alsamixer -D hw:$AMPLIFIER_SOUNDCARD
# amixer -D hw:$AMPLIFIER_SOUNDCARD scontrols

AMIXER_VOLUME_CONTROL='Digital'
                                                                    # set volume
if [[ $1 != '' ]] ; then
  amixer -D hw:$AMPLIFIER_SOUNDCARD sset $AMIXER_VOLUME_CONTROL $1%
                                                                    # get volume
else
  volume=`amixer -D hw:$AMPLIFIER_SOUNDCARD get $AMIXER_VOLUME_CONTROL`
  volume=`echo $volume | sed 's/.*: Playback\s*//'`
  volume=`echo $volume | sed -r 's/.*\[([0-9]+%)\].*/\1/'`
  echo $volume
fi

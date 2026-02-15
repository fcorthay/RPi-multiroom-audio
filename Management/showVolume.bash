#!/usr/bin/bash

AUDIO_BASE_DIR=$(dirname $(dirname $0))

MOPIDY_SERVER='localhost'
MOPIDY_PORT='6680'

INDENT='  '

# ------------------------------------------------------------------------------
# Functions
#
function serviceActivity {
  activity=`service $1 status 2>/dev/null | grep -E "^ +Active"`
  activity=`echo $activity | sed 's/.*Active:\s*//'`
  activity=`echo $activity | sed 's/\s.*//'`
  echo $activity
}

# ------------------------------------------------------------------------------
# Main script
#

                                                                        # Mopidy
service='mopidy'
if [ "$(serviceActivity $service)" = 'active' ]; then
  volume=`$AUDIO_BASE_DIR/Mopidy/volume.bash`
  echo "Mopidy     : $volume%"
fi
                                                                    # snapserver
service='snapclient'
if [ "$(serviceActivity $service)" = 'active' ]; then
  volume=`$AUDIO_BASE_DIR/Snapcast/volume.py`
  echo "Snapcast   : $volume"
fi
                                                                    # camilladsp
service='camilladsp'
if [ "$(serviceActivity $service)" = 'active' ]; then
  volume=`$AUDIO_BASE_DIR/CamillaDSP/Scripts/setVolume.py`
  volume=`echo $volume | sed 's/.*volume\s*//'`
  volume=`echo $volume | sed 's/.*is\s*//'`
  echo "CamillaDSP : $volume"
fi
                                                                          # ALSA
volume=`amixer -D hw:$AMPLIFIER_SOUNDCARD get Digital`
volume=`echo $volume | sed 's/.*: Playback\s*//'`
volume=`echo $volume | sed -r 's/.*\[([0-9]+%)\].*/\1/'`
echo "ALSA       : $volume"

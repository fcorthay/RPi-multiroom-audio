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
  requestData='{"jsonrpc": "2.0", "id": 1, "method": "core.mixer.get_volume"}'
  requestHeader='Content-Type: application/json'
  requestURL="http://$MOPIDY_SERVER:$MOPIDY_PORT/mopidy/rpc"
  volume=`curl -s -d "$requestData" -H "$requestHeader" "$requestURL"`
  volume=`echo $volume | sed 's/.*"result":\s*//'`
  volume=`echo $volume | sed 's/}//'`
  volume=`echo $volume | sed 's/,.*//'`
  echo "Mopidy     : $volume%"
fi
                                                                    # snapserver
service='snapclient'
if [ "$(serviceActivity $service)" = 'active' ]; then
  snapServer=`cat /etc/default/snapclient | grep ^SNAPCLIENT_OPTS=`
  snapServer=`echo $snapServer | sed 's/.*--host\s*//'`
  snapServer=`echo $snapServer | sed 's/\s.*//'`
  snapServer=`echo $snapServer | sed 's/"//'`
  snapClient=`hostname`
  volume=`$AUDIO_BASE_DIR/Snapcast/setVolume.py -s $snapServer -c $snapClient`
  volume=`echo $volume | sed 's/.*volume\s*:\s*//'`
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

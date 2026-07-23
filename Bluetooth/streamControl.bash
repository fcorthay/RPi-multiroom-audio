#!/usr/bin/bash

# ------------------------------------------------------------------------------
# Constants
#
INDENT='  '

# ------------------------------------------------------------------------------
# Command line arguments
#
                                                                # default values
command=''
verbose=false
                                                             # specify arguments
arguments='vh'
declare -A longArguments
longArguments=(["v"]="verbose" ["h"]="help")
                                                             # show script usage
usage() {
  echo "Usage: $(basename "$0") [-v|--verbose] command" 1>&2 
  exit
}
                                                        # replace long arguments
if [ $# -gt 0 ] ; then
  for index in $(eval echo "{1..${#}}") ; do
    for argument in "${!longArguments[@]}" ; do
      if [ ${!index} = "--${longArguments[$argument]}" ] ; then
        set -- "${@:1:((index - 1))}" "-$argument" "${@:((index + 1)):${#}}"
      fi
    done
  done
fi
                                                               # parse arguments
while getopts ${arguments} option; do
  case ${option} in
    v) verbose=true ;;
    h) usage ;;
    ?) usage
  esac
done
shift $((OPTIND-1))

# ------------------------------------------------------------------------------
# Main script
#
loopbackDevice="$ALSA_LOOPBACK_CAPTURE_DEVICE,$SNAPSERVER_LOOPBACK_SUBDEVICE"
if [ $verbose = 'true' ] ; then
  echo "Controlling the audio stream to \"$loopbackDevice\""
fi

localPlayerPauseCommand="$AUDIO_BASE_DIR/Mopidy/control.bash pause"
localPlayerPlayCommand="$AUDIO_BASE_DIR/Mopidy/control.bash play"

btStreamCommand="ffmpeg -nostdin -hide_banner -nostats -loglevel quiet"
btStreamCommand="$btStreamCommand -f alsa -i bluealsa"
btStreamCommand="$btStreamCommand -ar $AUDIO_RATE -c:a pcm_s${AUDIO_BIT_NB}le"
btStreamCommand="$btStreamCommand -f alsa dmix:$loopbackDevice"

btPlayCommand="$AUDIO_BASE_DIR/Bluetooth/control.bash play"

btState='disconnected'
while true ; do
  player=`playerctl -l 2>/dev/null`
#echo "$player"
  if [ -n "$player" ] ; then
    if [ $btState = 'disconnected' ] ; then
      btState='connected'
      if [ $verbose = 'true' ] ; then
        echo "${INDENT}$player connected"
      fi
      $localPlayerPauseCommand
      $btStreamCommand 2>/dev/null &
      $btPlayCommand >/dev/null
    fi
  else
    if [ $btState = 'connected' ] ; then
      btState='disconnected'
      if [ $verbose = 'true' ] ; then
        echo "${INDENT}BT audio source disconnected"
      fi
      $localPlayerPlayCommand
    fi
  fi
  sleep 1
done

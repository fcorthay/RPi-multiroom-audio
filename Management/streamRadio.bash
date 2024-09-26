#!/usr/bin/bash

AUDIO_BASE_DIR=$(dirname $(dirname $0))
INDENT='  '

# ------------------------------------------------------------------------------
# Command line arguments
#
                                                                # default values
listStations=false
station=''
endSreaming=false
verbose=false
                                                             # specify arguments
arguments='ls:evh'
declare -A longArguments
longArguments=(
  ["l"]="listStations" ["s"]="station" ["e"]="endSreaming"
  ["v"]="verbose"
)
                                                             # show script usage
usage() {
  echo "Usage: $(basename "$0") [-l|--listStations] [-s|--station station]" 1>&2 
  echo "${INDENT}[-e|--endSreaming] [-v|--verbose]" 1>&2 
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
    l) listStations=true ;;
    s) station="$OPTARG" ;;
    e) endSreaming=true ;;
    v) verbose=true ;;
    h) usage ;;
    ?) usage
  esac
done
shift $((OPTIND-1))
station=`echo $station | tr '[:upper:]' '[:lower:]'`

if [ -z $station ] && [ $endSreaming = 'false' ] ; then
  listStations=true
fi

# ------------------------------------------------------------------------------
# Main script
#
                                                        # configuration elements
source $AUDIO_BASE_DIR/configuration.bash
AUDIO_SINK="dmix:$ALSA_LOOPBACK_CAPTURE_DEVICE,$SNAPSERVER_LOOPBACK_SUBDEVICE"
STATION_LIST=(`env | grep 'RADIO_'`)
                                                       # get radio stations info
declare -A stationDictionary
  for knownStation in ${STATION_LIST[@]} ; do
    name=`echo $knownStation | cut -d '=' -f 1`
    url=`echo $knownStation | cut -d '=' -f 2`
    name=${name#RADIO_}
    name=`echo $name | tr '[:upper:]' '[:lower:]'`
    stationDictionary[$name]=$url
  done
                                                           # list radio stations
if [ $listStations = 'true' ] ; then
  echo "Known radio stations:"
  for station in ${!stationDictionary[@]} ; do
    echo "$INDENT$station : ${stationDictionary[$station]}"
  done
                                                          # stop radio streaming
elif [ $endSreaming = 'true' ] ; then
  IFS=$'\n' presentStreams=(`ps ax | grep -v grep | grep vlc`)
  for presentStream in "${presentStreams[@]}" ; do
    presentStream=`echo $presentStream | sed 's/^\s*//'`
    if [[ "$presentStream" == *"$AUDIO_SINK"* ]] ; then
      streamProcessId=`echo $presentStream | cut -d ' ' -f 1`
     kill $streamProcessId
   fi
  done
  $AUDIO_BASE_DIR/Mopidy/control.bash play
                                                                  # stream radio
else
                                                                      # find URL
  streamUrl=''
  stationName=$station
  for knownStation in ${!stationDictionary[@]} ; do
    stationShort=${knownStation:0:${#station}}
    stationCompare=${station// /_}
    if [ "$stationCompare" = "$stationShort" ] ; then
      streamUrl=${stationDictionary[$knownStation]}
      stationName=$knownStation
    fi
  done
  echo "Streaming radio from $stationName"
  if [ -z $streamUrl ] ; then
      echo "${INDENT}station \"$station\" not found"
      exit
  fi
                                                    # check if already streaming
  presentStream=`ps ax | grep -v grep | grep vlc | head -n 1`
  streamProcessId=''
  if [[ "$presentStream" == *"$AUDIO_SINK"* ]] ; then
    if [[ "$presentStream" == *`which vlc`* ]] ; then
      streamProcessId=`echo $presentStream | cut -d ' ' -f 1`
      currentStreamUrl=`echo $presentStream | rev | cut -d ' ' -f 1 | rev`
    fi
  fi
  if [ -n "$streamProcessId" ] ; then
    if [ $verbose = 'true' ] ; then
      echo "${INDENT}Stopping $currentStreamUrl"
    fi
    kill $streamProcessId
  fi
                                                            # launching streamer
  if [ $verbose = 'true' ] ; then
    echo "${INDENT}Streaming from $streamUrl"
  fi
  $AUDIO_BASE_DIR/Mopidy/control.bash pause
  cvlc -A alsa --alsa-audio-device $AUDIO_SINK $streamUrl > /dev/null 2>&1 &
fi

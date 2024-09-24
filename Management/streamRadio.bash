#!/usr/bin/bash

AUDIO_BASE_DIR=$(dirname $(dirname $0))
INDENT='  '
                                                         # command line argument
command=${1:-list}
command=`echo $command | tr '[:upper:]' '[:lower:]'`

                                                        # configuration elements
source $AUDIO_BASE_DIR/configuration.bash
AUDIO_SINK="dmix:$ALSA_LOOPBACK_CAPTURE_DEVICE,$SNAPSERVER_LOOPBACK_SUBDEVICE"
STATION_LIST=(`env | grep 'RADIO_'`)
                                                       # get radio stations info
declare -A stationDictionary
  for station in ${STATION_LIST[@]} ; do
    name=`echo $station | cut -d '=' -f 1`
    url=`echo $station | cut -d '=' -f 2`
    name=${name#RADIO_}
    name=`echo $name | tr '[:upper:]' '[:lower:]'`
    stationDictionary[$name]=$url
  done
                                                           # list radio stations
if [ "$command" = 'list' ] ; then
  echo "Known radio stations:"
  for station in ${!stationDictionary[@]} ; do
    echo "$INDENT$station : ${stationDictionary[$station]}"
  done
                                                          # stop radio streaming
elif [ "$command" = 'stop' ] ; then
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
  echo "Streaming radio from $command"
                                                                      # find URL
  streamUrl=''
  for station in ${!stationDictionary[@]} ; do
    stationShort=${station:0:${#command}}
    commandCompare=${command// /_}
    if [ "$commandCompare" = "$stationShort" ] ; then
      streamUrl=${stationDictionary[$station]}
    fi
  done
  if [ -z $streamUrl ] ; then
      echo "$INDENT\"$command\" not found"
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
    echo "${INDENT}Stopping $currentStreamUrl"
    kill $streamProcessId
  fi
                                                            # launching streamer
  echo "${INDENT}Streaming from $streamUrl"
  $AUDIO_BASE_DIR/Mopidy/control.bash pause
  cvlc -A alsa --alsa-audio-device $AUDIO_SINK $streamUrl > /dev/null 2>&1 &
fi

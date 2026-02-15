#!/usr/bin/bash

AUDIO_BASE_DIR=$(dirname $(dirname $0))

INDENT='  '

# ------------------------------------------------------------------------------
# Functions
#
function serviceSourceSink {
  for path in ${streamList[@]} ; do
    if [[ $path == $1*$2 ]] ; then
      sourceSink=`echo $path | cut -d ' ' -f 2`
      card=''
      for cardName in ${cardList[@]} ; do
        if [ ${sourceSink:1:1} = ${cardName:0:1} ]; then
          card=${cardName:2}
          device=${sourceSink:3:1}
        fi
      done
      echo "$card $device"
    fi
  done
}

function serviceSource {
#  serviceSourceSink $1 'c'
#  echo 'hello'
  echo $(serviceSourceSink $1 'c')
}

function serviceSink {
  echo $(serviceSourceSink $1 'p')
}

# ------------------------------------------------------------------------------
# Main script
#
                                                                 # get card list
IFS=$'\n' cardList=(`aplay -l | grep ^card | tr -d ':' | cut -d ' ' -f 2,3`)
                                                             # get audio streams
streamList=''
reply=`sudo -nv 2>&1`
if [[ $reply != Sorry* ]] ; then
  echo "Checking for audio streams"
  IFS=$'\n' streamList=(`\
    sudo lsof +c 15 /dev/snd/* \
      | grep /dev/snd/pcm | sed 's/\/dev\/snd\/pcm//' | sed 's/0t0//' \
      | tr -s ' ' | cut -d ' ' -f 1,8 | uniq \
  `)
  echo
fi
                                                                        # Mopidy
service='mopidy'
sinkDevice=$(serviceSink $service)
if [ -n "$sinkDevice" ] ; then
  echo 'Mopidy player'
  sinkDevice=`$AUDIO_BASE_DIR/Mopidy/mopidySink.bash`
  echo "${INDENT}files -> mopidy -> $sinkDevice"
fi
echo
                                                                    # snapserver
service='snapserver'
sourceDevice=$(serviceSource $service)
if [ -n "$sourceDevice" ] ; then
  echo 'Snapcast server'
  sourceDevice=`$AUDIO_BASE_DIR/Snapcast/serverSource.bash`
  echo "$INDENT$sourceDevice -> snapServer -> Ethernet"
fi
echo
                                                                    # snapclient
service='snapclient'
sinkDevice=$(serviceSink $service)
if [ -n "$sinkDevice" ] ; then
  echo 'Snapcast client'
  host=`cat /etc/default/snapclient | grep ^SNAPCLIENT_OPTS=`
  host=`echo $host | sed 's/.*--host\s*//'`
  host=`echo $host | sed 's/\s.*//'`
  host=`echo $host | sed 's/".*//'`
  sinkDevice=`$AUDIO_BASE_DIR/Mopidy/mopidySink.bash`
  echo "${INDENT}Ethernet:$host -> snapclient -> $sinkDevice"
fi
echo
                                                                    # camilladsp
service='camilladsp'
sourceDevice=$(serviceSource $service)
if [ -n "$sourceDevice" ] ; then
  echo 'CamillaDSP'
  echo "$INDENT$sourceDevice -> CamillaDSP -> "
fi

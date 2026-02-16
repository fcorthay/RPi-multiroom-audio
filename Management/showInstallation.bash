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

function serviceActivity {
  activity=`sudo service $1 status | grep -E "^ +Active"`
  activity=`echo $activity | sed 's/.*Active:\s//'`
  activity=`echo $activity | tr ')' '_' | sed 's/_.*/)/'`
  echo $activity
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
  echo "${INDENT}status: $(serviceActivity $service)"
fi
echo
                                                                    # snapserver
service='snapserver'
sourceDevice=$(serviceSource $service)
if [ -n "$sourceDevice" ] ; then
  echo 'Snapcast server'
  sourceDevice=`$AUDIO_BASE_DIR/Snapcast/serverSource.bash`
  echo "$INDENT$sourceDevice -> snapServer -> Ethernet"
  echo "${INDENT}status: $(serviceActivity $service)"
fi
echo
                                                                    # snapclient
service='snapclient'
sinkDevice=$(serviceSink $service)
if [ -n "$sinkDevice" ] ; then
  echo 'Snapcast client'
  host=`$AUDIO_BASE_DIR/Snapcast/clientSource.bash`
  sinkDevice=`$AUDIO_BASE_DIR/Snapcast/clientSink.bash`
  echo "${INDENT}Ethernet:$host -> snapclient -> $sinkDevice"
  echo "${INDENT}status: $(serviceActivity $service)"
fi
echo
                                                                    # camilladsp
service='camilladsp'
sourceDevice=$(serviceSource $service)
if [ -n "$sourceDevice" ] ; then
  echo 'CamillaDSP'
  sourceDevice=`$CAMILLA_DIR/Scripts/camillaSource.bash`
  sinkDevice=`$CAMILLA_DIR/Scripts/camillaSink.bash`
  echo "$INDENT$sourceDevice -> CamillaDSP -> $sinkDevice"
  echo "${INDENT}status: $(serviceActivity $service)"
fi
                                                                      # alsaloop
alsaloopCommand=`ps ax | grep -v grep | grep alsaloop`
if [ -n "$alsaloopCommand" ] ; then
  echo "Alsaloop"
  audioInput=`echo $alsaloopCommand | sed 's/.*-C *//'`
  audioInput=`echo $audioInput | sed 's/ .*//'`
  audioInput=`echo $audioInput | sed 's/.*\://'`
  audioOutput=`echo $alsaloopCommand | sed 's/.*-P *//'`
  audioOutput=`echo $audioOutput | sed 's/ .*//'`
  audioOutput=`echo $audioOutput | sed 's/.*\://'`
  echo "${INDENT}$audioInput -> alsaloop -> $audioOutput"
fi

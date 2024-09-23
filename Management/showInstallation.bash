#!/usr/bin/bash

AUDIO_BASE_DIR=$(dirname $(dirname $0))

INDENT='  '

# ------------------------------------------------------------------------------
# Functions
#
function serviceActivity {
  activity=`sudo service $1 status | grep -E "^ +Active"`
  activity=`echo $activity | sed 's/.*Active:\s//'`
  activity=`echo $activity | tr ')' '_' | sed 's/_.*/)/'`
  echo $activity
}

function serviceSink {
  sink=`$AUDIO_BASE_DIR/$1 | tr -d '"'`
  sink=`echo $sink | sed 's/.*is\s*//'`
  echo $sink
}

# ------------------------------------------------------------------------------
# Main script
#
echo -e "Checking for services\n"
serviceList=`systemctl list-unit-files --type=service`
                                                                        # Mopidy
echo 'Mopidy'
service='mopidy'
serviceExists=`echo $serviceList | grep $service`
if [ -z "$serviceExists" ] ; then
  echo "${INDENT}service not installed"
else
  echo "${INDENT}$(serviceActivity $service)"
  echo "${INDENT}files -> mopidy -> $(serviceSink Mopidy/mopidySink.bash)"
fi
                                                                    # snapserver
echo 'Snapcast server'
service='snapserver'
serviceExists=`echo $serviceList | grep $service`
if [ -z "$serviceExists" ] ; then
  echo "${INDENT}service not installed"
else
  echo "${INDENT}$(serviceActivity $service)"
  echo "${INDENT}$(serviceSink Snapcast/serverSource.bash)" \
    "-> snapserver -> Ethernet"
fi
                                                                    # snapclient
echo 'Snapcast client'
service='snapclient'
serviceExists=`echo $serviceList | grep $service`
if [ -z "$serviceExists" ] ; then
  echo "${INDENT}service not installed"
else
  echo "${INDENT}$(serviceActivity $service)"
  audioInput=`cat /etc/default/snapclient | grep ^SNAPCLIENT_OPTS=`
  audioInput=`echo $audioInput | sed 's/.*--host\s*//'`
  audioInput=`echo $audioInput | sed 's/\s.*//'`
  audioInput=`echo $audioInput | sed 's/"//'`
  echo "${INDENT}Ethernet $audioInput -> snapclient" \
    "-> $(serviceSink Snapcast/clientSink.bash)"
fi
                                                                    # camilladsp
echo 'CamillaDSP'
service='camilladsp'
serviceExists=`echo $serviceList | grep $service`
if [ -z "$serviceExists" ] ; then
  echo "${INDENT}service not installed"
else
  echo "${INDENT}$(serviceActivity $service)"
  audioInput=`cat $CAMILLA_CONFIGURATION_FILE | grep -A 4 capture | grep device`
  audioInput=`echo $audioInput | sed 's/ *device: "//'`
  audioInput=`echo $audioInput | sed 's/".*//'`
  audioOutput=`cat $CAMILLA_CONFIGURATION_FILE | grep -A 4 playback`
  audioOutput=`echo -e "$audioOutput" | grep device`
  audioOutput=`echo $audioOutput | sed 's/ *device: "//'`
  audioOutput=`echo $audioOutput | sed 's/".*//'`
  echo "${INDENT}$audioInput -> CamillaDSP -> $audioOutput"
fi

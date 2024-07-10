#!/usr/bin/bash

INDENT='  '

echo -e "Checking for services\n"
serviceList=`systemctl list-unit-files --type=service`
                                                                        # Mopidy
echo 'Mopidy'
service='mopidy'
serviceExists=`echo $serviceList | grep $service`
if [ -z "$serviceExists" ] ; then
  echo "${INDENT}service not installed"
else
  serviceActivity=`sudo service $service status | grep -E "^ +Active"`
  serviceActivity=`echo $serviceActivity | sed 's/.*Active:\s//'`
  serviceActivity=`echo $serviceActivity | tr ')' '_' | sed 's/_.*/)/'`
  echo "${INDENT}$serviceActivity"
  audioOutput=`cat /etc/mopidy/mopidy.conf | grep ^output | sed 's/.*device=//'`
  echo "${INDENT}files -> mopidy -> $audioOutput"
fi
                                                                    # snapserver
echo 'Snapcast server'
service='snapserver'
serviceExists=`echo $serviceList | grep $service`
if [ -z "$serviceExists" ] ; then
  echo "${INDENT}service not installed"
else
  serviceActivity=`sudo service $service status | grep -E "^ +Active"`
  serviceActivity=`echo $serviceActivity | sed 's/.*Active:\s//'`
  serviceActivity=`echo $serviceActivity | tr ')' '_' | sed 's/_.*/)/'`
  echo "${INDENT}$serviceActivity"
  audioInput=`cat /etc/snapserver.conf | grep ^source | sed 's/source\s*=\s*//'`
  if [[ "$audioInput" =~ ^alsa.* ]]; then
    audioInput=`echo $audioInput | sed 's/.*device=//'`
  fi
  echo "${INDENT}$audioInput -> snapserver -> Ethernet"
fi
                                                                    # snapserver
echo 'Snapcast client'
service='snapclient'
serviceExists=`echo $serviceList | grep $service`
if [ -z "$serviceExists" ] ; then
  echo "${INDENT}service not installed"
else
  serviceActivity=`sudo service $service status | grep -E "^ +Active"`
  serviceActivity=`echo $serviceActivity | sed 's/.*Active:\s//'`
  serviceActivity=`echo $serviceActivity | tr ')' '_' | sed 's/_.*/)/'`
  echo "${INDENT}$serviceActivity"
  audioInput=`cat /etc/default/snapclient | grep ^SNAPCLIENT_OPTS=`
  audioInput=`echo $audioInput | sed 's/.*--host\s*//'`
  audioInput=`echo $audioInput | sed 's/\s.*//'`
  audioInput=`echo $audioInput | sed 's/"//'`
  audioOutput=`cat /etc/default/snapclient | grep ^SNAPCLIENT_OPTS=`
  audioOutput=`echo $audioOutput | sed 's/.*--soundcard\s*//'`
  audioOutput=`echo $audioOutput | sed 's/\s.*//'`
  audioOutput=`echo $audioOutput | sed 's/"//'`
  echo "${INDENT}$audioInput -> snapclient -> $audioOutput"
fi

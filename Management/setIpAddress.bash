#!/usr/bin/bash

INDENT='  '
                                                              # check IP address
fixedIpAddress=$1
if [ -z "$fixedIpAddress" ] ; then
  echo "IP address not provided"
else
  IFS='.' read -r -a addressParts <<< "$fixedIpAddress"
  addressValid=True
  if [ ${#addressParts[@]} -ne 4 ] ; then
    echo "IP address not valid"
  fi
  if [ $addressValid != 'True' ] ; then
    echo "IP address not valid"
  else

    domainPart=$(IFS='.' ; echo "${addressParts[*]:0:3}")
    echo $domainPart
    echo "sudo nmcli con mod "Wired connection 1" ipv4.addresses $fixedIpAddress/24 ipv4.method manual"
    echo "sudo nmcli con mod "Wired connection 1" ipv4.gateway $domainPart.1"
    echo "sudo nmcli con mod "Wired connection 1" ipv4.dns $domainPart.1"
  fi
fi

#!/usr/bin/bash
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
                                                                # set IP address
    echo "Changing IP address to $fixedIpAddress"
    domainPart=$(IFS='.' ; echo "${addressParts[*]:0:3}")
    sudo nmcli con mod "Wired connection 1" ipv4.method manual
    sudo nmcli con mod "Wired connection 1" ipv4.addresses $fixedIpAddress/24
    sudo nmcli con mod "Wired connection 1" ipv4.gateway $domainPart.1
    sudo nmcli con mod "Wired connection 1" ipv4.dns $domainPart.1
                                                                   # show result
    echo
    ifconfig | grep -A 3 ^eth0 | grep -v inet6
  fi
fi

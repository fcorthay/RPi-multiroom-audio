#!/usr/bin/bash
                                                               # check host name
newName=$1
if [ -z "$newName" ] ; then
  echo "Host name not provided"
else
  echo "Setting host name to $newName"
  hostnamectl set-hostname $newName
  sudo sed -i "s/127\.0\.1\.1.*/127.0.1.1\t$newName/" /etc/hosts
                                                                   # show result
  echo
  echo '/etc/hosts :'
  cat /etc/hosts | grep -v ip6 | grep -v '^[[:space:]]*$'
  echo
  echo '/etc/hostname :'
  cat /etc/hostname
fi

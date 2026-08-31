#!/bin/bash

# ------------------------------------------------------------------------------
# Constants
#
PRINT_FORMAT='%-12s %-10s %-8s %-16s %-16s'
SEPARATOR='------------------------------------------------------------------'

# ------------------------------------------------------------------------------
# Main script
#
                                 # Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ] ; then
  echo "Error: Please run this script with sudo."
  exit 1
fi
                                                            # columns definition
echo $SEPARATOR
printf "$PRINT_FORMAT\n" \
  'ALSA DEVICE' 'SUBDEVICE' 'PID' 'PROCESS NAME' 'ACCESS TYPE'
echo $SEPARATOR
                                                  # PID list to avoid duplicates
trackedPids=()

# ------------------------------------------------------------------------------
# Direct hardware tracking (loop through active running ALSA subdevices)
#
for statusFile in /proc/asound/card*/pcm*/sub*/status; do
  [ -e "$statusFile" ] || continue
  
  if grep -q "state: RUNNING" "$statusFile" ; then
                                     # extract card, device, and subdevice names
    devNode=$(echo "$statusFile" | awk -F'/' '{print $5}')
    subNode=$(echo "$statusFile" | awk -F'/' '{print $6}')
                                                              # locate processes
    pids=$(fuser "$statusFile" 2>/dev/null | tr -d ' ')
    if [ -z "$pids" ] ; then
      cardNum=$(echo "$statusFile" | sed -n 's/.*card\([0-9]\+\).*/\1/p')
      devNum=$(echo "$statusFile" | sed -n 's/.*pcm\([0-9]\+\)p.*/\1/p')
      pids=$(lsof -t "/dev/snd/pcmC${cardNum}D${devNum}p" 2>/dev/null)
    fi
                                                               # print processes
    for pid in $pids; do
      if [ -n "$pid" ] && [[ "$pid" =~ ^[0-9]+$ ]] ; then
        processName=$(ps -p "$pid" -o comm= 2>/dev/null)
        if [ -n "$processName" ] ; then
          printf "$PRINT_FORMAT\n" \
            "$devNode" "$subNode" "$pid" "$processName" 'Direct Hardware'
          trackedPids+=("$pid")
        fi
      fi
    done
  fi
done

# ------------------------------------------------------------------------------
# ALSA Shared Memory IPC Tracking (scan processes mapped to alsa libraries)
#
for mapsFile in /proc/[0-9]*/maps; do
  [ -e "$mapsFile" ] || continue
  
  if grep -E -q "libasound|alsa-dmix|/dev/shm/" "$mapsFile" ; then
    pid=$(echo "$mapsFile" | awk -F'/' '{print $3}')
    
                                                       # skip if already tracked
    if [[ " ${trackedPids[*]} " =~ " ${pid} " ]] ; then
      continue
    fi
    
    processName=$(ps -p "$pid" -o comm= 2>/dev/null)
                                                               # print processes
    if [ -n "$processName" ] ; then
      printf "$PRINT_FORMAT\n" \
        "dmix-shared" "indirect" "$pid" "$processName" "ALSA Shared Mem"
      trackedPids+=("$pid")
    fi
  fi
done

echo $SEPARATOR

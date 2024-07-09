#!/usr/bin/bash

# ==============================================================================
# Constants
#
INDENT='  '

# ==============================================================================
# Command line arguments
#
                                                                # default values
frequency=440
duration=3
rampTime=0.5
plotInput=false
plotRecorded=false
recordStart=1
recordEnd=0

loudspeaker='Loopback,0,0'
microphone='Quadcast'

keepRecording=false
dryRun=false
verbose=false
                                                             # specify arguments
arguments='f:d:r:pPs:e:m:knvh'
declare -A longArguments
longArguments=(
  ["f"]="frequency"
  ["d"]="duration"
  ["r"]="rampTime"
  ["P"]="plotWave"
  ["p"]="plotRecorded"
  ["s"]="recordStart"
  ["e"]="recordEnd"
  ["l"]="loudspeaker"
  ["m"]="microphone"
  ["k"]="keepRecording"
  ["n"]="dryRun"
  ["v"]="verbose"
  ["h"]="help"
)
                                                             # show script usage
usage() {
  usage="Usage: $(basename "$0")" 
  usage+="\n\t"
  usage+=' [-f|--frequency]'
  usage+=' [-d|--duration]'
  usage+=' [-r|--rampTime]'
  usage+="\n\t"
  usage+=' [-P|--plotInput]'
  usage+=' [-p|--plotRecorded]'
  usage+=' [-s|--recordStart \e[4mtime\e[0m]'
  usage+=' [-e|--recordEnd \e[4mtime\e[0m]'
  usage+="\n\t"
  usage+=' [-l|--loudspeaker \e[4mcard\e[0m]'
  usage+=' [-m|--microphone \e[4mcard\e[0m]'
  usage+="\n\t"
  usage+=' [-k|--keepRecording]'
  usage+=' [-n|--dryRun]'
  usage+=' [-v|--verbose]'
  usage+=' [-h|--help]'
  echo -e $usage 1>&2 
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
    f) frequency="$OPTARG" ;;
    d) duration="$OPTARG" ;;
    r) rampTime="$OPTARG" ;;
    P) plotInput=true ;;
    p) plotRecorded=true ;;
    s) recordStart="$OPTARG" ;;
    e) recordEnd="$OPTARG" ;;
    l) loudspeaker="$OPTARG" ;;
    m) microphone="$OPTARG" ;;
    k) keepRecording=true ;;
    n) dryRun=true ;;
    v) verbose=true ;;
    h) usage ;;
    ?) usage
  esac
done

shift $((OPTIND-1))
if [ -n "$1" ] ; then
  frequency=$1
fi
                                                              # calculate values
if [ $recordEnd = '0' ] ; then
  recordEnd=`perl -E "print $recordStart+$duration+0.5"`
fi
recordDuration=`perl -E "print int($recordEnd+1+0.5)"`
recordWait=3

if [ $plotRecorded = false ] ; then
  keepRecording=true
fi
                                                             # display arguments
if [ $verbose = true ] ; then
  echo "Analysing frequency $frequency"
  echo "${INDENT}plot source wave       : $plotInput"
  echo "${INDENT}plot recorded wave     : $plotRecorded"
  echo "${INDENT}wave duration          : $duration"
  echo "${INDENT}ramp up/down time      : $rampTime"
  echo "${INDENT}recordind start        : $recordStart s"
  echo "${INDENT}recordind end          : $recordEnd s"
  echo "${INDENT}loudspeaker sound card : $loudspeaker"
  echo "${INDENT}microphone sound card  : $microphone"
  echo "${INDENT}keep recorded file     : $keepRecording"
fi

verboseParam=''
if [ $verbose = true ] ; then
  verboseParam='-v'
fi

if [ $dryRun = true ] ; then
  exit
fi

# ==============================================================================
# Main
#
frequency_string=`perl -E "printf(\"%.3f\", $frequency)"`
inputFile="frequency-$frequency_string"
outputFile="record-$frequency_string"
                                                            # build audio signal
./buildSingleFrequency.py -f $frequency -d $duration -r $rampTime $verboseParam
                                                             # plot audio signal
if [ $plotInput = true ] ; then
  ./wavPlot.py $verboseParam -t "wave at $frequency Hz"\
    $verboseParam $inputFile.wav
fi
                                                     # record loudspeaker output
if [ $verbose = true ] ; then
  arecord -D plughw:$microphone --format S16_LE \
    --duration $recordDuration $outputFile.wav &
  sleep 0.1
  echo
else
    arecord -D plughw:$microphone --format S16_LE \
    --duration $recordDuration $outputFile.wav > /dev/null 2>&1 &
fi
                                                             # play audio signal
if [ $verbose = true ] ; then
  sudo aplay -D dmix:$loudspeaker $inputFile.wav
else
  sudo aplay -D dmix:$loudspeaker $inputFile.wav > /dev/null 2>&1
fi
                                                        # wait for recording end
sleep $recordWait
                                                       # plot loudspeaker output
if [ $plotRecorded = true ] ; then
  ./wavPlot.py -s $recordStart -e $recordEnd    \
    -t "wave at $frequency_string Hz recording" \
    $verboseParam $outputFile.wav
fi
if [ $keepRecording = false ] ; then
  rm record-$frequency_string.wav
fi

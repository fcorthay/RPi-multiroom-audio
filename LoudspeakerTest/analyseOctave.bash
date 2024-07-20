#!/usr/bin/bash

# ==============================================================================
# Constants
#
INDENT='  '

# ==============================================================================
# Command line arguments
#
                                                                # default values
octave=4
noteDuration=0.5
interval=0.1
whiteOctave=false
plotInput=false
recordStart=1
recordEnd=0

loudspeaker='Loopback,0,0'
microphone='Quadcast'

keepRecording=false
dryRun=false
verbose=false
                                                             # specify arguments
arguments='d:i:wps:e:m:knvh'
declare -A longArguments
longArguments=(
  ["d"]="duration"
  ["i"]="interval"
  ["w"]="whiteOctave"
  ["p"]="plotOctave"
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
  usage+=' [-d|--duration \e[4mtime\e[0m]'
  usage+=' [-i|--interval \e[4mtime\e[0m]'
  usage+="\n\t"
  usage+=' [-w|--whiteOctave]'
  usage+=' [-p|--plotInput]'
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
  usage+=' [octave]'
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
    d) noteDuration="$OPTARG" ;;
    i) interval="$OPTARG" ;;
    w) whiteOctave=true ;;
    p) plotInput=true ;;
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
  octave=$1
fi
                                                              # calculate values
if [ $recordEnd = '0' ] ; then
  intervalNb=12
  if [ $whiteOctave = true ] ; then
    intervalNb=7
  fi
  intervalNb=$(($intervalNb+2))
  recordEnd=`perl -E "print $recordStart+$intervalNb*($noteDuration+$interval)"`
fi
recordDuration=`perl -E "print int($recordEnd+1+0.5)"`
recordWait=3

                                                             # display arguments
if [ $verbose = true ] ; then
  echo "Analysing octave $octave"
  echo "${INDENT}note duration          : $noteDuration s"
  echo "${INDENT}interval between notes : $interval s"
  echo "${INDENT}use white octave       : $whiteOctave"
  echo "${INDENT}plot source octave     : $plotInput"
  echo "${INDENT}recordind start        : $recordStart s"
  echo "${INDENT}recordind end          : $recordEnd s"
  echo "${INDENT}loudspeaker sound card : $loudspeaker"
  echo "${INDENT}microphone sound card  : $microphone"
  echo "${INDENT}keep recorded file     : $keepRecording"
fi

whiteOctaveParam=''
if [ $whiteOctave = true ] ; then
  whiteOctaveParam='-w'
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
scriptDirectory=$(dirname "$0")
inputFile="$scriptDirectory/octave-$octave-$octave"
inputFileShort="$scriptDirectory/octave-$octave"
outputFile="$scriptDirectory/record-$octave"
                                                            # build audio signal
$scriptDirectory/buildNoteSet.py -s $octave -e $octave \
  -d $noteDuration -i $interval $whiteOctaveParam $verboseParam
                                                             # plot audio signal
if [ $plotInput = true ] ; then
  $scriptDirectory/wavPlot.py $verboseParam -t "octave $octave input"\
    $verboseParam $inputFile.wav
  mv $inputFile.png $inputFileShort.png
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
$scriptDirectory/wavPlot.py -s $recordStart -e $recordEnd -t "octave \
  $octave recording" $verboseParam $outputFile.wav
if [ $keepRecording = false ] ; then
  rm $outputFile.wav
fi

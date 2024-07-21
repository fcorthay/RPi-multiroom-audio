#!/usr/bin/bash

# ==============================================================================
# Constants
#
SAMPLE_RATE='192000'
SAMPLE_FORMAT='S16_LE'
RECORD_ADDITIONAL_DURATION=2
RECORD_INTERVAL_DURATION=3

PLOT_START=0
PLOT_END=0

INDENT='  '
INDENT2="$INDENT$INDENT"

# ==============================================================================
# Command line arguments
#
script_directory=`dirname $0`
script_directory_full=`realpath $script_directory`
                                                                # default values
createStimuli=false
playAndRecord=false
analyseResponses=false
filterRegEx=''

startOctave=4
endOctave=4
pointsPerOctave=12
duration=3
rampTime=0.5
regionOfInterestStart=0
regionOfInterestEnd=0

loudspeaker='Loopback,0,0'
microphone='NTUSB'

outputDirectory="$script_directory_full/Batch"
plotResponses=false

dryRun=false
verbose=false
                                                             # specify arguments
arguments='123f:s:e:p:d:r:S:E:Pl:m:o:vh'
declare -A longArguments
longArguments=(
  ["1"]="createStimuli"
  ["2"]="playAndRecord"
  ["3"]="analyseResponses"
  ["f"]="filterRegEx"
  ["s"]="startOctave"
  ["e"]="endOctave"
  ["p"]="pointsPerOctave"
  ["d"]="duration"
  ["r"]="rampTime"
  ["S"]="analysisStart"
  ["E"]="analysisEnd"
  ["l"]="loudspeaker"
  ["m"]="microphone"
  ["o"]="outputDirectory"
  ["P"]="plotResponses"
  ["n"]="dryRun"
  ["v"]="verbose"
  ["h"]="help"
)
                                                             # show script usage
usage() {
  usage="Usage: $(basename "$0")" 
  usage+="\n\t"
  usage+=' [-1|--createStimuli'
  usage+=' [-2|--playAndRecord'
  usage+=' [-3|--analyseResponses'
  usage+=' [-f|--filterRegEx'
  usage+="\n\t"
  usage+=' [-s|--startOctave \e[4moctave\e[0m]'
  usage+=' [-e|--endOctave \e[4moctave\e[0m]'
  usage+=' [-p|--pointsPerOctave \e[4mnb\e[0m]'
  usage+="\n\t"
  usage+=' [-d|--duration \e[4mtime\e[0m]'
  usage+=' [-r|--ramp \e[4mtime\e[0m]'
  usage+="\n\t"
  usage+=' [-S|--analysisStart \e[4mtime\e[0m]'
  usage+=' [-E|--analysisEnd \e[4mtime\e[0m]'
  usage+="\n\t"
  usage+=' [-l|--loudspeaker \e[4mcard\e[0m]'
  usage+=' [-m|--microphone \e[4mcard\e[0m]'
  usage+="\n\t"
  usage+=' [-o|--outputDirectory]'
  usage+=' [-P|--plotResponses]'
  usage+="\n\t"
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
    1) createStimuli=true ;;
    2) playAndRecord=true ;;
    3) analyseResponses=true ;;
    f) filterRegEx="$OPTARG" ;;
    s) startOctave="$OPTARG" ;;
    e) endOctave="$OPTARG" ;;
    p) pointsPerOctave="$OPTARG" ;;
    d) duration="$OPTARG" ;;
    r) rampTime="$OPTARG" ;;
    S) regionOfInterestStart="$OPTARG" ;;
    E) regionOfInterestEnd="$OPTARG" ;;
    l) loudspeaker="$OPTARG" ;;
    m) microphone="$OPTARG" ;;
    o) outputDirectory="$OPTARG" ;;
    P) plotResponses=true ;;
    n) dryRun=true ;;
    v) verbose=true ;;
    h) usage ;;
    ?) usage
  esac
done
                                                             # display arguments
if [ $verbose = true ] ; then
  echo "Analysing octaves from $startOctave to $endOctave"
  echo "${INDENT}create stimuli         : $createStimuli"
  echo "${INDENT}play and record        : $playAndRecord"
  echo "${INDENT}analyse responses      : $analyseResponses"
  echo "${INDENT}filter regular expr.   : $filterRegEx"
  echo "${INDENT}points per octave      : $pointsPerOctave"
  echo "${INDENT}wave duration          : $duration s"
  echo "${INDENT}ramp up/down time      : $rampTime s"
  echo "${INDENT}analysis start time    : $regionOfInterestStart s"
  echo "${INDENT}analysis end time      : $regionOfInterestEnd s"
  echo "${INDENT}loudspeaker sound card : $loudspeaker"
  echo "${INDENT}microphone sound card  : $microphone"
  echo "${INDENT}output directory       : $outputDirectory"
  echo "${INDENT}plot responses         : $plotResponses"
fi

verboseParam=''
if [ $verbose = true ] ; then
  verboseParam='-v'
fi

# ==============================================================================
# Main
#
# ------------------------------------------------------------------------------
# 1) create stimuli
#
if [ $createStimuli = true ] ; then
  taskStartTime=`date +%s`
  if [ $verbose = true ] ; then
    echo -e "\nCreating stimuli"
  fi
                                                              # create directory
  if [ ! -d $outputDirectory ] ; then
    if [ $verbose = true ] ; then
      echo "${INDENT}Creating directory \"$outputDirectory\""
      mkdir -p $outputDirectory
    fi
  fi
                                              # build reference frequencies list
  A4Frequency=440
  C4Frequency=`perl -E "print $A4Frequency/2**(9/12)"`
  C0Frequency=`perl -E "print $C4Frequency/2**4"`
  octave0Frequencies=()
  for frequencyId in $(seq 0 $((pointsPerOctave - 1))) ; do
    frequency=`perl -E "print $C0Frequency*2**($frequencyId/$pointsPerOctave)"`
    octave0Frequencies+=($frequency)
  done
                                                           # build stimuli files
  for octave in $(seq $startOctave $endOctave) ; do
    if [ $verbose = true ] ; then
      echo "${INDENT}octave $octave"
    fi
    for frequencyId in $(seq 0 $((pointsPerOctave - 1))) ; do
      frequency=${octave0Frequencies[$frequencyId]}
      frequency=`perl -E "print sprintf('%.3f', $frequency*2**$octave)"`
      if [ $verbose = true ] ; then
        echo "${INDENT2}frequency : $frequency Hz"
      fi
      $script_directory/buildSingleFrequency.py -f $frequency \
        -d $duration -r $rampTime -o $outputDirectory
    done
  done
  taskEndTime=`date +%s`
  executionTime=$((taskEndTime-taskStartTime))
  echo "${INDENT}done in $executionTime s"
fi

# ------------------------------------------------------------------------------
# 2) play and record
#
if [ $playAndRecord = true ] ; then
  taskStartTime=`date +%s`
  if [ $verbose = true ] ; then
    echo -e "\nPlaying and recording"
  fi
                                                            # loop through files
  for stimulusFile in $outputDirectory/frequency-*.wav ; do
    if [ $verbose = true ] ; then
      echo "$INDENT$(basename $stimulusFile)"
    fi
                                                     # record loudspeaker output
    responseFile=${stimulusFile/frequency/record}
    durationCalc="$duration+$RECORD_ADDITIONAL_DURATION+0.5"
    recordDuration=`perl -E "print int($durationCalc)"`
    arecord -D plughw:$microphone --format $SAMPLE_FORMAT --rate $SAMPLE_RATE \
      --duration $recordDuration $responseFile > /dev/null 2>&1 &
                                                             # play audio signal
    sudo aplay -D dmix:$loudspeaker $stimulusFile > /dev/null 2>&1
                                                        # wait for recording end
    sleep $RECORD_INTERVAL_DURATION
  done
  taskEndTime=`date +%s`
  executionTime=$((taskEndTime-taskStartTime))
  echo "${INDENT}done in $executionTime s"
fi

# ------------------------------------------------------------------------------
# 3) analyse responses
#
if [ $analyseResponses = true ] ; then
  taskStartTime=`date +%s`
  if [ $verbose = true ] ; then
    echo -e "\nAnalysing responses"
  fi
                                                            # loop through files
  frequencyResponse=()
  for responseFile in $outputDirectory/record-*.wav ; do
    recordingRegex='[0-9].wav'
    if [[ $responseFile =~ $recordingRegex ]]; then
      if [[ $responseFile =~ $filterRegEx ]]; then
        if [ $verbose = true ] ; then
          echo "$INDENT$(basename $responseFile)"
        fi
        frequencyString=`echo $responseFile | sed 's/.*-//'`
        frequencyString=${frequencyString%'.wav'}
                                                       # find responses envelope
        $script_directory/wavEnvelope.py $responseFile
                                                      # find responses amplitude
        envelopeFile="${responseFile%.*}-envelope.wav"
        responsePoint=`$script_directory/wavAmplitude.py \
          -s $regionOfInterestStart -e $regionOfInterestEnd $envelopeFile`
        responsePoint=`echo $responsePoint | tr ' ' :`
        frequencyResponse+=($responsePoint)
                                                    # plot loudspeaker responses
        if [ $plotResponses = true ] ; then
          $script_directory/analysisPlot.py                           \
          -s $PLOT_START -e $PLOT_END                                 \
          -S $regionOfInterestStart -E $regionOfInterestEnd           \
            -t "wave at $frequencyString Hz recording" $responseFile
        fi
      fi
    fi
  done
                                                        # write ampitude to file
  csvFile="$outputDirectory/amplitude.csv"
  if [ $verbose = true ] ; then
    echo "${INDENT}writing amplitude response to $csvFile"
  fi
  echo 'frequency, amplitude' > $csvFile
  for responsePoint in "${frequencyResponse[@]}" ; do
    frequency=${responsePoint%:*}
    amplitude=${responsePoint#*:}
    echo "$frequency, $amplitude" >> $csvFile
  done
                                                        # plot ampitude response
  pngFile="${csvFile%.*}.png"
  if [ $verbose = true ] ; then
    echo "${INDENT}plotting amplitude response in $pngFile"
  fi
  $script_directory/amplitudePlot.py $csvFile

  taskEndTime=`date +%s`
  executionTime=$((taskEndTime-taskStartTime))
  echo "${INDENT}done in $executionTime s"
fi

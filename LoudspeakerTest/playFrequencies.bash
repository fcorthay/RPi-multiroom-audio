#!/usr/bin/bash

# ==============================================================================
# Constants
#
INDENT='  '

# ==============================================================================
# Command line arguments
#
                                                                # default values
frequencyStart=1000
frequencyEnd=10000
frequencyStep=1000
duration=2
soundCard='sndrpihifiberry'
verbose=false
                                                             # specify arguments
arguments='s:e:p:d:c:vh'
declare -A longArguments
longArguments=(
  ["s"]="frequencyStart"
  ["e"]="frequencyEnd"
  ["p"]="frequencyStep"
  ["d"]="duration"
  ["c"]="soundCard"
  ["v"]="verbose"
  ["h"]="help"
)
                                                             # show script usage
usage() {
  usage="Usage: $(basename "$0")" 
  usage+="\n\t"
  usage+=' [-s|--frequencyStart \e[4mfreq\e[0m]'
  usage+=' [-e|--frequencyEnd \e[4mfreq\e[0m]'
  usage+=' [-p|--frequencyStep \e[4mfreq\e[0m]'
  usage+="\n\t"
  usage+=' [-d|--duration \e[4mtime\e[0m]]'
  usage+=' [-c|--soundCard \e[4mcard\e[0m]'
  usage+="\n\t"
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
    s) frequencyStart="$OPTARG" ;;
    e) frequencyEnd="$OPTARG" ;;
    p) frequencyStep="$OPTARG" ;;
    d) duration="$OPTARG" ;;
    c) soundCard="$OPTARG" ;;
    v) verbose=true ;;
    h) usage ;;
    ?) usage
  esac
done

# ==============================================================================
# Main
#
if [ $verbose = true ] ; then
  echo "Playing sinewaves from $frequencyStart to $frequencyEnd Hz"
fi

for frequency in `seq $frequencyStart $frequencyStep $frequencyEnd`; do
  if [ $verbose = true ] ; then
    echo "$INDENT$frequency"
  fi
  SDL_AUDIODRIVER='alsa' AUDIODEV="dmix:$soundCard" \
    ffplay -autoexit -loglevel quiet                          \
    -f lavfi "sine=frequency=$frequency:duration=$duration" >/dev/null 2>&1
done

#!/usr/bin/bash

CONFIGURATION_FILE='/etc/snapserver.conf'

INDENT='  '

# ------------------------------------------------------------------------------
# Command line arguments
#
                                                                # default values
newSource=''
restart=false
verbose=false
                                                             # specify arguments
arguments='rvh'
declare -A longArguments
longArguments=(["r"]="restart" ["v"]="verbose")
                                                             # show script usage
usage() {
  echo "Usage: $(basename "$0") [-v|--verbose] [-r|--restart] server" 1>&2 
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
    r) restart=true ;;
    v) verbose=true ;;
    h) usage ;;
    ?) usage
  esac
done
shift $((OPTIND-1))

if [ -n $1 ] ; then
  newSource=$1
fi

# ------------------------------------------------------------------------------
# Main script
#
                                                      # check configuration file
if [ ! -f $CONFIGURATION_FILE ] ; then
  echo "File \"$CONFIGURATION_FILE\" not found."
  exit
fi
                                                           # find current source
audioInputFull=`cat $CONFIGURATION_FILE | grep '^source *='`
audioInput=`echo $audioInputFull | sed 's/^source\s*=\s*//'`
  if [[ "$audioInput" =~ ^pipe.* ]]; then
    audioInput=`echo $audioInput | sed 's/pipe:\/\///'`
    audioInput=`echo $audioInput | sed 's/\?.*//'`
  fi
  if [[ "$audioInput" =~ ^alsa.* ]]; then
    audioInput=`echo $audioInput | sed 's/.*device=//'`
  fi
echo "Snapserver source is \"$audioInput\""
if [ $verbose = 'true' ] ; then
  echo "${INDENT}$audioInputFull"
fi
if [ -z $newSource ] ; then
  exit
fi
                                                             # check source name
if [ $verbose = 'true' ] ; then
  echo
fi
echo "Changing source to \"$newSource\""
sourceIsFifo=false
if [[ $newSource =~ ^/ ]] ; then
  sourceIsFifo=true
fi
sourceIsAlsa=false
if [[ $newSource =~ [0-9],[0-9]$ ]] ; then
  sourceIsAlsa=true
fi
if [ $sourceIsFifo = 'false' ] && [ $sourceIsAlsa = 'false' ] ; then
  echo "${INDENT} source expression not valid"
  exit
fi
                                              # duplicate and comment old source
sedPatternStart="/^source\s*=/"
sudo sed -i "${sedPatternStart}s/^\(.*\)$/#\1\n\1/" $CONFIGURATION_FILE
                                                                 # change source
if [ $sourceIsFifo = 'true' ] ; then
  sourceName=`echo $newSource | sed 's/.*\///'`
  newSourceEscaped=${newSource////\\/}
  sourceSpec="source = pipe:\/\/$newSourceEscaped?name=$sourceName"
fi
if [ $sourceIsAlsa = 'true' ] ; then
  sourceName=`echo $newSource | sed 's/,[0-9],[0-9]$//'`
  sourceSpec="source = alsa:\/\/\/?name=$sourceName\&device=hw:$newSource"
fi
sudo sed -i "${sedPatternStart}s/.*/$sourceSpec/" $CONFIGURATION_FILE
if [ $verbose = 'true' ] ; then
  audioOutputNew=`cat $CONFIGURATION_FILE | grep '^source *='`
  echo "${INDENT}$audioOutputNew"
fi
                                                               # restart service
if [ $restart = 'true' ] ; then
  if [ $verbose = 'true' ] ; then
    echo "Restarting snapserver"
  fi
  sudo service snapserver restart
fi

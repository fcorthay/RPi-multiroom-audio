#!/usr/bin/bash

CONFIGURATION_FILE='/etc/default/snapclient'

INDENT='  '

# ------------------------------------------------------------------------------
# Command line arguments
#
                                                                # default values
newSink=''
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
  newSink=$1
fi

# ------------------------------------------------------------------------------
# Main script
#
                                                      # check configuration file
if [ ! -f $CONFIGURATION_FILE ] ; then
  echo "File \"$CONFIGURATION_FILE\" not found."
  exit
fi
                                                             # find current sink
audioOutputFull=`cat /etc/default/snapclient | grep ^SNAPCLIENT_OPTS=`
audioOutput=`echo $audioOutputFull | sed 's/.*--soundcard\s*//'`
audioOutput=`echo $audioOutput | sed 's/\s.*//'`
audioOutput=`echo $audioOutput | sed 's/"//'`
audioOutput=`echo $audioOutput | sed 's/Loopback/Loopback(,0,0)/'`
echo "Snapclient sink is \"$audioOutput\""
if [ $verbose = 'true' ] ; then
  echo "${INDENT}$audioOutputFull"
fi
if [ -z $newSink ] ; then
  exit
fi
                                                               # check sink name
if [ $verbose = 'true' ] ; then
  echo
fi
echo "Changing sink to \"$newSink\""
sinkIsKnown=`snapclient -l | grep CARD=$newSink`
if [ "${#sinkIsKnown}" -eq 0 ] ; then
  echo "${INDENT} sink name \"$newSink\" not valid"
  exit
fi
                                                # duplicate and comment old sink
lineStart='SNAPCLIENT_OPTS'
sedPatternStart="/^$lineStart\s*=/"
sudo sed -i "${sedPatternStart}s/^\(.*\)$/#\1\n\1/" $CONFIGURATION_FILE
                                                                   # change sink
options=`cat $CONFIGURATION_FILE | grep ^$lineStart | sed -e "s/$lineStart//"`
options=`echo $options | sed -e 's/^\s*=\s*"//'`
options=`echo $options | sed -e 's/"$//'`
options=`echo $options | sed -e 's/\s*--/-/g' | sed -e 's/^-//'`
IFS='-' read -r -a optionArray <<< "$options"
options=''
for option in "${optionArray[@]}" ; do
  key=`echo $option | cut -d ' ' -f 1`
  value=`echo $option | cut -d ' ' -f 2`
  if [ $key == 'soundcard' ] ; then
    value=$newSink
  fi
  if [[ ${#key} -gt 1 ]] ; then
    key="-$key"
  fi
  options="$options -$key $value"
done
options=${options:1}
sudo sed -i "${sedPatternStart}s/\".*\"/\"$options\"/" $CONFIGURATION_FILE
if [ $verbose = 'true' ] ; then
 audioOutputNew=`cat $CONFIGURATION_FILE | grep ^SNAPCLIENT_OPTS`
 echo "${INDENT}$audioOutputNew"
fi
                                                               # restart service
if [ $restart = 'true' ] ; then
  sudo service snapclient restart
fi

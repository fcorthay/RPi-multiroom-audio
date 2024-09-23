#!/usr/bin/bash

CONFIGURATION_FILE='/etc/mopidy/mopidy.conf'

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
audioOutputFull=`cat $CONFIGURATION_FILE | grep ^output`
audioOutput=`echo $audioOutputFull | grep ^output | sed 's/.*device=//'`
audioOutput=`echo $audioOutput | sed 's/.*location=//'`
echo "Mopidy sink is \"$audioOutput\""
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
sinkIsFifo=false
if [[ $newSink =~ ^/ ]] ; then
  sinkIsFifo=true
fi
sinkIsAlsa=false
if [[ $newSink =~ [0-9],[0-9]$ ]] ; then
  sinkIsAlsa=true
fi
if [ $sinkIsFifo = 'false' ] && [ $sinkIsAlsa = 'false' ] ; then
  echo "${INDENT} sink expression not valid"
  exit
fi
                                                # duplicate and comment old sink
sed -i '/^output\s*=/s/^\(.*\)$/#\1\n\1/' $CONFIGURATION_FILE
                                                                   # change sink
sed -i '/^output\s*=/s/ location\s*\=/ sink=/' $CONFIGURATION_FILE
sed -i '/^output\s*=/s/ device\s*\=/ sink=/' $CONFIGURATION_FILE
newSinkEscaped=${newSink////\\/}
sed -i "/^output\s*=/s/\(sink\s*=\s*.*\)\(\s\|$\)/sink=$newSinkEscaped/" \
  $CONFIGURATION_FILE
                                                              # change sink type
if [ $sinkIsFifo = 'true' ] ; then
  sed -i '/^output\s*=/s/ alsasink / filesink /' $CONFIGURATION_FILE
  sed -i '/^output\s*=/s/ sink=/ location=/' $CONFIGURATION_FILE
fi
if [ $sinkIsAlsa = 'true' ] ; then
  sed -i '/^output\s*=/s/ filesink / alsasink /' $CONFIGURATION_FILE
  sed -i '/^output\s*=/s/ sink=/ device=dmix:/' $CONFIGURATION_FILE
fi
if [ $verbose = 'true' ] ; then
  audioOutputNew=`cat $CONFIGURATION_FILE | grep ^output`
  echo "${INDENT}$audioOutputNew"
fi
                                                               # restart service
if [ $restart = 'true' ] ; then
  if [ $verbose = 'true' ] ; then
    echo "Restarting mopidy"
  fi
  sudo service mopidy restart
fi

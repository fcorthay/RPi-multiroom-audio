#!/usr/bin/bash

CONFIGURATION_FILES=(
  "$CAMILLA_CONFIGURATIONS_DIR/stereo2mono.yaml"
  "$CAMILLA_CONFIGURATION_FILE"
)

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
configurationFile=''
for fileSpec in "${CONFIGURATION_FILES[@]}" ; do
  if [ -f $fileSpec ] ; then
    configurationFile=$fileSpec
  fi
done
if [ -z $configurationFile ] ; then
  echo 'No configuration file found.'
  exit 1
fi
if [ $verbose = 'true' ] ; then
  echo "Reading info from \"$configurationFile\""
fi
                                                           # find current source
captureDevice=`yq '.devices.capture.device' $configurationFile | tr -d '"'`
if [ $verbose = 'true' ] ; then
  echo "${INDENT}current CamillaDSP source is \"$captureDevice\""
else
  echo $captureDevice
fi
if [ -z $newSource ] ; then
  exit
fi
                                                             # check source name
if [ $verbose = 'true' ] ; then
  echo
fi
echo "Changing source to \"$newSource\""
sourceDevice=`echo $newSource | sed 's/.*://' | sed 's/,.*//'`
source=`aplay -l | grep ^card | grep $sourceDevice`
source=`echo $source | cut -d ' ' -f 3`
if [ -z $source ] ; then
  echo "${INDENT} error : device \"$sourceDevice\" unknown"
  exit 1
fi
                                                                 # change source
sed -i -e "s/$captureDevice/$newSource/" $configurationFile
                                                               # restart service
if [ $restart = 'true' ] ; then
  sudo service camilladsp restart
fi

#!/usr/bin/bash

# ------------------------------------------------------------------------------
# Constants
#
INDENT='  '

# ------------------------------------------------------------------------------
# Command line arguments
#
                                                                # default values
command=''
verbose=false
                                                             # specify arguments
arguments='vh'
declare -A longArguments
longArguments=(["v"]="verbose" ["h"]="help")
                                                             # show script usage
usage() {
  echo "Usage: $(basename "$0") [-v|--verbose] command" 1>&2 
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
    v) verbose=true ;;
    h) usage ;;
    ?) usage
  esac
done
shift $((OPTIND-1))

if [ -n "$1" ] ; then
  command=`echo $1 | tr '[:upper:]' '[:lower:]'`
else
  echo 'No command provided.'
  exit
fi

# ------------------------------------------------------------------------------
# Main script
#
if [ $verbose = 'true' ] ; then
  echo "Sending \"$command\" command"
fi

if [ $command = 'play' ] ; then
  bluetoothctl player.play
elif [ $command = 'pause' ] ; then
  bluetoothctl player.pause
elif [ $command = 'status' ] ; then
  status=`playerctl status`
  echo "${INDENT}$status"
fi

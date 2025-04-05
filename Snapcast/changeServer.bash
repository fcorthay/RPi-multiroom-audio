#!/usr/bin/bash

# ------------------------------------------------------------------------------
# Constants
#
INDENT='  '

# ------------------------------------------------------------------------------
# Command line arguments
#
                                                                # default values
snapServer='localhost'
verbose=false
                                                             # specify arguments
arguments='s:vh'
declare -A longArguments
longArguments=(["s"]="server" ["v"]="verbose")
                                                             # show script usage
usage() {
  echo "Usage: $(basename "$0") [-v|--verbose] server" 1>&2 
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
    s) snapServer="$OPTARG" ;;
    v) verbose=true ;;
    h) usage ;;
    ?) usage
  esac
done
shift $((OPTIND-1))

if [ -n "$1" ] ; then
  snapServer=$@
fi

# ------------------------------------------------------------------------------
# Main script
#
if [ $verbose = 'true' ] ; then
  echo "Changing to Snapcast server \"$snapServer\""
fi
sudo sed -i -E "s/(^[^#].*)--host [^ ]*/\1--host $snapServer/" /etc/default/snapclient
sudo service snapclient restart

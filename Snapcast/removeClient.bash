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
snapClient='00:00:00:00:00:00'
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
  snapClient=$@
fi

# ------------------------------------------------------------------------------
# Main script
#
if [ $verbose = 'true' ] ; then
  echo "Removing client \"$snapClient\" from server \"$snapServer\""
fi

RPC_START='curl -s -d '\''{"jsonrpc": "2.0", "id": 1, "method": "'
PARAMETERS_START='", "params": {'
RPC_END='}}'\'' -H '\''Content-Type: application/json'\'''
RPC_END=`echo "$RPC_END http://localhost:1780/jsonrpc | jq"`
procedure='Server.DeleteClient'
parameters="\"id\":\"$snapClient\""

COMMAND="$RPC_START$procedure$PARAMETERS_START$parameters$RPC_END"
if [ $verbose = 'true' ] ; then
  echo $COMMAND
fi
eval $COMMAND

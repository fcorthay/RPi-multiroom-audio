#!/usr/bin/bash

# ------------------------------------------------------------------------------
# Constants
#
INDENT='  '

# ------------------------------------------------------------------------------
# Command line arguments
#
                                                                # default values
mopidyServer='localhost'
command=''
context='playback'
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
    s) mopidyServer="$OPTARG" ;;
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
if [ -n "$2" ] ; then
  context=$2
fi

# ------------------------------------------------------------------------------
# Main script
#
if [ $verbose = 'true' ] ; then
  echo "Setting \"$context\" to \"$command\""
fi

RPC_START='curl -s -d '\''{"jsonrpc": "2.0", "id": 1, "method": "core.'
RPC_END='"}'\'' -H '\''Content-Type: application/json'\'''
RPC_END=`echo "$RPC_END http://$mopidyServer:6680/mopidy/rpc"`
procedure="$context.$command"

COMMAND="$RPC_START$procedure$RPC_END"
if [ $verbose = 'true' ] ; then
  echo $COMMAND
  eval $COMMAND
  echo
else
  eval $COMMAND >/dev/null
fi

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
volume=''
verbose=false
                                                             # specify arguments
arguments='s:vh'
declare -A longArguments
longArguments=(["s"]="server" ["v"]="verbose")
                                                             # show script usage
usage() {
  echo "Usage: $(basename "$0") [-s|--server server] [-v|--verbose] volume" 1>&2
  echo "${INDENT}volume can be:" 1>&2
  echo "${INDENT}${INDENT}- a number between 0 and 100" 1>&2
  echo "${INDENT}${INDENT}- mute" 1>&2
  echo "${INDENT}${INDENT}- unmute" 1>&2
  echo "${INDENT}if it is not provided, the script queries the volume" 1>&2
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
  volume=$1
fi

# ------------------------------------------------------------------------------
# Main script
#
                                                 # prepare remote procedure call
RPC_START='curl -s -d '\''{"jsonrpc": "2.0", "id": 1, "method": "core.mixer.'
RPC_PARAM_START='", "params": ['
RPC_PARAM_END=']}'\'''
RPC_COMMAND_END='"}'\'''
RPC_END=' -H '\''Content-Type: application/json'\'''
RPC_END=`echo "$RPC_END http://$mopidyServer:6680/mopidy/rpc"`
                                                                    # get volume
if [ -z "$volume" ] ; then
  if [ $verbose = 'true' ] ; then
    echo 'Getting volume'
    echo -n "${INDENT}volume is "
  fi
  procedure='get_volume'
  RPC_COMMAND="$RPC_START$procedure$RPC_COMMAND_END$RPC_END"
#  echo $RPC_COMMAND
  volume=`eval $RPC_COMMAND`
  volume=`echo $volume | sed s/.*result// | sed s/.*://`
  volume=`echo $volume | sed s/,.*// | sed s/}.*//`
  echo $volume
else
                                                          # prepare mute command
  if [ "${volume,,}" = 'mute' ] ; then
    if [ $verbose = 'true' ] ; then
      echo "Muting Mopidy"
    fi
    procedure='set_mute'
    value='true'
                                                        # prepare unmute command
  elif [ "${volume,,}" = 'unmute' ] ; then
    if [ $verbose = 'true' ] ; then
      echo "Unmuting Mopidy"
    fi
    procedure='set_mute'
    value='false'
                                                        # prepare volume command
  else
    if [ $verbose = 'true' ] ; then
      echo "Setting volume to $volume%"
    fi
    procedure='set_volume'
    value=$volume
  fi
                                                               # execute command
  RPC_COMMAND="$RPC_START$procedure$RPC_PARAM_START$value$RPC_PARAM_END$RPC_END"
#  echo $RPC_COMMAND
  eval $RPC_COMMAND >/dev/null
fi

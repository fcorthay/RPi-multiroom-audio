#!/usr/bin/env python3
import argparse
from camilladsp import CamillaClient
import sys
import time

# ------------------------------------------------------------------------------
# Constants
#
INDENT = 2*' '

# ------------------------------------------------------------------------------
# command line arguments
#
                                                             # specify arguments
parser = argparse.ArgumentParser(
  description='set CamillaDSP volume'
)
                                                                        # volume
parser.add_argument(
    'volume', nargs='?', default=0,
    help = 'audio volume'
)
                                                                   # server name
parser.add_argument(
    '-s', '--server', default='localhost',
    help = 'server name'
)
                                                                          # port
parser.add_argument(
    '-p', '--port', default=5005,
    help = 'control port'
)
                                                                # verbose output
parser.add_argument(
    '-v', '--verbose', action='store_true',
    help = 'Verbose display'
)
                                                             # process arguments
parser_arguments = parser.parse_args()

set_volume = True
if parser_arguments.volume :
    volume = float(parser_arguments.volume)
else :
    set_volume = False
control_port = parser_arguments.port
server_name = parser_arguments.server

verbose = parser_arguments.verbose

# ------------------------------------------------------------------------------
# Main
#
if verbose:
    print('Setting CamillaDSP volume')
    print(INDENT + "server       : %s" % server_name)
    print(INDENT + "control port : %d" % control_port)
    print()
                                                          # connect to websocket
camillaDSP_client = CamillaClient(server_name, control_port)
camillaDSP_client.connect()
                                                                    # get volume
current_volume = camillaDSP_client.volume.main_volume()
if verbose or (not set_volume):
    print("Current volume is %g dB" % current_volume)
                                                                    # set volume
if set_volume :
    print("Setting volume to %g dB" % volume)
    camillaDSP_client.volume.set_main_volume(volume)
                                                     # disconnect from websocket
camillaDSP_client.disconnect()

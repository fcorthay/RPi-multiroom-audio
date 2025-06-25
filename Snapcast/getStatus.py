#!/usr/bin/env python3
import argparse
import json
import requests
import uuid

# ------------------------------------------------------------------------------
# Constants
#
INDENT = 2*' '

# ------------------------------------------------------------------------------
# command line arguments
#
                                                             # specify arguments
parser = argparse.ArgumentParser(
  description='get snapserver status'
)
                                                                   # server name
parser.add_argument(
    '-s', '--server', default='localhost',
    help = 'server name'
)
                                                                  # control port
parser.add_argument(
    '-p', '--port', default=1780,
    help = 'JSON control port'
)
                                                                # verbose output
parser.add_argument(
    '-v', '--verbose', action='store_true',
    help = 'Verbose display'
)
                                                             # process arguments
parser_arguments = parser.parse_args()

snap_server_name = parser_arguments.server
snap_server_port = parser_arguments.port
verbose = parser_arguments.verbose

# ------------------------------------------------------------------------------
# Main
#
                                                        # find local MAC address
MAC_address = "%X" % uuid.getnode()
MAC_address = ':'.join(
    [MAC_address[i:i+2] for i in range(0, len(MAC_address), 2)]
)
                                                        # basic request elements
url = "http://%s:%d/jsonrpc" % (snap_server_name, snap_server_port)
request_id = 0
payload = {'jsonrpc': '2.0', 'id': request_id}
                                                                    # set method
payload['method'] = 'Server.GetStatus'
                                                                  # send request
try :
    response = requests.post(url, data=json.dumps(payload)).json()
except :
    print("No response from SnapServer on %s" % snap_server_name)
    quit()
request_id = request_id + 1
                                                                 # print results
print('Clients:')
groups_info = response['result']['server']['groups']
for group_info in groups_info :
    for client_info in group_info['clients'] :
        comment = ''
        client_name = client_info['host']['name']
        client_id = client_info['id']
        client_MAC_address = client_info['host']['mac']
        if client_MAC_address.lower() == MAC_address.lower() :
            comment = ', localhost'
        client_OS = client_info['host']['os']
        if client_OS.startswith('Android') or client_OS.startswith('iOS') :
            comment = ', mobile'
        print(INDENT + "%s (%s%s)" % (client_name, client_id, comment))
        client_muted_staus = client_info['config']['volume']['muted']
        print(2*INDENT + "muted  : %s" % client_muted_staus)
        client_volume = client_info['config']['volume']['percent']
        print(2*INDENT + "volume : %s%%" % client_volume)

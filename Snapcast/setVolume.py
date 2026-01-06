#!/usr/bin/env python3
import argparse
import json
import requests

# ------------------------------------------------------------------------------
# Constants
#
INDENT = 2*' '

# ------------------------------------------------------------------------------
# command line arguments
#
                                                             # specify arguments
parser = argparse.ArgumentParser(
  description='set snapclient volume'
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
                                                                  # control port
parser.add_argument(
    '-p', '--port', default=1780,
    help = 'JSON control port'
)
                                                                # snap client id
parser.add_argument(
    '-c', '--client', default='00:00:00:00:00:00',
    help = 'Snap client id'
)
                                                                # verbose output
parser.add_argument(
    '-v', '--verbose', action='store_true',
    help = 'Verbose display'
)
                                                             # process arguments
parser_arguments = parser.parse_args()

client_id = parser_arguments.client
volume = int(parser_arguments.volume)
snap_server_name = parser_arguments.server
snap_server_port = parser_arguments.port
verbose = parser_arguments.verbose

# ------------------------------------------------------------------------------
# Main
#
                                                        # basic request elements
url = "http://%s:%d/jsonrpc" % (snap_server_name, snap_server_port)
request_id = 0
payload = {'jsonrpc': '2.0', 'id': request_id}
                                              # change hostname to snapserver id
payload['method'] = 'Server.GetStatus'
response = requests.post(url, data=json.dumps(payload)).json()
request_id = request_id + 1
groups_info = response['result']['server']['groups']
client_ids = {}
for group_info in groups_info :
#    print(group_info)
    for client_info in group_info['clients'] :
        client_info_id = client_info['id']
        client_name = client_info['host']['name']
        client_ids[client_info_id] = client_name
        if client_name.lower() == client_id.lower() :
            client_id = client_info_id
                                                                    # set method
if volume :
    payload['method'] = 'Client.SetVolume'
    parameters = {}
    parameters['id'] = client_id
    parameters['volume'] = {'muted':False, 'percent':volume}
    if volume == 0 :
        parameters['volume'] = {'muted':True}
    payload['params'] = parameters
else :
    payload['method'] = 'Client.GetStatus'
    parameters = {}
    parameters['id'] = client_id
    payload['params'] = parameters
                                                                  # send request
response = requests.post(url, data=json.dumps(payload)).json()
request_id = request_id + 1

if 'error' in response :
#    print(response)
    print("Error : %s" % response['error']['message'], end='')
    if 'data' in response['error'] :
        response_data = response['error']['data']
        print(" \"%s\"" % response_data)
        if response_data == 'Client not found' :
            print(INDENT + 'specify client with "-c" out of:')
            for client_id, client_name in client_ids.items():
                print(2*INDENT + "%s (%s)" % (client_name, client_id))
    else :
        print()
                                                                    # print info
else :
    if volume :
        status = response['result']
    else :
        status = response['result']['client']['config']
    status_muted = status['volume']['muted']
    status_volume = status['volume']['percent']
    if verbose or (not volume) :
        print("muted  : %s" % status_muted)
        print("volume : %s%%" % status_volume)

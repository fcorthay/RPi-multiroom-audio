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
  description='get snapserver status'
)
                                                                # snap client id
parser.add_argument('client')
                                                                        # volume
parser.add_argument('volume')
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

client_id = parser_arguments.client
volume = int(parser_arguments.volume)
sanp_server_name = parser_arguments.server
sanp_server_port = parser_arguments.port
verbose = parser_arguments.verbose

# ------------------------------------------------------------------------------
# Main
#
                                                        # basic request elements
url = "http://%s:%d/jsonrpc" % (sanp_server_name, sanp_server_port)
request_id = 0
payload = {'jsonrpc': '2.0', 'id': request_id}
                                                                    # set method
payload['method'] = 'Client.SetVolume'
parameters = {}
parameters['id'] = client_id
parameters['volume'] = {'muted':False, 'percent':volume}
if volume == 0 :
    parameters['volume'] = {'muted':True}
payload['params'] = parameters
                                                                  # send request
response = requests.post(url, data=json.dumps(payload)).json()
request_id = request_id + 1
search_for_id = False
if 'error' in response :
    search_for_id = True
                                                                    # print info
else :
    if verbose :
        print("muted  : %s" % response['result']['volume']['muted'])
        print("volume : %s%%" % response['result']['volume']['percent'])
                                                                 # search for id
if search_for_id :
    if verbose :
        print('Searching for client id')
    client_name = client_id
    client_id = ''
                                                                    # set method
    payload['method'] = 'Server.GetStatus'
    payload.pop('params', None)
                                                                 # search for id
    response = requests.post(url, data=json.dumps(payload)).json()
    request_id = request_id + 1
#    print(response)
    groups_info = response['result']['server']['groups']
    for group_info in groups_info :
        for client_info in group_info['clients'] :
            client_info_name = client_info['host']['name']
            if client_info['host']['name'].lower() == client_name.lower() :
                client_id = client_info['id']
    if client_id :
        if verbose :
            print(
                INDENT + "client \"%s\" has id \"%s\"" %
                (client_name, client_id)
            )
                                                                    # set method
        payload['method'] = 'Client.SetVolume'
        parameters['id'] = client_id
        payload['params'] = parameters
                                                                  # send request
        response = requests.post(url, data=json.dumps(payload)).json()
        request_id = request_id + 1
        if 'error' in response :
            print("error")
                                                                    # print info
        else :
            if verbose :
                print(
                    2*INDENT + "muted  : %s" %
                    response['result']['volume']['muted']
                )
                print(
                    2*INDENT + "volume : %s%%" %
                    response['result']['volume']['percent']
                )
    else :
        if verbose :
            print("client not found")

#!/usr/bin/env python3
import os
import subprocess
import argparse
import json
import requests

# ------------------------------------------------------------------------------
# Constants
#
INDENT = 2*' '

script_path = os.path.dirname(os.path.realpath(__file__))
script_run = subprocess.Popen(
    ['bash', script_path+'/clientSource.bash'],
    stdout=subprocess.PIPE, stderr=subprocess.STDOUT
)
snap_server = script_run.communicate()[0].decode()
snap_server = snap_server[snap_server.find('"')+1:]
snap_server = snap_server[:snap_server.find('"')]

# ------------------------------------------------------------------------------
# command line arguments
#
                                                             # specify arguments
parser = argparse.ArgumentParser(
  description='set snapclient volume'
)
                                                                        # volume
parser.add_argument('volume', nargs='?')
                                                                # snap client id
parser.add_argument(
    '-c', '--client', default=os.uname().nodename,
    help = 'client name'
)
                                                                   # server name
parser.add_argument(
    '-s', '--server', default=snap_server,
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

get_volume = True
if parser_arguments.volume :
    volume = int(parser_arguments.volume)
    get_volume = False

client_id = parser_arguments.client
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
                                                                    # set method
if get_volume :
    payload['method'] = 'Client.GetStatus'
    parameters = {}
    parameters['id'] = client_id
else :
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
    sub_response = response['result']
    if get_volume :
        sub_response = sub_response['client']['config']
    muted = sub_response['volume']['muted']
    volume = sub_response['volume']['percent']
    if verbose :
        print("muted  : %s" % muted)
        print("volume : %s%%" % volume)
    elif get_volume :
        print(volume)
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
        if get_volume :
            payload['method'] = 'Client.GetStatus'
            parameters['id'] = client_id
            payload['params'] = parameters
        else :
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
            sub_response = response['result']
            if get_volume :
                sub_response = sub_response['client']['config']
            muted = sub_response['volume']['muted']
            volume = sub_response['volume']['percent']
            if verbose :
                print(2*INDENT + "muted  : %s" % muted)
                print(2*INDENT + "volume : %s%%" % volume)
            elif get_volume :
                print(volume)
    else :
        if verbose :
            print("client not found")

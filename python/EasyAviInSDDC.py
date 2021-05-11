#!/usr/bin/env python3

import requests                         # need this for Get/Post/Delete
import sys
import json
import os

strProdURL      = 'https://vmc.vmware.com'
strCSPProdURL   = 'https://console.cloud.vmware.com'
Refresh_Token   = sys.argv[1]
ORG_ID          = sys.argv[2]
SDDC_ID         = sys.argv[3]

def getAccessToken(myKey):
    """ Gets the Access Token using the Refresh Token """
    params = {'refresh_token': myKey}
    headers = {'Content-Type': 'application/json'}
    response = requests.post('https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/authorize', params=params, headers=headers)
    jsonResponse = response.json()
    access_token = jsonResponse['access_token']
    return access_token

def getNSXTproxy(org_id, sddc_id, sessiontoken):
    """ Gets the Reverse Proxy URL """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = "{}/vmc/api/orgs/{}/sddcs/{}".format(strProdURL, org_id, sddc_id)
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    proxy_url = json_response['resource_config']['nsx_api_public_endpoint_url']
    return proxy_url

def checkEasyAviLocation(proxy_url, sessiontoken):
    """ Gets the SDDC Networks """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/api/v1/fabric/vifs")
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    if any(vm['mac_address'] == os.environ.get('HOST_MAC') for vm in json_response['results']):
            print('{"EasyAviInSDDC": true}')
    else:
            print('{"EasyAviInSDDC": false}')

session_token = getAccessToken(Refresh_Token)
proxy = getNSXTproxy(ORG_ID, SDDC_ID, session_token)
checkEasyAviLocation(proxy, session_token)

#!/bin/bash
#
# This script automatically selects an ovpn file to be used with openvpn.
# It uses the filters passed by the user as arguments to narrow the selection.
# The file to be used is chosen at random from the list of files that passed by the filter.
# If no filter is provided, then one file is chosen at random from all of the available ovpn files.

VPNFOLDER="/home/odysseus/Documents/Study/Infosec/ProtonVPN"
VPNPREFIX="protonvpn"

if [[ $# -eq 0 ]]; then
        echo "No filter provided. Randomizing all available ovpn files..."
        ovpnfile=$(/bin/ls $VPNFOLDER/*$VPNPREFIX* | shuf -n1)
        echo "Got VPN file: $ovpnfile"
        echo "Connecting..."
        openvpn $ovpnfile
else
        echo "Got some filters. Working..."
        ovpnfiles=$(/bin/ls $VPNFOLDER/*$VPNPREFIX* | tr ' ' '\n')
        for filter in "$@"; do
                ovpnfiles=$(echo $ovpnfiles | grep -i $filter)
                if [[ $? -ne 0 ]]; then
                        echo "Filter $filter not found. Please, provide valid filters"
                        exit 1
                fi
        done
        ovpnfile=$(echo $ovpnfiles | shuf -n1)
        echo "Got VPN file: $ovpnfile"
        echo "Connecting..."
        openvpn $ovpnfile
fi

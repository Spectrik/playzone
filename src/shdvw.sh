#!/bin/bash

# TODO: Create hostapd conf file
# TODO: Create dnsmasq conf file
# TODO: Parse the details about the network. Only the WEP/WPA/WPA2 part - possibly better solution
# TODO: Disconnect the clients from spoofed wifi so they can connect to ours
# TODO: Check if interface card supports 5GHz
# TODO: Non-reproducer mode. Just set up an access point
# TODO: Arguments:
# --clone
# --disconnect
# 

# Vars init
CONF_FILE="../conf/shdvw.conf" ### This var only for debugging
WIFI_NOT_FOUND=0

# Set magic variables for current file & dir
__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__FILE="${__DIR}/$(basename "${BASH_SOURCE[0]}")"
__BASE="$(basename ${__FILE} .sh)"

# Exit on error
set -e

# Exit on use of undeclared variable
# set -u

# Source files with functions
if [ -e "./functions.sh" ]; then
    source functions.sh
else
    echo "Functions file was not found"
    exit 1
fi

# Show help
if [ $# -eq 0 ]; then
    show_help
fi

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    show_help
fi
    
# Include conf file
if ! [ -e "/etc/shdvw/shdvw.conf" ]; then
    if [ $# -eq 0 ]; then
        x_msg "You need to provide the path to the configuration file!" 1
    fi
else
    source "/etc/shdvw/shdvw.conf"
fi

source "$1"

# Check for PID file
if [ -e "${PIDFILE}" ]; then
    x_msg "It seems this program is already running?" 1
fi

# Check for root privs
is_root

# Send info
x_msg "> Running pre-checks..."

# Check for installed software
is_installed hostapd || ( echo "It seems hostapd is not installed!"; exit 1 )
is_installed dnsmasq || ( echo "It seems dnsmasq is not installed!"; exit 1 )
is_installed iwlist || ( echo "It seems iwlist is not installed!"; exit 1 )
is_installed ip || ( echo "It seems ip utility is not installed!"; exit 1 )

# Write PID file
PID=$(echo $$)

if ! [ -e /var/run/shdvw ] && [ -d /var/run/shdvw ]; then
    rm /var/run/shdvw
fi

if ! [ -e /var/run/shdvw ]; then
    mkdir /var/run/shdvw
fi

echo "${PID}" > "${PIDFILE}"

# Check if the wlan interface to work on exists
if ! ls /sys/class/net | grep -q "${INTERFACE}"; then
    x_msg "Interface ${INTERFACE} was not found on this machine!" 1
fi

# Check for network manager
if ps -ef | grep -i -q "networkmanager"; then
    x_msg "Hostapd collides with network manager. Stop & disable it first."
fi

# Make sure the interface is up
ip link set dev "${INTERFACE}" up

x_msg "Checking for available networks..."

# Check if the supposed network is present nearby
for I in {1..5}
do
    if ! iwlist "${INTERFACE}" scan | grep -i -q "${SSID}"; then
        WIFI_NOT_FOUND=1
    else
        WIFI_NOT_FOUND=0
    fi

    echo "."
done

# If network was not found
if [ ${WIFI_NOT_FOUND} -eq 1 ]; then
    x_msg "It seems there is no wi-fi with SSID: ${SSID} around! Maybe it is because the interface card does not support 5GHz?" 1
fi

### Get the network details
x_msg "Gathering info about the network ${SSID} for our spoofer..."

# Get the BSSID - TODO: FIX THE GREP - ASUS ASUS_5G
AP_ADDRESS=$(iwlist "${INTERFACE}" scan | egrep -i "${SSID}\"$" -C5 | egrep -i -o "Address: .*" | cut -d " " -f 2)

if [ -z "${AP_ADDRESS}" ]; then
    x_msg "AP Info empty!" 1
fi

# Gather data about the network. Put it to temporary file
iwlist "${INTERFACE}" scan | grep "${AP_ADDRESS}" -A29 > "${TMPFILE_PATH}"

### Parse the temp file for network details

# Get the channel
AP_CHANNEL=$(egrep "Channel:.*" ${TMPFILE_PATH} | cut -d ":" -f 2)

# Get the frequency
if egrep -q -i -o "Frequency.*:2.4" ${TMPFILE_PATH}; then
    AP_HWMODE="b"
else
    AP_HWMODE="ad"
fi

# Get the encryption details (WEP?, WPA, WPA2. TKIP, AES, TKIP+AES)
# CCMP = AES
AP_CIPHERS=$(egrep -i -o "Group Cipher.*" ${TMPFILE_PATH} | cut -d ":" -f 2)

# Here the order of grep is important. Or fix the regex :))
if grep "WPA" ${TMPFILE_PATH}; then
    AP_ENCRYPTION="WPA"
fi

if grep "WPA2" ${TMPFILE_PATH}; then
    AP_ENCRYPTION="WPA2"
fi

# Remove the temp file
rm "${TMPFILE_PATH}"

# Configure hostapd
x_msg "> Creating hostapd configuration file..."
create_hostapd_conf "${INTERFACE}" "${SSID}" "${AP_HWMODE}" "${AP_CHANNEL}" "${AP_ENCRYPTION}" "${AP_CIPHERS}" "${WIFI_PASS}"

# Configure dnsmasq
x_msg "> Creating dnsmasq configuration file..."

# Starting hostapd
x_msg "> Starting hostapd..."

# Starting dnsmasq
x_msg "> Starting dnsmasq..."



# Define trap

# TODO: Remove PID, stop hostapd and dnsmasq on exit
trap "rm ${PIDFILE}; kill ${HOSTAPD_PID}; kill ${DNSMASQ_PID} exit" EXIT SIGQUIT SIGINT SIGSTOP SIGTERM ERR

sleep 15

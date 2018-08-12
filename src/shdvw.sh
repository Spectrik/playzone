#!/bin/bash

# TODO: Create hostapd conf file
# TODO: Create dnsmasq conf file
# TODO: Parse the details about the network
# TODO: Disconnect the clients from spoofed wifi so they can connect to ours
# Configure hostapd, dnsmasq

# Vars init
CONF_FILE="../conf/shdvw.conf" ### This var only for debugging
HOSTAPD_CONF_FILE="./hostapd.conf"
DNSMASQ_CONF_FILE="./dnsmasq.conf"
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
is_installed iwlist || ( echo "It seems iwlist is not installed!"; exit 1 ) 1 )
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
ip link set dev "${INTERFACE} up"

x_msg "Checking for available networks..."

# Check if the supposed network is present nearby
for I in {1..5}
do
    if ! iwlist "${INTERFACE}" scan | grep -i -q "${SSID}"; then
        WIFI_NOT_FOUND=1
    else
        WIFI_NOT_FOUND=0
    fi

    echo ".."
done

# If network was not found
if [ ${WIFI_NOT_FOUND} -eq 1 ]; then
    x_msg "It seems there is no wi-fi with SSID: ${SSID} around! Maybe it is because the interface card does not support 5GHz?" 1
fi

### Get the network details
x_msg "Gathering info about the network for our spoofer..."

# Get the BSSID
AP_ADDRESS=$(iwlist "${INTERFACE}" scan | grep -i "${SSID}" -C5 | egrep -i -o "Address: .*" | cut -d " " -f 2)

if [ -z "${AP_ADDRESS}" ]; then
    x_msg "AP Info empty!" 1
fi

# Gather data about the network. Put it to temporary file
iwlist "${INTERFACE}" scan | grep "${AP_ADDRESS}" -A29 > "${TMPFILE_PATH}"

# Parse the temp file for network details
AP_FREQUENCY=""
AP_CHANNEL=""
AP_ENCRYPTION=""

# Configure hostapd
x_msg "> Creating hostapd configuration file..."

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

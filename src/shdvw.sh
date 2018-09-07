#!/bin/bash

# TODO: Custom dns entries - hosts to spoof
# TODO: Parse the details about the network. Only the WEP/WPA/WPA2 part - possibly better solution
# TODO: Disconnect the clients from spoofed wifi so they can connect to ours
# TODO: Check if interface card supports 5GHz - wifi 'ad' mode
# TODO: Provide internet connection via second wireless interface (ip_forward, masquerading, default_gw)
# TODO: Non-reproducer mode. Just set up an access point
# TODO: Logging
# TODO: Write help
# TODO: Fix the traps

# Vars init
WIFI_NOT_FOUND=0
CLONE_AP=0
DISCONNECT=0
USE_DHCP=0

# Set magic variables for current file & dir
__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__FILE="${__DIR}/$(basename "${BASH_SOURCE[0]}")"
__BASE="$(basename ${__FILE} .sh)"

# Only for debugging
# set -o xtrace

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

# Check for root privs
is_root

# Show help
if [ $# -eq 0 ]; then
    show_help
fi

# First arg is positional arg - conf file. No options allowed
if $(echo $1 | grep -q "-"); then
    x_msg "First argument is path to the configuration file. No options allowed" 1
fi

# Include conf file
if [ $# -eq 0 ]; then
    x_msg "You need to provide the path to the configuration file!" 1
fi

if ! [ -e "$1" ]; then
    x_msg "File \"$1\" does not exist!" 1
fi

source "$1"

### Arg parsing. $1 is positional argument - the configuration file. So shift it away.
shift
 
OPTS=$(getopt -o h --long help,clone,dhcp,disconnect,kill -n 'parse-options' -- "$@")

if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

# Set the options
eval set -- "$OPTS"

while true; do
  case "$1" in
    --clone)
        CLONE_AP=1
        shift
    ;;
    
    --kill)
        killall "hostapd" && killall "dnsmasq" || killall "dnsmasq"
        exit 0
    ;;

    -h | --help)
        show_help
        exit 0
    ;;
    
    --dhcp) 
        USE_DHCP=1
        shift
    ;;
    
    --disconnect)
        DISCONNECT=1
        shift
    ;;

    --)
    shift
    break
    ;;
    
    *)
    break
    ;;
  esac
done

# Check for PID file
if [ -e "${PIDFILE}" ]; then
    x_msg "It seems this program is already running?" 1
fi

# Send info
x_msg "> Running pre-checks..."

# Check for installed software
is_installed hostapd || ( echo "It seems hostapd is not installed!"; exit 1 )
is_installed dnsmasq || ( echo "It seems dnsmasq is not installed!"; exit 1 )
is_installed iwlist || ( echo "It seems iwlist is not installed!"; exit 1 )
is_installed ip || ( echo "It seems ip utility is not installed!"; exit 1 )

# TODO: Check for any other dnsmasq or hostapd processes - FIX THIS
if $(ps -ef | egrep -q "dnsmasq|hostapd"); then
    x_msg "It seems that there are already some processes of hostapd or dnsmasq running. You might want to run this script with --kill option first" 1
fi

### Write PID file
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
    x_msg "WARNING: Hostapd might collide with network manager service. If it does, stop & disable it first."
fi

# Make sure the interface is up
if ! ip link set dev "${INTERFACE}" up; then
    x_msg  "There was a problem when setting the interface to UP status!"
fi

############# ACCESS POINT CLONING PART STARTS ################
if [ "${CLONE_AP}" -eq 1 ]; then

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

    # Get data about the network. Put it to temporary file
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
    AP_CIPHERS=$(egrep -i -o "Group Cipher.*" ${TMPFILE_PATH} | cut -d ":" -f 2 | tr -d '[:space:]')

    # Here the order of greps is important. Or fix the regex :))
    if grep -q "WPA" ${TMPFILE_PATH}; then
        AP_ENCRYPTION="WPA"
    fi

    if grep -q "WPA2" ${TMPFILE_PATH}; then
        AP_ENCRYPTION="WPA2"
    fi

    ############# ACCESS POINT CLONING PART ENDS ###############
else
    # Create just an access point

    if [ -z "${AP_CHANNEL}" ] || [ -z "${AP_HWMODE}" ] || [ -z "${AP_ENCRYPTION}" ] || [ -z "${AP_CIPHERS}" ]; then
        x_msg "Missing configuration options for setting up the access point!" 1
    fi
fi

# If type of encryption is not WEP, we always need the password
if [ "${AP_ENCRYPTION}" != "WEP" ]; then
    
    if [ -z "${WIFI_PASS}" ]; then
        x_msg "Wifi password must not be empty!" 1
    fi

    # Check the length of password
    if [ ${#WIFI_PASS} -lt 8 ]; then
        x_msg "Wifi password has to be at least 8 chars in length!" 1
    fi
fi

# Delete this - just for debugging
echo "${AP_CIPHERS}"
echo "${AP_ENCRYPTION}"

# Remove the temp file
if [ -e "${TMPFILE_PATH}" ]; then
    rm "${TMPFILE_PATH}"
fi

# Configure hostapd
x_msg "> Creating hostapd configuration file..."
create_hostapd_conf "${INTERFACE}" "${SSID}" "${AP_HWMODE}" "${AP_CHANNEL}" "${AP_ENCRYPTION}" "${AP_CIPHERS}" "${WIFI_PASS}"

# Configure dnsmasq
x_msg "> Creating dnsmasq configuration file..."
create_dnsmasq_conf "${DHCP_IP_RANGE}" "${INTERFACE}"

# sleep 150

# Starting hostapd
x_msg "> Starting hostapd..."
hostapd ${HOSTAPD_CONF_FILE} &
HOSTAPD_PID=$(echo $$)

# Give it some time to start the access point. Dnsmasq must be started after it is initialized
sleep 10

# Do we want to use DHCP service?
if [ "${USE_DHCP}" -eq 1 ]; then

    # Starting dnsmasq
    x_msg "> Starting dnsmasq..."

    if ! $(which dnsmasq) --conf-file="${DNSMASQ_CONF_FILE}"; then
        x_msg "dnsmasq failed to start!" 1
    fi

    DNSMASQ_PID=$(echo $$)
fi

# Trap
rm ${PIDFILE}

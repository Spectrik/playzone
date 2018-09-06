### function file

# Check if command is usable
function is_installed {
    if [ -n "$1" ]; then
        if which $1 > /dev/null; then
            return 0
        else
            return 1
        fi
    fi
}

# Check for root privileges
function is_root {
    if [ $(id -u) -ne 0 ]; then
        echo "You need to run this as root!"
        exit 1
    fi
}

# Echo with exit code
function x_msg {
    echo "$1"
    
    if [ -n "$2" ]; then
        exit "$2"
    fi
}

# Show help
function show_help {
    echo "THIS IS HELP!"
    exit 0
}

# Configure hostapd 
# "${INTERFACE}" "${SSID}" "${AP_HWMODE}" "${AP_CHANNEL}" "${AP_ENCRYPTION}" "${AP_CIPHERS}" "${WIFI_PASS}"
function create_hostapd_conf {

    # Check argcount
    if [ $# -ne 7 ]; then
        x_msg "Wrong count of args passed to the create_hostapd_conf function!" 1
    fi

    # Default stuff
    echo "driver=nl80211" > ${HOSTAPD_CONF_FILE}
    echo "country_code=CZ" >> ${HOSTAPD_CONF_FILE}

    # Argument stuff
    echo "interface=$1" >> ${HOSTAPD_CONF_FILE}
    echo "ssid=$2" >> ${HOSTAPD_CONF_FILE}
    echo "hw_mode=$3" >> ${HOSTAPD_CONF_FILE}
    echo "channel=$4" >> ${HOSTAPD_CONF_FILE}

    # Empty wifi password - no encryption
    if [ -z "$7" ]; then
        return 0
    fi

    # Encryption type related stuff
    case ${5} in
        "WEP")
            echo "auth_algs=2" >> ${HOSTAPD_CONF_FILE}
            echo "wep_default_key=1" >> ${HOSTAPD_CONF_FILE}
            echo "wep_key1=$7" >> ${HOSTAPD_CONF_FILE}

            return 0
        ;;

        "WPA")
            echo "wpa=1" >> ${HOSTAPD_CONF_FILE}
        ;;

        "WPA2")
            echo "wpa=2" >> ${HOSTAPD_CONF_FILE}
        ;;
    
        *)
            x_msg "Uknown type of encryption!" 1
        ;;
    esac

    # Set the cipher & password
    echo "auth_algs=1" >> ${HOSTAPD_CONF_FILE}
    echo "wpa_pairwise=$6" >> ${HOSTAPD_CONF_FILE}
    echo -e "wpa_key_mgmt=WPA-PSK\nwpa_passphrase=$7" >> ${HOSTAPD_CONF_FILE}

    return 0
}

# Configure dnsmasq
function create_dnsmasq_conf {
    
    local PREFIX
    local GW
    local RANGE

    # Check argcount
    if [ $# -ne 2 ]; then
        x_msg "Wrong count of args passed to the create_dnsmasq_conf function!" 1
    fi

    if [ ${1: -2} != ".0" ]; then
        x_msg "Wrong IP network format entered!" 1
    fi

    PREFIX=${1::-2}
    GW="${PREFIX}.1"
    RANGE="${PREFIX}.100,${PREFIX}.200,12h"

    echo "dhcp-range=${RANGE}" > ${DNSMASQ_CONF_FILE}
    echo "dhcp-option=3,${GW}" >> ${DNSMASQ_CONF_FILE}
    echo "dhcp-option=6,${GW},8.8.8.8" >> ${DNSMASQ_CONF_FILE}
    echo "no-resolv" >> ${DNSMASQ_CONF_FILE}
    echo "interface=${2}" >> ${DNSMASQ_CONF_FILE}
    echo "listen-address=${GW}" >> ${DNSMASQ_CONF_FILE}
    echo "bind-interfaces" >> ${DNSMASQ_CONF_FILE}

    # Assign the IP to the interface
    if ! ip address show ${INTERFACE} | grep -q "${GW}/24"; then
        if ! ip address add "${GW}/24" dev wlan1; then
            x_msg "Could not assign the ${GW}/24 to ${INTERFACE} interface" 1
        fi
    fi
}

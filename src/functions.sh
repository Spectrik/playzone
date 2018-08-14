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
            # TODO
        ;;

        "WPA")
            # TODO
            # CCMP does not make sense here. TKIP only.
        ;;

        "WPA2")
            # TODO
        ;;
    
        *)
            x_msg "Uknown type of encryption!" 1
        ;;
    esac

    # Set the password
    echo -e "wpa_key_mgmt=WPA-PSK\nwpa_passphrase=$7" >> ${HOSTAPD_CONF_FILE}

    return 0

}

# Configure dnsmasq
function create_dnsmasq_conf {

}
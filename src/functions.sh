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
function create_hostapd_conf {

}

# Configure dnsmasq
function create_dnsmasq_conf {
    
}
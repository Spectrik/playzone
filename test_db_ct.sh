#!/bin/bash

# Requires systemd based system
# Requires RPM based package manager
# Requires mysql-client
# Requires jq

# TODO: Function if provided datadir is not already mounted in some other container

### Vars (default values)

# Optional database dump file to restore
DUMP_FILE=""

# Name of the container
CT_NAME=""

# Mariadb docker image to use
MARIADB_DOCKER_IMG="mariadb"

# Local port to map to the port inside the CT
LOCAL_PORT_TO_MAP="6603"

# Local datadir folder to map to the one inside the CT
DB_LOCAL_DATADIR="$HOME/mysql"

# Mysql root password
MYSQL_ROOT_PASS="123456"

### Functions

# Check if provided datadir is not already mounted in some other container
check_datadir()
{
    local ID
    local TMP

    for ID in $(docker ps -a | awk '{print $1}' | tail -n +2)
    do
        # Get the mount paths from the container
        TMP=$(docker inspect $ID | jq '.[0].Mounts' | grep "Source")

        # Skip the empty ones
        if [ -z "$TMP" ]; then
            continue
        fi

        # Tell the user
        if echo "$TMP" | grep -q "$DB_LOCAL_DATADIR"; then
            echo "The local mount $DB_LOCAL_DATADIR is probably already mounted in container $ID"
            exit 1
        fi
    done
}

# Show usage
show_help ()
{
    echo -e "TODO: Short desc\n"
    echo -e "\tUsage:"
    echo -e "\t\t--port         Local port to map to the database port inside the CT (default 6603)"
    echo -e "\t\t--dump         Optional path to the database dump file to restore"
    echo -e "\t\t--ctname       Name of the container"
    echo -e "\t\t--datadir      Local datadir folder to map to the one inside the CT (default \$HOME/mysql)"
    echo -e "\t\t--password     Mysql root password (default 123456)\n"
}

# Checks
run_checks ()
{
    # Check if root
    if ! [ $(id -u) -eq 0 ]; then
        echo "Run this script as root!"
        exit 1
    fi

    # Check if docker is installed
    if ! rpm -qa docker > /dev/null 2>&1; then
        echo "Docker is probably not installed! Install it first, please."
        exit 1
    fi

    # Check if jq is installed
    if ! rpm -qa jq > /dev/null 2>&1; then
        echo "jq is probably not installed! Install it first, please."
        exit 1
    fi

    # Check if mysql-client is installed
    if ! which mysql > /dev/null 2>&1; then
        echo "mysql-client is probably not installed! Install it first, please."
        exit 1
    fi

    # Check if docker is running
    if ! systemctl status docker > /dev/null; then
        echo "Docker is probably not running!"
        systemctl status docker

        exit 1
    fi

    # Check if the local datadir mount exists
    if [ -n "$DB_LOCAL_DATADIR" ]; then
        if ! [ -e "$DB_LOCAL_DATADIR" ]; then
            echo "Local mount datadir $DB_LOCAL_DATADIR does not exist!"
            exit 1
        fi
    fi

    # Check if the DB dump file exists
    if [ -n "$DUMP_FILE" ]; then
        if [ -e "$DUMP_FILE" ]; then
            echo "The DB dump file $DUMP_FILE does not exist!"
            exit 1
        fi
    fi

    # Check if the user provided  the name of the container
    if [ -z "$CT_NAME" ]; then
        echo "You need to provide the name of the container!"
        exit 1
    fi

    # Check if we have the docker image
    if ! docker images | awk '{print $1}' | tail -n +2 | grep "$MARIADB_DOCKER_IMG" > /dev/null; then
        echo "Could not find the database image! Trying to pull it now..."

        if ! docker pull "$MARIADB_DOCKER_IMG"; then
            echo "Could not pull the image $MARIADB_DOCKER_IMG"
            exit 1
        fi
    fi

    # Check whether the port is already taken
    if netstat -natp | grep docker-proxy | grep "$LOCAL_PORT_TO_MAP"; then
        echo "The port $LOCAL_PORT_TO_MAP is already being used by other container!"
        exit 1
    fi

    # Check datadir
    check_datadir
}

### MAIN

# Process args
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

while [[ $# -gt 0 ]]; do
    KEY="$1"

    case $KEY in

        --help)
            show_help
            exit 0
        ;;

        --port)
            LOCAL_PORT_TO_MAP="$2"
            shift 
        ;;

        --password)
            MYSQL_ROOT_PASS="$2"
            shift 
        ;;

        --dump)
            DUMP_FILE="$2"
            shift 
        ;;

        --datadir)
            DB_LOCAL_DATADIR="$2"
            shift 
        ;;

        --ctname)
            CT_NAME="$2"
            shift 
        ;;

        *)
            break
        ;;
    esac
    shift
done

# Run all the neccessary checks
run_checks

# CT already existing?
if docker ps -a | grep "$CT_NAME" > /dev/null; then
    echo "There is already some container with name $CT_NAME!"
    exit 1
fi

# Starting the container
if ! docker run -d --name "$CT_NAME" -p "$LOCAL_PORT_TO_MAP":3306 -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASS" -v "$DB_LOCAL_DATADIR":/var/lib/mysql "$MARIADB_DOCKER_IMG" > /dev/null; then
    echo "Could not start the container!"
    exit 1
fi

# Give some time to the container to start
echo "Giving some time to container to start..."
sleep 5

# Optionally restore the database dump
if [ -n "$DUMP_FILE" ]; then
    echo "Restoring the dump now..."

    if ! mysql -h 127.0.0.1 -u root -p$MYSQL_ROOT_PASS -P $LOCAL_PORT_TO_MAP < $DUMP_FILE; then
        echo "Could not restore the DB dump!"
        exit 1
    fi
fi

# Give the user info
echo "You should be able to connect to mysql console by running: mysql -h 127.0.0.1 -u root -p$MYSQL_ROOT_PASS -P $LOCAL_PORT_TO_MAP"

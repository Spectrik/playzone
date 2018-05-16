#!/bin/bash

# Author: ojanas@redhat.com

# TODO: Desc
# TODO: get rid of jq with docker inspect --format

# Requires systemd based system
# Requires RPM based package manager
# Requires mysql-client
# Requires jq

### Vars (default values)

# Get IP address of container switch
GET_IP=0
GET_IP_CT_NAME=""

# Use web interface for database?
USE_ADMINER=0

# HTTP local port to map to the port inside the CT
ADMINER_LOCAL_PORT="8080"

# Optional database dump file to restore
DUMP_FILE=""

# Name of the DB container
CT_NAME=""

# Mariadb docker image to use
MARIADB_DOCKER_IMG="mariadb"

# Database local port to map to the port inside the CT
DATABASE_LOCAL_PORT="6603"

# Local datadir folder to map to the one inside the CT
DB_LOCAL_DATADIR="$HOME/mysql"

# Mysql root password
MYSQL_ROOT_PASS="123456"

### Functions

# Show usage
show_help ()
{
    echo -e "TODO: Short desc\n"
    echo -e "\tUsage:"
    echo -e "\t\t--port         Local port to map to the database port inside the CT (default 6603)"
    echo -e "\t\t--dump         Optional path to the database dump file to restore"
    echo -e "\t\t--ctname       Name of the container"
    echo -e "\t\t--datadir      Local datadir folder to map to the one inside the CT (default \$HOME/mysql)"
    echo -e "\t\t--password     Mysql root password (default 123456)"
    echo -e "\t\t--adminer      Deploy a web interface container to manage the database"
    echo -e "\t\t--adminerport  Local port to map to the adminer port inside the CT (default 8080)"
    echo -e "\t\t--getip        Get local IP of the container based on its name in order to log into DB via adminer"  
}

# Get local IP of CT
get_ip ()
{
    # Get the IP address of the CT
    if [ "$GET_IP" -eq 1 ]; then
        if [ -z "$GET_IP_CT_NAME" ]; then
            echo "You need to provide a name of the container in order to get it's IP address!"
            exit 1
        fi

        if ! docker ps --format '{{.Names}}' | grep -q "$GET_IP_CT_NAME"; then
            echo "There is no container with name $GET_IP_CT_NAME"
            exit 1
        fi

        docker inspect "$GET_IP_CT_NAME" --format '{{.NetworkSettings.Networks.bridge.IPAddress}}'
        exit 1
    fi
}

# Check functions
general_checks ()
{
    # Check if root
    if ! [ $(id -u) -eq 0 ]; then
        echo "Run this script as root!"
        exit 1
    fi

    # Check if docker is installed
    package_exists docker 

    # Check if jq is installed
    package_exists jq

    # Check if mysql-client is installed
    if ! which mysql > /dev/null 2>&1; then
        echo "mysql-client is probably not installed! Install it first, please."
        exit 1
    fi

    # Check if docker daemon is running
    if ! systemctl status docker > /dev/null; then
        echo "Docker is probably not running!"
        systemctl status docker

        exit 1
    fi
}

db_checks ()
{
    # Check if the local datadir mount exists
    if [ -n "$DB_LOCAL_DATADIR" ]; then
        if ! [ -e "$DB_LOCAL_DATADIR" ]; then
            echo "Local mount datadir $DB_LOCAL_DATADIR does not exist!"
            exit 1
        fi
    fi

    # Check if the DB dump file exists
    if [ -n "$DUMP_FILE" ]; then
        if ! [ -e "$DUMP_FILE" ]; then
            echo "The DB dump file $DUMP_FILE does not exist!"
            exit 1
        fi
    fi

    # Check if the user provided  the name of the container
    if [ -z "$CT_NAME" ]; then
        echo "You need to provide the name of the DB container in order to deploy it!"
        exit 1
    fi

    # Check if we have the docker image
    image_exists "$MARIADB_DOCKER_IMG"

    # Check whether the port is already taken
    port_taken "$DATABASE_LOCAL_PORT"

    # Check datadir
    check_datadir

    # DB CT already existing?
    if is_running "$CT_NAME"; then
        exit 1
    fi
}

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

# Check if container is running
is_running ()
{
    if docker ps -a | grep "$1" > /dev/null; then
        echo "There is already some container with name $1!"
        return 0
    fi

    return 1
}

# Check if package is istalled
package_exists ()
{
    if ! rpm -qa "$1" > /dev/null 2>&1; then
        echo "$1 is probably not installed! Install it first, please."
        exit 1
    fi
}

# Check if docker image exists locally
image_exists ()
{
    if ! docker images | awk '{print $1}' | tail -n +2 | grep "$1" > /dev/null; then
        echo "Could not find the database image! Trying to pull it now..."

        if ! docker pull "$1"; then
            echo "Could not pull the image $1"
            exit 1
        fi
    fi
}

# Check if port is already taken
port_taken ()
{
    if netstat -natp | grep docker-proxy | grep "$1" > /dev/null; then
        echo "The port $1 is already being used by other container!"
        exit 1
    fi
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

        --adminerport)
            ADMINER_LOCAL_PORT="$2"
            shift
        ;;

        --port)
            DATABASE_LOCAL_PORT="$2"
            shift 
        ;;

        --adminer)
            USE_ADMINER=1
        ;;

        --password)
            MYSQL_ROOT_PASS="$2"
            shift 
        ;;

        --dump)
            DUMP_FILE="$2"
            shift 
        ;;

        --getip)
            GET_IP=1
            GET_IP_CT_NAME="$2"
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
general_checks

# Get IP
get_ip

# Run adminer?
if [ "$USE_ADMINER" -eq 1 ]; then
    
    image_exists "adminer"
    
    if ! is_running "adminer"; then
        if ! docker run --name adminer -d -p "$ADMINER_LOCAL_PORT":8080 adminer > /dev/null; then
            echo "Could not start adminer container!"
            exit 1
        fi
    fi

    # Give user the info
    echo -e "You should be able to connect to adminer by going to http://127.0.0.1:$ADMINER_LOCAL_PORT \n"
fi

# Run DB checks
db_checks

# Starting the container
if ! docker run -d --name "$CT_NAME" -p "$DATABASE_LOCAL_PORT":3306 -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASS" -v "$DB_LOCAL_DATADIR":/var/lib/mysql "$MARIADB_DOCKER_IMG" > /dev/null; then
    echo "Could not start the container!"
    exit 1
fi

# Give some time to the container to start
echo "Giving some time to container to start..."
sleep 5

# Optionally restore the database dump
if [ -n "$DUMP_FILE" ]; then
    echo "Restoring the dump now..."

    if ! mysql -h 127.0.0.1 -u root -p$MYSQL_ROOT_PASS -P $DATABASE_LOCAL_PORT < $DUMP_FILE; then
        echo "Could not restore the DB dump!"
        exit 1
    fi
fi

# Give the user info
echo "You should be able to connect to mysql console by running: mysql -h 127.0.0.1 -u root -p$MYSQL_ROOT_PASS -P $DATABASE_LOCAL_PORT"
